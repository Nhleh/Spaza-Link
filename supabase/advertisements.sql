-- ============================================================================
-- Advertisements — sliding Shop banner managed from the Admin dashboard.
-- Depends on: public.is_admin() (schema.sql).
-- Safe to run multiple times.
-- ============================================================================

create table if not exists public.advertisements (
  id          uuid primary key default gen_random_uuid(),
  title       text not null default '',
  image_url   text not null,
  link_url    text,
  active      boolean not null default true,
  starts_at   timestamptz,
  ends_at     timestamptz,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists advertisements_active_idx
  on public.advertisements (active, sort_order);

alter table public.advertisements enable row level security;

-- Public (customer app) may read only ads that are active AND within their
-- optional schedule window — so an inactive/expired ad never reaches a phone.
drop policy if exists advertisements_read_active on public.advertisements;
create policy advertisements_read_active
  on public.advertisements
  for select
  using (
    active
    and (starts_at is null or starts_at <= now())
    and (ends_at   is null or ends_at   >= now())
  );

-- Admins can see and manage everything (create/edit/delete/activate/schedule).
drop policy if exists advertisements_admin_read on public.advertisements;
create policy advertisements_admin_read
  on public.advertisements for select
  using (public.is_admin());

drop policy if exists advertisements_admin_write on public.advertisements;
create policy advertisements_admin_write
  on public.advertisements for all
  using (public.is_admin())
  with check (public.is_admin());

-- Keep updated_at fresh.
create or replace function public.touch_advertisements()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists advertisements_touch on public.advertisements;
create trigger advertisements_touch
  before update on public.advertisements
  for each row execute function public.touch_advertisements();

-- Public storage bucket for advertisement images.
insert into storage.buckets (id, name, public)
values ('ad_images', 'ad_images', true)
on conflict (id) do nothing;

drop policy if exists ad_images_public_read on storage.objects;
create policy ad_images_public_read
  on storage.objects for select
  using (bucket_id = 'ad_images');

drop policy if exists ad_images_admin_write on storage.objects;
create policy ad_images_admin_write
  on storage.objects for all
  using (bucket_id = 'ad_images' and public.is_admin())
  with check (bucket_id = 'ad_images' and public.is_admin());
