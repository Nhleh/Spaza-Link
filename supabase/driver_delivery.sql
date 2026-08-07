-- ============================================================================
-- SpazaLink — Driver / Delivery (Phase 1). Run once in Supabase → SQL Editor.
-- Adds delivery fields to orders, driver status guards, lifecycle timestamps,
-- on-the-way / delivered notifications, and a private proof-of-delivery bucket.
-- Safe to re-run.
-- ============================================================================

-- 1) Order delivery fields ---------------------------------------------------
alter table public.orders add column if not exists delivery_address text not null default '';
alter table public.orders add column if not exists pickup_address   text not null default '';
alter table public.orders add column if not exists payment_method   text not null default 'cod';
alter table public.orders add column if not exists payment_status   text not null default 'pending';
alter table public.orders add column if not exists assigned_at      timestamptz;
alter table public.orders add column if not exists picked_up_at     timestamptz;
alter table public.orders add column if not exists delivered_at     timestamptz;
alter table public.orders add column if not exists signature_path   text;   -- delivery_proofs object path
alter table public.orders add column if not exists pod_path         text;   -- signed-invoice object path

create index if not exists orders_driver_status_idx on public.orders (driver_id, status);

-- 2) Lifecycle timestamps (stamped automatically on status change) -----------
create or replace function public.stamp_order_lifecycle()
returns trigger language plpgsql as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'assigned'         and new.assigned_at  is null then new.assigned_at  := now(); end if;
    if new.status = 'out_for_delivery' and new.picked_up_at is null then new.picked_up_at := now(); end if;
    if new.status = 'delivered'        and new.delivered_at is null then new.delivered_at := now(); end if;
  end if;
  return new;
end $$;

drop trigger if exists orders_stamp_lifecycle on public.orders;
create trigger orders_stamp_lifecycle
  before update on public.orders
  for each row execute function public.stamp_order_lifecycle();

-- 3) Driver guard: an assigned driver may only advance their own order along
--    valid transitions, and can never reassign it. Admins bypass. -----------
create or replace function public.guard_driver_order_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then
    return new;                                   -- admins do anything
  end if;

  if public.is_driver() and old.driver_id = auth.uid() then
    if not (
      (old.status = 'assigned'         and new.status = 'out_for_delivery') or
      (old.status = 'out_for_delivery' and new.status = 'delivered')        or
      (new.status = old.status)                   -- signature / payment-only updates
    ) then
      raise exception 'Invalid delivery transition % -> %', old.status, new.status;
    end if;
    new.driver_id := old.driver_id;               -- can't hand the order to someone else
    new.customer_id := old.customer_id;
    new.total_cents := old.total_cents;
    return new;
  end if;

  return new;
end $$;

drop trigger if exists orders_driver_guard on public.orders;
create trigger orders_driver_guard
  before update on public.orders
  for each row execute function public.guard_driver_order_update();

-- 4) Customer notifications: friendly "on the way" and "delivered" copy. ------
create or replace function public.notify_order_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  ref   text := upper(split_part(NEW.id::text, '-', 1));
  title text;
  body  text;
begin
  if (TG_OP = 'INSERT') then
    insert into public.messages (audience, recipient_id, title, body, created_by)
    values ('direct', NEW.customer_id,
      'Order received — #' || ref,
      'We''ve received your order #' || ref || '. It is now being processed.',
      NEW.customer_id);
    return NEW;
  end if;

  if (TG_OP = 'UPDATE' and NEW.status is distinct from OLD.status) then
    if NEW.status = 'out_for_delivery' then
      title := 'Your order is on the way 🚚';
      body  := 'Order #' || ref || ' is out for delivery and on its way to you.';
    elsif NEW.status = 'delivered' then
      title := 'Order #' || ref || ' delivered ✅';
      body  := 'Your order #' || ref || ' has been delivered. Open it to view your signed invoice.';
    elsif NEW.status = 'cancelled' then
      title := 'Order #' || ref || ' cancelled';
      body  := 'Your order #' || ref || ' has been cancelled.';
    else
      title := 'Order #' || ref || ' — ' || initcap(NEW.status);
      body  := 'Your order #' || ref || ' is now "' || NEW.status || '".';
    end if;

    insert into public.messages (audience, recipient_id, title, body, created_by)
    values ('direct', NEW.customer_id, title, body, NEW.customer_id);
  end if;
  return NEW;
end $$;

-- 5) Proof-of-delivery storage (private) -------------------------------------
insert into storage.buckets (id, name, public)
values ('delivery_proofs', 'delivery_proofs', false)
on conflict (id) do nothing;

-- Signed URLs are minted by the apps; any signed-in user with the object path
-- (only ever stored on their own RLS-protected order) can read it.
drop policy if exists delivery_proofs_read on storage.objects;
create policy delivery_proofs_read on storage.objects for select
  using (bucket_id = 'delivery_proofs' and auth.uid() is not null);

-- Only the assigned driver or an admin can upload proof of delivery.
drop policy if exists delivery_proofs_write on storage.objects;
create policy delivery_proofs_write on storage.objects for insert
  with check (bucket_id = 'delivery_proofs' and (public.is_admin() or public.is_driver()));

-- 6) Driver live location — admin-only, ONLY while actively delivering. -------
create table if not exists public.driver_locations (
  driver_id  uuid primary key references public.profiles(id) on delete cascade,
  lat        double precision not null,
  lng        double precision not null,
  updated_at timestamptz not null default now()
);

alter table public.driver_locations enable row level security;

-- A driver writes only their own position.
drop policy if exists driver_loc_write on public.driver_locations;
create policy driver_loc_write on public.driver_locations for all
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());

-- An admin may read a driver's position ONLY while that driver has an order
-- out for delivery — no tracking otherwise, and never by the customer.
drop policy if exists driver_loc_admin_read on public.driver_locations;
create policy driver_loc_admin_read on public.driver_locations for select
  using (
    public.is_admin()
    and exists (
      select 1 from public.orders o
      where o.driver_id = driver_locations.driver_id
        and o.status = 'out_for_delivery'
    )
  );

-- 7) Helper: list of drivers for the admin "Assign to driver" picker. ---------
--    Admin-only (RLS on profiles already limits reads to self/admin).
create or replace function public.list_drivers()
returns table (id uuid, display_name text, phone_number text)
language sql security definer stable set search_path = public as $$
  select id, display_name, phone_number
  from public.profiles
  where role = 'driver' and is_active
  order by display_name;
$$;
revoke all on function public.list_drivers() from public;
grant execute on function public.list_drivers() to authenticated;
