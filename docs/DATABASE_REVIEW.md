# Veritabani Incelemesi

**Tarih:** 2026-03-11
**Kapsam:** `supabase/migrations/`, `supabase/functions/`, RLS ve RPC katmani

## Ozet

Supabase semasi bugunku urun asamasi icin olgun gorunuyor. Migration gecmisi duzenli, isimlendirme tutarli ve RPC-first write deseni guvenlik acisindan dogru bir taban kuruyor. Ana gelisim alanlari:

- tum admin listelerinde standardize edilmemis server-side pagination
- owner analytics tarafinda saatlik granulerlik eksigi
- RBAC gecisi oncesinden kalan bazi eski gating izleri

**Genel not:** A- seviyesinde, uretime hazir ama hedefli iyilestirme gerektiriyor.

## Migration Sagligi

| Metrik | Deger |
|---|---|
| Toplam migration | 178+ |
| Isim kalibi | `YYYYMMDDNNNNNN_{description}.sql` |
| RLS kapsami | Hassas tablolarda aktif |
| Edge Function | 8 |

Belirgin bir sira bozuklugu veya kopuk migration izi goze carpmiyor.

## Tablo Kumelemesi

### Public menu ekseni

| Tablo | Public okuma | Not |
|---|---|---|
| `businesses` | Evet | `slug` ve `public_slug` tasir |
| `menus` | Evet | Public menu akisinin cekirdegi |
| `menu_sections` | Evet | |
| `menu_categories` | Evet | |
| `menu_items` | Evet | |
| `menu_item_variants` | Evet | |
| `menu_item_photos` | Evet | |
| `menu_translations` | Evet | |
| `business_media` | Evet | Isletme bazli path izolasyonu var |
| `business_hours` | Evet | |
| `analytics_events` | Hayir | Yalnizca RPC uzerinden write |

### Katki ve moderasyon ekseni

| Tablo | Not |
|---|---|
| `menu_item_price_suggestions` | Tuketici fiyat onerileri |
| `reports` | Kullanici raporlari |
| `owner_claims` | Isletme sahiplik talepleri |
| `business_submissions` | Yeni isletme basvurulari |
| `receipt_submissions` | Operator review alanlariyla zenginlesmis fis kaniti |
| `receipt_matches` | Fis-urun eslesmeleri |
| `client_mutation_idempotency_keys` | Mobil duplicate write onleme |
| `admin_audit_log` | Admin aksiyon audit izi |

### Etkilesim ve sosyal eksen

| Tablo | Not |
|---|---|
| `favorites` | Kaydedilen isletme ve urunler |
| `notifications` | Inbox bildirimleri |
| `price_alerts` | Fiyat alarmi |
| `group_requests` | Grup yemek talepleri |
| `group_offers` | Isletme yanitlari |
| `visits` | Ziyaret takibi |

### Takim ve erisim ekseni

| Tablo | Not |
|---|---|
| `admin_users` | Admin panel kullanicilari |
| `business_team_memberships` | Subeye veya business'a bagli erisim |
| `chain_memberships` | Zincir seviyesi erisim |

## Ana Riskler

| Risk | Etki | Oneri |
|---|---|---|
| Eski gating izleri | Yetki modelinde kafa karisikligi | `rbac.md` kaynak belge olarak korunmali |
| Saatlik analytics eksigi | Owner raporlari sinirli kaliyor | Saatlik agregasyon secenegi eklenmeli |
| Admin pagination standardi eksigi | Buyuk listelerde performans ve dogruluk riski | Tum admin liste RPC'leri ayni sayfalama desenine alinmali |

## Ne Zaman Bu Belgeye Bakilir?

- Supabase migration sagligini gozden gecirirken
- RLS, RPC ve veri guvenligi tartisilirken
- Tablo kumelemesini hizli anlamak isterken

Detayli tablo ve RPC listesi icin birincil belge `docs/data-model.md` dosyasidir.
