-- Corrective fix: live testing on a real device shows every Realtime
-- subscription to vault_documents failing with:
--   RealtimeSubscribeException(status: channelError, details: Exception:
--   Unable to subscribe to changes with given parameters. Please check
--   Realtime is enabled for the given connect parameters: [...table:
--   vault_documents...])
--
-- This is Supabase's own diagnostic message for exactly one condition:
-- the table was never added to the supabase_realtime publication. This
-- was already step 4 of supabase_vault_documents.sql back in the original
-- Firestore -> Postgres migration -- the same kind of drift as the
-- owner_uid/owner_id mismatch: what's live on the project doesn't match
-- what the script specified.
--
-- Run this once, manually, in the Supabase Dashboard's SQL Editor.
--
-- Safe to run even if it's already correctly configured elsewhere --
-- adding a table that's already in the publication is a no-op here
-- because of the existence check.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'vault_documents'
  ) then
    alter publication supabase_realtime add table public.vault_documents;
  end if;
end $$;
