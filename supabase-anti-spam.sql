-- RuangNovel anti-spam protection for public comments
-- Run this file in Supabase Dashboard > SQL Editor AFTER supabase-comments.sql.
-- Enforces limits in the database so refreshing the browser cannot bypass them.

create or replace function public.ruangnovel_check_comment_spam()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  recent_count integer;
begin
  -- Serialize checks for the same normalized pen name to reduce race-condition bypasses.
  perform pg_advisory_xact_lock(hashtextextended(lower(regexp_replace(trim(new.nickname), '\s+', ' ', 'g')), 0));

  -- Prevent an identical message in the same discussion from being reposted for 2 minutes.
  if exists (
    select 1
    from public.ruangnovel_comments c
    where lower(trim(c.nickname)) = lower(trim(new.nickname))
      and c.scope_type = new.scope_type
      and c.novel_id = new.novel_id
      and c.chapter_number is not distinct from new.chapter_number
      and c.parent_id is not distinct from new.parent_id
      and lower(regexp_replace(trim(c.message), '\s+', ' ', 'g')) =
          lower(regexp_replace(trim(new.message), '\s+', ' ', 'g'))
      and c.created_at > now() - interval '2 minutes'
  ) then
    raise exception 'RUANGNOVEL_SPAM_DUPLICATE';
  end if;

  -- Maximum 5 comments per normalized pen name in a rolling 10-minute window.
  select count(*) into recent_count
  from public.ruangnovel_comments c
  where lower(trim(c.nickname)) = lower(trim(new.nickname))
    and c.created_at > now() - interval '10 minutes';

  if recent_count >= 5 then
    raise exception 'RUANGNOVEL_SPAM_RATE_LIMIT';
  end if;

  return new;
end;
$$;

drop trigger if exists ruangnovel_comment_anti_spam on public.ruangnovel_comments;
create trigger ruangnovel_comment_anti_spam
before insert on public.ruangnovel_comments
for each row execute function public.ruangnovel_check_comment_spam();

-- Trigger function is called by PostgreSQL automatically; clients do not need direct access.
revoke all on function public.ruangnovel_check_comment_spam() from public, anon, authenticated;
