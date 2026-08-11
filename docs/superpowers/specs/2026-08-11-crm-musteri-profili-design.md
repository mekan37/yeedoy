# CRM — Birleşik Müşteri Profili — Design Doc

## Bağlam

Kullanıcının owner panel özellik öncelik sırası **"Destek → Çoklu Şube → Sadakat → CRM"** (bkz. `docs/superpowers/specs/2026-08-06-destek-sistemi-design.md` §Bağlam). Destek, Çoklu Şube ve Sadakat tamamlandı; CRM sıradaki ve son özellik.

Sahip panelinde müşteri etkileşimleri şu an dağınık: yorumlar (`/sahip/yorumlar`), rezervasyonlar (`/sahip/rezervasyonlar`), sadakat üyeleri (`/sahip/pazarlama/sadakat`) ayrı sayfalarda. Owner'ın "bu müşteri kim, geçmişi ne" sorusuna tek yerden cevap bulabileceği birleşik bir görünüm yok.

Ayrı bir "müşteri" domain tablosu gerekmiyor — müşteri kimliği zaten `auth.users`'ta var. "Bu işletmenin müşterisi" olmak, şu mevcut tablolardan birinde o işletmeye ait bir kayıt sahibi olmak demek: `reviews`, `reservations`, `loyalty_members` (program üzerinden), `business_follows`, `visits`.

## Hedefler

- Owner, kendi işletmesiyle etkileşimi olan (yorum/rezervasyon/sadakat/takip) tüm müşterileri tek bir listede görebilsin.
- Bir müşteriye tıklayınca, o müşterinin bu işletmeyle olan tüm geçmişini kronolojik bir zaman çizelgesinde görebilsin.

## Kapsam Dışı (v1, YAGNI)

- Not/etiket ekleme, müşteri segmentasyonu — ayrı bir faz.
- Toplu e-posta/bildirim/kampanya gönderimi — ayrı bir faz.
- Liste sayfasında arama/filtre — v1'de yok.
- Zincir-çapında birleşik görünüm — sadakat zincir çapında paylaşılsa da, CRM görünümü v1'de **şube bazlı** kalır (owner seçili tek işletmenin müşterilerini görür). Zincir-çapında birleştirme ayrı bir faz olabilir.
- Mobil uygulamada CRM — proje kısıtı gereği zaten yok (`CLAUDE.md`: "No admin/owner CRUD in mobile app").

## Veri Modeli

Yeni tablo yok. Mevcut tablolardan okuma yapan iki yeni RPC:

```
get_business_customers_v1(p_business_id)
  → her müşteri için: user_id, display_name, avatar_url,
    last_interaction_at, review_count, reservation_count,
    loyalty_progress (varsa), loyalty_reward_threshold (varsa)

get_customer_timeline_v1(p_business_id, p_user_id)
  → kronolojik olay listesi: event_type ('review'|'reservation'|
    'loyalty_scan'|'loyalty_redeem'|'follow'), occurred_at,
    summary (örn. yorum metni özeti, rezervasyon kişi sayısı/saati,
    sadakat ilerleme miktarı)
```

Her iki RPC de mevcut tablolardan `UNION ALL` + `JOIN` ile okuma yapar; INSERT/UPDATE yok, salt-okunur.

## RPC Yüzeyi

**Owner (`has_business_permission_v1(p_business_id, 'menu_write')` — editor+ ile korunur, sadakat'teki desenin aynısı):**

- `get_business_customers_v1(p_business_id)` — liste görünümü
- `get_customer_timeline_v1(p_business_id, p_user_id)` — detay/zaman çizelgesi görünümü

Personel (staff, rank 200) bu iki RPC'yi çağıramaz — müşteri verisi hassas, sadakat'teki QR tarama gibi bir sayaç işlemi değil.

## Akışlar

1. Owner sol menüde bağımsız **"Müşteriler"** nav öğesine tıklar → `/sahip/musteriler`.
2. Liste sayfası `get_business_customers_v1` ile yüklenir, tablo halinde gösterilir (Müşteri / Son Etkileşim / Yorum / Rezervasyon / Sadakat sütunları — mevcut sadakat üye listesi tablosuyla aynı görsel desen).
3. Bir satıra tıklayınca `/sahip/musteriler/[user_id]` detay sayfasına gidilir.
4. Detay sayfası `get_customer_timeline_v1` ile yüklenir: sol tarafta sabit özet kart (isim, ilk etkileşim tarihi, sadakat ilerleme çubuğu varsa), sağ tarafta kronolojik olay akışı (her olay tipi kendi ikonuyla — yorum, rezervasyon, sadakat tarama/ödül, takip).

## UI

- **Liste sayfası** (`/sahip/musteriler`): mevcut `PanelSayfaBasligi` + `PanelIcerikYuzeyi` kabuğu, tablo (mevcut `uye-listesi.tsx` deseniyle aynı stil). Boş durum: mevcut `PanelEmptyState` bileşeni ("Henüz hiç müşteri etkileşimi yok").
- **Detay sayfası** (`/sahip/musteriler/[user_id]`): sol-sağ split layout — sol sabit özet kart, sağ kronolojik zaman çizelgesi (mockup'ta onaylanan "C — Sol profil + sağ zaman çizelgesi" seçeneği).
- Sol menüde bağımsız "Müşteriler" nav öğesi (Destek/Ekip ile aynı seviyede).

Mockup onaylandı (bkz. brainstorming oturumu — 3 layout seçeneğinden "Zaman Çizelgesi" seçildi).

## Güvenlik

- Her iki RPC de `SECURITY DEFINER`, sadakat'teki kritik dersle aynı üçlü REVOKE deseni uygulanacak: `REVOKE ALL ... FROM PUBLIC` + `REVOKE EXECUTE ... FROM anon` + `GRANT EXECUTE ... TO authenticated`, ardından `has_function_privilege()` ile production'da doğrudan doğrulanacak (advisor cache'ine güvenilmeyecek).
- Yetkilendirme `has_business_permission_v1(p_business_id, 'menu_write')` (editor+) — staff erişemez.
- Yeni bir veri sızıntısı riski yaratmıyor: owner zaten Yorumlar/Rezervasyonlar sayfalarından aynı veriye tek tek erişebiliyor, bu RPC'ler sadece birleştirip tek görünümde sunuyor.

## Test Stratejisi

- **DB:** Local `supabase db reset` + gerçek rol bazlı SQL testleri (owner görür, staff göremez, başka işletmenin owner'ı göremez) — sadakat'te kullanılan yöntemin aynısı.
- **Web:** Sadakat'teki `sadakat-islemleri.test.ts` deseninde smoke test (export + zod doğrulama, varsa server action).
- Gerçek tarayıcı doğrulaması: yeni test owner/müşteri fixture'ı ile local ortamda (mümkünse `curl` ile hesap oluşturup local Supabase Auth'un form-doldurma sırasındaki flakiness'ini bypass ederek — sadakat oturumunda öğrenilen ders).
