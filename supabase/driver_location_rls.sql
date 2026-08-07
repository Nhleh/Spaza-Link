-- ============================================================================
-- Broaden admin visibility of a driver's live location: show it from the moment
-- the driver accepts the job (assigned) through delivery (out_for_delivery),
-- not only while out for delivery. Still admin-only; customers never see it.
-- Safe to re-run.
-- ============================================================================

drop policy if exists driver_loc_admin_read on public.driver_locations;
create policy driver_loc_admin_read on public.driver_locations for select
  using (
    public.is_admin()
    and exists (
      select 1 from public.orders o
      where o.driver_id = driver_locations.driver_id
        and o.status in ('assigned', 'out_for_delivery')
    )
  );
