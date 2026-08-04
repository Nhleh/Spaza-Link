-- ============================================================================
-- SpazaLink — account-existence check for clearer login errors
-- Lets the app tell "account does not exist" apart from "wrong password"
-- (Supabase returns the same generic error for both).
-- Run once in the Supabase SQL Editor.
-- ============================================================================

create or replace function public.email_exists(p_email text)
returns boolean
language sql
security definer
set search_path = public, auth
as $$
  select exists(
    select 1 from auth.users where lower(email) = lower(trim(p_email))
  );
$$;

-- Callable before the user is signed in.
grant execute on function public.email_exists(text) to anon, authenticated;
