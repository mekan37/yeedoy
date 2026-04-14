insert into public.business_amenities (key, label, icon)
values
  ('parking', 'Otopark', 'parking'),
  ('kids_area', 'Cocuk Alani', 'kids_area'),
  ('wifi', 'Wi-Fi', 'wifi'),
  ('pet_friendly', 'Pet Friendly', 'pet_friendly'),
  ('smoking_area', 'Sigara Alani', 'smoking_area'),
  ('outdoor_seating', 'Dis Mekan', 'outdoor_seating'),
  ('alcohol', 'Alkol', 'alcohol'),
  ('delivery', 'Paket Servis', 'delivery'),
  ('takeaway', 'Gel Al', 'takeaway')
on conflict (key) do update
set
  label = excluded.label,
  icon = excluded.icon;
