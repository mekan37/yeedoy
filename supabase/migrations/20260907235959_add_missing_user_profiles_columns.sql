-- user_profiles.birth_date/gender/phone/city/district canlıda vardı ama
-- hiçbir migration dosyası bu kolonları eklemiyordu (base_schema.sql'deki
-- ilk CREATE TABLE'da da yoklar) — muhtemelen migration akışı dışında elle
-- eklenmişti. 20260908120000_lock_down_user_profiles_sensitive_columns.sql
-- bu kolonlardan REVOKE SELECT yaptığı için `supabase db reset` ile
-- sıfırdan kurulum "column does not exist" ile patlıyordu. Canlı
-- information_schema/pg_constraint'ten doğrulandı — [[private şema]] ve
-- [[review_photos]]/[[list_menu_ai_analysis_v1]] ile aynı drift deseni.
alter table public.user_profiles
  add column if not exists birth_date date,
  add column if not exists gender text,
  add column if not exists phone text,
  add column if not exists city text,
  add column if not exists district text;

alter table public.user_profiles
  add constraint user_profiles_gender_check
  check (gender = any (array['male','female','other','prefer_not_to_say']));
