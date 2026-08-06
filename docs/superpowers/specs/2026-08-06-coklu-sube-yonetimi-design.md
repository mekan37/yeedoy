# Çoklu Şube Yönetimi (Owner) — Design

## Bağlam

Destek Sistemi'nden sonra kullanıcının önceliklendirdiği ikinci büyük özellik. Mevcut durum: `businesses.chain_id`/`branch_label` kolonları ve `chains` tablosu var, ama **sadece admin panelinden** (`app/yonetici/zincirler/`) zincir oluşturulup işletme gruplanabiliyor. Owner kendi işletmelerini bir zincir altında gruplayamıyor.

Araştırma bulguları:
- `chain_memberships` tablosu (user_id/chain_id/role) **hiç kullanılmıyor** — web app kodunda hiçbir referansı yok, sadece generated type dosyalarında var. Gerçek "hangi işletme hangi zincirde" mekanizması `businesses.chain_id` (FK).
- `chains` tablosu base_schema'daki basit halinden `20260709000001_chain_menu_system.sql` ile genişletilmiş: `category`, `logo_url`, `is_verified`, `template_business_id` kolonları eklenmiş (chain-menu-template özelliği için — bu spec'in kapsamı dışında, dokunulmuyor).
- Yeni işletme oluşturma (`owner_submit_new_business_v1`) zaten bir başvuru/onay akışı — bu spec bunu **değiştirmiyor**, yeniden kullanıyor.
- `analytics_events` (qr_scanned/menu_link_opened/vb., business_id bazlı) ve `reservations` (business_id bazlı) tabloları gerçek, aggregate edilebilir veri sağlıyor — mockup'taki istatistik kartları sahte olmayacak.
- Çalışma saatleri (`saveHours`, `app/sahip/ayarlar/saatler/saat-islemleri.ts`) ve kampanya oluşturma (`kampanya-islemleri.ts`) **tek işletme bazlı** — toplu işlemler bunları yeniden yazmak yerine döngüyle çağıracak.
- CSV export için admin tarafında emsal var: `app/sunucu/yonetici/raporlar-csv/route.ts`.
- Harita bileşeni için emsal: `src/ui/acik/harita-istemcisi.tsx` (maplibre-gl tabanlı, public keşif haritasında kullanılıyor).

Kullanıcı bir referans mockup paylaştı ("Çoklu Şube Yönetimi" sayfası — istatistik kartları, sekmeli tablo, şehir dağılımı, mini harita, hızlı işlemler paneli). Görüntülenen tüm bölümler için gerçek veri/altyapı doğrulandı, hiçbir sahte/boş bileşen yok.

## Kapsam

**Dahil (V1, bu spec):**
- Owner kendi onaylı işletmelerini (`owner_claims.status='approved'`) bir zincir altında gruplayabilir — yeni işletme oluşturma yok, salt metadata işlemi
- `/sahip/coklu-sube` sayfası: istatistik kartları, sekmeli/aranabilir şube tablosu, sürükle-bırak sıralama, "Ana Şube" rozeti
- Sağ sidebar: şehre göre dağılım, hafif mini harita, Hızlı İşlemler paneli
- Toplu işlemler: Çalışma Saatlerini Yönet, Kampanya Atama (ikisi de mevcut tek-işletme action'larını döngüyle çağırır), Raporu Dışa Aktar (CSV)
- "Yeni Şube Ekle": mevcut onaylı ama zincire bağlı olmayan işletmeleri listele + ekle; uygun işletme yoksa mevcut başvuru akışına yönlendir

**Kapsam dışı (V2 — ayrı bir tasarım turu gerektirir, aşağıda "Gelecek" bölümünde belgelendi):**
- Owner'ın başka bir owner'ın zaten oluşturduğu bir zincire katılması (franchise senaryosu) — paylaşımlı yetkilendirme modeli gerektiriyor
- Chain-menu-template özelliği (`chains.template_business_id`) ile entegrasyon — mevcut, dokunulmuyor
- Toplu Bilgi Güncelle (mockup'ta vardı ama hangi alanların "toplu güncellenebilir" olacağı net değil — V1'de çıkarıldı, tekil şube düzenleme zaten mevcut sayfalardan yapılabiliyor)

## Mimari

### Veri modeli değişikliği

```sql
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS chain_sort_order integer;
```

Nullable — sadece zincire bağlı işletmeler için anlamlı. Sürükle-bırak sıralama bunu günceller.

### RPC'ler (yeni migration)

Hepsi `owner_claims.status='approved'` üzerinden sahiplik kontrolü yapan SECURITY DEFINER fonksiyonlar, `is_owner_of_business` deseniyle tutarlı:

- `owner_create_chain_v1(p_business_id uuid, p_chain_name text) RETURNS uuid` — yeni zincir oluşturur, verilen işletmeyi "Ana Şube" (chain'e eklenen ilk işletme, `chain_sort_order=0`) yapar. `p_business_id` owner'a ait olmalı ve şu an başka bir zincirde olmamalı.
- `owner_add_business_to_chain_v1(p_chain_id uuid, p_business_id uuid, p_branch_label text) RETURNS void` — owner'a ait, zincirsiz bir işletmeyi mevcut bir zincire ekler. Hem `p_chain_id`'nin owner'ın kendi oluşturduğu bir zincir olduğu (chain'deki en az bir işletme owner'a ait olmalı) hem `p_business_id`'nin owner'a ait olduğu kontrol edilir.
- `owner_remove_business_from_chain_v1(p_business_id uuid) RETURNS void` — işletmeyi zincirden çıkarır (`chain_id`/`branch_label`/`chain_sort_order` NULL'a çekilir). Zincirdeki son işletmeyse `chains` satırı da silinir (boş zincir kalmasın).
- `owner_reorder_chain_branch_v1(p_business_id uuid, p_new_sort_order integer) RETURNS void` — sürükle-bırak sıralama güncellemesi (Task 2'deki `reorderItem` deseniyle aynı).
- `owner_get_chain_overview_v1(p_business_id uuid) RETURNS jsonb` — owner'ın işletmesinin bağlı olduğu zincirin tüm şubelerini + aggregate istatistikleri (toplam görüntülenme, toplam rezervasyon, şehir dağılımı) tek çağrıda döner. `p_business_id` owner'a ait olmalı; işletme hiçbir zincirde değilse `null` chain bilgisiyle boş sonuç döner (sayfa "henüz zincirin yok" boş durumunu gösterir).

### Server Actions (`app/sahip/coklu-sube/coklu-sube-islemleri.ts`)

- `subeYonetimVerisiGetir(businessId: string)` — `owner_get_chain_overview_v1` çağırır, sayfa için tüm veriyi döner.
- `zincirOlustur(businessId: string, chainName: string)` — `owner_create_chain_v1`.
- `subeEkle(chainId: string, businessId: string, branchLabel: string)` — `owner_add_business_to_chain_v1`.
- `subeCikar(businessId: string)` — `owner_remove_business_from_chain_v1` (onay dialoğu UI'da).
- `subeSirasiGuncelle(businessId: string, newSortOrder: number)` — `owner_reorder_chain_branch_v1`.
- `eklenebilirIsletmeleriListele(chainId: string | null)` — owner'ın `owner_claims`'inden, `chain_id IS NULL` olan işletmelerini döner ("Yeni Şube Ekle" modalının seçim listesi).

### Toplu işlemler — mevcut action'ları döngüyle çağırma

`saatleriTopluUygula(businessIds: string[], hours: HoursInput)`: seçilen her `businessId` için mevcut `saveHours(businessId, formData)`'ı sırayla çağırır (paralel değil — sıralı, ilk hata olduğunda kalan işletmeler için de denenir, sonunda "X/Y başarılı" özeti döner; tek bir işletmedeki hata diğerlerini engellemez).

`kampanyaTopluOlustur(businessIds: string[], campaignInput)`: aynı desen, mevcut kampanya oluşturma action'ını her işletme için çağırır.

Bu iki fonksiyon **yeni bir RPC yazmaz** — sadece istemci/server-action seviyesinde var olan tek-işletme fonksiyonlarını sarmalar.

### CSV Export

`app/sunucu/sahip/coklu-sube-rapor-csv/route.ts` — admin'in `raporlar-csv/route.ts` deseniyle aynı (auth+ownership kontrolü, CSV header/satır oluşturma, `Content-Disposition: attachment`). Şube adı, şehir, durum, görüntülenme, rezervasyon kolonları.

## UI Bileşenleri

### Sayfa — `/sahip/coklu-sube`

Sol menüde yeni "Çoklu Şube Yönetimi" nav öğesi (owner'ın zinciri yoksa da sayfa erişilebilir, boş durum + "Zincir Oluştur" CTA gösterir).

**Üst — istatistik kartları:** Toplam Şube, Toplam Görüntülenme (`analytics_events` SUM, tüm zincir işletmeleri), Toplam Rezervasyon (`reservations` COUNT), şehir sayısı.

**Ana sütun:** Sekmeler (Tümü/Aktif/Pasif — `businesses.is_active`), arama (şube adı/şehir), tablo (görsel, şube adı + "Ana Şube" rozeti, şehir, durum, görüntülenme, rezervasyon, işlemler — düzenle/çıkar). `chain_sort_order`'a göre varsayılan sıralama, sürükle-bırak ile değiştirilebilir (menü editöründeki native HTML5 `draggable` deseni).

**Sağ sidebar:**
- Şehre göre dağılım: basit sayı listesi (dataviz skill'e göre renklendirilmiş, mockup'taki donut yerine — token bazlı, erişilebilir bir liste/basit halka grafik; dataviz skill'in verdiği yöne göre implementasyon sırasında netleşecek).
- Mini harita: **Araştırma sırasında bulundu** — `/kesif/harita` sayfası business_id filtresi desteklemiyor, ve maplibre-gl bu projede daha önce ciddi bir Turbopack worker bug'ına neden olmuştu (bkz. proje belleği, PMTiles fix). Gerçek interaktif harita yerine, şehre göre dağılım listesiyle birleşik **statik bir şehir/pin-ikonu listesi** (yeni kütüphane bağımlılığı yok). "Haritada Görüntüle" linki genel `/kesif/harita` sayfasına gider (filtresiz — mevcut sayfa değiştirilmiyor).
- Hızlı İşlemler: Şube Sıralamasını Düzenle (tabloyu sürükle-bırak moduna alır), Çalışma Saatlerini Yönet, Kampanya Atama, Raporu Dışa Aktar — dördü de modal/ayrı panel açar.

**"+ Yeni Şube Ekle":** Modal — owner'ın zincire bağlı olmayan onaylı işletmeleri listelenir (varsa), seçilip branch_label girilir. Owner'ın eklenebilir işletmesi yoksa "Yeni İşletme Başvurusu Yap" linkiyle `/sahip/isletmeler/yeni`'ye yönlendirilir.

**Toplu işlem modalleri:** Şube çoklu-seçim (checkbox) + ilgili form (saat şablonu / kampanya formu) + "X/Y başarılı" sonuç özeti.

## Hata Yönetimi

Mevcut owner panel deseni: `{ error: string } | ...` dönüş tipi, kırmızı banner. Toplu işlemlerde kısmi başarı durumu (bazı şubeler başarılı, bazıları hata) açıkça gösterilir — tek bir hata tüm işlemi geri almaz.

## Test Planı

- `pnpm run typecheck` + `pnpm run lint`
- Saf yardımcı fonksiyonlar için vitest (şehir dağılımı hesaplama, tab filtreleme — Destek Sistemi'ndeki `destek-yardimcilari.ts` deseniyle aynı)
- RLS/RPC testleri: local Supabase'de iki farklı owner ile çapraz erişim (owner A'nın zincirine owner B işletme ekleyemez/çıkaramaz/göremez)
- `pnpm run test:ci`
- Dev server ile manuel doğrulama: zincir oluştur → şube ekle → sürükle-bırak sırala → toplu saat uygula → CSV indir

## Gelecek (V2 — bu spec'te tasarlanmıyor, sadece not düşülüyor)

**Var olan bir zincire katılma (franchise senaryosu):** Birden fazla owner'ın aynı zinciri paylaşması. Bunun için düşünülmesi gerekenler: zincire "davet" mekanizması (kim davet edebilir — zinciri oluşturan mı, admin mi), zincir-seviyesi yetkilendirme (chain_memberships tablosu belki burada gerçek bir amaç kazanır), davet edilen owner'ın kendi işletmesini zincire eklerken onay gerekip gerekmediği, ve zincirden çıkarma/çıkma yetkisinin kimde olacağı. Kullanıcı bunun önemli olduğunu belirtti — bu özellik V1 tamamlandıktan sonra ayrı bir brainstorming/spec turu olarak ele alınmalı.
