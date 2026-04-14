-- Remove legacy compatibility view. Canonical source is public.favorites table.
drop view if exists public.user_favorites;
