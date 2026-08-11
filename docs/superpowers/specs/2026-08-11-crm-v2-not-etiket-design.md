# CRM v2 — Müşteri Notu ve Etiketleme — Design Doc

## Bağlam

CRM v1 (birleşik müşteri profili — liste + zaman çizelgesi) tamamlandı (`docs/superpowers/specs/2026-08-11-crm-musteri-profili-design.md`). Kullanıcı, CRM'i v2'ye taşımak istiyor; v1'in "Kapsam Dışı" bölümünde bırakılan dört bağımsız alt-özellik var: not/etiket ekleme, arama/filtre, zincir-çapında birleşik görünüm, toplu e-posta/kampanya. Bunlar birbirinden bağımsız alt-projeler olarak ele alınıyor; bu doküman ilk alt-projeyi (**not/etiket ekleme**) kapsıyor.

## Hedefler

- Owner, bir müşteriye zaman damgalı notlar ekleyebilsin (örn. "10 Ağustos: masa istedi", "15 Ağustos: şikayet etti") — çoklu, log tarzı.
- Owner, bir müşteriye serbest metin etiketler ekleyebilsin (örn. "VIP", "Şikayetçi") — bir müşteri birden fazla etiket alabilir.
- Etiketler müşteri listesi sayfasında (tabloda) rozet olarak görünsün, owner detay sayfasına girmeden hangi müşterinin hangi etiketi taşıdığını görsün.
- Eklenen notlar, müşteri detay sayfasındaki mevcut zaman çizelgesine otomatik akan bir olay tipi olarak görünsün (ayrı bir sekmede kaybolmasın).

## Kapsam Dışı (v2.1, YAGNI)

- Not düzenleme/silme — v2'de sadece ekleme var. Owner hatalı not eklerse, ayrı bir düzeltici not ekler.
- Etiket düzenleme — sadece ekleme ve silme var, mevcut bir etiketin metnini değiştirme yok.
- Önceden tanımlı/sabit etiket listesi — owner serbest metin yazıyor, kapalı bir kategori seti yok.
- Zincir-çapında not/etiket paylaşımı — CRM v1 ile tutarlı, business bazlı kalır (zincir-çapında birleşik görünüm ayrı bir alt-proje, henüz yapılmadı).
- Notların/etiketlerin kim tarafından eklendiğinin UI'da gösterilmesi — `created_by` veritabanında tutulur (denetim izi) ama v2 UI'ında personel adı gösterilmiyor, sadece owner'a görünüyor.

## Veri Modeli

```
customer_notes
  id            uuid pk
  business_id   uuid fk -> businesses(id)
  user_id       uuid fk -> auth.users(id)   -- hangi müşteri
  note          text
  created_by    uuid fk -> auth.users(id)   -- hangi personel/owner yazdı
  created_at    timestamptz default now()

customer_tags
  id            uuid pk
  business_id   uuid fk -> businesses(id)
  user_id       uuid fk -> auth.users(id)
  tag           text                         -- serbest metin, örn. "VIP"
  created_by    uuid fk -> auth.users(id)
  created_at    timestamptz default now()
  unique(business_id, user_id, tag)           -- aynı etiket iki kez eklenemez
```

**RLS:** Her iki tabloda da client rollerine (`authenticated`) hiçbir INSERT/UPDATE/DELETE GRANT'ı yok — tüm yazımlar SECURITY DEFINER RPC'ler üzerinden. Public read yok (owner'ın kendi müşteri verisi, RPC üzerinden okunur).

## RPC Yüzeyi

**Owner (`has_business_permission_v1(p_business_id, 'menu_write')` — editor+ ile korunur, CRM v1'deki desenin aynısı):**

- `add_customer_note_v1(p_business_id, p_user_id, p_note)` — yeni bir not ekler, `created_by = auth.uid()`
- `add_customer_tag_v1(p_business_id, p_user_id, p_tag)` — yeni bir etiket ekler (aynısı zaten varsa `unique` constraint hatası, UI'da nazikçe ele alınır)
- `remove_customer_tag_v1(p_tag_id)` — bir etiketi siler

**Mevcut RPC'lerin genişletilmesi:**

- `get_business_customers_v1` — dönüşe `tags: string[]` alanı eklenir (her müşteri için mevcut etiket listesi)
- `get_customer_timeline_v1` — dönüşe yeni bir `event_type: 'note'` eklenir (`summary` = not metni), mevcut `UNION ALL` zincirine bir blok daha eklenir

Personel (staff, rank 200) bu RPC'leri çağıramaz — CRM v1'deki gerekçenin aynısı (müşteri verisi hassas).

## Akışlar

1. Owner müşteri detay sayfasında (`/sahip/musteriler/[user_id]`) sol paneldeki "Etiketler" bölümünden bir etiket yazıp ekler → `add_customer_tag_v1` → sayfa yenilenir, rozet görünür.
2. Owner aynı panelde "Not ekle" textarea'sına yazıp kaydeder → `add_customer_note_v1` → sayfa yenilenir, not sağdaki zaman çizelgesinde en yeni olay olarak görünür.
3. Owner bir etiketi kaldırmak isterse rozetin üzerindeki (x) ikonuna tıklar → `remove_customer_tag_v1`.
4. Owner müşteri listesi sayfasına (`/sahip/musteriler`) girdiğinde, her müşterinin etiketleri "Etiketler" sütununda rozet olarak görünür.

## UI

- **Liste sayfası** (`/sahip/musteriler`): tabloya "Etiketler" sütunu eklenir, küçük rozetler halinde (örn. `VIP` `Sadık Müşteri`). Etiketi olmayan müşteride sütun boş.
- **Detay sayfası** (`/sahip/musteriler/[user_id]`): sol paneldeki "Müşteri Bilgileri" kartına iki bölüm eklenir — "Etiketler" (mevcut rozetler + ekleme input'u/butonu) ve "Not ekle" (textarea + "Kaydet" butonu). Eklenen notlar ayrı bir liste olarak gösterilmez, sağdaki mevcut zaman çizelgesine `📝 Not` olay tipi olarak akar.

Mockup gerekmedi — mevcut CRM v1 sayfalarına küçük ekler, yeni bir layout yok.

## Güvenlik

- Her üç RPC de `SECURITY DEFINER`, CRM v1'deki kritik dersle aynı üçlü REVOKE deseni: `REVOKE ALL ... FROM PUBLIC` + `REVOKE EXECUTE ... FROM anon` + `GRANT EXECUTE ... TO authenticated`, ardından `has_function_privilege()` ile production'da doğrudan doğrulanacak.
- Yetkilendirme `has_business_permission_v1(p_business_id, 'menu_write')` (editor+) — staff erişemez.
- `customer_notes`/`customer_tags` tablolarında client'a doğrudan yazma GRANT'ı yok, sadece RPC üzerinden.
- `created_by` alanı `auth.uid()` ile otomatik doldurulur — client bunu manipüle edemez.

## Test Stratejisi

- **DB:** Local `supabase db reset` + rol bazlı SQL testleri (owner ekleyebilir, staff ekleyemez, başka işletmenin owner'ı ekleyemez, aynı etiketi iki kez eklemeye çalışma unique constraint ile reddedilir).
- **Web:** CRM v1'deki smoke-test deseninde (export doğrulama, varsa server action zod doğrulaması).
- Gerçek tarayıcı doğrulaması: `curl` ile test hesabı oluşturup (form-doldurma flakiness'inden kaçınarak — CRM v1'de öğrenilen ders), local ortamda not/etiket ekleme akışını uçtan uca doğrulama.
