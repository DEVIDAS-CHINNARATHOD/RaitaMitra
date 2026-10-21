begin;
create extension if not exists pg_net with schema extensions;
-- The request key is held in Vault, never in the APK or an exposed table.
create function public.rm_request_refresh(p_market text) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rm_markets; state public.rm_refresh; k text; req bigint; usage integer;
begin
 select * into m from public.rm_markets where id=p_market;
 if m.id is null then raise exception 'Unknown market'; end if;
 perform pg_advisory_xact_lock(hashtext('rm_refresh_budget'));
 select * into state from public.rm_refresh where market_id=p_market;
 if state.requested_at>now()-interval '45 seconds' and state.status='pending' then
  return jsonb_build_object('status','pending','message','A shared refresh is already running.');
 end if;
 if state.next_retry_at>now() then
  return jsonb_build_object('status',state.status,'message',coalesce(state.message,'Saved prices are being reused.'));
 end if;
 select decrypted_secret into k from vault.decrypted_secrets where name='rm_data_gov_api_key' limit 1;
 if k is null then return jsonb_build_object('status','unconfigured','message','The market data connection is awaiting configuration.'); end if;
 select used into usage from rm_private.api_budget where day=current_date;
 if coalesce(usage,0)>=60 then return jsonb_build_object('status','limited','message','The shared daily refresh budget is reached. Saved reports remain available.'); end if;
 insert into rm_private.api_budget(day,used) values(current_date,1) on conflict(day) do update set used=rm_private.api_budget.used+1;
 select net.http_get(
  url:='https://api.data.gov.in/resource/35985678-0d79-46b4-9ed6-6f13308a1d24',
  params:=jsonb_build_object('api-key',k,'format','json','limit','10','offset','0','filters[State]','Karnataka','filters[District]',coalesce(m.api_district,(select name from public.rm_districts where id=m.district_id)),'filters[Market]',coalesce(m.api_name,m.name),'sort[Arrival_Date]','desc'),
  timeout_milliseconds:=15000
 ) into req;
 insert into public.rm_refresh(market_id,request_id,status,requested_at,next_retry_at,message)
 values(p_market,req,'pending',now(),now()+interval '1 minute','Checking the source for reported prices.')
 on conflict(market_id) do update set request_id=req,status='pending',requested_at=now(),next_retry_at=now()+interval '1 minute',message='Checking the source for reported prices.';
 return jsonb_build_object('status','pending','message','Checking the source for reported prices.');
end; $$;

create function public.rm_finish_refresh(p_market text) returns jsonb language plpgsql security definer set search_path='' as $$
declare state public.rm_refresh; response net._http_response; payload jsonb; n integer; records jsonb;
begin
 select * into state from public.rm_refresh where market_id=p_market for update;
 if state.market_id is null then return jsonb_build_object('status','never'); end if;
 if state.status<>'pending' then return jsonb_build_object('status',state.status,'message',state.message); end if;
 select * into response from net._http_response where id=state.request_id;
 if response.id is null then
  if state.requested_at>now()-interval '40 seconds' then return jsonb_build_object('status','pending'); end if;
  update public.rm_refresh set status='error',message='The source did not respond. Showing saved reports.',next_retry_at=now()+interval '15 minutes' where market_id=p_market;
  return jsonb_build_object('status','error','message','The source did not respond. Showing saved reports.');
 end if;
 if response.status_code<>200 or response.timed_out or response.error_msg is not null then
  update public.rm_refresh set status='error',message='Source refresh unavailable. Showing saved reports.',next_retry_at=now()+interval '15 minutes' where market_id=p_market;
  return jsonb_build_object('status','error','message','Source refresh unavailable. Showing saved reports.');
 end if;
 begin
  payload:=response.content::jsonb;
  if jsonb_typeof(payload->'records')<>'array' or payload->'records' is null then raise exception 'Unexpected data'; end if;
  -- Only ingest rows that match the requested market, even if an upstream filter is ignored.
  select coalesce(jsonb_agg(r),'[]'::jsonb) into records from jsonb_array_elements(payload->'records') r
  where lower(r->>'Market')=lower((select coalesce(api_name,name) from public.rm_markets where id=p_market));
  n:=rm_private.ingest(records);
  update public.rm_refresh set status='ready',checked_at=now(),next_retry_at=now()+interval '1 hour',imported=n,partial=true,
  message=case when n=0 then 'No matching reports returned. Saved observations remain available.' else 'Source checked. Showing available reports; coverage may be partial.' end
  where market_id=p_market;
  return jsonb_build_object('status','ready','imported',n,'message','Source checked. Report dates are shown with each price.');
 exception when others then
  update public.rm_refresh set status='error',message='The source response could not be read.',next_retry_at=now()+interval '15 minutes' where market_id=p_market;
  return jsonb_build_object('status','error','message','The source response could not be read.');
 end;
end; $$;
revoke all on function public.rm_request_refresh(text),public.rm_finish_refresh(text) from public;
grant execute on function public.rm_request_refresh(text),public.rm_finish_refresh(text) to anon,authenticated;
commit;
