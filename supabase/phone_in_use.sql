-- Phone-uniqueness helper for customer registration.
-- The customer app calls this (as anon) BEFORE creating an auth user, so a
-- cellphone that already belongs to an account is rejected up front with the
-- correct "phone already registered" message. This also keeps phone-login
-- unambiguous, since login-by-phone resolves a number back to a single email.
--
-- Run this once in the Supabase SQL Editor.

create or replace function public.phone_in_use(p_phone text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where phone_number = p_phone
      and coalesce(p_phone, '') <> ''
  );
$$;

grant execute on function public.phone_in_use(text) to anon, authenticated;

-- Optional but recommended: enforce uniqueness at the database level too, so a
-- duplicate can never slip in via a race. Partial unique index ignores blanks.
create unique index if not exists profiles_phone_number_unique
  on public.profiles (phone_number)
  where phone_number is not null and phone_number <> '';
