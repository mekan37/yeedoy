# Haziran 2026 Tamamlananlar

## 2026-06-04 — owner/marketing/loyalty MVP

**Branch:** `feature/web-owner-loyalty-mvp`

- `app/owner/marketing/loyalty/page.tsx` stub'ı gerçek MVP'ye çevrildi
- `src/lib/veri/owner/sadakat.ts` — `loyalty_programs` tablosu data helper (`getOwnerLoyaltyPrograms`)
- `app/owner/marketing/loyalty/loyalty-actions.ts` — `upsert_loyalty_program_v1` server action
- `app/owner/marketing/loyalty/loyalty-form.tsx` — `useActionState` tabanlı client form bileşeni
- `hasOwnerBusiness()` ile server action ownership guard (fail-closed)
- Puan kuralları: checkin / review / photo / reward_threshold / reward_type / reward_value
- Aktif/pasif toggle (program durdurma)
- Çoklu business desteği: `?business_id=uuid` searchParams
- Sağ panel info card: puan kazanım özeti
- Geçersiz `sadakat_karti` migration'a dokunulmadı

---

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
