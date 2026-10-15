-- RuangNovel comment moderation
-- Run once in the Supabase SQL Editor for project fhcosyggbgpjhjbtyhge.
-- The moderator is the RuangNovel Auth user for asepridhwan73@gmail.com.
-- Never place a service_role key in the public website.

create table if not exists public.ruangnovel_moderators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.ruangnovel_moderators enable row level security;
grant select on public.ruangnovel_moderators to authenticated;

drop policy if exists "Moderators can view their own moderator record"
  on public.ruangnovel_moderators;
create policy "Moderators can view their own moderator record"
on public.ruangnovel_moderators
for select to authenticated
using ((select auth.uid()) = user_id);

insert into public.ruangnovel_moderators (user_id)
select id from auth.users
where lower(email) = lower('asepridhwan73@gmail.com')
on conflict (user_id) do nothing;

grant delete on public.ruangnovel_comments to authenticated;
drop policy if exists "Moderators can delete comments"
  on public.ruangnovel_comments;
create policy "Moderators can delete comments"
on public.ruangnovel_comments
for delete to authenticated
using (exists (
  select 1
  from public.ruangnovel_moderators m
  where m.user_id = (select auth.uid())
));

-- Deleting a top-level comment removes its replies as well.
alter table public.ruangnovel_comments
  drop constraint if exists ruangnovel_comments_parent_id_fkey;
alter table public.ruangnovel_comments
  add constraint ruangnovel_comments_parent_id_fkey
  foreign key (parent_id)
  references public.ruangnovel_comments(id)
  on delete cascade;
