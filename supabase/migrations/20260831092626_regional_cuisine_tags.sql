-- Şehir bazlı yöresel yemek kataloğu — yönetici panelinden CRUD, mobilde
-- konum-farkında öneri motorunun veri kaynağı.
CREATE TABLE public.regional_cuisine_tags (
  id          uuid primary key default gen_random_uuid(),
  city        text not null,
  label       text not null,
  created_at  timestamptz not null default now(),
  unique (city, label)
);

ALTER TABLE public.regional_cuisine_tags ENABLE ROW LEVEL SECURITY;
-- Bilinçli olarak hiç policy yok — tüm erişim SECURITY DEFINER RPC'ler üzerinden.

-- Bir işletme en fazla bir yöresel etiket taşır (v1 basitliği).
ALTER TABLE public.businesses
  ADD COLUMN regional_tag_id uuid REFERENCES public.regional_cuisine_tags(id) ON DELETE SET NULL;

-- Push/bildirim tekilleştirme — "aynı şehir için 14 günde 1 kez" kuralını sunucu tarafında garanti eder.
CREATE TABLE public.regional_recommendation_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  city        text not null,
  sent_at     timestamptz not null default now()
);
CREATE INDEX regional_recommendation_events_user_city_idx
  ON public.regional_recommendation_events (user_id, city, sent_at DESC);

ALTER TABLE public.regional_recommendation_events ENABLE ROW LEVEL SECURITY;
-- Policy yok — sadece SECURITY DEFINER RPC erişir.

-- 81 il için başlangıç seed'i — en az 1 iyi bilinen yöresel lezzet/ürün.
-- Admin panelinden düzenlenebilir/genişletilebilir.
INSERT INTO public.regional_cuisine_tags (city, label) VALUES
  ('Adana', 'Adana Kebap'),
  ('Adıyaman', 'Çiğ Köfte'),
  ('Afyonkarahisar', 'Afyon Sucuğu'),
  ('Ağrı', 'Abgoşt'),
  ('Aksaray', 'Bulgur Pilavı'),
  ('Amasya', 'Amasya Elması'),
  ('Ankara', 'Ankara Tava'),
  ('Antalya', 'Piyaz'),
  ('Ardahan', 'Ardahan Balı'),
  ('Artvin', 'Muşmula Tatlısı'),
  ('Aydın', 'İncirli Kebap'),
  ('Balıkesir', 'Manda Yoğurdu'),
  ('Bartın', 'Bartın Pidesi'),
  ('Batman', 'Kaburga Dolması'),
  ('Bayburt', 'Bayburt Pilavı'),
  ('Bilecik', 'Bozüyük Şeftalisi'),
  ('Bingöl', 'Kadıköy Kebabı'),
  ('Bitlis', 'Kete'),
  ('Bolu', 'Bolu Mantısı'),
  ('Burdur', 'Burdur Şiş Köfte'),
  ('Bursa', 'İskender Kebap'),
  ('Çanakkale', 'Çanakkale Peyniri'),
  ('Çankırı', 'Çorba Tarhanası'),
  ('Çorum', 'Çorum Leblebisi'),
  ('Denizli', 'Denizli Kebabı'),
  ('Diyarbakır', 'Diyarbakır Kaburga Dolması'),
  ('Düzce', 'Düzce Fındığı'),
  ('Edirne', 'Edirne Ciğeri'),
  ('Elazığ', 'Elazığ Kadayıf Dolması'),
  ('Erzincan', 'Erzincan Tulum Peyniri'),
  ('Erzurum', 'Cağ Kebabı'),
  ('Eskişehir', 'Çibörek'),
  ('Gaziantep', 'Baklava'),
  ('Giresun', 'Karalahana Çorbası'),
  ('Gümüşhane', 'Kuymak'),
  ('Hakkari', 'Kaburga Dolması'),
  ('Hatay', 'Künefe'),
  ('Iğdır', 'Kayısı Kurusu'),
  ('Isparta', 'Gül Reçeli'),
  ('İstanbul', 'İstanbul Balık Ekmek'),
  ('İzmir', 'İzmir Kumru'),
  ('Kahramanmaraş', 'Maraş Dondurması'),
  ('Karabük', 'Safranbolu Lokumu'),
  ('Karaman', 'Karaman Etli Ekmek'),
  ('Kars', 'Kars Kaşarı'),
  ('Kastamonu', 'Kastamonu Pastırması'),
  ('Kayseri', 'Kayseri Mantısı'),
  ('Kırıkkale', 'Kırıkkale Pidesi'),
  ('Kırklareli', 'Kırklareli Cevizli Sucuk'),
  ('Kırşehir', 'Kırşehir Çekirdek'),
  ('Kilis', 'Kilis Tava'),
  ('Kocaeli', 'Pişmaniye'),
  ('Konya', 'Etli Ekmek'),
  ('Kütahya', 'Kütahya Yağlaması'),
  ('Malatya', 'Malatya Kayısısı'),
  ('Manisa', 'Manisa Mesir Macunu'),
  ('Mardin', 'İkbebet'),
  ('Mersin', 'Mersin Tantunisi'),
  ('Muğla', 'Muğla Tarhanası'),
  ('Muş', 'Muş Balı'),
  ('Nevşehir', 'Testi Kebabı'),
  ('Niğde', 'Niğde Pekmezi'),
  ('Ordu', 'Ordu Fındığı'),
  ('Osmaniye', 'Osmaniye Bici Bici'),
  ('Rize', 'Rize Çayı'),
  ('Sakarya', 'Sakarya Pidesi'),
  ('Samsun', 'Samsun Pidesi'),
  ('Siirt', 'Siirt Büryan'),
  ('Sinop', 'Hamsili Pilav'),
  ('Sivas', 'Sivas Köftesi'),
  ('Şanlıurfa', 'Urfa Kebabı'),
  ('Şırnak', 'Kadeh Kebabı'),
  ('Tekirdağ', 'Tekirdağ Köftesi'),
  ('Tokat', 'Tokat Kebabı'),
  ('Trabzon', 'Trabzon Akçaabat Köftesi'),
  ('Tunceli', 'Tunceli Balı'),
  ('Uşak', 'Uşak Külünçesi'),
  ('Van', 'Van Kahvaltısı'),
  ('Yalova', 'Yalova Kivisi'),
  ('Yozgat', 'Yozgat Testi Kebabı'),
  ('Zonguldak', 'Zonguldak Pidesi');
