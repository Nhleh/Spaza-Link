-- ============================================================================
-- SpazaLink — security hardening. Run once in Supabase → SQL Editor.
-- Fixes the two highest-severity issues found in the audit:
--   1) Privilege escalation: a customer could set their own profiles.role to
--      'admin' (RLS allowed updating your own row, with no column guard).
--   2) Over-broad storage writes: any signed-in user could upload/overwrite
--      product & category images.
-- Safe to re-run.
-- ============================================================================

-- 1) Lock privileged profile columns. Non-admins can still edit their name,
--    phone, preferences, etc., but role / is_active are frozen to their old
--    values — only an admin can change them.
create or replace function public.protect_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    new.role      := old.role;
    new.is_active := old.is_active;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_privileges on public.profiles;
create trigger profiles_protect_privileges
  before update on public.profiles
  for each row execute function public.protect_profile_privileges();

-- 2) Restrict the shared image buckets. Shop owners may still upload their shop
--    photo (they're authenticated during registration); product & category
--    images become admin-only. (ad_images is already admin-only.)
drop policy if exists "spaza auth write" on storage.objects;
create policy "spaza auth write" on storage.objects for insert
  with check (
    (bucket_id = 'shop_photos'   and auth.uid() is not null)
    or (bucket_id in ('product_images','category_icons') and public.is_admin())
  );

drop policy if exists "spaza auth update" on storage.objects;
create policy "spaza auth update" on storage.objects for update
  using (
    (bucket_id = 'shop_photos'   and auth.uid() is not null)
    or (bucket_id in ('product_images','category_icons') and public.is_admin())
  );
