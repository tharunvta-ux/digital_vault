-- Phase 5: Firebase Storage -> Supabase Storage migration for Smart Vault.
-- Run this once, manually, in the Supabase Dashboard's SQL Editor.
-- Nothing here has been executed on your project yet.

-- Private bucket -- matches your existing storage.rules, which restricted
-- access to request.auth.uid == uid, not "anyone with the URL." Access is
-- enforced below via RLS on storage.objects, not by making the bucket
-- public.
insert into storage.buckets (id, name, public)
values ('vault-files', 'vault-files', false)
on conflict (id) do nothing;

-- storage.objects already has Row Level Security enabled by default on
-- Supabase projects. These four policies mirror storage.rules' single rule
-- (allow read, write: if request.auth != null && request.auth.uid == uid)
-- for the users/{uid}/vault/{fileName} path convention used by
-- SupabaseVaultStorageService. storage.foldername(name) splits an object's
-- path into its folder segments, e.g. for
-- 'users/11111111-2222-.../vault/abc.pdf' it returns
-- ['users', '11111111-2222-...', 'vault'] -- index [2] is the uid segment.

create policy "Users can read their own vault files"
  on storage.objects for select
  using (
    bucket_id = 'vault-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

create policy "Users can upload their own vault files"
  on storage.objects for insert
  with check (
    bucket_id = 'vault-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

create policy "Users can update their own vault files"
  on storage.objects for update
  using (
    bucket_id = 'vault-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = auth.uid()::text
  )
  with check (
    bucket_id = 'vault-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

create policy "Users can delete their own vault files"
  on storage.objects for delete
  using (
    bucket_id = 'vault-files'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
