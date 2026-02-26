# Supabase Rebrand Checklist (yeedoy -> yeedoy)

## 1) Auth Redirect URLs
- Supabase Dashboard -> Authentication -> URL Configuration altında tüm `yeedoy` domain/subdomain adreslerini `yeedoy` ile güncelle.
- Güncellenecek minimum URL seti:
  - `https://<domain>/login/callback`
  - `https://<domain>/owner/*`
  - `https://<domain>/admin/*`
  - `https://<domain>/menu-builder/*`
- Mobile deep link kullanılıyorsa `yeedoy://` şemasını da ekle.

## 2) Site URL / App URL Env
- `NEXT_PUBLIC_APP_URL` ve benzeri public URL env değerlerinde `yeedoy` geçen hostları güncelle.
- Supabase Edge Functions içinde callback oluşturulan URL'ler varsa yeni domainleri kullan.

## 3) Storage Public URL Kontrolü
- Public bucket URL'lerinde brand adı geçmiyorsa değişiklik gerekmeyebilir.
- Eğer custom CDN veya path prefix içinde `yeedoy` varsa yeni prefix'e yönlendirme planı yap.

## 4) Edge Functions Brand-Specific Varsayılanlar
- Varsayılan rate-limit salt/metinler güncellendi:
  - `yeedoy_default_salt` -> `yeedoy_default_salt`
  - `yeedoy_upload` -> `yeedoy_upload`
- Üretimde mutlaka `EDGE_RATE_LIMIT_SALT` env değişkeni set edilmelidir.

## 5) DB Şema Kontrolü
- Bu çalışmada tablo/kolon adlarında `yeedoy` tespit edilmediği için DB DDL değişikliği yapılmadı.
- Eğer ileride brand adını taşıyan seed/metadata satırları varsa data migration ile güncelle.

## 6) Supabase Push Sırası
1. Local migration/function değişikliklerini doğrula.
2. `supabase db push --include-all --yes`
3. `supabase functions deploy <function-name>` (değişen function'lar)
4. Auth redirect URL'leri dashboard'da doğrula.

