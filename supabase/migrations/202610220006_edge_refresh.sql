begin;

-- Keep using the existing Vault secret so no API key needs to be copied into
-- Edge Function settings or embedded in the Flutter client.
create or replace function public.rm_get_data_api_key() returns text
language sql security definer set search_path='' as $$
 select decrypted_secret from vault.decrypted_secrets where name='rm_data_gov_api_key' limit 1;
$$;

-- Claim the once-per-day market refresh and reserve one shared API attempt.
-- The Edge Function performs the upstream request; Postgres only guards the
-- daily budget and persists the normalized response.
create or replace function public.rm_claim_current_refresh(p_market text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare state public.rm_refresh; usage integer; today_local date; retry_at timestamptz;
begin
 if not exists(select 1 from public.rm_markets where id=p_market) then
  return jsonb_build_object('status','invalid','message','The selected mandi could not be found.');
 end if;
 today_local:=(now() at time zone 'Asia/Kolkata')::date;
 retry_at:=((today_local+1)::timestamp at time zone 'Asia/Kolkata');

 if exists(select 1 from public.rm_prices where market_id=p_market and report_date=today_local) then
  return jsonb_build_object('status','ready','message','Today’s market prices are already saved.');
 end if;

 perform pg_advisory_xact_lock(hashtext('rm_refresh_budget'));
 select * into state from public.rm_refresh where market_id=p_market for update;
 if state.status='pending' and state.requested_at>now()-interval '45 seconds' then
  return jsonb_build_object('status','pending','message','A shared refresh is already running.');
 end if;
 -- Retry transient transport failures on a new app request. Successful empty
 -- results remain once per day, as required to protect the upstream quota.
 if state.next_retry_at>now() and state.status not in ('error','never') then
  return jsonb_build_object('status',state.status,'message',coalesce(state.message,'Waiting for today’s market report.'));
 end if;

 select used into usage from rm_private.api_budget where day=today_local for update;
 if coalesce(usage,0)>=60 then
  insert into public.rm_refresh(market_id,status,requested_at,checked_at,next_retry_at,message)
  values(p_market,'limited',now(),now(),retry_at,'The shared daily refresh budget is reached. Saved reports remain available.')
  on conflict(market_id) do update set status='limited',checked_at=now(),next_retry_at=retry_at,
   message='The shared daily refresh budget is reached. Saved reports remain available.';
  return jsonb_build_object('status','limited','message','The shared daily refresh budget is reached. Saved reports remain available.');
 end if;
 insert into rm_private.api_budget(day,used) values(today_local,1)
 on conflict(day) do update set used=rm_private.api_budget.used+1;

 insert into public.rm_refresh(market_id,request_id,status,requested_at,next_retry_at,message)
 values(p_market,null,'pending',now(),now()+interval '45 seconds','Checking the current daily market report.')
 on conflict(market_id) do update set request_id=null,status='pending',requested_at=now(),
  next_retry_at=now()+interval '45 seconds',message='Checking the current daily market report.';
 return jsonb_build_object('status','claimed','message','Checking the current daily market report.');
end; $$;

create or replace function public.rm_finish_current_refresh(p_market text,p_records jsonb,p_error text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare n integer:=0; today_local date; retry_at timestamptz; has_today boolean;
begin
 today_local:=(now() at time zone 'Asia/Kolkata')::date;
 retry_at:=((today_local+1)::timestamp at time zone 'Asia/Kolkata');
 if p_error is not null then
  update public.rm_refresh set status='error',checked_at=now(),message=left(p_error,240),next_retry_at=now()
  where market_id=p_market;
  return jsonb_build_object('status','error','message',left(p_error,240));
 end if;
 if jsonb_typeof(coalesce(p_records,'[]'::jsonb))<>'array' then
  update public.rm_refresh set status='error',checked_at=now(),message='The source response could not be read.',next_retry_at=now()
  where market_id=p_market;
  return jsonb_build_object('status','error','message','The source response could not be read.');
 end if;
 n:=rm_private.ingest(coalesce(p_records,'[]'::jsonb));
 select exists(select 1 from public.rm_prices where market_id=p_market and report_date=today_local) into has_today;
 update public.rm_refresh set status='ready',checked_at=now(),next_retry_at=retry_at,imported=n,partial=not has_today,
  message=case when has_today then 'Today’s prices were saved from the current daily report.'
   when n=0 then 'No current-day prices yet. Saved observations remain available; another check is scheduled for tomorrow.'
   else 'Older report rows were saved. Waiting for today’s price report; another check is scheduled for tomorrow.' end
 where market_id=p_market;
 return jsonb_build_object('status','ready','imported',n,'current_day',has_today,
  'message',case when has_today then 'Today’s market prices are saved.' else 'No current-day prices yet. Saved reports remain available.' end);
exception when others then
 update public.rm_refresh set status='error',checked_at=now(),message='The source response could not be saved.',next_retry_at=now()
 where market_id=p_market;
 return jsonb_build_object('status','error','message','The source response could not be saved.');
end; $$;

revoke all on function public.rm_claim_current_refresh(text) from public,anon,authenticated;
revoke all on function public.rm_finish_current_refresh(text,jsonb,text) from public,anon,authenticated;
revoke all on function public.rm_get_data_api_key() from public,anon,authenticated;
grant execute on function public.rm_claim_current_refresh(text) to service_role;
grant execute on function public.rm_finish_current_refresh(text,jsonb,text) to service_role;
grant execute on function public.rm_get_data_api_key() to service_role;

-- The old pg_net path timed out before reaching data.gov.in. Clear only its
-- cooldown so the Edge Function can retry the same market immediately.
update public.rm_refresh set next_retry_at=now()
where status='error' and requested_at>now()-interval '3 days'
 and (message ilike '%did not respond%' or message ilike '%refresh unavailable%');

commit;
