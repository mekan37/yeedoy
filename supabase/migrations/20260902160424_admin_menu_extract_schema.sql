-- Admin "Menü Analiz Et" özelliği: harici Menu Extractor servisinden gelen
-- ham analiz sonuçlarının staging alanı. Gerçek menu_items tablosuna hiçbir
-- veri, admin_apply_menu_extract_job_v1 üzerinden admin'in açık onayı
-- olmadan yazılmaz.
CREATE TABLE public.admin_menu_extract_jobs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  source_type text not null check (source_type in ('url','upload')),
  source_url text,
  source_file_name text,
  external_job_id text not null,
  status text not null default 'queued' check (status in ('queued','started','finished','failed')),
  result jsonb,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
CREATE INDEX admin_menu_extract_jobs_business_idx ON public.admin_menu_extract_jobs (business_id, created_at DESC);

ALTER TABLE public.admin_menu_extract_jobs ENABLE ROW LEVEL SECURITY;
-- Policy yok — tüm erişim aşağıdaki SECURITY DEFINER RPC'ler üzerinden (bu
-- projenin admin-only tablolar için standart deseni, ör. moderation_blacklist_terms).

CREATE TABLE public.admin_menu_extract_items (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.admin_menu_extract_jobs(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  category_name text,
  name text not null,
  description text,
  price_cents integer,
  currency text not null default 'TRY',
  confidence numeric(4,3),
  requires_review boolean not null default false,
  review_reasons jsonb not null default '[]'::jsonb,
  warnings jsonb not null default '[]'::jsonb,
  excluded boolean not null default false,
  imported boolean not null default false,
  imported_menu_item_id uuid references public.menu_items(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
CREATE INDEX admin_menu_extract_items_job_idx ON public.admin_menu_extract_items (job_id);

ALTER TABLE public.admin_menu_extract_items ENABLE ROW LEVEL SECURITY;
-- Policy yok — SECURITY DEFINER RPC'ler üzerinden erişim.

COMMENT ON TABLE public.admin_menu_extract_jobs IS
  'Admin "Menü Analiz Et" özelliği: harici Menu Extractor servisine gönderilen her URL/dosya analiz isteğinin kaydı. Yönetimi: app/yonetici/isletmeler/[id]/menu-analiz.';
COMMENT ON TABLE public.admin_menu_extract_items IS
  'Bir admin_menu_extract_jobs kaydının ürettiği, henüz gerçek menu_items''e aktarılmamış (veya kısmen aktarılmış) taslak satırlar. price_cents NULL olabilir — asla otomatik doldurulmaz, admin_apply_menu_extract_job_v1 fiyatı NULL olan kalemleri "create" için reddeder.';
