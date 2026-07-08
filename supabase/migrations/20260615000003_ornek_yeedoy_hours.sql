-- Add opening/closing hours for the "Örnek Yeedoy" demo business so the
-- business detail page's hours section renders real data instead of the
-- "hours info missing" empty state.
insert into public.business_hours (
  business_id,
  mon_open, mon_close,
  tue_open, tue_close,
  wed_open, wed_close,
  thu_open, thu_close,
  fri_open, fri_close,
  sat_open, sat_close,
  sun_open, sun_close
) values (
  '2e9be57b-62cd-4f5f-bb4b-0d665994765c',
  '09:00', '22:00',
  '09:00', '22:00',
  '09:00', '22:00',
  '09:00', '22:00',
  '09:00', '23:00',
  '10:00', '23:00',
  '10:00', '22:00'
)
on conflict (business_id) do update set
  mon_open = excluded.mon_open, mon_close = excluded.mon_close,
  tue_open = excluded.tue_open, tue_close = excluded.tue_close,
  wed_open = excluded.wed_open, wed_close = excluded.wed_close,
  thu_open = excluded.thu_open, thu_close = excluded.thu_close,
  fri_open = excluded.fri_open, fri_close = excluded.fri_close,
  sat_open = excluded.sat_open, sat_close = excluded.sat_close,
  sun_open = excluded.sun_open, sun_close = excluded.sun_close;
