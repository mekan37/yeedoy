-- OCR motoru DeepSeek-OCR/Replicate'ten OCR.Space'e geçiyor (Türkçe dil desteği,
-- tek senkron istek — Replicate'in create+poll döngüsüne gerek yok, şeffaf
-- ücretsiz kota: 25K istek/ay, IP başına 500/gün). Eski 'deepseek-ocr' değeri
-- geçmiş kayıtlar için constraint'te tutuluyor, yeni satırlar 'ocr-space' kullanacak.

ALTER TABLE public.menu_ocr_jobs
  DROP CONSTRAINT menu_ocr_jobs_ocr_engine_check;

ALTER TABLE public.menu_ocr_jobs
  ADD CONSTRAINT menu_ocr_jobs_ocr_engine_check
  CHECK (ocr_engine IN ('none', 'deepseek-ocr', 'ocr-space', 'manual'));
