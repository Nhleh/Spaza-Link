-- ============================================================================
-- SpazaLink — order price/total integrity. Run once in Supabase → SQL Editor.
-- Stops a tampered client (or a raw API call) from underpaying: item prices and
-- the order total are recomputed server-side from the catalogue.
--
-- Mirrors the app's pricing exactly:
--   effective base = sale_price_cents (when < price_cents) else price_cents
--   customer unit  = round(effective_base * 1.15)      -- 15% markup
--   delivery fee   = 0 when subtotal >= 175000 else 13500   (R1750 / R135)
-- Safe to re-run.
-- ============================================================================

-- 1) Force every order item to the authoritative catalogue price (ignore the
--    price the client sent). numeric round() ties away from zero to match the
--    Dart `.round()` the app uses.
create or replace function public.enforce_order_item_price()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base int;
  sale int;
  eff  int;
begin
  if new.qty is null or new.qty < 1 then
    new.qty := 1;
  end if;

  -- Custom line with no catalogue product — nothing to price against.
  if new.product_id is null then
    return new;
  end if;

  select price_cents, sale_price_cents into base, sale
    from public.products where id = new.product_id;

  -- Unknown product — leave the client value; the order is still admin-reviewed.
  if base is null then
    return new;
  end if;

  eff := case when sale is not null and sale < base then sale else base end;
  new.price_cents := round(eff::numeric * 1.15)::int;
  return new;
end;
$$;

drop trigger if exists order_items_enforce_price on public.order_items;
create trigger order_items_enforce_price
  before insert on public.order_items
  for each row execute function public.enforce_order_item_price();

-- 2) Recompute the parent order total from its (now trusted) items + delivery,
--    and set the trustworthy delivery-savings value. SECURITY DEFINER so it can
--    update the order regardless of who placed it.
create or replace function public.recompute_order_total()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  oid      uuid := coalesce(new.order_id, old.order_id);
  subtotal int;
  fee      int;
begin
  select coalesce(sum(qty * price_cents), 0) into subtotal
    from public.order_items where order_id = oid;

  fee := case when subtotal >= 175000 then 0 else 13500 end;

  update public.orders
     set total_cents          = subtotal + fee,
         delivery_saved_cents  = case when fee = 0 then 13500 else 0 end
   where id = oid;

  return null;
end;
$$;

drop trigger if exists order_items_recompute_total on public.order_items;
create trigger order_items_recompute_total
  after insert or update or delete on public.order_items
  for each row execute function public.recompute_order_total();
