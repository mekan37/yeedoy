# Web Next Remaining Tasks

## Kalan İşler

- Kalıcı favori: `FavoriteButton` local optimistic state yerine mevcut auth/favoriler yapısına bağlanmalı.
- Rapor modeli: business/review report payloadları mevcut `reports` tablosuyla ayrı rate-limited endpoint’e taşınabilir.
- Menü kategori adları: `menu_categories` için translation veya display name adapter’ı netleştirilmeli.
- Arama kalitesi: mobilde kullanılan `search_nearby_businesses_v3` web adapter’ına opsiyonel geo parametreleriyle bağlanabilir.
- İşletme detay RPC: `get_business_detail_v1` web tarafında read adapter fallback’i olarak eklenebilir.
- Lighthouse: canlı data ve production env ile `/`, `/kesif`, `/isletme/[slug]`, `/m/[slug]` ölçümü tekrar alınmalı.

## Kontrol Notları

- Supabase migration yazılmadı.
- Owner/admin CRUD public Next deneyimine taşınmadı.
- QR menü route’u korunarak bırakıldı.
- `npm --prefix uygulamalar/web run typecheck`: geçti.
- `npm --prefix uygulamalar/web run lint`: geçti; yalnızca mevcut unrelated `<img>` uyarıları var.
- `npm --prefix uygulamalar/web run test:unit`: çalışmadı; `uygulamalar/web/node_modules/vitest/vitest.mjs` bulunamadı.
- `npm --prefix uygulamalar/web run build`: kod derlemesine geçmeden `.next/trace` için Windows `EPERM` temizleme hatasında durdu.
- `npm --prefix uygulamalar/web run build:next`: 6 dakika sonunda çıktı üretmeden zaman aşımına girdi.


