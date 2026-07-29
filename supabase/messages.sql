-- ============================================================================
-- SpazaLink — Admin ⇄ Customer messaging
-- Run this in the Supabase SQL Editor (one time).
-- Depends on public.profiles and public.is_admin() from schema.sql.
-- ============================================================================

-- A message is either a broadcast (to every customer) or direct (to one owner).
create table if not exists public.messages (
  id           uuid primary key default gen_random_uuid(),
  audience     text not null check (audience in ('broadcast','direct')),
  recipient_id uuid references public.profiles(id) on delete cascade, -- null for broadcast
  title        text not null,
  body         text not null,
  created_by   uuid references public.profiles(id),
  created_at   timestamptz not null default now()
);

create index if not exists messages_recipient_idx on public.messages(recipient_id);
create index if not exists messages_created_idx on public.messages(created_at desc);

-- Per-user read state (works for broadcasts too — one row per user who read it).
create table if not exists public.message_reads (
  message_id uuid references public.messages(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete cascade,
  read_at    timestamptz not null default now(),
  primary key (message_id, profile_id)
);

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.messages enable row level security;
alter table public.message_reads enable row level security;

-- Customers see broadcasts + their own direct messages; admins see everything.
drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages for select
  using (
    audience = 'broadcast'
    or recipient_id = auth.uid()
    or public.is_admin()
  );

-- Only admins may send / manage messages.
drop policy if exists messages_admin_write on public.messages;
create policy messages_admin_write on public.messages for all
  using (public.is_admin())
  with check (public.is_admin());

-- Read receipts: a user manages only their own.
drop policy if exists message_reads_select on public.message_reads;
create policy message_reads_select on public.message_reads for select
  using (profile_id = auth.uid() or public.is_admin());

drop policy if exists message_reads_insert on public.message_reads;
create policy message_reads_insert on public.message_reads for insert
  with check (profile_id = auth.uid());

-- ============================================================================
-- Profile preferences (notification toggles, payment method, delivery notes)
-- Stored as JSON on the person's profile so it's saved per-user and visible to
-- admins (who can already read every profile).
-- ============================================================================
alter table public.profiles
  add column if not exists preferences jsonb not null default '{}'::jsonb;

-- Shops get an optional secondary delivery address (primary stays physical_address).
alter table public.shops
  add column if not exists delivery_address text;
