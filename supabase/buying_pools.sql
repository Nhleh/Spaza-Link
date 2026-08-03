-- ============================================================================
-- SpazaLink — Buying Pools (collective buying)
-- A customer starts a pool on ONE product by pledging >= 50 units and setting a
-- target. Others join by pledging units of the same product. Discount is by the
-- pool's TOTAL pledged quantity and applies to everyone in the pool:
--   >= 50  -> 5%
--   >= 100 -> 10%
--   >= 150 -> 15%  (maximum)
-- A pool stays open for max 3 days, or until total >= target.
-- Run this once in the Supabase SQL Editor. Depends on: products, profiles,
-- public.is_admin() (from schema.sql).
-- ============================================================================

create table if not exists public.buying_pools (
  id uuid primary key default gen_random_uuid(),
  product_id       text not null references public.products(id) on delete cascade,
  product_name     text not null default '',
  product_image    text not null default '',
  -- customer-facing unit price (already includes the 15% markup) at creation.
  unit_price_cents int  not null default 0,
  creator_id       uuid not null references public.profiles(id) on delete cascade,
  target_qty       int  not null check (target_qty >= 50),
  status           text not null default 'open'
                     check (status in ('open','fulfilled','expired','cancelled')),
  created_at       timestamptz not null default now(),
  closes_at        timestamptz not null default (now() + interval '3 days')
);

create table if not exists public.pool_members (
  id        uuid primary key default gen_random_uuid(),
  pool_id   uuid not null references public.buying_pools(id) on delete cascade,
  member_id uuid not null references public.profiles(id) on delete cascade,
  quantity  int  not null check (quantity >= 1),
  joined_at timestamptz not null default now(),
  unique (pool_id, member_id)
);

create index if not exists idx_pool_members_pool on public.pool_members(pool_id);
create index if not exists idx_buying_pools_status on public.buying_pools(status);

-- Discount tier (percent) for a given pooled quantity.
create or replace function public.pool_discount_pct(qty int)
returns int language sql immutable as $$
  select case
    when qty >= 150 then 15
    when qty >= 100 then 10
    when qty >= 50  then 5
    else 0
  end;
$$;

-- Live totals + current discount tier per pool.
create or replace view public.pool_totals as
select
  p.id                                   as pool_id,
  coalesce(sum(m.quantity), 0)::int      as total_qty,
  count(m.id)::int                       as member_count,
  public.pool_discount_pct(coalesce(sum(m.quantity), 0)::int) as discount_pct
from public.buying_pools p
left join public.pool_members m on m.pool_id = p.id
group by p.id;

grant select on public.pool_totals to anon, authenticated;

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.buying_pools enable row level security;
alter table public.pool_members enable row level security;

-- Any signed-in user can browse pools + members (needed to see progress).
drop policy if exists pools_select on public.buying_pools;
create policy pools_select on public.buying_pools for select
  using (auth.uid() is not null);

drop policy if exists pools_insert on public.buying_pools;
create policy pools_insert on public.buying_pools for insert
  with check (creator_id = auth.uid());

drop policy if exists pools_update on public.buying_pools;
create policy pools_update on public.buying_pools for update
  using (creator_id = auth.uid() or public.is_admin());

drop policy if exists pool_members_select on public.pool_members;
create policy pool_members_select on public.pool_members for select
  using (auth.uid() is not null);

drop policy if exists pool_members_insert on public.pool_members;
create policy pool_members_insert on public.pool_members for insert
  with check (member_id = auth.uid());

drop policy if exists pool_members_update on public.pool_members;
create policy pool_members_update on public.pool_members for update
  using (member_id = auth.uid());

drop policy if exists pool_members_delete on public.pool_members;
create policy pool_members_delete on public.pool_members for delete
  using (member_id = auth.uid());

-- When a pool reaches its target, mark it fulfilled automatically.
create or replace function public.check_pool_target()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  total int;
  tgt   int;
begin
  select coalesce(sum(quantity),0) into total
    from public.pool_members where pool_id = NEW.pool_id;
  select target_qty into tgt from public.buying_pools where id = NEW.pool_id;
  if total >= tgt then
    update public.buying_pools set status = 'fulfilled'
      where id = NEW.pool_id and status = 'open';
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_check_pool_target on public.pool_members;
create trigger trg_check_pool_target
  after insert or update on public.pool_members
  for each row execute function public.check_pool_target();
