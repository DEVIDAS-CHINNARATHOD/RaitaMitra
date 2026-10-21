create table if not exists rm_private.chat_quota (
 user_id uuid not null references auth.users(id) on delete cascade,
 day date not null,
 requests integer not null default 0,
 primary key(user_id, day)
);
create or replace function public.rm_chat_allow() returns boolean
language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
 if auth.uid() is null then return false; end if;
 insert into rm_private.chat_quota(user_id,day,requests)
 values(auth.uid(), (now() at time zone 'UTC')::date, 1)
 on conflict(user_id,day) do update set requests=rm_private.chat_quota.requests+1
 where rm_private.chat_quota.requests < 40
 returning requests into n;
 return n is not null;
end;
$$;
revoke all on function public.rm_chat_allow() from public, anon;
grant execute on function public.rm_chat_allow() to authenticated;
