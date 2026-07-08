-- user_profiles.language_code: kullanıcının uygulama dil tercihi.
-- Önceden mobil Profile.languageCode/LocaleController bu kolonu bekliyordu
-- ama kolon yoktu; tercih hiçbir zaman backend'e yazılmıyordu (yalnızca
-- oturum içi local state). profile_settings_page.dart'taki "Para Birimi"
-- olarak yanlış etiketlenmiş dropdown da bu eksikliğin bir belirtisiydi.
alter table public.user_profiles
  add column if not exists language_code text;

alter table public.user_profiles
  add constraint user_profiles_language_code_check
  check (language_code is null or language_code in ('tr', 'en'));
