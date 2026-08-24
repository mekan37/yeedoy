CREATE TABLE public.stock_dish_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  keywords text[] NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX stock_dish_images_active_idx ON public.stock_dish_images (is_active) WHERE is_active = true;

ALTER TABLE public.stock_dish_images ENABLE ROW LEVEL SECURITY;
-- Politika yok: tüm erişim aşağıdaki SECURITY DEFINER RPC'ler üzerinden (Task 2-3).

COMMENT ON TABLE public.stock_dish_images IS
  'Ürün adı eşleştirmesiyle otomatik/manuel önerilen stok yemek görseli kütüphanesi. Erişim: get_stock_dish_images_v1 (public okuma), admin_* RPC''ler (admin yazma).';
