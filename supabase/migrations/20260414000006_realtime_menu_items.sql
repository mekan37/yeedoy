-- Enable Supabase Realtime for menu_items so price changes are broadcast
-- to all connected QR menu viewers in real-time.
alter publication supabase_realtime add table public.menu_items;
