# Delivery Integration Status — Email (Owner Kampanyaları)

> **Kapsam Notu (2026-08-28):** Bu belge eskiden Push (FCM), Email (Resend) ve SMS
> olmak üzere 3 kanalı birden kapsıyordu. Güncel durum:
> - **Push (FCM):** Tamamen kapatıldı. `app/sunucu/yonetici/push-kampanyalari/route.ts`
>   artık bir kill-switch — her istekte `410 feature_disabled` döner. FCM client kodu
>   (`fcm-client.ts`, `get-segment-tokens.ts`) repodan silinmiş durumda.
> - **SMS:** Hiç uygulanmadı, altyapı ertelendi (bkz. proje hafızası: bütçe kısıtı).
>   `sms_campaigns` route/tablosu repoda yok.
> - **Email (Resend):** Tek hâlâ yaşayan kanal. Aşağıdaki belge yalnızca bunu kapsar.
>
> "Delivery" burada **mesaj teslimatı** (e-posta bildirim altyapısı) anlamındadır;
> sipariş/yemek teslimatı (delivery) **DEĞİLDİR** — sipariş teslimatı final stratejik
> karar raporuna göre kapsam dışıdır.

---

## Kod ve Altyapı

| Bileşen | Konum | Durum |
|---|---|---|
| Owner email route | `app/sunucu/sahip/eposta-kampanya/route.ts` | ✅ Deployed |
| Resend client | `src/lib/email/resend-client.ts` | ✅ Deployed (`sendEmailCampaign`) |
| Unsubscribe token | `src/lib/email/unsubscribe-token.ts` | ✅ Deployed |
| Route şema/yardımcılar | `app/sunucu/sahip/eposta-kampanya/sema.ts`, `metin-temizle.ts` | ✅ Deployed |
| Owner email sekmesi (UI) | `app/sahip/pazarlama/kampanyalar/eposta-sekmesi.tsx` | ✅ Deployed |
| `email_campaigns` tablosu | Supabase | ✅ Şema mevcut |
| `estimate_email_segment_v1` | RPC | ✅ Mevcut, düzeltilmiş (`business_follows.business_id`/`is_subscribed_email` filtresi + yetki kontrolü) |

**Fail-safe pattern:** `RESEND_API_KEY` eksikse `provider_not_configured: true` döner, throw etmez.

## Ortam Durumu

| Ortam | `RESEND_API_KEY` | Not |
|---|---|---|
| GitHub Secrets | ✅ Mevcut (2026-06-29'da eklendi, `gh secret list` ile doğrulandı) | — |
| Production runtime (Vercel) | **Doğrulanmadı** | GitHub secret'ları Vercel env var'larına otomatik yansımaz — production'da aktif olup olmadığı ayrıca kontrol edilmeli (`vercel env ls` veya Vercel dashboard) |

## KVKK / Consent Filtresi

Gönderim yalnızca `is_subscribed_email = true` olan kullanıcılara yapılır — consent vermemiş kullanıcı otomatik dışlanır.

## Sonraki Adım

Production'da e-posta kampanyalarının gerçekten gönderim yapıp yapmadığını doğrulamak için: `RESEND_API_KEY`'in Vercel Production ortam değişkenlerinde olduğunu teyit et, ardından `/sahip/pazarlama/kampanyalar` üzerinden küçük bir test kampanyası gönderip `provider_not_configured: false` yanıtını doğrula.

## İlgili Belgeler

- `docs/security/account-security.md` — SMS 2FA neden tercih edilmedi bağlamı
- `docs/kalan-isler.md` — açık iş kalemleri
