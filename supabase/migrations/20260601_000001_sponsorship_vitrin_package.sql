-- Yeedoy Vitrin sponsorluk paketi — ilk satılabilir paket
insert into public.sponsorship_packages (name, surface, duration_days, price_display, price_cents, currency_code, inventory_limit, is_active)
select 'Yeedoy Vitrin', 'discovery', 30, '490 TL/ay', 49000, 'TRY', 100, true
where not exists (
  select 1 from public.sponsorship_packages where name = 'Yeedoy Vitrin'
);
