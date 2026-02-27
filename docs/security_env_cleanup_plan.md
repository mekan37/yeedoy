# Guvenlik Cleanup Plani - `.env.example`

## Mevcut Durum (2026-02-27)

`apps/web_next/.env.example` dosyasi placeholder formatina cekildi.

Etkilenen dosya:
- `apps/web_next/.env.example`

Mobil ve panel example dosyalari placeholder formatinda:
- `apps/mobile_flutter/.env.example`
- `apps/panel_flutter_web/.env.example`

## Risk (Kalan)

- Bu dosya temizlendi; ancak lokal makinelerde kalmis olabilecek eski `.env` dosyalari hala risk olusturabilir.
- CI tarafinda otomatik secret scan olmadigi icin regressions tekrar gelebilir.

## Aksiyon Plani

1. Eski key'ler kullanildiysa key rotasyonu yap (anon + service role).
2. CI secret scan ekle (`gitleaks` veya benzeri).
3. PR checklist'e `env.example secret check` maddesi ekle.

## Hizli Kontrol

```bash
rg -n "eyJhbGci|SUPABASE_SERVICE_ROLE_KEY=.*[A-Za-z0-9_-]{20,}" apps/**/.env.example
```

Beklenen: eslesme olmamasi.
