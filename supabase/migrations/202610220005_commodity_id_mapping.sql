begin;

-- The current-daily resource may omit Commodity_Code. Reuse an existing
-- commodity id by its normalized name so new observations join the same
-- history and crop-price views as earlier imported records.
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

   cid:=nullif(source_code,'');
   if cid is null then
    select c.id into cid from public.rm_commodities c
    where regexp_replace(lower(c.name),'[^a-z0-9]','','g')=regexp_replace(lower(source_commodity),'[^a-z0-9]','','g')
    order by c.id limit 1;
   end if;
   cid:=coalesce(cid,rm_private.slug(source_commodity));
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

commit;
