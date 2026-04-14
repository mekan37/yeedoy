# Supabase Rebrand Checklist (yeedoy -> yeedoy)

> Arşiv notu: Bu dosya rebrand donemi icin uretilmis tek seferlik bir kontrol listesidir.
> Aktif gorev olarak kullanilmaz.

## 1) Auth Redirect URLs
- Supabase Dashboard -> Authentication -> URL Configuration altinda tum `yeedoy` domain/subdomain adreslerini `yeedoy` ile guncelle.
- Guncellenecek minimum URL seti:
  - `https://<domain>/login/callback`
  - `https://<domain>/owner/*`
  - `https://<domain>/admin/*`
  - `https://<domain>/menu-builder/*`
- Mobile deep link kullaniliyorsa `yeedoy://` semasini da ekle.

## 2) Site URL / App URL Env
- `NEXT_PUBLIC_APP_URL` ve benzeri public URL env degerlerinde `yeedoy` gecen hostlari guncelle.
- Supabase Edge Functions icinde callback olusturulan URL'ler varsa yeni domainleri kullan.

## 3) Storage Public URL Kontrolu
- Public bucket URL'lerinde brand adi gecmiyorsa degisiklik gerekmeyebilir.
- Eger custom CDN veya path prefix icinde `yeedoy` varsa yeni prefix'e yonlendirme plani yap.

## 4) Edge Functions Brand-Specific Varsayilanlar
- Varsayilan rate-limit salt/metinler guncellendi:
  - `yeedoy_default_salt` -> `yeedoy_default_salt`
  - `yeedoy_upload` -> `yeedoy_upload`
- Uretimde mutlaka `EDGE_RATE_LIMIT_SALT` env degiskeni set edilmelidir.

## 5) DB Sema Kontrolu
- Bu calismada tablo/kolon adlarinda `yeedoy` tespit edilmedigi icin DB DDL degisikligi yapilmadi.
- Eger ileride brand adini tasiyan seed/metadata satirlari varsa data migration ile guncelle.

## 6) Supabase Push Sirasi
1. Local migration/function degisikliklerini dogrula.
2. `supabase db push --include-all --yes`
3. `supabase functions deploy <function-name>` (degisen function'lar)
4. Auth redirect URL'leri dashboard'da dogrula.
