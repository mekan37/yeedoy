# Dagitim Notlari (Kod Tabanli)

Bu belge dagitim davranisini koddaki scriptlere gore aciklar.

## Build Komutlari

```bash
npm run build:owner
npm run build:admin
npm run build:next
npm run build:all
```

Kanit: `package.json` (repo root)

## Cikti Klasorleri

- `deploy/owner` -> Flutter web owner
- `deploy/admin` -> Flutter web admin
- `deploy/next` -> Next.js build ciktisi

## Operasyon Notu

- Flutter web owner/admin statik dagitilabilir.
- Next tarafi Node.js process ister (`next start`). Salt FTP statik kopya yeterli degil.
