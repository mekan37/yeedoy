-- Keep anonymous feedback inserts available, but make the RLS check explicit.

drop policy if exists "anon_can_insert_menu_feedback" on public.menu_feedback;
create policy "anon_can_insert_menu_feedback"
  on public.menu_feedback
  for insert
  to anon, authenticated
  with check (
    rating between 1 and 5
    and category in ('menu', 'price', 'service', 'app', 'other')
    and (message is null or char_length(message) <= 500)
  );
