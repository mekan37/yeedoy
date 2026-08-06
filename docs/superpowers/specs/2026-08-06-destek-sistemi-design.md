# Destek Sistemi (Owner) — Design

## Bağlam

Kullanıcı, önceki bir kod denetiminde (3 Ağustos 2026 tarihli "Fiyatlandırma Özellikleri Kod Denetimi") owner panelinde bir destek/ticket sisteminin hiç olmadığını tespit etti. Bu, CRM/Sadakat/Çoklu Şube ile birlikte 4 büyük özellikten biri — kullanıcı öncelik sırasını "Destek → Çoklu Şube → Sadakat → CRM" olarak belirledi (küçükten büyüğe).

Araştırma sırasında beklenenden fazla altyapı bulundu: `support_tickets` ve `support_ticket_messages` tabloları `20260520000001_admin_api_keys_support_tickets.sql` ile zaten var ve admin panelinde (`app/yonetici/musteri-destek/`) tam işlevsel bir liste+detay+yanıt akışı çalışıyor. Eksik olan, owner'ın kendi talebini açabildiği/görebildiği taraf — hem RLS hem UI.

## Kapsam

Kullanıcı, tasarım için bir referans görsel paylaştı (kart tabanlı "yardım merkezi" + sekmeli talep listesi + sağ sidebar). Görsel incelenip hangi bölümlerin gerçek/işlevsel olacağı netleştirildi — bkz. UI bölümü.

**Dahil:**
- `support_tickets`'a `business_id` (nullable) eklenmesi
- Owner için RLS policy'leri (`support_tickets`, `support_ticket_messages`)
- Owner-facing server action'lar (yeni talep oluşturma, listeleme, mesaj gönderme)
- `/sahip/destek` sayfası: Popüler Konular (mevcut sayfalara hızlı link) + sekmeli talep listesi + detay/yanıt görünümü + "Yeni Talep" formu + sağ sidebar (statik SSS + e-posta bazlı Hızlı İletişim)
- Sol menüde bağımsız "Destek" nav öğesi
- Admin yanıt verdiğinde owner'a e-posta bildirimi (mevcut `eposta.ts` altyapısı ile)

**Kapsam dışı:**
- Admin tarafının (`app/yonetici/musteri-destek/`) değiştirilmesi — sadece reply route'una e-posta tetikleme eklenecek, başka dokunulmayacak
- Canlı chat / WebSocket ("Canlı Destek" butonu dahil) — asenkron ticket modeli yeterli
- Telefon/WhatsApp iletişim satırı — Yeedoy'a ait gerçek bir hat yok, uydurulmayacak
- "Yardım Kaynakları" (video eğitimler, kullanım kılavuzu, duyurular) — gerçek içerik yok
- SLA takibi, otomatik önceliklendirme, üçüncü parti helpdesk entegrasyonu

## Mimari

### Veri modeli değişikliği

```sql
ALTER TABLE public.support_tickets
  ADD COLUMN IF NOT EXISTS business_id uuid REFERENCES public.businesses(id) ON DELETE SET NULL;
```

Nullable — owner'ın birden fazla işletmesi olabilir ama bazı talepler (hesap/faturalama gibi) işletmeye özel olmayabilir. Tek işletmesi olan owner için formda bu alan gizlenir/otomatik doldurulur.

### RLS Policy'leri

Mevcut `support_tickets_admin_all` / `support_ticket_messages_admin_all` (`FOR ALL ... USING (is_admin())`) korunur, yanına eklenir:

```sql
CREATE POLICY support_tickets_owner_select ON public.support_tickets
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY support_tickets_owner_insert ON public.support_tickets
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY support_ticket_messages_owner_select ON public.support_ticket_messages
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

CREATE POLICY support_ticket_messages_owner_insert ON public.support_ticket_messages
  FOR INSERT TO authenticated WITH CHECK (
    sender = 'user'
    AND EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );
```

Owner talebi oluşturduktan sonra `status`/`priority`/`assigned_to` güncelleyemez (admin-only kalır — bu alanlar için ayrı bir UPDATE policy owner'a açılmaz).

### Server Actions (`app/sahip/destek/destek-islemleri.ts`)

- `destekTalebiOlustur(businessId: string | null, category: string, subject: string, message: string)` — `support_tickets` INSERT (`user_id = auth.uid()`, `requester_name`/`requester_email` profilden), ardından `support_ticket_messages` INSERT (`sender='user'`), tek mantıksal işlem.
- `destekTalebiListele()` — owner'ın kendi ticket'larını `status`/`created_at` ile döner.
- `destekMesajGonder(ticketId: string, message: string)` — mevcut ticket'a `sender='user'` mesaj ekler, `support_tickets.updated_at` günceller.

Admin'in `/sunucu/yonetici/musteri-destek` route'una dokunulmaz — bu action'lar `is_admin()` gerektirmez, sadece owner kimliğiyle çalışır.

### UI — `/sahip/destek`

Kullanıcının paylaştığı referans mockup'a göre (kart tabanlı yardım merkezi + sekmeli talep listesi + sağ sidebar) yeniden tasarlandı. Sol menüde bağımsız "Destek" sekmesi (yeni ikon).

**Sayfa üstü — Popüler Konular:** 5 kart, panelde zaten var olan sayfalara hızlı link (yeni içerik yok, sadece navigasyon):
| Kart | Link |
|---|---|
| İşletme Bilgileri | `/sahip/isletmeler` |
| Menü Yönetimi | `/sahip/menuler` |
| QR Menü & Kod | `/sahip/karekod` |
| İstatistikler | `/sahip/analitik` |
| Rezervasyonlar | `/sahip/rezervasyonlar` |

**Ana sütun — Destek Taleplerim:**
- Sekmeler: **Tümü / Açık / Beklemede / Çözüldü** — mevcut `support_tickets.status` enum'una (`open`, `in_progress`, `resolved`, `closed`) eşlenir: Açık=`open`, Beklemede=`in_progress`, Çözüldü=`resolved` VEYA `closed`. Yeni bir status değeri **eklenmiyor** — admin tarafıyla tam uyumlu kalması için.
- Tablo: Talep No (`id`'nin kısaltılmış/okunur hali, örn. ilk 8 karakter), Konu, Durum rozeti (admin `STATUS_MAP` ile aynı renk/etiket), Son Güncelleme, satıra tıklayınca detay.
- "+ Yeni Talep Oluştur" butonu.
- **Detay görünümü:** seçili ticket'ın mesaj geçmişi (admin `musteri-destek-istemci.tsx`'teki balon deseninin owner-tarafı aynası — `sender='user'` sağda, `sender='agent'` solda) + yanıt kutusu.
- **Yeni talep formu:** İşletme seç (dropdown, tek işletmesi varsa gizli/otomatik), Kategori (`Fatura/Ödeme`, `Teknik Sorun`, `Özellik Talebi`, `Hesap/Erişim`, `Diğer` — sabit liste), Konu, Mesaj.

**Sağ sidebar:**
- **Sıkça Sorulan Sorular:** statik, kodda sabit 5-6 soru-cevap. Mevcut `app/(genel)/destek/page.tsx`'teki "İşletme Sahipleri" bölümünün 2 gerçek maddesi (`İşletmemi Yeedoy'a nasıl ekletirim?`, `Menü ve fiyatlarımı nasıl yönetirim?`) yeniden kullanılır + owner panele özgü 3-4 yeni madde eklenir (örn. "Destek talebimin durumunu nereden takip ederim?"). Yeni bir CMS/tablo gerekmez, sabit bir dizi olarak koda yazılır.
- **Hızlı İletişim:** sadece e-posta — `mailto:destek@yeedoy.com` + çalışma saatleri ("Pazartesi–Cuma 09:00–18:00", `/destek` sayfasındaki gerçek metinle aynı). **Telefon/WhatsApp satırı eklenmez** — kod tabanında Yeedoy'a ait gerçek bir destek hattı bulunamadı, kullanıcı onayıyla sadece e-posta ile sınırlı tutuldu.

**Kapsam dışı bırakılan mockup öğeleri:** "Canlı Destek" (Sohbete Başla) butonu ve "Yardım Kaynakları" (video eğitimler, kullanım kılavuzu, duyurular) — gerçek içerik/altyapı olmadığı için eklenmiyor, boş/placeholder bırakılmıyor.

### E-posta bildirimi

Admin'in mevcut reply route'unun (`sender='agent'` INSERT sonrası) sonuna, `src/lib/eposta.ts`'teki mevcut gönderim fonksiyonu ile owner'ın hesap e-postasına "Destek talebinize yanıt geldi" bildirimi eklenir (ticket linkiyle `/sahip/destek?ticket=<id>`). Yeni altyapı gerekmez, best-effort (e-posta gönderimi hata verirse reply akışını engellemez — mevcut `claim_pending_team_invites_v1` best-effort deseniyle tutarlı).

## Hata Yönetimi

Mevcut owner panel action'larındaki desen (`{ error: string } | null` dönüş tipi, kırmızı banner gösterimi) izlenir — bkz. `menu-islemleri.ts` konvansiyonu.

## Test Planı

- `pnpm run typecheck` + `pnpm run lint`
- RLS policy'leri için: local Supabase'de iki farklı owner hesabıyla çapraz erişim testi (owner A, owner B'nin ticket'ını göremiyor/mesaj ekleyemiyor)
- `pnpm run test:unit` (varsa yeni saf yardımcı fonksiyonlar için)
- Dev server ile manuel doğrulama: talep oluşturma → admin panelinde görünüyor mu → admin yanıtlıyor → owner panelinde ve e-postada görünüyor mu

## Kapsam Dışı (net karar)

- Canlı chat/WebSocket ("Canlı Destek" butonu)
- Telefon/WhatsApp iletişim satırı (gerçek hat yok)
- "Yardım Kaynakları" (video eğitimler, kullanım kılavuzu, duyurular — gerçek içerik yok)
- SLA/otomatik önceliklendirme
- Üçüncü parti helpdesk entegrasyonu
- Admin panelinin (`app/yonetici/musteri-destek/`) yeniden tasarımı
