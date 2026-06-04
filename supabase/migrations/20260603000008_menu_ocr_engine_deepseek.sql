-- ============================================================
-- 20260603000008_menu_ocr_engine_deepseek.sql
--
-- Amaç: menu_ocr_jobs.ocr_engine CHECK constraint'ini 'deepseek-ocr'
-- değerini kabul edecek şekilde genişlet.
--
-- Bağlam: ai-menu-analyze edge function (index.ts:276) aşağıdaki değeri
-- yazar: ocr_engine = 'deepseek-ocr'. Orijinal constraint
-- (20260411000001_ai_menu_analysis_v1.sql — _archive) yalnızca
-- ('none', 'paddleocr', 'manual') değerlerine izin veriyor.
-- Bu migration eksik değeri ekler.
--
-- Not: menu_ocr_jobs tablosu _archive migration'ında tanımlı olup
-- production'a henüz uygulanmamış olabilir. Bu migration idempotent
-- şekilde tasarlandı — tablo yoksa no-op olarak çalışır.
--
-- ROLLBACK:
--   BEGIN;
--   ALTER TABLE public.menu_ocr_jobs
--     DROP CONSTRAINT IF EXISTS menu_ocr_jobs_ocr_engine_check;
--   ALTER TABLE public.menu_ocr_jobs
--     ADD CONSTRAINT menu_ocr_jobs_ocr_engine_check
--     CHECK (ocr_engine IN ('none', 'paddleocr', 'manual'));
--   COMMIT;
--   -- DİKKAT: Rollback öncesi 'deepseek-ocr' engine değeriyle
--   -- oluşturulmuş satırlar temizlenmeli veya 'manual' değerine
--   -- güncellenmeli: UPDATE menu_ocr_jobs SET ocr_engine = 'manual'
--   --   WHERE ocr_engine = 'deepseek-ocr';
-- ============================================================

DO $$
DECLARE
  v_conname text;
BEGIN
  -- Tablo yoksa no-op (fresh DB veya archive migration uygulanmadıysa)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'menu_ocr_jobs'
  ) THEN
    RAISE NOTICE 'menu_ocr_jobs tablosu bulunamadı — migration atlanıyor.';
    RETURN;
  END IF;

  -- Mevcut ocr_engine CHECK constraint adını bul
  SELECT conname INTO v_conname
  FROM pg_constraint
  WHERE conrelid = 'public.menu_ocr_jobs'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%ocr_engine%'
  LIMIT 1;

  -- Eski constraint varsa düşür
  IF v_conname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.menu_ocr_jobs DROP CONSTRAINT %I', v_conname);
    RAISE NOTICE 'Eski constraint kaldırıldı: %', v_conname;
  END IF;

  -- Genişletilmiş constraint ekle
  ALTER TABLE public.menu_ocr_jobs
    ADD CONSTRAINT menu_ocr_jobs_ocr_engine_check
    CHECK (ocr_engine IN ('none', 'paddleocr', 'manual', 'deepseek-ocr'));

  -- Kolon açıklamasını güncelle
  COMMENT ON COLUMN public.menu_ocr_jobs.ocr_engine IS
    'OCR engine: none | paddleocr | manual | deepseek-ocr (Replicate/DeepSeek). '
    ''deepseek-ocr'' 2026-06-03 eklendi — ai-menu-analyze edge function.';

  RAISE NOTICE 'menu_ocr_jobs_ocr_engine_check constraint güncellendi: deepseek-ocr eklendi.';
END;
$$;
