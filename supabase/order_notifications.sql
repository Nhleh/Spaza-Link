-- ============================================================================
-- SpazaLink — order status updates + automatic customer notifications
-- Run this in the Supabase SQL Editor (one time).
-- Depends on: orders, messages (from schema.sql + messages.sql), public.is_admin()
-- ============================================================================

-- 1) Let admins (and a driver assigned to the order) UPDATE orders.
--    Without this, RLS silently blocks status changes (0 rows updated) — which
--    is why the status kept reverting to "pending".
drop policy if exists orders_update on public.orders;
create policy orders_update on public.orders for update
  using (public.is_admin() or driver_id = auth.uid())
  with check (public.is_admin() or driver_id = auth.uid());

-- 2) Auto-message the customer when an order is created or its status changes.
--    SECURITY DEFINER so the trigger can insert into messages regardless of who
--    performed the order action.
create or replace function public.notify_order_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  ref text := upper(split_part(NEW.id::text, '-', 1));
begin
  if (TG_OP = 'INSERT') then
    insert into public.messages (audience, recipient_id, title, body, created_by)
    values (
      'direct', NEW.customer_id,
      'Order received — #' || ref,
      'We''ve received your order #' || ref || '. It is now being processed. '
        || 'We''ll message you here whenever the status changes.',
      NEW.customer_id
    );
  elsif (TG_OP = 'UPDATE' and NEW.status is distinct from OLD.status) then
    insert into public.messages (audience, recipient_id, title, body, created_by)
    values (
      'direct', NEW.customer_id,
      'Order #' || ref || ' — ' || initcap(NEW.status),
      'Your order #' || ref || ' is now "' || NEW.status || '".',
      NEW.customer_id
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_notify_order_insert on public.orders;
create trigger trg_notify_order_insert
  after insert on public.orders
  for each row execute function public.notify_order_change();

drop trigger if exists trg_notify_order_update on public.orders;
create trigger trg_notify_order_update
  after update on public.orders
  for each row execute function public.notify_order_change();
