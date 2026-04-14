-- Sync QR menu schema with existing production DB
-- Safe/idempotent migration for mixed legacy schema

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'translation_entity_type'
  ) THEN
    CREATE TYPE public.translation_entity_type AS ENUM ('business', 'category', 'item');
  END IF;
END
$$;
CREATE TABLE IF NOT EXISTS public.menu_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  sort int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.menu_translations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type public.translation_entity_type NOT NULL,
  entity_id uuid NOT NULL,
  locale text NOT NULL,
  name text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT menu_translations_unique UNIQUE (entity_type, entity_id, locale)
);
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.menu_categories(id) ON DELETE SET NULL;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_available boolean NOT NULL DEFAULT true;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS tags jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS sort int NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_menu_categories_business_id ON public.menu_categories (business_id, sort);
CREATE INDEX IF NOT EXISTS idx_menu_translations_entity ON public.menu_translations (entity_type, entity_id, locale);
CREATE INDEX IF NOT EXISTS idx_menu_items_category_sort ON public.menu_items (business_id, category_id, sort);
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_translations ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_categories' AND policyname = 'menu_categories_owner_all'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_categories_owner_all
      ON public.menu_categories
      FOR ALL
      TO authenticated
      USING (is_admin() OR is_owner_of_business(business_id))
      WITH CHECK (is_admin() OR is_owner_of_business(business_id))
    $sql$;
  END IF;
END
$$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_categories' AND policyname = 'menu_categories_public_read'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_categories_public_read
      ON public.menu_categories
      FOR SELECT
      TO public
      USING (
        is_active = true
        AND EXISTS (
          SELECT 1
          FROM public.businesses b
          WHERE b.id = menu_categories.business_id
            AND b.is_active = true
        )
      )
    $sql$;
  END IF;
END
$$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_translations' AND policyname = 'menu_translations_owner_all'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_translations_owner_all
      ON public.menu_translations
      FOR ALL
      TO authenticated
      USING (
        is_admin() OR (
          (entity_type = 'business' AND is_owner_of_business(entity_id))
          OR (entity_type = 'category' AND EXISTS (
            SELECT 1 FROM public.menu_categories c
            WHERE c.id = entity_id
              AND is_owner_of_business(c.business_id)
          ))
          OR (entity_type = 'item' AND EXISTS (
            SELECT 1 FROM public.menu_items i
            WHERE i.id = entity_id
              AND is_owner_of_business(i.business_id)
          ))
        )
      )
      WITH CHECK (
        is_admin() OR (
          (entity_type = 'business' AND is_owner_of_business(entity_id))
          OR (entity_type = 'category' AND EXISTS (
            SELECT 1 FROM public.menu_categories c
            WHERE c.id = entity_id
              AND is_owner_of_business(c.business_id)
          ))
          OR (entity_type = 'item' AND EXISTS (
            SELECT 1 FROM public.menu_items i
            WHERE i.id = entity_id
              AND is_owner_of_business(i.business_id)
          ))
        )
      )
    $sql$;
  END IF;
END
$$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_translations' AND policyname = 'menu_translations_public_read'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_translations_public_read
      ON public.menu_translations
      FOR SELECT
      TO public
      USING (true)
    $sql$;
  END IF;
END
$$;
NOTIFY pgrst, 'reload schema';
