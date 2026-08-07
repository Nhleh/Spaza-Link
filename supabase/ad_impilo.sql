-- ============================================================================
-- Advertisement: Impilo Spirulina (orangered-cattle-853527.hostingersite.com)
-- Requires advertisements.sql to have been run first (creates the table).
-- Re-running replaces the same ad instead of duplicating it.
-- ============================================================================

delete from public.advertisements
where link_url = 'https://orangered-cattle-853527.hostingersite.com/';

insert into public.advertisements (title, image_url, link_url, active, sort_order)
values (
  'Impilo Spirulina — Boost Your Energy',
  'https://orangered-cattle-853527.hostingersite.com/combo.jpg',
  'https://orangered-cattle-853527.hostingersite.com/',
  true,
  1
);
