-- review_photos: yorum fotoğrafları için kalıcı tablo
--
-- Sorun: fotoğraflar temp_uploads tablosuna kind='review_photo' ile yazılıyordu.
-- temp_uploads kayıtları temizlenince fotoğraflar kaybolabiliyordu.
-- Bu migration yorum fotoğrafları için ayrılmış bir tablo açıyor.
--
-- Flutter: reviews_repository.dart güncellendi (aynı PR).

create table if not exists public.review_photos (
  id             uuid        primary key default gen_random_uuid(),
  review_id      uuid        references public.reviews(id) on delete cascade,
  business_id    uuid        references public.businesses(id) on delete cascade,
  user_id        uuid        references auth.users(id) on delete set null,
  storage_bucket text        not null default 'temp',
  storage_path   text        not null,
  mime_type      text,
  bytes          integer,
  status         text        not null default 'pending'
                             check (status in ('pending', 'approved', 'rejected')),
  created_at     timestamptz not null default now()
);

-- Index: business bazlı galeri sorgusu için
create index if not exists review_photos_business_id_created_at_idx
  on public.review_photos (business_id, created_at desc)
  where status <> 'rejected';

-- Index: review bazlı sorgu için
create index if not exists review_photos_review_id_idx
  on public.review_photos (review_id);

-- RLS
alter table public.review_photos enable row level security;

-- SELECT: reject olmayan fotoğraflar herkese açık
create policy "review_photos_select"
  on public.review_photos for select
  using (status <> 'rejected');

-- INSERT: kendi fotoğrafını ekleyebilir
create policy "review_photos_insert"
  on public.review_photos for insert
  with check (auth.uid() = user_id);

-- Grant
grant select on public.review_photos to anon, authenticated;
grant insert on public.review_photos to authenticated;
