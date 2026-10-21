begin;

alter table public.rm_profiles add column if not exists avatar_url text;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('profile-photos','profile-photos',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,
 allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "Profile photos are publicly readable" on storage.objects;
create policy "Profile photos are publicly readable" on storage.objects
for select to public using(bucket_id='profile-photos');

drop policy if exists "Users upload their own profile photo" on storage.objects;
create policy "Users upload their own profile photo" on storage.objects
for insert to authenticated with check(
 bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text
);

drop policy if exists "Users update their own profile photo" on storage.objects;
create policy "Users update their own profile photo" on storage.objects
for update to authenticated using(
 bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text
) with check(
 bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text
);

drop policy if exists "Users delete their own profile photo" on storage.objects;
create policy "Users delete their own profile photo" on storage.objects
for delete to authenticated using(
 bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text
);

commit;
