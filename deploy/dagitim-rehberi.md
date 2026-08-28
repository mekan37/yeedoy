# YEEDOY Deploy Rehberi (FTP)

> **Not (2026-08-28):** Bu rehber eskiden `deploy/owner` ve `deploy/admin` altında toplanan
> ayrı Flutter-web owner/admin panel build çıktılarını da kapsıyordu. O panel mimarisi
> Next.js'e taşındı (`/sahip`, `/yonetici`), kök `package.json`'da `build:owner`/`build:admin`
> script'leri artık yok, ve `deploy/admin`/`deploy/owner` klasörleri (70MB donmuş build
> çıktısı) repodan silindi. Kalan tek deploy çıktısı `deploy/next`.

Bu repo yapısında deploy çıktıları tek yerde toplanır:

- `deploy/next` -> Next.js build çıktısı (server deploy)

## 1) Build Komutları

Repo kökünden:

```bash
npm run build:next
npm run build:all
```

## 2) Next.js Server Deploy Notu

`deploy/next` içinde `.next` ve gerekli dosyalar bulunur.

Örnek sunucu adımları:

1. `deploy/next` dosyalarını sunucuda bir klasöre yükle (ör. `/var/www/yeedoy-next`).
2. Sunucuda:
   - `npm install --omit=dev`
   - `npm run start` (veya PM2 ile)
3. Reverse proxy (Nginx/Apache) ile `/:` root'unu bu Node servisine yönlendir.

Not: Static-only FTP host kullanıyorsan Next tarafı için ayrı Node/VPS gereklidir.
