# YEEDOY Deploy Rehberi (FTP)

Bu repo yapısında deploy çıktıları tek yerde toplanır:

- `deploy/owner` -> Flutter web owner panel statik çıktı
- `deploy/admin` -> Flutter web admin panel statik çıktı
- `deploy/next` -> Next.js build çıktısı (server deploy)

## 1) Build Komutları

Repo kökünden:

```bash
npm run build:owner
npm run build:admin
npm run build:next
npm run build:all
```

## 2) FTP'ye Neyi Nereye Atacağım?

Örnek hedefler:

- Owner panel: `/public_html/owner/`
  - FTP'ye yükle: `deploy/owner/*`
- Admin panel: `/public_html/admin/`
  - FTP'ye yükle: `deploy/admin/*`
- Next.js:
  - `deploy/next` statik export değildir.
  - Server tarafında Node.js ile çalıştırılmalıdır.
  - FTP ile sadece dosya yüklemek yeterli değildir; process manager (PM2/systemd) gerekir.

## 3) Flutter Web (Owner/Admin) Sunucu Ayarları

### Base path

- Owner build: `--base-href /owner/`
- Admin build: `--base-href /admin/`

### SPA route fallback

Owner ve admin için tüm bilinmeyen route'lar ilgili `index.html` dosyasına düşmelidir:

- `/owner/*` -> `/owner/index.html`
- `/admin/*` -> `/admin/index.html`

### Cache headers (önerilen)

- `*.js`, `*.css`, `*.wasm`, `assets/*`: uzun cache
  - `Cache-Control: public, max-age=31536000, immutable`
- `index.html`: kısa cache
  - `Cache-Control: no-cache, no-store, must-revalidate`

## 4) Next.js Server Deploy Notu

`deploy/next` içinde `.next` ve gerekli dosyalar bulunur.

Örnek sunucu adımları:

1. `deploy/next` dosyalarını sunucuda bir klasöre yükle (ör. `/var/www/yeedoy-next`).
2. Sunucuda:
   - `npm install --omit=dev`
   - `npm run start` (veya PM2 ile)
3. Reverse proxy (Nginx/Apache) ile `/:` root'unu bu Node servisine yönlendir.

Not: Static-only FTP host kullanıyorsan Next tarafı için ayrı Node/VPS gereklidir.
