# Web Next Kurallari

Bu app public menu dagitim katmanidir. Owner/admin CRUD buraya eklenmez.

## Kanonik Yapi

- Routes: `app/**`
- Read model: `src/lib/db/*`
- Route helper/schema: `src/lib/*`
- UI section'lari: `src/ui/*`
- Stil: `src/styles/tokens.css`, `globals.css`, `tailwind.config.js`
- I18n: `src/lib/i18n.ts`

## Yazim Kurali

- Public veri okumasi `src/lib/db` tarafinda cozulur.
- Client component sadece interaktivite alir; veri kontrati server helper'dan gelir.
- Yeni mutation `app/api/**/route.ts` altina gider.
- Route handler icinde `zod.safeParse`, auth/yetki ve gerekirse rate limit kullanilir.
- User-facing copy inline yazilmaz; `src/lib/i18n.ts` veya ilgili merkezi sabit dosyaya tasinir.

## Stil

- Raw hex yerine token class'lari kullan: `bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`.
- React state icin mevcut basit kalip korunur; yeni global state library eklenmez.
- Public menu temalari mevcut registry ile uyumlu kalir.

## Validation

```bash
npm --prefix apps/web_next run typecheck
npm --prefix apps/web_next run lint
```

UI/route degisikliginde uygun oldugunda:

```bash
npm --prefix apps/web_next run test
```
