-- Phase 4: Firestore -> Supabase PostgreSQL migration for Smart Vault.
-- Run this once, manually, in the Supabase Dashboard's SQL Editor.
-- Nothing here has been executed on your project yet.

-- Extension needed for gen_random_uuid()'s DEFAULT below (usually already
-- enabled on Supabase projects; harmless no-op if it already is).
create extension if not exists pgcrypto;

create table public.vault_documents (
  id            uuid primary key default gen_random_uuid(),
  owner_uid     uuid not null references auth.users (id),
  title         text not null,
  category      text not null,
  file_type     text not null,
  file_url      text not null,
  storage_path  text not null,
  file_size     bigint not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  -- Reserved for a future soft-delete feature. Unused by the app today --
  -- every delete is still a hard delete, exactly as it was with Firestore.
  deleted_at    timestamptz null
);

-- Matches watchDocuments' ORDER BY updated_at DESC, scoped per user
create index vault_documents_owner_updated_idx
  on public.vault_documents (owner_uid, updated_at desc);

-- Matches watchDocumentsByCategory
create index vault_documents_owner_category_idx
  on public.vault_documents (owner_uid, category);

-- Row Level Security -- the Postgres equivalent of your existing
-- firestore.rules ("allow read, write: if request.auth.uid == uid")
alter table public.vault_documents enable row level security;

create policy "Users can read their own documents"
  on public.vault_documents for select
  using (auth.uid() = owner_uid);

create policy "Users can insert their own documents"
  on public.vault_documents for insert
  with check (auth.uid() = owner_uid);

create policy "Users can update their own documents"
  on public.vault_documents for update
  using (auth.uid() = owner_uid)
  with check (auth.uid() = owner_uid);

create policy "Users can delete their own documents"
  on public.vault_documents for delete
  using (auth.uid() = owner_uid);

-- Required for the live-updating list/category streams (Firestore's
-- .snapshots() equivalent) -- without this, Supabase's .stream() loads
-- once and never receives live updates.
alter publication supabase_realtime add table public.vault_documents;
