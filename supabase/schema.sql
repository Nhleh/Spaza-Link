-- ============================================================================
-- SpazaLink — Supabase schema (Postgres). Run once in Supabase → SQL Editor.
-- Mirrors the former Firestore collections. Safe to re-run (idempotent-ish).
-- ============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ── profiles (was users) ─────────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text        not null default '',
  email         text,
  phone_number  text        not null default '',
  role          text        not null default 'customer'
                            check (role in ('customer','admin','driver')),
  is_active     boolean     not null default true,
  fcm_tokens    text[]      not null default '{}',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Auto-create a profile row whenever an auth user is created.
create or replace function public.handle_new_user()
  returns trigger language plpgsql security definer
  set search_path = public as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Role helpers (defined AFTER profiles; SECURITY DEFINER avoids RLS recursion)
create or replace function public.role_of(uid uuid)
  returns text language sql security definer stable
  set search_path = public as $$
  select coalesce((select role from public.profiles where id = uid), 'anon');
$$;

create or replace function public.is_admin()
  returns boolean language sql security definer stable
  set search_path = public as $$
  select public.role_of(auth.uid()) = 'admin';
$$;

create or replace function public.is_driver()
  returns boolean language sql security definer stable
  set search_path = public as $$
  select public.role_of(auth.uid()) = 'driver';
$$;

-- Resolve a cellphone number to its account email (for "login with cellphone").
create or replace function public.email_for_phone(p_phone text)
  returns text language sql security definer stable
  set search_path = public as $$
  select email from public.profiles
  where phone_number = p_phone and email is not null
  limit 1;
$$;
grant execute on function public.email_for_phone(text) to anon, authenticated;

-- ── shops ────────────────────────────────────────────────────────────────────
create table if not exists public.shops (
  id                uuid primary key default gen_random_uuid(),
  owner_id          uuid not null references public.profiles(id) on delete cascade,
  shop_name         text not null,
  owner_name        text not null default '',
  physical_address  text not null default '',
  city              text not null default '',
  province          text not null default '',
  gps_lat           double precision,
  gps_lng           double precision,
  status            text not null default 'pending'
                    check (status in ('pending','approved','rejected','suspended')),
  rejection_reason  text,
  approved_by       uuid,
  approved_at       timestamptz,
  shop_photo_url    text,
  business_reg_url  text,
  owner_id_url      text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists shops_owner_idx on public.shops(owner_id);

-- ── categories ───────────────────────────────────────────────────────────────
create table if not exists public.categories (
  id             text primary key,            -- slug is the id
  name           text not null,
  slug           text unique not null,
  icon_url       text not null default '',
  image_url      text not null default '',
  sort_order     int  not null default 0,
  is_available   boolean not null default true,
  product_count  int  not null default 0,
  subcategories  jsonb not null default '[]',
  created_at     timestamptz not null default now()
);

-- ── products ─────────────────────────────────────────────────────────────────
create table if not exists public.products (
  id               uuid primary key default gen_random_uuid(),
  category_id      text references public.categories(id) on delete set null,
  name             text not null,
  description      text not null default '',
  sku              text not null default '',
  barcode          text,
  image_urls       text[] not null default '{}',
  price_cents      int  not null,
  sale_price_cents int,
  pack_size        text not null default '',
  stock_quantity   int  not null default 0,
  weight_grams     int,
  supplier         text,
  is_featured      boolean not null default false,
  is_available     boolean not null default true,
  tags             text[] not null default '{}',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists products_category_idx on public.products(category_id);

-- ── orders / order_items (basic — for checkout later) ────────────────────────
create table if not exists public.orders (
  id           uuid primary key default gen_random_uuid(),
  customer_id  uuid not null references public.profiles(id) on delete cascade,
  shop_id      uuid references public.shops(id) on delete set null,
  driver_id    uuid,
  status       text not null default 'pending',
  total_cents  int  not null default 0,
  local_uuid   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create table if not exists public.order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  product_id  uuid references public.products(id) on delete set null,
  name        text not null default '',
  qty         int  not null default 1,
  price_cents int  not null default 0
);

-- ============================================================================
-- Row-Level Security
-- ============================================================================
alter table public.profiles    enable row level security;
alter table public.shops       enable row level security;
alter table public.categories  enable row level security;
alter table public.products    enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select
  using (id = auth.uid() or public.is_admin());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert
  with check (id = auth.uid());

drop policy if exists shops_select on public.shops;
create policy shops_select on public.shops for select
  using (owner_id = auth.uid() or public.is_admin() or public.is_driver());
drop policy if exists shops_insert on public.shops;
create policy shops_insert on public.shops for insert
  with check (owner_id = auth.uid() and status = 'pending');
drop policy if exists shops_update on public.shops;
create policy shops_update on public.shops for update
  using (owner_id = auth.uid() or public.is_admin())
  with check (public.is_admin() or (owner_id = auth.uid() and status = 'pending'));

drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories for select using (true);
drop policy if exists categories_admin on public.categories;
create policy categories_admin on public.categories for all
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists products_select on public.products;
create policy products_select on public.products for select using (true);
drop policy if exists products_admin on public.products;
create policy products_admin on public.products for all
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists orders_select on public.orders;
create policy orders_select on public.orders for select
  using (customer_id = auth.uid() or driver_id = auth.uid() or public.is_admin());
drop policy if exists orders_insert on public.orders;
create policy orders_insert on public.orders for insert
  with check (customer_id = auth.uid());
drop policy if exists order_items_all on public.order_items;
create policy order_items_all on public.order_items for all
  using (exists (select 1 from public.orders o
                 where o.id = order_id
                   and (o.customer_id = auth.uid() or public.is_admin())))
  with check (exists (select 1 from public.orders o
                 where o.id = order_id
                   and (o.customer_id = auth.uid() or public.is_admin())));

-- ============================================================================
-- Storage buckets + policies (public read; authenticated write)
-- ============================================================================
insert into storage.buckets (id, name, public) values
  ('product_images','product_images', true),
  ('category_icons','category_icons', true),
  ('shop_photos','shop_photos', true)
on conflict (id) do nothing;

drop policy if exists "spaza public read" on storage.objects;
create policy "spaza public read" on storage.objects for select
  using (bucket_id in ('product_images','category_icons','shop_photos'));

drop policy if exists "spaza auth write" on storage.objects;
create policy "spaza auth write" on storage.objects for insert
  with check (bucket_id in ('product_images','category_icons','shop_photos')
              and auth.uid() is not null);

drop policy if exists "spaza auth update" on storage.objects;
create policy "spaza auth update" on storage.objects for update
  using (bucket_id in ('product_images','category_icons','shop_photos')
         and auth.uid() is not null);
