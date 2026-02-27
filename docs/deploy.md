# Dağıtım Notları (Güncel Durum)

Bu belge dağıtım notudur. Ürün/mimari gerçekleri için öncelikli kaynak:

- `docs/product.md`
- `docs/apps.md`
- `docs/architecture.md`
- `docs/setup.md`

## Build Çıktıları

Kök scriptler:

```bash
npm run build:owner
npm run build:admin
npm run build:next
npm run build:all
```

Kaynak: repo kökü `package.json`

## Çıktı Klasörleri

- `deploy/owner` -> Flutter web owner çıktısı
- `deploy/admin` -> Flutter web admin çıktısı
- `deploy/next` -> Next.js build çıktısı

## Operasyonel Not

- Flutter web owner/admin statik dağıtılabilir.
- Next tarafı Node.js süreç gerektirir (`next start`), yalnızca statik FTP kopyası yeterli değildir.
