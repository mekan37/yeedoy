# web_next

Next.js public web uygulaması (landing + QR menü + dashboard yüzeyleri).

## Kurulum
1. `.env.example` dosyasını `.env.local` olarak kopyala.
2. Değişkenleri doldur.
3. Çalıştır:

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
npm run start
```

## Lint / Typecheck

```bash
npm run lint
npm run typecheck
```

## Ana Route’lar
- `/`
- `/dashboard`
- `/b/[slug]`
- `/q/[code]`
- `/devtools` (yalnızca `DEV_TOOLS_ENABLED=true` ve production dışı)
