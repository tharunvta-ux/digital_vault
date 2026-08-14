-- Module 5, Phase 1: Smart Reminder database schema.
-- Run this once, manually, in the Supabase Dashboard's SQL Editor.
-- Assumes only that public.vault_documents already exists (from the
-- Firestore -> Postgres migration) -- nothing else is assumed present.

create extension if not exists pgcrypto;

create table public.reminders (
  id                     uuid primary key default gen_random_uuid(),
  owner_uid              uuid not null references auth.users (id),
  -- Mandatory: every reminder belongs to exactly one document. Deleting
  -- that document deletes its reminders too -- a reminder about a document
  -- that no longer exists isn't a state this schema allows.
  document_id            uuid not null references public.vault_documents (id) on delete cascade,
  title                  text not null,
  description            text null,
  reminder_date          date not null,
  reminder_time          time not null,
  repeat_type            text not null default 'once'
                           constraint reminders_repeat_type_check
                           check (repeat_type in ('once', 'daily', 'weekly', 'monthly', 'yearly')),
  notification_enabled   boolean not null default true,
  completed              boolean not null default false,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

-- Matches how a reminder list screen will query: current user's reminders,
-- soonest first, optionally filtered to pending vs completed.
create index reminders_owner_date_time_idx
  on public.reminders (owner_uid, reminder_date, reminder_time);

create index reminders_owner_completed_idx
  on public.reminders (owner_uid, completed);

-- Postgres doesn't auto-index foreign key columns; needed once Phase 6
-- queries "reminders for this document."
create index reminders_document_id_idx
  on public.reminders (document_id);

-- updated_at auto-touch trigger -- unlike vault_documents (which sets
-- updated_at manually from Dart on every write), this one is enforced at
-- the database level so it can never be forgotten on a future write path.
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger reminders_set_updated_at
  before update on public.reminders
  for each row
  execute function public.set_updated_at();

-- Row Level Security -- same per-operation policy shape already used for
-- vault_documents and storage.objects.
alter table public.reminders enable row level security;

create policy "Users can read their own reminders"
  on public.reminders for select
  using (auth.uid() = owner_uid);

create policy "Users can insert their own reminders"
  on public.reminders for insert
  with check (auth.uid() = owner_uid);

create policy "Users can update their own reminders"
  on public.reminders for update
  using (auth.uid() = owner_uid)
  with check (auth.uid() = owner_uid);

create policy "Users can delete their own reminders"
  on public.reminders for delete
  using (auth.uid() = owner_uid);
