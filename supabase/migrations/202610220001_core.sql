begin;
create schema if not exists rm_private;
revoke all on schema rm_private from public, anon, authenticated;

create table public.rm_districts (
 id text primary key, name text not null unique, name_kn text
);
create table public.rm_markets (
 id text primary key, district_id text not null references public.rm_districts(id),
 name text not null, api_name text, api_district text,
 latitude double precision, longitude double precision,
 verified boolean not null default false,
 source text not null default 'User supplied directory; not independently verified',
 unique(district_id,name),
 check(latitude between -90 and 90), check(longitude between -180 and 180)
);
create table public.rm_commodities (
 id text primary key, name text not null, name_kn text, source_code text
);
create table public.rm_prices (
 id bigint generated always as identity primary key,
 market_id text not null references public.rm_markets(id),
 commodity_id text not null references public.rm_commodities(id),
 variety text not null default '', grade text not null default '',
 report_date date not null, min_price numeric, max_price numeric,
 modal_price numeric not null check(modal_price>0),
 unit text not null default 'INR/quintal',
 fetched_at timestamptz not null default now(), source_resource text not null,
 unique(market_id,commodity_id,variety,grade,report_date),
 check(min_price is null or min_price>=0),
 check(max_price is null or max_price>=0),
 check(min_price is null or max_price is null or min_price<=max_price)
);
create index rm_prices_latest on public.rm_prices(market_id,commodity_id,variety,grade,report_date desc);
create table public.rm_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null default '', district_id text references public.rm_districts(id),
 market_id text references public.rm_markets(id), language text not null default 'en' check(language in ('en','kn')),
 updated_at timestamptz not null default now()
);
create table public.rm_crops (
 id uuid primary key, user_id uuid not null references auth.users(id) on delete cascade,
 commodity_name text not null check(length(commodity_name) between 1 and 100),
 variety text not null default '', quantity numeric check(quantity>0),
 planting_date date not null, harvest_date date, market_id text references public.rm_markets(id),
 notes text not null default '', created_at timestamptz not null default now(),
 check(harvest_date is null or harvest_date>=planting_date)
);
create index rm_crops_user on public.rm_crops(user_id);
create table public.rm_forecasts (
 id bigint generated always as identity primary key,
 market_id text not null references public.rm_markets(id), commodity_id text not null references public.rm_commodities(id),
 variety text not null default '', grade text not null default '',
 target_date date not null, low numeric not null, expected numeric not null, high numeric not null,
 model_version text not null, generated_at timestamptz not null default now(), valid_until timestamptz not null,
 check(low>0 and low<=expected and expected<=high),
 unique(market_id,commodity_id,variety,grade,target_date,model_version)
);
create table public.rm_alerts (
 id uuid primary key, user_id uuid not null references auth.users(id) on delete cascade,
 commodity_name text not null, market_id text references public.rm_markets(id),
 threshold numeric not null check(threshold>0), enabled boolean not null default true,
 created_at timestamptz not null default now()
);
create table public.rm_refresh (
 market_id text primary key references public.rm_markets(id),
 request_id bigint, status text not null default 'never',
 requested_at timestamptz, checked_at timestamptz, next_retry_at timestamptz,
 message text, imported integer not null default 0,
 partial boolean not null default true
);
create table rm_private.api_budget (
 day date primary key, used integer not null default 0
);

alter table public.rm_districts enable row level security;
alter table public.rm_markets enable row level security;
alter table public.rm_commodities enable row level security;
alter table public.rm_prices enable row level security;
alter table public.rm_profiles enable row level security;
alter table public.rm_crops enable row level security;
alter table public.rm_forecasts enable row level security;
alter table public.rm_alerts enable row level security;
alter table public.rm_refresh enable row level security;
create policy directory_read on public.rm_districts for select to anon,authenticated using(true);
create policy markets_read on public.rm_markets for select to anon,authenticated using(true);
create policy commodities_read on public.rm_commodities for select to anon,authenticated using(true);
create policy prices_read on public.rm_prices for select to anon,authenticated using(true);
create policy forecasts_read on public.rm_forecasts for select to anon,authenticated using(true);
create policy refresh_read on public.rm_refresh for select to anon,authenticated using(true);
create policy profile_owner on public.rm_profiles for all to authenticated using((select auth.uid())=id) with check((select auth.uid())=id);
create policy crop_owner on public.rm_crops for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy alert_owner on public.rm_alerts for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
grant select on public.rm_districts,public.rm_markets,public.rm_commodities,public.rm_prices,public.rm_forecasts,public.rm_refresh to anon,authenticated;
grant select,insert,update,delete on public.rm_profiles,public.rm_crops,public.rm_alerts to authenticated;

create view public.rm_latest_prices with (security_invoker=true) as
 select distinct on (p.market_id,p.commodity_id,p.variety,p.grade)
 p.*,c.name as commodity_name,m.name as market_name,m.district_id,d.name as district_name,
 (select p2.modal_price from public.rm_prices p2 where p2.market_id=p.market_id and p2.commodity_id=p.commodity_id and p2.variety=p.variety and p2.grade=p.grade and p2.report_date<p.report_date order by p2.report_date desc limit 1) as previous_price
 from public.rm_prices p join public.rm_commodities c on c.id=p.commodity_id
 join public.rm_markets m on m.id=p.market_id join public.rm_districts d on d.id=m.district_id
 order by p.market_id,p.commodity_id,p.variety,p.grade,p.report_date desc;
grant select on public.rm_latest_prices to anon,authenticated;

create function rm_private.slug(value text) returns text language sql immutable set search_path='' as $$
 select trim(both '-' from regexp_replace(lower(value),'[^a-z0-9]+','-','g'));
$$;
-- Only trusted ingestion code may call this. Each source observation keeps its date.
create function rm_private.ingest(payload jsonb) returns integer language plpgsql security definer set search_path='' as $$
declare r jsonb; mid text; cid text; count_rows integer:=0; report_day date; price numeric;
begin
 for r in select value from jsonb_array_elements(payload) loop
  begin
   if r->>'State'<>'Karnataka' then continue; end if;
   select id into mid from public.rm_markets where
    lower(coalesce(api_name,name))=lower(r->>'Market') and
    lower(coalesce(api_district,(select name from public.rm_districts where id=district_id)))=lower(r->>'District') limit 1;
   if mid is null then continue; end if;
   cid:=coalesce(nullif(r->>'Commodity_Code',''),rm_private.slug(r->>'Commodity'));
   report_day:=to_date(r->>'Arrival_Date','DD/MM/YYYY');
   if to_char(report_day,'DD/MM/YYYY')<>r->>'Arrival_Date' or report_day>current_date then continue; end if;
   price:=(r->>'Modal_Price')::numeric;
   if price<=0 then continue; end if;
   insert into public.rm_commodities(id,name,source_code) values(cid,r->>'Commodity',r->>'Commodity_Code') on conflict(id) do update set name=excluded.name;
   insert into public.rm_prices(market_id,commodity_id,variety,grade,report_date,min_price,max_price,modal_price,source_resource)
   values(mid,cid,coalesce(r->>'Variety',''),coalesce(r->>'Grade',''),report_day,nullif(r->>'Min_Price','')::numeric,nullif(r->>'Max_Price','')::numeric,price,'35985678-0d79-46b4-9ed6-6f13308a1d24')
   on conflict(market_id,commodity_id,variety,grade,report_date) do update set min_price=excluded.min_price,max_price=excluded.max_price,modal_price=excluded.modal_price,fetched_at=now();
   count_rows:=count_rows+1;
  exception when invalid_text_representation or datetime_field_overflow or check_violation or not_null_violation then continue;
  end;
 end loop;
 return count_rows;
end; $$;
revoke all on all functions in schema rm_private from public,anon,authenticated;
commit;
