-- ============================================================================
-- Savings capture — records how much each order saved the customer, split into
-- the three categories shown on the Savings Report (spec #3, #6).
--   • discount_saved_cents  — buying on-sale / discounted products
--   • pool_saved_cents      — joining a buying pool
--   • delivery_saved_cents  — qualifying for free delivery
-- Total savings = sum of the three. Older orders keep 0 (shown as an empty
-- state), new orders are written with real values by the Customer app.
-- Safe to run multiple times.
-- ============================================================================

alter table public.orders
  add column if not exists discount_saved_cents int not null default 0;
alter table public.orders
  add column if not exists pool_saved_cents     int not null default 0;
alter table public.orders
  add column if not exists delivery_saved_cents  int not null default 0;

-- Helpful for the "savings over time" queries (per customer, by date).
create index if not exists orders_customer_created_idx
  on public.orders (customer_id, created_at);
