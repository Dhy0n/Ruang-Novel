-- RuangNovel: reader accounts' cross-device bookmarks
-- Run this entire file in Supabase Dashboard > SQL Editor.
create table if not exists public.ruangnovel_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  novel_id integer not null check (novel_id > 0),
  created_at timestamptz not null default now(),
  primary key (user_id, novel_id)
);

create index if not exists ruangnovel_bookmarks_user_idx
  on public.ruangnovel_bookmarks (user_id);

alter table public.ruangnovel_bookmarks enable row level security;

revoke all on table public.ruangnovel_bookmarks from anon, authenticated;
grant select, insert, delete on table public.ruangnovel_bookmarks to authenticated;

drop policy if exists "Readers can view their own bookmarks" on public.ruangnovel_bookmarks;
create policy "Readers can view their own bookmarks"
  on public.ruangnovel_bookmarks for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Readers can add their own bookmarks" on public.ruangnovel_bookmarks;
create policy "Readers can add their own bookmarks"
  on public.ruangnovel_bookmarks for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Readers can remove their own bookmarks" on public.ruangnovel_bookmarks;
create policy "Readers can remove their own bookmarks"
  on public.ruangnovel_bookmarks for delete
  to authenticated
  using ((select auth.uid()) = user_id);
