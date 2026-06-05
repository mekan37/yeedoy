# Eksik / Stub Sayfa Listesi

Bu dosya, admin/owner panel sayfalarının tamamlanma durumunu izler.

| # | Route | Açıklama |
|---|-------|----------|
| 3 | `owner/marketing/email` | ✅ MVP tamamlandı — Resend delivery helper hazır. is_subscribed_email consent filtresi aktif. RESEND_API_KEY runtime env bekliyor. estimate_email_segment_v1 broken (follower_id kolonu yok) — direct query kullanıldı. |
| 4 | `owner/marketing/loyalty` | ✅ MVP tamamlandı — loyalty_programs + upsert_loyalty_program_v1 RPC, puan kuralları, aktif/pasif toggle (PR #48) |
| 19 | `admin/appeals` | ✅ MVP tamamlandı — moderation_appeals tablosu + admin_list/decide_v1 RPC, status filtresi, admin note, pagination (PR #XX) |
