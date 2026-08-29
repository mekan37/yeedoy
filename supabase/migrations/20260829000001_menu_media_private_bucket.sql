begin;

-- menu-media-private: kritik/hassas görsel yüklemeleri (fiyat doğrulama makbuzu,
-- fiyat önerisi kanıtı, menü OCR kaynak görseli) için private bucket. Bu bucket
-- menu-media'nın aksine PUBLIC DEĞİL — tek erişim yolu media-upload-user edge
-- function'ının service_role client'ı (RLS'i bypass eder) ve onun ürettiği
-- kısa ömürlü imzalı URL'lerdir. Bu yüzden authenticated/public rollerine
-- kasıtlı olarak hiçbir storage.objects policy'si verilmiyor.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-media-private',
  'menu-media-private',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

commit;
