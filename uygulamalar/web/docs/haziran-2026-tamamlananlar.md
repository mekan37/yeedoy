# Haziran 2026 Tamamlananlar

## 2026-06-04 — admin/appeals MVP

**Branch:** `feature/web-admin-appeals-mvp`

- `app/admin/appeals/page.tsx` stub'ı gerçek MVP'ye çevrildi
- `src/lib/veri/admin/itirazlar.ts` — `admin_list_moderation_appeals_v1` RPC data helper
- `app/admin/appeals/appeal-actions.ts` — `admin_decide_moderation_appeal_v1` server action
- `checkAdminAccess()` ile server-side ikinci katman admin guard
- Status filtresi: pending / approved / rejected / all
- Onay/red aksiyonu: admin note desteği, decision whitelist
- PII maskeleme: `appellant_user_id` → `Kullanıcı #XXXXXX`
- `source_type` badge (yorum / işletme / menü öğesi / kullanıcı)
- Pagination, overflow-x-auto mobil scroll
