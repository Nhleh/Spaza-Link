-- ============================================================================
-- Let the assigned driver read the items of orders assigned to them (so the
-- Driver app can show what to deliver). Read-only; only their assigned orders.
-- Safe to re-run.
-- ============================================================================

drop policy if exists order_items_driver_read on public.order_items;
create policy order_items_driver_read on public.order_items for select
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.driver_id = auth.uid()
    )
  );
