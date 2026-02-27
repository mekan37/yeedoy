# Güvenlik Cleanup Planı - `.env.example`

## Amaç

Repo içinde örnek dosyalarda gerçek anahtar/token bulunmasını engellemek ve ekip için güvenli bir örnek şablon bırakmak.

## Bu Turda Uygulananlar

- `apps/mobile_flutter/.env.example` içindeki gerçek anahtarlar placeholder ile değiştirildi.
- `apps/mobile_flutter/.env.example` içindeki hatalı anahtar adı `SSUPABASE_URL` -> `SUPABASE_URL` düzeltildi.
- `apps/web_next/.env.example` içindeki gerçek anahtarlar placeholder ile değiştirildi.

## Kontrol Kapsamı

- Track edilen env dosyaları:
  - `apps/mobile_flutter/.env.example`
  - `apps/panel_flutter_web/.env.example`
  - `apps/web_next/.env.example`
- Track edilmeyen yerel dosyalar (`.env`, `.env.local`) `.gitignore` ile dışarıda.

## Push Sonrası Yapılacak Operasyonlar

1. Supabase anahtar rotasyonu:
   - `ANON KEY`
   - `SERVICE ROLE KEY`
2. Geçmiş commitlerde anahtar sızıntısı varsa history cleanup (gerekirse BFG/filter-repo).
3. CI tarafına secret scanning ekleme (örn. gitleaks/trufflehog).
4. PR template'e "secret leak check" maddesi ekleme.

## Hızlı Doğrulama

Push öncesi şu kontrol uygulanmalı:

```bash
rg -n "eyJhbGci|SUPABASE_SERVICE_ROLE_KEY=.*[A-Za-z0-9_-]{20,}" apps/**/.env.example
```

Beklenen: eşleşme olmaması.
