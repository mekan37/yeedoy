-- P2: bulk_op_logs sadece "kaç kayit" tutuyordu, HANGİ kayitlarin etkilendigi
-- hic saklanmiyordu — bir toplu islem sonrasi inceleme/geri alma imkansizdi.
ALTER TABLE public.bulk_op_logs ADD COLUMN IF NOT EXISTS target_ids uuid[];

COMMENT ON COLUMN public.bulk_op_logs.target_ids IS
  'İşlemin talep ettiği hedef kayıt ID''leri (etkilenen sayısı count kolonunda farklı olabilir — RLS/eşleşmeme nedeniyle). Called by: app/sunucu/yonetici/toplu-islemler/route.ts.';
