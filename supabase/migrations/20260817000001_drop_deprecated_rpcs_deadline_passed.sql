-- Deadline'ı 2026-08-01'de geçen deprecated RPC'lerin kaldırılması
-- (bkz. docs/kalan-isler.md — Deprecated RPC'ler tablosu).
--
-- Kod tabanında (uygulamalar/web, uygulamalar/mobil) hiçbir çağrı kalmadığı
-- doğrulandı — sadece otomatik üretilen database.types.ts / veri-tanimlari.ts
-- tip dosyalarında geçiyorlardı. Yerine geçen *_v1 sürümleri zaten üretimde.
--
-- get_top_businesses BU LİSTEYE DAHİL DEĞİL: fonksiyon
-- "DANGEROUS_TO_REMOVE: still referenced by app/runtime paths" yorumuyla
-- işaretli, kaldırılmadan önce ayrıca doğrulanmalı.

DROP FUNCTION IF EXISTS public.approve_business_suggestion(uuid);
DROP FUNCTION IF EXISTS public.approve_owner_claim(uuid);
DROP FUNCTION IF EXISTS public.create_owner_claim(uuid);
DROP FUNCTION IF EXISTS public.reject_business_suggestion(uuid, text);
