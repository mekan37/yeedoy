-- Enable Supabase Realtime for menu_items so price changes are broadcast
-- to all connected QR menu viewers in real-time.
do $$ begin
  alter publication supabase_realtime add table public.menu_items;
exception when duplicate_object then null;
end $$;
