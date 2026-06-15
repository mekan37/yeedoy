alter table public.reviews disable trigger trg_reviews_edge_guard_v1;
alter table public.reviews disable trigger trg_recompute_achievements_reviews_v1;
alter table public.reviews disable trigger trg_reviews_rate_limit_v1;

insert into public.reviews (
  business_id, user_id, rating, content, status,
  overall_rating, taste_rating, service_speed_rating,
  price_performance_rating, cleanliness_rating, atmosphere_rating,
  created_at
) values
  ('2e9be57b-62cd-4f5f-bb4b-0d665994765c', 'b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', 5,
   'Harika bir deneyim, tekrar geleceğim!', 'approved', 5, 5, 5, 5, 5, 5,
   now() - interval '1 day'),
  ('2e9be57b-62cd-4f5f-bb4b-0d665994765c', 'b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', 5,
   'Servis ve lezzet mükemmeldi, herkese tavsiye ederim.', 'approved', 5, 5, 5, 5, 5, 5,
   now() - interval '2 days'),
  ('2e9be57b-62cd-4f5f-bb4b-0d665994765c', 'b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', 4,
   'Genel olarak çok memnun kaldım, fiyat performansı iyi.', 'approved', 4, 4, 4, 4, 4, 4,
   now() - interval '3 days');

alter table public.reviews enable trigger trg_reviews_edge_guard_v1;
alter table public.reviews enable trigger trg_recompute_achievements_reviews_v1;
alter table public.reviews enable trigger trg_reviews_rate_limit_v1;
