-- ============================================================================
-- Advertisement: Nkukhu Farm (violet-goat-262317.hostingersite.com)
-- Free range chickens & organic eggs.
-- Requires advertisements.sql to have been run first.
-- Re-running replaces the same ad instead of duplicating it.
-- ============================================================================

delete from public.advertisements
where link_url = 'https://violet-goat-262317.hostingersite.com/';

insert into public.advertisements (title, image_url, link_url, active, sort_order)
values (
  'Nkukhu Farm — Free Range Chickens & Organic Eggs',
  'https://violet-goat-262317.hostingersite.com/images/nkukhu-feature-1200.avif',
  'https://violet-goat-262317.hostingersite.com/',
  true,
  2
);
