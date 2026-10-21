begin;

-- Normalize both API resources: the variety-wise endpoint uses title-case
-- fields, while the current-daily endpoint uses lower-case field names.
create or replace function rm_private.ingest(payload jsonb) returns integer
language plpgsql security definer set search_path='' as $$
declare
 r jsonb; mid text; cid text; rows_added integer:=0; report_day date; price numeric;
 source_state text; source_district text; source_market text; source_commodity text;
 source_variety text; source_grade text; arrival text; source_min text; source_max text;
 source_modal text; source_code text;
begin
 for r in select value from jsonb_array_elements(payload) loop
  begin
   source_state:=coalesce(r->>'State',r->>'state');
   source_district:=coalesce(r->>'District',r->>'district');
   source_market:=coalesce(r->>'Market',r->>'market');
   source_commodity:=coalesce(r->>'Commodity',r->>'commodity');
   source_variety:=coalesce(r->>'Variety',r->>'variety','');
   source_grade:=coalesce(r->>'Grade',r->>'grade','');
   source_code:=coalesce(r->>'Commodity_Code',r->>'commodity_code');
   arrival:=coalesce(r->>'Arrival_Date',r->>'arrival_date');
   source_min:=coalesce(r->>'Min_Price',r->>'min_price');
   source_max:=coalesce(r->>'Max_Price',r->>'max_price');
   source_modal:=coalesce(r->>'Modal_Price',r->>'modal_price');

   if lower(coalesce(source_state,''))<>'karnataka' or source_market is null or source_commodity is null then continue; end if;
   select id into mid from public.rm_markets where
    lower(coalesce(api_name,name))=lower(source_market) and
    lower(coalesce(api_district,(select name from public.rm_districts where id=district_id)))=lower(coalesce(source_district,'')) limit 1;
   if mid is null then continue; end if;

   if arrival ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' then
    report_day:=to_date(arrival,'DD/MM/YYYY');
   elsif arrival ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    report_day:=to_date(arrival,'YYYY-MM-DD');
   else
    continue;
   end if;
   if report_day is null or report_day>(now() at time zone 'Asia/Kolkata')::date then continue; end if;
   price:=nullif(source_modal,'')::numeric;
   if price is null or price<=0 then continue; end if;

   cid:=coalesce(nullif(source_code,''),rm_private.slug(source_commodity));
   insert into public.rm_commodities(id,name,source_code)
   values(cid,source_commodity,source_code)
   on conflict(id) do update set name=excluded.name,source_code=coalesce(excluded.source_code,public.rm_commodities.source_code);
   insert into public.rm_prices(market_id,commodity_id,variety,grade,report_date,min_price,max_price,modal_price,source_resource)
   values(mid,cid,source_variety,source_grade,report_day,nullif(source_min,'')::numeric,nullif(source_max,'')::numeric,price,'9ef84268-d588-465a-a308-a864a43d0070')
   on conflict(market_id,commodity_id,variety,grade,report_date) do update
   set min_price=excluded.min_price,max_price=excluded.max_price,modal_price=excluded.modal_price,
       source_resource=excluded.source_resource,fetched_at=now();
   rows_added:=rows_added+1;
  exception when invalid_text_representation or datetime_field_overflow or check_violation or not_null_violation then
   continue;
  end;
 end loop;
 return rows_added;
end; $$;

create or replace function public.rm_request_refresh(p_market text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 m public.rm_markets; state public.rm_refresh; k text; req bigint; usage integer;
 today_local date; retry_at timestamptz;
begin
 select * into m from public.rm_markets where id=p_market;
 if m.id is null then raise exception 'Unknown market'; end if;
 today_local:=(now() at time zone 'Asia/Kolkata')::date;
 retry_at:=((today_local+1)::timestamp at time zone 'Asia/Kolkata');

 -- Once this market has any observation dated today, app opens only read the
 -- shared Supabase rows. They never contact data.gov.in again that day.
 if exists(select 1 from public.rm_prices where market_id=p_market and report_date=today_local) then
  return jsonb_build_object('status','ready','message','Today’s market prices are already saved.');
 end if;

 perform pg_advisory_xact_lock(hashtext('rm_refresh_budget'));
 select * into state from public.rm_refresh where market_id=p_market for update;
 if state.requested_at>now()-interval '45 seconds' and state.status='pending' then
  return jsonb_build_object('status','pending','message','A shared refresh is already running.');
 end if;
 -- At most one source attempt per market per local calendar day while today’s
 -- observations have not arrived. A new day automatically becomes eligible.
 if state.next_retry_at>now() then
  return jsonb_build_object('status',state.status,'message',coalesce(state.message,'Waiting for today’s market report.'));
 end if;

 select decrypted_secret into k from vault.decrypted_secrets where name='rm_data_gov_api_key' limit 1;
 if k is null then return jsonb_build_object('status','unconfigured','message','The market data connection is awaiting configuration.'); end if;
 select used into usage from rm_private.api_budget where day=today_local;
 if coalesce(usage,0)>=60 then
  update public.rm_refresh set status='limited',next_retry_at=retry_at,message='The shared daily refresh budget is reached. Saved reports remain available.' where market_id=p_market;
  return jsonb_build_object('status','limited','message','The shared daily refresh budget is reached. Saved reports remain available.');
 end if;
 insert into rm_private.api_budget(day,used) values(today_local,1)
 on conflict(day) do update set used=rm_private.api_budget.used+1;

 -- Current Daily Prices resource. A large page captures all varieties and
 -- commodities for this mandi in one upstream request where the key allows it.
 select net.http_get(
  url:='https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070',
  params:=jsonb_build_object(
   'api-key',k,'format','json','limit','1000','offset','0',
   'filters[state.keyword]','Karnataka',
   'filters[district]',coalesce(m.api_district,(select name from public.rm_districts where id=m.district_id)),
   'filters[market]',coalesce(m.api_name,m.name)
  ), timeout_milliseconds:=20000
 ) into req;
 insert into public.rm_refresh(market_id,request_id,status,requested_at,next_retry_at,message)
 values(p_market,req,'pending',now(),now()+interval '1 minute','Checking the current daily market report.')
 on conflict(market_id) do update set request_id=req,status='pending',requested_at=now(),next_retry_at=now()+interval '1 minute',message='Checking the current daily market report.';
 return jsonb_build_object('status','pending','message','Checking the current daily market report.');
end; $$;

create or replace function public.rm_finish_refresh(p_market text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 state public.rm_refresh; response net._http_response; payload jsonb; n integer; records jsonb;
 today_local date; retry_at timestamptz; has_today boolean;
begin
 today_local:=(now() at time zone 'Asia/Kolkata')::date;
 retry_at:=((today_local+1)::timestamp at time zone 'Asia/Kolkata');
 select * into state from public.rm_refresh where market_id=p_market for update;
 if state.market_id is null then return jsonb_build_object('status','never'); end if;
 if state.status<>'pending' then return jsonb_build_object('status',state.status,'message',state.message); end if;
 select * into response from net._http_response where id=state.request_id;
 if response.id is null then
  if state.requested_at>now()-interval '40 seconds' then return jsonb_build_object('status','pending'); end if;
  update public.rm_refresh set status='error',message='The source did not respond. Saved reports remain available.',next_retry_at=retry_at where market_id=p_market;
  return jsonb_build_object('status','error','message','The source did not respond. Saved reports remain available.');
 end if;
 if response.status_code<>200 or response.timed_out or response.error_msg is not null then
  update public.rm_refresh set status='error',message='Source refresh unavailable. Saved reports remain available.',next_retry_at=retry_at where market_id=p_market;
  return jsonb_build_object('status','error','message','Source refresh unavailable. Saved reports remain available.');
 end if;
 begin
  payload:=response.content::jsonb;
  if jsonb_typeof(payload->'records')<>'array' or payload->'records' is null then raise exception 'Unexpected data'; end if;
  select coalesce(jsonb_agg(r),'[]'::jsonb) into records from jsonb_array_elements(payload->'records') r
  where lower(coalesce(r->>'market',r->>'Market',''))=lower((select coalesce(api_name,name) from public.rm_markets where id=p_market));
  n:=rm_private.ingest(records);
  select exists(select 1 from public.rm_prices where market_id=p_market and report_date=today_local) into has_today;
  update public.rm_refresh set status='ready',checked_at=now(),next_retry_at=retry_at,imported=n,partial=not has_today,
   message=case when has_today then 'Today’s prices were saved from the current daily report.'
    when n=0 then 'No current-day prices yet. Saved observations remain available; another check is scheduled for tomorrow.'
    else 'Older report rows were saved. Waiting for today’s price report; another check is scheduled for tomorrow.' end
   where market_id=p_market;
  return jsonb_build_object('status','ready','imported',n,'current_day',has_today,
   'message',case when has_today then 'Today’s market prices are saved.' else 'No current-day prices yet. Saved reports remain available.' end);
 exception when others then
  update public.rm_refresh set status='error',message='The source response could not be read. Another check is scheduled for tomorrow.',next_retry_at=retry_at where market_id=p_market;
  return jsonb_build_object('status','error','message','The source response could not be read.');
 end;
end; $$;

revoke all on function public.rm_request_refresh(text),public.rm_finish_refresh(text) from public;
grant execute on function public.rm_request_refresh(text),public.rm_finish_refresh(text) to anon,authenticated;
commit;
