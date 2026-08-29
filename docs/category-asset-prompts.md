# Yeedoy Mobile Category Asset Prompts

Date: 2026-06-08

Live Supabase project checked: `yeedoy-production` (`dktdnbeougrmhkzplbap`)

Findings:
- `public.businesses.category` exists as `text not null`.
- `public.businesses.category_slug` does not exist.
- No `businesses` check constraint or enum for `category` was found in production.
- Runtime import category allow-list existed in `supabase/functions/import_places_json/index.ts` at the time of this audit (function since removed along with the OSM/Foursquare import pipeline it served).

Production distribution:

| Category | Slug | Source | Business count / evidence | Visual needed |
|---|---|---|---:|---|
| Restoran | restoran | Live DB + import allow-list | 26,517 rows | Yes |
| Kafe | kafe | Live DB + import allow-list | 14,477 rows | Yes |
| Balık / Et | balik-et | Live DB + import allow-list | 6,001 rows | Yes |
| Mekan | mekan | Live DB + import allow-list | 4,622 rows | Yes |
| Tatlıcı | tatlici | Live DB + import allow-list | 2,210 rows | Yes |
| Kahvaltı | kahvalti | Live DB + import allow-list | 1,175 rows | Yes |
| Default | default | App fallback | Fallback for unknown legacy values | Yes |

Static evidence (as of this audit; the two Supabase source files below have since been removed):
- `supabase/functions/import_places_json/index.ts`: `ALLOWED = new Set(["Kafe", "Restoran", "Tatlıcı", "Kahvaltı", "Balık / Et", "Mekan"])`
- `supabase/seed/migrate_businesses.sql`: legacy/sample values included `Restoran`, `Balık`, `Kafe`, `restaurant`, plus non-food legacy values such as `Oto Servis` and `Klinik`.
- `uygulamalar/web/src/ui/acik/kesif.tsx`: public discovery category UI includes `Restoran`, `Kafe`, `Kahvaltı`.
- `uygulamalar/mobil/lib/l10n/app_tr.arb`: mobile copy includes `Kafe`, `Restoran`, `Tatlıcı`, `Kahvaltı`, `Balık / Et`, `Mekan`.

Style rules for all assets:
- Real business photos are not used.
- No copyrighted brand, logo, watermark, readable text, or people.
- Premium 3D semi-realistic food/place illustration.
- 1:1 square source, optimized to 512x512 WebP for Flutter.
- Warm, clean, appetizing, Turkish-local food/place cues.
- Works in list cards, category filters, empty states, and discovery surfaces.

## Kafe / cafe

Asset path:
`assets/images/categories/cafe.webp`

Prompt:
"Modern mobile app category illustration for a Turkish cafe, ceramic coffee cup, Turkish tea glass, small dessert plate, cozy wooden table, warm lighting, soft cream background, premium 3D semi-realistic style, centered composition, clean negative space, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail, mobile UI asset"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy background, low quality, distorted food, extra objects, alcohol"

## Restoran / restoran

Asset path:
`assets/images/categories/restoran.webp`

Prompt:
"Modern restaurant category illustration, elegant plated main dish, fork and folded napkin, subtle steam, warm restaurant table setting, premium 3D semi-realistic mobile app asset, soft neutral cream background, centered composition, clean negative space, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy background, low quality, distorted food, extra objects, alcohol"

## Tatlıcı / tatlici

Asset path:
`assets/images/categories/tatlici.webp`

Prompt:
"Turkish dessert shop category illustration, baklava pieces, cake slice, small dessert plate, pistachio garnish, warm appetizing colors, premium 3D semi-realistic mobile app asset, soft cream background, centered composition, clean negative space, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy background, low quality, distorted food, extra objects, alcohol"

## Kahvaltı / kahvalti

Asset path:
`assets/images/categories/kahvalti.webp`

Prompt:
"Turkish breakfast category illustration, simit, cheese, olives, tomato, cucumber, Turkish tea glass, small breakfast plates, bright morning feeling, premium 3D semi-realistic mobile app asset, soft light background, centered composition, clean negative space, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy background, low quality, distorted food, extra objects, alcohol"

## Balık / Et / balik-et

Asset path:
`assets/images/categories/balik-et.webp`

Prompt:
"Combined fish and meat restaurant category illustration for Turkish users, grilled fish plate with lemon and herbs plus a small grilled kebab or steak element, clean light cream background with subtle sea-blue accent and warm grill-table feeling, premium 3D semi-realistic mobile app asset, centered composition, clear focal plate, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy background, low quality, distorted food, extra objects, harsh smoke, raw meat, alcohol"

## Mekan / mekan

Asset path:
`assets/images/categories/mekan.webp`

Prompt:
"Generic venue category illustration, modern local storefront facade, small table and chair, warm entrance light, minimal food display without readable text or signage, friendly Turkish local place atmosphere, premium 3D semi-realistic mobile app asset, clean soft background, centered composition, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy street, crowded background, distorted architecture, low quality, alcohol"

## Default / default

Asset path:
`assets/images/categories/default.webp`

Prompt:
"Generic food place category illustration, simple plate, fork, small location pin shape without text, a few fresh food accents, warm friendly mobile app style, premium 3D semi-realistic asset, clean soft cream background, centered composition, no text, no logo, no watermark, no people, no human faces, no brand names, no alcohol, 1:1 square, high detail"

Negative prompt:
"text, logo, watermark, brand names, human faces, people, messy background, low quality, distorted food, extra objects, overly abstract icon look, alcohol"

