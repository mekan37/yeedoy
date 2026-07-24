-- Duplicate/redundant index temizliği (Supabase Performance Advisor + doğrudan pg_index
-- sorgusuyla bulundu, her çift tek tek indexdef karşılaştırmasıyla doğrulandı). Plain
-- (unique olmayan) index, aynı kolonları kapsayan bir UNIQUE/PK index tarafından zaten
-- tamamen karşılanıyorsa siliniyor; iki index birebir aynıysa biri siliniyor. Sorgu
-- performansına etkisi yok, sadece gereksiz yazma maliyeti ve disk kullanımı ortadan kalkıyor.
--
-- NOT: menu_items.idx_menu_items_desc_trgm / idx_menu_items_name_trgm BİLEREK atlandı —
-- ilk bakışta "duplicate" görünen bir gruplama sorgusuna yakalandılar ama gerçekte farklı
-- kolonları (description vs name) indexliyorlar, gerçek duplicate değiller.

DROP INDEX IF EXISTS public.idx_admin_audit_log_created;
DROP INDEX IF EXISTS public.business_hours_business_idx;
DROP INDEX IF EXISTS public.business_special_hours_business_date_idx;
DROP INDEX IF EXISTS public.idx_businesses_geog;
DROP INDEX IF EXISTS public.custom_domains_domain_idx;
DROP INDEX IF EXISTS public.favorites_business_user_idx;
DROP INDEX IF EXISTS public.favorites_user_business_idx;
DROP INDEX IF EXISTS public.idx_menu_item_allergens_item;
DROP INDEX IF EXISTS public.idx_menu_item_ingredients_item;
DROP INDEX IF EXISTS public.menu_item_nutrition_item_idx;
DROP INDEX IF EXISTS public.idx_menu_translations_entity;
ALTER TABLE public.menu_translations DROP CONSTRAINT IF EXISTS menu_translations_unique;
DROP INDEX IF EXISTS public.idx_review_replies_review_id;
DROP INDEX IF EXISTS public.idx_review_votes_user_review;
DROP INDEX IF EXISTS public.idx_reviews_business_status_created;
DROP INDEX IF EXISTS public.idx_reviews_business_status_helpful;

-- businesses.city üzerinde ILIKE '%...%' araması (search_businesses_v1'den değil,
-- doğrudan PostgREST REST filtrelerinden) 55K satırda sequential scan yapıyordu
-- (EXPLAIN ile doğrulandı). pg_stat_statements'ta bu tam desen 321+321 çağrı,
-- ortalama ~1.3 saniye. Trigram GIN index ile ILIKE artık index kullanabilir.
CREATE INDEX IF NOT EXISTS idx_businesses_city_trgm
  ON public.businesses USING gin (city gin_trgm_ops);
