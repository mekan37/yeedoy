-- Engine 1→3 router'ının hangi motorun sonucu döndürdüğünü ayırt edebilmesi
-- için ayrı bir değer (Engine 3'ün ayrı/dar kotasını izlemek amacıyla).

ALTER TABLE public.menu_ocr_jobs
  DROP CONSTRAINT menu_ocr_jobs_ocr_engine_check;

ALTER TABLE public.menu_ocr_jobs
  ADD CONSTRAINT menu_ocr_jobs_ocr_engine_check
  CHECK (ocr_engine IN ('none', 'deepseek-ocr', 'ocr-space', 'ocr-space-e3', 'manual'));
