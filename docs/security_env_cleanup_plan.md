# Guvenlik Cleanup Plani - `.env.example`

## Mevcut Durum (2026-02-27)

Su anda `apps/web_next/.env.example` dosyasinda gercek key benzeri degerler bulunuyor.

Etkilenen dosya:
- `apps/web_next/.env.example`

Mobil ve panel example dosyalari placeholder formatinda:
- `apps/mobile_flutter/.env.example`
- `apps/panel_flutter_web/.env.example`

## Risk

- Ornek dosyada gercek key birakmak, key rotasyonu yapilsa bile operasyonel hijyen acigi olusturur.
- Yeni ekip uyelerinde "bunlar test key" algisi olusup production key dagitimi riski dogar.

## Aksiyon Plani

1. `apps/web_next/.env.example` dosyasini placeholder degerlere cek.
2. Key rotasyonu yap (anon + service role).
3. CI secret scan ekle (`gitleaks` veya benzeri).
4. PR checklist'e `env.example secret check` maddesi ekle.

## Hizli Kontrol

```bash
rg -n "eyJhbGci|SUPABASE_SERVICE_ROLE_KEY=.*[A-Za-z0-9_-]{20,}" apps/**/.env.example
```

Beklenen: eslesme olmamasi.
