-- RuangNovel: shared comments and replies (Supabase)
-- Run this entire file in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.ruangnovel_comments (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null check (scope_type in ('novel', 'chapter')),
  novel_id integer not null check (novel_id > 0),
  chapter_number integer,
  parent_id uuid references public.ruangnovel_comments(id) on delete cascade,
  nickname text not null check (char_length(trim(nickname)) between 1 and 40),
  message text not null check (char_length(trim(message)) between 1 and 1500),
  created_at timestamptz not null default now(),
  constraint ruangnovel_scope_chapter_check check (
    (scope_type = 'novel' and chapter_number is null) or
    (scope_type = 'chapter' and chapter_number is not null and chapter_number > 0)
  )
);

create index if not exists ruangnovel_comments_scope_created_idx
  on public.ruangnovel_comments (scope_type, novel_id, chapter_number, created_at desc);
create index if not exists ruangnovel_comments_parent_idx
  on public.ruangnovel_comments (parent_id);

alter table public.ruangnovel_comments enable row level security;

grant select, insert on table public.ruangnovel_comments to anon, authenticated;

drop policy if exists "Anyone can read RuangNovel comments" on public.ruangnovel_comments;
create policy "Anyone can read RuangNovel comments"
  on public.ruangnovel_comments for select
  to anon, authenticated
  using (true);

drop policy if exists "Anyone can post RuangNovel comments" on public.ruangnovel_comments;
create policy "Anyone can post RuangNovel comments"
  on public.ruangnovel_comments for insert
  to anon, authenticated
  with check (
    char_length(trim(nickname)) between 1 and 40
    and char_length(trim(message)) between 1 and 1500
    and (
      parent_id is null
      or exists (
        select 1
        from public.ruangnovel_comments parent
        where parent.id = ruangnovel_comments.parent_id
          and parent.scope_type = ruangnovel_comments.scope_type
          and parent.novel_id = ruangnovel_comments.novel_id
          and parent.chapter_number is not distinct from ruangnovel_comments.chapter_number
      )
    )
  );

-- No public UPDATE or DELETE policy is intentionally created.
