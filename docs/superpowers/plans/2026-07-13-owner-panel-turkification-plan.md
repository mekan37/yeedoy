# Owner Paneli Türkçeleştirme (Faz 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/owner` ve `/sahip` altında paralel, diverge etmiş owner panel ağaçlarını tek bir kanonik `/sahip` ağacına uzlaştırıp `/owner`'ı kaldırmak — hiçbir gerçek özellik kaybı olmadan.

**Architecture:** Next.js 15 App Router, iki route ağacı (`app/owner/(panel)/**` ve `app/sahip/**`) + iki paralel API katmanı (`app/api/owner/**` ve `app/sunucu/sahip/**`). Bazı sayfalar 1:1 taşınacak (owner kazanıyor veya sahip zaten kazanıyor), bazıları gerçek iki-yönlü özellik birleştirmesi gerektiriyor (her iki tarafta da diğerinde olmayan gerçek, çalışan özellikler var).

**Tech Stack:** Next.js 15 (App Router), TypeScript, Supabase, Tailwind (semantic token sınıfları).

**Referans:** Tüm bulgular `docs/superpowers/specs/2026-07-13-owner-panel-turkification-design.md` dosyasında detaylı tablolar halinde belgelendi — her task'ta o spec'in ilgili bölümüne atıf var, gerekirse oradan tam bağlamı oku.

---

## Dosya Yapısı Özeti

**Silinecek (tamamen):**
- `app/owner/**` (tüm route ağacı — layout, tüm sayfalar, tüm client/actions dosyaları)
- `app/sahip/crm/`, `app/sahip/sponsorluk/`, `app/sahip/finansal/`, `app/sahip/envanter/`, `app/sahip/siparisler/` (ölü stub'lar)
- `src/ui/shell/owner-shell-client.tsx` (kullanılmayan)
- Karşılık gelen ölü `app/sunucu/sahip/*` API stub'ları (envanter, siparis-listesi, finansal-csv vb. — sadece silinen sayfaların backend'i)

**Oluşturulacak (yeni):**
- `app/sahip/rezervasyonlar/**`
- `app/sahip/fotograflar/**`
- `app/sahip/bildirimler/**`
- `app/sahip/karekod/[businessId]/**`

**İçeriği birleştirilecek/güncellenecek (mevcut dosya, içerik değişir):**
- `app/sahip/isletmeler/[id]/**` (meal-card-editor, branding-editor eklenir)
- `app/sahip/yapay-zeka-analizi/**` (owner içeriğiyle değiştirilir)
- `app/sahip/analitik/**` (feature-union)
- `app/sahip/menu/ceviriler/**` (feature-union)
- `app/sahip/gosterge-panosu/page.tsx` (feature-union)
- `app/sahip/yorumlar/**` (feature-union)
- `app/sahip/ayarlar/**` (owner'ın tabs mimarisi taşınır)
- `app/sahip/menuler/[menuId]/duzenle/**` (feature-union)
- `app/sahip/pazarlama/**` (feature-union)
- `app/giris/page.tsx` (görsel tasarım owner/login'e göre güncellenir)
- `app/sahip/page.tsx` (owner landing page içeriği taşınır)
- `src/ui/kabuk/sahip-kabuk-istemcisi.tsx` (nav genişletilir)
- `middleware.ts` (guard sadeleşir, OWNER_LOGIN_PATH/OWNER_PUBLIC_PATHS güncellenir)
- `next.config.mjs` (redirects eklenir)
- `app/forbidden/page.tsx`, `app/login/page.tsx` (referanslar güncellenir)

---

### Task 1: Düz taşımalar — rezervasyonlar, fotograflar, bildirimler

**Files:**
- Move: `app/owner/(panel)/reservations/actions.ts` → `app/sahip/rezervasyonlar/rezervasyon-islemleri.ts`
- Move: `app/owner/(panel)/reservations/page.tsx` → `app/sahip/rezervasyonlar/page.tsx`
- Move: `app/owner/(panel)/reservations/reservations-client.tsx` → `app/sahip/rezervasyonlar/rezervasyonlar-istemcisi.tsx`
- Move: `app/owner/(panel)/photos/page.tsx` → `app/sahip/fotograflar/page.tsx`
- Move: `app/owner/(panel)/photos/photos-client.tsx` → `app/sahip/fotograflar/fotograflar-istemcisi.tsx`
- Move: `app/owner/(panel)/notifications/page.tsx` → `app/sahip/bildirimler/page.tsx`
- Move: `app/owner/(panel)/notifications/notifications-client.tsx` → `app/sahip/bildirimler/bildirimler-istemcisi.tsx`

- [ ] **Step 1: Dosyaları taşı**

```bash
cd /c/yeedoy/uygulamalar/web
mkdir -p "app/sahip/rezervasyonlar" "app/sahip/fotograflar" "app/sahip/bildirimler"
git mv "app/owner/(panel)/reservations/actions.ts" "app/sahip/rezervasyonlar/rezervasyon-islemleri.ts"
git mv "app/owner/(panel)/reservations/page.tsx" "app/sahip/rezervasyonlar/page.tsx"
git mv "app/owner/(panel)/reservations/reservations-client.tsx" "app/sahip/rezervasyonlar/rezervasyonlar-istemcisi.tsx"
git mv "app/owner/(panel)/photos/page.tsx" "app/sahip/fotograflar/page.tsx"
git mv "app/owner/(panel)/photos/photos-client.tsx" "app/sahip/fotograflar/fotograflar-istemcisi.tsx"
git mv "app/owner/(panel)/notifications/page.tsx" "app/sahip/bildirimler/page.tsx"
git mv "app/owner/(panel)/notifications/notifications-client.tsx" "app/sahip/bildirimler/bildirimler-istemcisi.tsx"
```

- [ ] **Step 2: İç import ve dosya-adı referanslarını güncelle**

Taşınan her dosyada:
- `./actions` / `./reservations-client` gibi relatif import'ları yeni dosya adlarına güncelle (`./rezervasyon-islemleri`, `./rezervasyonlar-istemcisi` vb.)
- Dosya içindeki component/export isimlerini olduğu gibi bırak (sadece dosya adları değişiyor, bu adımda export isimlerini değiştirme — Task 6'da nav/route bağlantıları ayrıca doğrulanacak)
- `metadata.title` alanlarındaki "Owner Panel" ibaresini "Sahip Paneli" yap

- [ ] **Step 3: Taşınan sayfaların çağırdığı API endpoint'lerini kontrol et**

`grep -n "fetch(" app/sahip/rezervasyonlar/*.ts* app/sahip/fotograflar/*.ts* app/sahip/bildirimler/*.ts*` çalıştır. Eğer `/api/owner/...` çağrısı varsa, ilgili endpoint `app/sunucu/sahip/` altında yoksa Task 5'te oluşturulacak — bu adımda sadece hangi endpoint'lerin gerektiğini not al (aşağıdaki Task 5'e girdi).

- [ ] **Step 4: Typecheck çalıştır**

Run: `npm run typecheck`
Expected: Bu 3 yeni route için hata olmamalı (diğer henüz taşınmamış owner-only importlarla ilgili hatalar bu aşamada beklenir, sonraki task'larda çözülecek — sadece bu task'ın dosyalarıyla ilgili yeni hata olmadığını doğrula).

- [ ] **Step 5: Commit**

```bash
git add app/sahip/rezervasyonlar app/sahip/fotograflar app/sahip/bildirimler
git commit -m "feat(web): rezervasyon/fotoğraf/bildirim sayfaları sahip paneline taşındı"
```

---

### Task 2: ai-analysis içeriğini yapay-zeka-analizi üzerine taşı

**Files:**
- Read: `app/owner/(panel)/ai-analysis/page.tsx`
- Modify: `app/sahip/yapay-zeka-analizi/page.tsx`
- Modify: `app/sahip/yapay-zeka-analizi/yapay-zeka-analiz-islemi.ts`
- Modify: `app/sahip/yapay-zeka-analizi/yapay-zeka-analiz-karti.tsx`

**Bağlam:** Spec'in "Route eşleştirmesi" tablosuna göre owner'ın `ai-analysis` içeriği (2026-07-10) sahip'in `yapay-zeka-analizi` içeriğinden (2026-06-23) 17 gün daha güncel — owner kazanır.

- [ ] **Step 1: İki tarafı da tam oku**

`app/owner/(panel)/ai-analysis/page.tsx` dosyasının tamamını oku (muhtemelen tek dosya, owner tarafında ayrı client/actions dosyası yok — eğer varsa `app/owner/(panel)/ai-analysis/` altında başka dosya olup olmadığını `find "app/owner/(panel)/ai-analysis" -type f` ile kontrol et). Ardından `app/sahip/yapay-zeka-analizi/` altındaki 3 dosyanın tamamını oku.

- [ ] **Step 2: Owner içeriğini sahip dosya yapısına uyarlayarak yaz**

Owner'ın page.tsx mantığını, sahip'in mevcut 3-dosyalık yapısına (page.tsx / yapay-zeka-analiz-islemi.ts / yapay-zeka-analiz-karti.tsx) dağıtarak yeniden yaz — route/dosya isimleri Türkçe kalır, ama iş mantığı (hangi RPC çağrılıyor, hangi UI state'leri var) owner sürümünden gelir. Sahip sürümünde owner'da olmayan bir özellik varsa (örn. farklı bir loading/error state deseni) onu da koru.

- [ ] **Step 3: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/ai-analysis"
```

- [ ] **Step 4: Typecheck**

Run: `npm run typecheck`
Expected: `app/sahip/yapay-zeka-analizi/**` için hata yok.

- [ ] **Step 5: Commit**

```bash
git add -A app/sahip/yapay-zeka-analizi
git commit -m "feat(web): yapay zeka analizi sayfası owner'ın güncel sürümüyle değiştirildi"
```

---

### Task 3: meal-card-editor ve branding-editor'ı isletmeler/[id]'ye taşı

**Files:**
- Move: `app/owner/(panel)/businesses/[id]/meal-card-editor.tsx` → `app/sahip/isletmeler/[id]/yemek-karti-editoru.tsx`
- Move: `app/owner/(panel)/businesses/[id]/branding-editor.tsx` → `app/sahip/isletmeler/[id]/marka-editoru.tsx`
- Modify: `app/sahip/isletmeler/[id]/page.tsx`
- Read: `app/owner/(panel)/businesses/[id]/page.tsx`

**Bağlam:** Spec: sahip'in `isletmeler/[id]` sayfasında bu iki editör hiç yok.

- [ ] **Step 1: Taşınacak dosyaları oku**

`app/owner/(panel)/businesses/[id]/meal-card-editor.tsx`, `branding-editor.tsx`, ve owner'ın `page.tsx`'inde bu iki component'in nasıl import edilip render edildiğini oku. Ardından `app/sahip/isletmeler/[id]/page.tsx`'i oku.

- [ ] **Step 2: Dosyaları taşı**

```bash
cd /c/yeedoy/uygulamalar/web
git mv "app/owner/(panel)/businesses/[id]/meal-card-editor.tsx" "app/sahip/isletmeler/[id]/yemek-karti-editoru.tsx"
git mv "app/owner/(panel)/businesses/[id]/branding-editor.tsx" "app/sahip/isletmeler/[id]/marka-editoru.tsx"
```

- [ ] **Step 3: sahip/isletmeler/[id]/page.tsx'e entegre et**

Owner'ın page.tsx'inde bu iki component'in render edildiği yeri (hangi prop'larla, hangi koşulla gösterildiği) referans alarak, sahip'in `page.tsx`'ine aynı import + render bloklarını ekle. Prop olarak geçirilen veri (business id, mevcut menü verisi vb.) sahip'in page.tsx'inde zaten var olan aynı isimli değişkenlerden gelmeli — yoksa owner'ın `businesses/[id]/actions.ts`'inden ilgili veri-çekme fonksiyonunu `app/sahip/isletmeler/[id]/isletme-islemleri.ts`'e ekle.

- [ ] **Step 4: Typecheck**

Run: `npm run typecheck`
Expected: Hata yok.

- [ ] **Step 5: Commit**

```bash
git add app/sahip/isletmeler
git commit -m "feat(web): yemek kartı ve marka editörü işletme detay sayfasına eklendi"
```

---

### Task 4: API route katmanını taşı (app/api/owner → app/sunucu/sahip)

**Files:**
- Read: `app/api/owner/ai-analyze/route.ts`, `app/api/owner/business-branding/**`, `app/api/owner/photos/route.ts`, `app/api/owner/review-reply/route.ts`
- Read: `app/sunucu/sahip/**` (mevcut endpoint'lerin tam listesi)
- Create/Modify: eksik olan endpoint'ler için `app/sunucu/sahip/` altında yeni route.ts dosyaları

**Bağlam:** Spec'in "API route katmanı" bölümü. Task 1-3'te taşınan sayfaların çağırdığı `/api/owner/*` endpoint'lerinin `/sunucu/sahip/*` karşılığı yoksa burada oluşturulmalı.

- [ ] **Step 1: Eksik endpoint'leri belirle**

`find app/sunucu/sahip -type f` ile mevcut listeyi çıkar. `app/api/owner/`'daki her endpoint için (`ai-analyze`, `business-branding`, `photos`, `review-reply` — Task 1-3'te taşınan sayfaların ihtiyaç duyduğu) karşılığının olup olmadığını kontrol et.

- [ ] **Step 2: Eksik olan her endpoint için route.ts oluştur**

Her eksik endpoint için: `app/api/owner/<isim>/route.ts`'i tam oku, aynı mantığı (auth kontrolü, zod validation, Supabase RPC çağrısı, rate limit) `app/sunucu/sahip/<turkce-isim>/route.ts` altında yeniden oluştur. CLAUDE.md kuralına göre her mutation route'u `zod.safeParse` + auth check + rate limit içermeli — bu üçü owner sürümünde zaten varsa aynen taşınır.

- [ ] **Step 3: Task 1-3'te taşınan sayfalardaki fetch çağrılarını güncelle**

`app/sahip/rezervasyonlar/**`, `app/sahip/fotograflar/**`, `app/sahip/bildirimler/**`, `app/sahip/isletmeler/[id]/**`, `app/sahip/yapay-zeka-analizi/**` içindeki `fetch('/api/owner/...')` çağrılarını yeni `/sunucu/sahip/...` path'lerine güncelle.

- [ ] **Step 4: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 5: Commit**

```bash
git add app/sunucu/sahip app/sahip
git commit -m "feat(web): eksik owner API endpoint'leri sunucu/sahip altına taşındı"
```

---

### Task 5: qr ↔ karekod birleştirmesi

**Files:**
- Read: `app/owner/(panel)/qr/actions.ts`, `app/owner/(panel)/qr/page.tsx`, `app/owner/(panel)/qr/qr-client.tsx`
- Read: `app/sahip/karekod/page.tsx`
- Create: `app/sahip/karekod/[businessId]/page.tsx`, `app/sahip/karekod/[businessId]/karekod-istemcisi.tsx`, `app/sahip/karekod/[businessId]/karekod-islemleri.ts`
- Modify: `app/sahip/karekod/page.tsx` (hub sayfasındaki "QR Studio" linkinin artık gerçek bir hedefe gittiğini doğrula)

**Bağlam:** Spec: sahip'in hub sayfası `/karekod/[id]`'ye link veriyor ama o route hiç yok — kırık link. Owner'ın çalışan tek-işletme mantığı oraya taşınmalı.

- [ ] **Step 1: Üç dosyayı da tam oku**

`app/owner/(panel)/qr/actions.ts`, `page.tsx`, `qr-client.tsx` — özellikle `owner_list_qr_codes_v1` RPC çağrısının nerede yapıldığına dikkat et. Ardından `app/sahip/karekod/page.tsx`'i oku, `/karekod/${businessId}` linkinin tam formatını (query param var mı, sadece path mi) not al.

- [ ] **Step 2: Yeni dinamik route'u oluştur**

```bash
cd /c/yeedoy/uygulamalar/web
mkdir -p "app/sahip/karekod/[businessId]"
git mv "app/owner/(panel)/qr/actions.ts" "app/sahip/karekod/[businessId]/karekod-islemleri.ts"
git mv "app/owner/(panel)/qr/page.tsx" "app/sahip/karekod/[businessId]/page.tsx"
git mv "app/owner/(panel)/qr/qr-client.tsx" "app/sahip/karekod/[businessId]/karekod-istemcisi.tsx"
```

- [ ] **Step 3: page.tsx'i dinamik route parametresine uyarla**

Taşınan `page.tsx` önceden owner'ın `owner_claims` sorgusundan tek işletme ID'si çıkarıyordu (limit 1). Yeni sürümde işletme ID'si `params.businessId`'den gelmeli — Next.js 15 App Router'da `params` bir Promise, `async function Page({ params }: { params: Promise<{ businessId: string }> })` imzasıyla `const { businessId } = await params;` şeklinde okunmalı. `owner_claims` sorgusu, seçilen `businessId`'nin gerçekten bu kullanıcıya ait olduğunu doğrulayan bir yetki kontrolüne dönüştürülmeli (RPC çağrısına `businessId` parametre olarak geçirilir).

- [ ] **Step 4: Hub sayfasındaki linki doğrula**

`app/sahip/karekod/page.tsx`'teki "QR Studio" butonunun `href`'inin `/karekod/${businessId}` formatıyla birebir eşleştiğini kontrol et (path segment adı `[businessId]` ile aynı olmalı).

- [ ] **Step 5: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 6: Tarayıcıda manuel doğrulama**

`npm run dev` başlat, `/sahip/karekod`'a git, bir işletme için "QR Studio" butonuna tıkla, `/sahip/karekod/<gerçek-id>` sayfasının QR kod listesini gösterdiğini doğrula.

- [ ] **Step 7: Commit**

```bash
git add -A app/sahip/karekod
git commit -m "fix(web): karekod hub sayfasındaki kırık link, owner'ın çalışan QR yöneticisiyle onarıldı"
```

---

### Task 6: analytics ↔ analitik feature-union

**Files:**
- Read: `app/owner/(panel)/analytics/page.tsx`, `app/owner/(panel)/analytics/analytics-client.tsx`
- Modify: `app/sahip/analitik/page.tsx`
- Create: `app/sahip/analitik/analitik-istemcisi.tsx` (eğer owner'daki client mantığı ayrı dosyaya çıkarılacaksa)

**Bağlam:** Spec tablosu — owner: trafik kaynağı kırılımı, haftanın günü heatmap'i, önceki döneme göre % değişim. Sahip: Yoğun Saatler widget'ı (`getYogunSaatler` RPC), whatsapp_click/qr_scan tracking, saatlik dağılım grafiği. **Hiçbiri atılmayacak.**

- [ ] **Step 1: İki tarafı da tam oku**

`app/owner/(panel)/analytics/page.tsx` + `analytics-client.tsx` tamamını oku. `app/sahip/analitik/page.tsx` tamamını oku (tek dosya).

- [ ] **Step 2: Sahip'in mevcut özelliklerini bir kenara not al**

`getYogunSaatler` RPC çağrısının tam imzasını, `YogunSaatlerKarti` component'inin nasıl render edildiğini, `whatsapp_click`/`qr_scan` event tracking'inin nerede tetiklendiğini kod içinden çıkar (bunlar birleştirme sırasında silinmeyecek).

- [ ] **Step 3: Birleştirilmiş sayfayı yaz**

`app/sahip/analitik/page.tsx`'i, owner'ın trafik kaynağı kırılımı + haftanın günü heatmap'i + önceki döneme göre % değişim mantığını ekleyerek, ama sahip'in Yoğun Saatler/whatsapp/qr_scan/saatlik dağılım mantığını koruyarak yeniden yaz. Eğer owner'ın client component'i (grafik render mantığı) yeterince büyükse ayrı bir `analitik-istemcisi.tsx` dosyasına çıkar, page.tsx sadece veri çekip client'a prop geçirsin (sahip'in mevcut deseniyle tutarlı — tek dosyaydı, artık gerekiyorsa ikiye bölünebilir, CLAUDE.md "dosya büyürse böl" kuralına uygun).

- [ ] **Step 4: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/analytics"
```

- [ ] **Step 5: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 6: Commit**

```bash
git add -A app/sahip/analitik
git commit -m "feat(web): analitik sayfası owner ve sahip özellik setleri birleştirilerek güncellendi"
```

---

### Task 7: menu/translations ↔ menu/ceviriler feature-union

**Files:**
- Read: `app/owner/(panel)/menu/translations/page.tsx`, `ceviri-editor.tsx`, `ceviri-islemleri.ts`, `ceviri-sabitleri.ts`
- Modify: `app/sahip/menu/ceviriler/page.tsx`, `otomatik-ceviri-istemci.tsx`

**Bağlam:** Owner: manuel çeviri editörü (dil bazlı tamamlanma yüzdesi). Sahip: otomatik çeviri tetikleyici (DeepL/OpenAI) + salt-okunur tablo. **İkisi de korunacak, aynı sayfada.**

- [ ] **Step 1: Dört owner dosyasını da tam oku**

`page.tsx`, `ceviri-editor.tsx`, `ceviri-islemleri.ts`, `ceviri-sabitleri.ts`. Ardından sahip'in `page.tsx` + `otomatik-ceviri-istemci.tsx`'ini tam oku.

- [ ] **Step 2: Birleştirilmiş sayfayı tasarla**

Sahip'in sayfası üstte otomatik çeviri tetikleme paneli + mevcut çeviriler tablosunu korur; owner'ın manuel `CeviriEditor`'ı bu sayfaya ikinci bir bölüm/sekme olarak eklenir (örn. "Otomatik" / "Manuel Düzenle" iki sekme, veya otomatik panelin altında "Manuel düzenlemek için" bir açılır bölüm — hangisi UI olarak daha az karmaşıksa onu tercih et, ama her iki işlevin de aynı sayfadan erişilebilir olması şart).

- [ ] **Step 3: Dosyaları taşı/oluştur**

```bash
cd /c/yeedoy/uygulamalar/web
git mv "app/owner/(panel)/menu/translations/ceviri-editor.tsx" "app/sahip/menu/ceviriler/ceviri-editor.tsx"
```

`ceviri-islemleri.ts` ve `ceviri-sabitleri.ts` içeriğini `app/sahip/menu/ceviriler/` altına aynı isimlerle taşı (isimler zaten Türkçe, çakışma yoksa doğrudan `git mv`, çakışıyorsa mevcut sahip dosyasıyla birleştir).

- [ ] **Step 4: page.tsx'i güncelle**

`app/sahip/menu/ceviriler/page.tsx`'e `CeviriEditor` import'unu ve render bloğunu ekle, owner'ın işletme seçici mantığını (birden fazla işletmesi olan sahip için) sahip'in zaten sahip olduğu işletme-seçici pattern'iyle uyumlu hale getir.

- [ ] **Step 5: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/menu/translations"
```

- [ ] **Step 6: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 7: Commit**

```bash
git add -A app/sahip/menu/ceviriler
git commit -m "feat(web): menü çevirileri sayfasına manuel çeviri editörü eklendi"
```

---

### Task 8: Dashboard feature-union

**Files:**
- Read: `app/owner/(panel)/dashboard/page.tsx`
- Modify: `app/sahip/gosterge-panosu/page.tsx`

**Bağlam:** Owner: tek işletmeye odaklı, görsel-ağırlıklı (cover/logo, son 3 yorum önizlemesi, Premium banner). Sahip: çok işletmeli KPI grid, QR-tarama sparkline, 7 günlük view chart, **pending-claim banner'ı**. **Sahip'in çoklu-işletme/pending-claim mantığı KORUNUR, owner'ın görsel zenginliği eklenir.**

- [ ] **Step 1: İki dosyayı da tam oku**

`app/owner/(panel)/dashboard/page.tsx` (92 satır) ve `app/sahip/gosterge-panosu/page.tsx` (180 satır) tamamını oku.

- [ ] **Step 2: Sahip'in korunacak mantığını doğrula**

Sahip'teki `hasPendingClaim` benzeri durumun (onay bekleyen sahiplenme talebi banner'ı) tam kod bloğunu, KPI grid sorgusunu, QR-tarama sparkline ve 7 günlük view chart mantığını not al — bunlar silinmeyecek.

- [ ] **Step 3: Owner'ın görsel bölümlerini ekle**

Owner'daki cover/logo görsel header'ı, yıldız puanı gösterimi, "Son Aktiviteler" (son 3 yorum önizlemesi + yanıtla linki), "Hızlı İşlemler" ikon grid'i ve Premium banner bileşenlerini, sahip'in mevcut çok-işletmeli yapısına uyacak şekilde ekle (tek işletmesi olan sahipler için owner'daki gibi görünür, birden fazla işletmesi olanlar için KPI grid üstte kalır, seçili/ilk işletme için görsel bölüm altta gösterilebilir — tasarım kararı: KPI grid + pending-claim banner en üstte sabit kalır, altına owner'ın görsel bölümü eklenir).

- [ ] **Step 4: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/dashboard"
```

- [ ] **Step 5: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 6: Commit**

```bash
git add -A app/sahip/gosterge-panosu
git commit -m "feat(web): gösterge panosuna owner'ın görsel bölümleri eklendi, çoklu-işletme mantığı korundu"
```

---

### Task 9: reviews ↔ yorumlar feature-union

**Files:**
- Read: `app/owner/(panel)/reviews/page.tsx`, `reviews-client.tsx`
- Modify: `app/sahip/yorumlar/page.tsx`, `yorum-satiri.tsx`

**Bağlam:** Owner: "Yeni" rozeti (localStorage last-seen), `helpful_count`, durum rozetleri (onaylı/bekleyen/reddedilen), `/api/owner/review-reply`. Sahip: hazır yanıt şablonları (4 canned reply), `displayName`/anonim gösterimi, "Gizli" rozeti, `/sunucu/sahip/yorumlar/yanit` (zaten çalışan route).

- [ ] **Step 1: İki tarafı da tam oku**

`app/owner/(panel)/reviews/page.tsx` + `reviews-client.tsx`, ve `app/sahip/yorumlar/page.tsx` + `yorum-satiri.tsx` tamamını oku.

- [ ] **Step 2: Kanonik API endpoint'i belirle**

`app/sunucu/sahip/yorumlar/yanit/route.ts`'i oku — eğer owner'ın `/api/owner/review-reply`'sindeki tüm işlevleri (reply create/update/delete) karşılıyorsa, kanonik endpoint bu olur ve owner'ın API route'u Task 12'de silinir. Karşılamıyorsa (örn. sadece POST var, DELETE yoksa), eksik metodu `app/sunucu/sahip/yorumlar/yanit/route.ts`'e owner'ın mantığından ekle.

- [ ] **Step 3: Birleştirilmiş `yorum-satiri.tsx`'i yaz**

Sahip'in `YorumSatiri` component'ini temel al (zaten hazır şablonlar, displayName, Gizli rozeti var), owner'ın `ReviewItem`'ından şu özellikleri ekle: `isNew` rozeti (localStorage `owner_reviews_last_seen_at` mantığı — anahtar adını `sahip_yorumlar_son_gorulme` olarak Türkçeleştir), `helpful_count` gösterimi, durum rozetleri (`STATUS_LABELS`: approved/pending/rejected → onaylı/bekleyen/reddedilen, sahip'in "Gizli" rozetiyle birlikte, ikisi farklı kavramlar — durum VE görünürlük ayrı ayrı gösterilir).

- [ ] **Step 4: page.tsx'i güncelle**

`app/sahip/yorumlar/page.tsx`'e, owner'ın `businessMap`/`showBusinessName` prop mantığını (birden fazla işletmesi olan sahip için) ve `lastSeenAt` state yönetimini ekle.

- [ ] **Step 5: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/reviews"
```

- [ ] **Step 6: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 7: Commit**

```bash
git add -A app/sahip/yorumlar
git commit -m "feat(web): yorumlar sayfası owner'ın Yeni/helpful/durum rozetleriyle zenginleştirildi"
```

---

### Task 10: settings ↔ ayarlar — owner'ın tabs mimarisini taşı

**Files:**
- Move: `app/owner/(panel)/settings/actions.ts` → `app/sahip/ayarlar/ayarlar-islemleri.ts`
- Move: `app/owner/(panel)/settings/settings-client.tsx` → `app/sahip/ayarlar/ayarlar-istemcisi.tsx`
- Move: `app/owner/(panel)/settings/settings-right-sidebar.tsx` → `app/sahip/ayarlar/ayarlar-sag-menu.tsx`
- Move: `app/owner/(panel)/settings/tabs/*.tsx` → `app/sahip/ayarlar/sekmeler/*.tsx`
- Modify: `app/sahip/ayarlar/page.tsx`

**Bağlam:** Sahip'in `ayarlar/page.tsx`'i sadece 2 linkten oluşuyor (domain/saatler zaten ayrı alt-route, kayıp değil). Owner'ın tam sekme mimarisi taşınmalı.

- [ ] **Step 1: Owner'ın tüm settings dosyalarını oku**

`actions.ts`, `settings-client.tsx`, `settings-right-sidebar.tsx`, `page.tsx`, ve `tabs/` altındaki 5 dosyayı (`bildirim-ayarlari-tab.tsx`, `gizlilik-guvenlik-tab.tsx`, `hesap-ayarlari-tab.tsx`, `isletme-profili-tab.tsx`, `rezervasyon-ayarlari-tab.tsx`) tam oku. Ardından mevcut `app/sahip/ayarlar/page.tsx`'i oku (2 link neye gidiyor: muhtemelen `/sahip/ayarlar/alan-adi` ve `/sahip/ayarlar/saatler`).

- [ ] **Step 2: Dosyaları taşı**

```bash
cd /c/yeedoy/uygulamalar/web
mkdir -p "app/sahip/ayarlar/sekmeler"
git mv "app/owner/(panel)/settings/actions.ts" "app/sahip/ayarlar/ayarlar-islemleri.ts"
git mv "app/owner/(panel)/settings/settings-client.tsx" "app/sahip/ayarlar/ayarlar-istemcisi.tsx"
git mv "app/owner/(panel)/settings/settings-right-sidebar.tsx" "app/sahip/ayarlar/ayarlar-sag-menu.tsx"
git mv "app/owner/(panel)/settings/tabs/bildirim-ayarlari-tab.tsx" "app/sahip/ayarlar/sekmeler/bildirim-ayarlari-sekmesi.tsx"
git mv "app/owner/(panel)/settings/tabs/gizlilik-guvenlik-tab.tsx" "app/sahip/ayarlar/sekmeler/gizlilik-guvenlik-sekmesi.tsx"
git mv "app/owner/(panel)/settings/tabs/hesap-ayarlari-tab.tsx" "app/sahip/ayarlar/sekmeler/hesap-ayarlari-sekmesi.tsx"
git mv "app/owner/(panel)/settings/tabs/isletme-profili-tab.tsx" "app/sahip/ayarlar/sekmeler/isletme-profili-sekmesi.tsx"
git mv "app/owner/(panel)/settings/tabs/rezervasyon-ayarlari-tab.tsx" "app/sahip/ayarlar/sekmeler/rezervasyon-ayarlari-sekmesi.tsx"
```

- [ ] **Step 3: page.tsx'i owner'ın mantığıyla değiştir, mevcut 2 linki koru**

`app/sahip/ayarlar/page.tsx`'i owner'ın `page.tsx`'i temel alınarak yeniden yaz (tabs mimarisini kullanan `AyarlarIstemcisi`'ni render eder). Owner'daki 5 sekmeye ek olarak, sahip'in mevcut "Çalışma Saatleri" ve "Özel Domain" linklerinin de (bir sekme içinde veya `isletme-profili-sekmesi.tsx` içinde ilgili yerde) erişilebilir kaldığından emin ol — bu iki alt-route (`alan-adi/`, `saatler/`) ayrı route olarak kalmaya devam edebilir, sadece ana ayarlar sayfasından linklenmeleri korunmalı.

- [ ] **Step 4: İç import path'lerini güncelle**

Taşınan tüm dosyalardaki relatif import'ları (`./actions` → `./ayarlar-islemleri`, `./tabs/...` → `./sekmeler/...` vb.) güncelle.

- [ ] **Step 5: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/settings"
```

- [ ] **Step 6: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 7: Commit**

```bash
git add -A app/sahip/ayarlar
git commit -m "feat(web): ayarlar sayfası owner'ın 5 sekmelik mimarisiyle değiştirildi"
```

---

### Task 11: Menü editörü birleştirmesi

**Files:**
- Read: `app/owner/(panel)/menus/[menuId]/edit/actions.ts`, `menu-editor-client.tsx`, `page.tsx`
- Modify: `app/sahip/menuler/[menuId]/duzenle/menu-islemleri.ts`, `menu-duzenleyici-istemcisi.tsx`, `page.tsx`
- Read: `app/sahip/menuler/[menuId]/spesiyel-toggle.tsx` (kullanımının bozulmadığından emin olmak için)

**Bağlam:** İki taraf da Temmuz 2026'da büyük güncelleme almış (767 vs 792 satır) — hangi değişikliklerin sadece bir tarafta olduğu bilinmiyor, gerçek satır satır karşılaştırma gerekiyor.

- [ ] **Step 1: Her iki tarafı da tam oku**

`app/owner/(panel)/menus/[menuId]/edit/menu-editor-client.tsx` (767 satır) ve `app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-istemcisi.tsx` (792 satır) tamamını oku. Aynı şekilde `actions.ts`/`menu-islemleri.ts` çiftini oku.

- [ ] **Step 2: Fonksiyon/state bazında fark listesi çıkar**

Her iki dosyadaki state hook'larını (`useState` çağrıları), fonksiyon isimlerini ve JSX bölüm başlıklarını listele. Sadece bir tarafta olan her state/fonksiyon/UI bölümünü not et (bu, ne ekleneceğinin listesidir).

- [ ] **Step 3: spesiyel-toggle.tsx'in entegrasyon noktasını doğrula**

`app/sahip/menuler/[menuId]/spesiyel-toggle.tsx`'in `menu-duzenleyici-istemcisi.tsx` içinde nerede import edilip kullanıldığını bul — birleştirme sırasında bu import/render bloğu silinmemeli.

- [ ] **Step 4: Birleştirilmiş dosyayı yaz**

`app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-istemcisi.tsx`'i, Step 2'de bulunan "sadece owner'da olan" state/fonksiyon/UI bölümlerini ekleyerek güncelle. `spesiyel-toggle.tsx` entegrasyonu ve sahip'e özgü diğer tüm mantık korunur. Aynısını `menu-islemleri.ts` için yap (owner'ın `actions.ts`'inde olup sahip'te olmayan server action'ları ekle).

- [ ] **Step 5: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/menus/[menuId]/edit"
```

- [ ] **Step 6: Typecheck + lint + ilgili unit testler**

Run: `npm run typecheck && npm run lint && npm run test:unit`
Expected: Hata yok, mevcut testler (varsa `test/` altında menü editörüyle ilgili) geçer.

- [ ] **Step 7: Tarayıcıda manuel doğrulama**

`npm run dev`, bir menüyü `/sahip/menuler/<id>/duzenle`'de aç, hem owner'dan gelen hem sahip'e özgü (spesiyel toggle dahil) tüm işlevlerin çalıştığını doğrula.

- [ ] **Step 8: Commit**

```bash
git add -A app/sahip/menuler
git commit -m "feat(web): menü editörü owner ve sahip sürümleri birleştirilerek güncellendi"
```

---

### Task 12: marketing ↔ pazarlama birleştirmesi

**Files:**
- Read: `app/owner/(panel)/marketing/**` (automations, campaigns, email, loyalty, page.tsx — 12 dosya)
- Modify: `app/sahip/pazarlama/**` (otomasyonlar, kampanyalar, e-posta, sadakat, page.tsx)

- [ ] **Step 1: Her alt-bölüm çiftini oku ve karşılaştır**

Dört alt-bölümün her biri için (automations↔otomasyonlar, campaigns↔kampanyalar, email↔e-posta, loyalty↔sadakat) owner ve sahip dosyalarını oku, fonksiyon/state bazında fark çıkar (Task 11'deki yöntemle aynı).

- [ ] **Step 2: Her alt-bölümü ayrı ayrı birleştir**

Her alt-bölüm için: sadece bir tarafta olan mantığı diğerine ekle, iki tarafta da aynı özellik varsa daha kapsamlı/güncel olanı koru. `pazarlama/page.tsx`'in (ana pazarlama landing/menu sayfası) owner'daki eşdeğerine göre eksik bir alt-bölüm linki olup olmadığını kontrol et.

- [ ] **Step 3: Owner kaynağını sil**

```bash
git rm -r "app/owner/(panel)/marketing"
```

- [ ] **Step 4: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 5: Commit**

```bash
git add -A app/sahip/pazarlama
git commit -m "feat(web): pazarlama sayfaları owner ve sahip sürümleri birleştirilerek güncellendi"
```

---

### Task 13: Login birleştirmesi — /giris kanonikleşir

**Files:**
- Read: `app/owner/login/page.tsx`
- Modify: `app/giris/page.tsx` (ve varsa `GirisFormu` component'i — grep ile bul: `grep -rn "GirisFormu" app/giris`)
- Modify: `middleware.ts` (`OWNER_LOGIN_PATH`)

**Bağlam:** Onaylanan karar: `/giris` kanonik login sayfası olur (hem public hem owner), TÜM görsel tasarımı `owner/login`'e göre güncellenir.

- [ ] **Step 1: Owner/login'in tam tasarımını oku**

`app/owner/login/page.tsx`'i tam oku — layout yapısı, renk/spacing sınıfları, form alanları, buton stilleri.

- [ ] **Step 2: /giris'in mevcut yapısını oku**

`app/giris/page.tsx`'i ve import ettiği `GirisFormu` (veya benzeri) component dosyasını tam oku — tab'lı giriş/kayıt akışının nasıl çalıştığını, hangi state'lerin yönetildiğini anla.

- [ ] **Step 3: Görsel tasarımı güncelle, işlevi koru**

`app/giris/page.tsx` ve ilgili form component'inin CSS class'larını, layout yapısını, renk paletini `owner/login`'inkiyle eşleştir. **İşlevsellik değişmez** — hâlâ hem giriş hem kayıt tab'ı, hem public hem owner kullanıcıları için çalışmalı; sadece görsel dil owner/login'e uyumlu hale gelir.

- [ ] **Step 4: middleware.ts'i güncelle**

`middleware.ts` içinde `OWNER_LOGIN_PATH = '/owner/login';` satırını `OWNER_LOGIN_PATH = '/giris';` yap.

- [ ] **Step 5: Owner login kaynağını sil**

```bash
cd /c/yeedoy/uygulamalar/web
git rm -r "app/owner/login"
```

- [ ] **Step 6: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 7: Tarayıcıda manuel doğrulama**

`npm run dev`, `/giris`'e git, hem giriş hem kayıt akışının çalıştığını doğrula; girişsiz kullanıcı olarak `/sahip/isletmeler` gibi korumalı bir sayfaya gidip `/giris`'e redirect edildiğini doğrula.

- [ ] **Step 8: Commit**

```bash
git add -A app/giris middleware.ts
git commit -m "feat(web): giriş sayfası owner/login tasarımıyla güncellendi, kanonik owner girişi oldu"
```

---

### Task 14: Landing page taşıması

**Files:**
- Read: `app/owner/page.tsx`, `app/owner/owner-landing-search.tsx`
- Modify: `app/sahip/page.tsx` (mevcut bare redirect kaldırılır)
- Create: `app/sahip/sahip-arama.tsx` (owner-landing-search.tsx'in Türkçe karşılığı)
- Modify: `middleware.ts` (`OWNER_PUBLIC_PATHS`)

**Bağlam:** `app/sahip/page.tsx` şu an sadece `redirect('/sahip/gosterge-panosu')`. Owner'ın 345 satırlık landing page'i (hero, özellik kartları, arama widget'ı, süreç anlatımı, SSS, footer) tamamen kayıp.

- [ ] **Step 1: Owner'ın landing page'ini tam oku**

`app/owner/page.tsx` (345 satır) ve `app/owner/owner-landing-search.tsx`'i tam oku.

- [ ] **Step 2: Mevcut sahip/page.tsx'i oku**

`app/sahip/page.tsx`'in şu anki (5 satırlık redirect) içeriğini doğrula.

- [ ] **Step 3: Landing page'i taşı**

```bash
cd /c/yeedoy/uygulamalar/web
git mv "app/owner/owner-landing-search.tsx" "app/sahip/sahip-arama.tsx"
```

`app/sahip/page.tsx`'in içeriğini, owner'ın `page.tsx`'inden birebir alınan landing page ile değiştir (redirect kaldırılır). Tüm iç linkler (`/owner/login` → `/giris`, işletme arama sonucu linkleri vb.) güncellenir. `owner-landing-search` import'u `sahip-arama` olarak güncellenir.

- [ ] **Step 4: middleware.ts — OWNER_PUBLIC_PATHS güncelle**

`middleware.ts`'te `OWNER_PUBLIC_PATHS` dizisine (şu an `[OWNER_LOGIN_PATH, '/owner']`) `/sahip`'i ekle: `const OWNER_PUBLIC_PATHS = [OWNER_LOGIN_PATH, '/owner', '/sahip'];` — bu sayede girişsiz ziyaretçi `/sahip`'e gittiğinde login'e değil, landing page'e düşer.

- [ ] **Step 5: Owner kaynağını sil**

```bash
git rm "app/owner/page.tsx"
```

(Not: `app/owner/` klasörünün tamamı Task 16'da silinecek, bu adım sadece bu dosyayı erken temizlemek için — eğer Task 16'ya kadar bekletmek istersen bu adımı atlayabilirsin, ama o zaman `app/owner/page.tsx`'in artık kullanılmadığından emin ol.)

- [ ] **Step 6: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 7: Tarayıcıda manuel doğrulama**

`npm run dev`, çıkış yapmış halde `/sahip`'e git, landing page'in (redirect değil) göründüğünü doğrula.

- [ ] **Step 8: Commit**

```bash
git add -A app/sahip middleware.ts
git commit -m "feat(web): owner landing page sahip köküne taşındı, girişsiz ziyaretçiler için erişilebilir yapıldı"
```

---

### Task 15: Ölü kodu sil

**Files:**
- Delete: `app/sahip/crm/`, `app/sahip/sponsorluk/`, `app/sahip/finansal/`, `app/sahip/envanter/`, `app/sahip/siparisler/`
- Delete: karşılık gelen `app/sunucu/sahip/` API stub'ları

**Bağlam:** Bu 5 route stub — `redirect('/sahip/gosterge-panosu')` + "MVP scope dışı" yorumu, sıfır gerçek RPC çağrısı. `fiyat-raporu` SİLİNMEZ (canlı, nav'da linkli).

- [ ] **Step 1: Her 5 route'un gerçekten stub olduğunu doğrula**

`grep -L "\.rpc(\|\.from(" app/sahip/crm/page.tsx app/sahip/sponsorluk/*.tsx app/sahip/sponsorluk/*.ts app/sahip/finansal/page.tsx app/sahip/envanter/*.tsx app/sahip/siparisler/*.tsx` çalıştır — hiçbiri gerçek Supabase çağrısı içermemeli (spec'te zaten doğrulandı, bu son bir kontrol).

- [ ] **Step 2: Sayfaları sil**

```bash
cd /c/yeedoy/uygulamalar/web
git rm -r app/sahip/crm app/sahip/sponsorluk app/sahip/finansal app/sahip/envanter app/sahip/siparisler
```

- [ ] **Step 3: Karşılık gelen ölü API stub'larını sil**

`find app/sunucu/sahip -type d | grep -iE "envanter|siparis|finansal|sponsor|crm"` ile ilgili API klasörlerini bul, her birinin içeriğinin de sadece silinen sayfalar tarafından kullanıldığını (`grep -rn "sunucu/sahip/envanter" app/` gibi) doğruladıktan sonra sil.

```bash
git rm -r app/sunucu/sahip/envanter app/sunucu/sahip/siparis-listesi app/sunucu/sahip/finansal-csv
```

(Yukarıdaki komut, Step 3'teki grep sonucuna göre ayarlanmalı — sadece gerçekten başka hiçbir yerden kullanılmayan klasörler silinir.)

- [ ] **Step 4: Nav'da bu route'lara link olmadığını doğrula**

`grep -n "crm\|sponsorluk\|finansal\|envanter\|siparisler" src/ui/kabuk/sahip-kabuk-istemcisi.tsx` — sonuç boş olmalı (spec'e göre zaten nav'da yoklardı).

- [ ] **Step 5: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok (silinen dosyalara referans kalmamalı).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore(web): kapsam dışı bırakılan sahip stub sayfaları (crm/sponsorluk/finansal/envanter/siparisler) silindi"
```

---

### Task 16: Shell nav güncelle, kullanılmayan owner-shell-client.tsx sil

**Files:**
- Modify: `src/ui/kabuk/sahip-kabuk-istemcisi.tsx`
- Delete: `src/ui/shell/owner-shell-client.tsx`

- [ ] **Step 1: sahip-kabuk-istemcisi.tsx'i tam oku**

Mevcut 14 item'lık nav dizisini ve 3 bölüm yapısını (Operasyon/Büyüme/Yönetim) tam oku.

- [ ] **Step 2: Yeni nav item'larını ekle**

Şu href/label çiftlerini uygun bölümlere ekle:
- `/sahip/rezervasyonlar` — "Rezervasyonlar" (Operasyon bölümü, "Yeni" badge'i owner'daki gibi korunabilir)
- `/sahip/fotograflar` — "Fotoğraflar" (Operasyon bölümü)
- `/sahip/bildirimler` — "Bildirimler" (Yönetim bölümü)
- `/sahip/pazarlama` — "Pazarlama" (zaten dosya var, nav'a ekleniyor — Büyüme bölümü)
- `/sahip/buyume` — "Büyüme" (zaten dosya var — Büyüme bölümü)
- `/sahip/denetim-kaydi` — "Denetim Kaydı" (zaten dosya var — Yönetim bölümü)
- `/sahip/yapay-zeka-analizi` — "Yapay Zeka Analizi" (zaten dosya var — Büyüme bölümü)

- [ ] **Step 3: Kullanılmayan dosyayı sil**

```bash
cd /c/yeedoy/uygulamalar/web
grep -rn "owner-shell-client" src/ app/ --include="*.tsx" --include="*.ts"
```

Expected: Sıfır sonuç (hiçbir yerden import edilmiyor — spec'te zaten doğrulandı). Sonra:

```bash
git rm src/ui/shell/owner-shell-client.tsx
```

- [ ] **Step 4: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 5: Tarayıcıda manuel doğrulama**

`npm run dev`, `/sahip/gosterge-panosu`'na giriş yap, sidebar'da yeni eklenen 7 item'ın göründüğünü ve hepsinin doğru sayfaya gittiğini doğrula.

- [ ] **Step 6: Commit**

```bash
git add -A src/ui
git commit -m "feat(web): sahip nav'ına yeni taşınan ve önceden erişilemeyen sayfalar eklendi"
```

---

### Task 17: Cross-reference güncellemeleri

**Files:**
- Modify: `app/forbidden/page.tsx`
- Modify: `app/login/page.tsx`

- [ ] **Step 1: forbidden/page.tsx'i güncelle**

`app/forbidden/page.tsx`'i oku, `/owner/dashboard` referansını `/sahip/gosterge-panosu`'na, `/owner/login` referansını `/giris`'e değiştir.

- [ ] **Step 2: Kök login/page.tsx'i güncelle**

`app/login/page.tsx`'i oku (satır 26 civarı: `redirect=${encodeURIComponent('/owner/businesses')}`), `/owner/businesses` referansını `/sahip/isletmeler`'e değiştir.

- [ ] **Step 3: Repo genelinde kalan `/owner/` referanslarını tara**

```bash
cd /c/yeedoy/uygulamalar/web
grep -rn "'/owner/\|\"/owner/\|\`/owner/" app src --include="*.ts" --include="*.tsx" | grep -v "app/owner/"
```

Expected: Sadece zaten bilinen/işlenmiş referanslar (varsa) kalmalı. Bulunan her yeni referansı aynı şekilde `/sahip/`'e çevir.

- [ ] **Step 4: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 5: Commit**

```bash
git add -A app/forbidden app/login
git commit -m "fix(web): forbidden ve login sayfalarındaki owner referansları sahip'e güncellendi"
```

---

### Task 18: Redirect'leri ekle

**Files:**
- Modify: `next.config.mjs`

- [ ] **Step 1: Mevcut redirects() array'ini oku**

`next.config.mjs`'in tam içeriğini oku (zaten biliniyor, referans için tekrar oku).

- [ ] **Step 2: Owner→sahip redirect'lerini ekle**

`redirects()` fonksiyonunun döndürdüğü array'e şu girdileri ekle (mevcut girdilerin altına):

```js
      // Owner paneli Türkçeleştirme — eski İngilizce path'lerden yenilerine
      { source: '/owner', destination: '/sahip', permanent: true },
      { source: '/owner/login', destination: '/giris', permanent: true },
      { source: '/owner/dashboard', destination: '/sahip/gosterge-panosu', permanent: true },
      { source: '/owner/businesses', destination: '/sahip/isletmeler', permanent: true },
      { source: '/owner/businesses/new', destination: '/sahip/isletmeler/yeni', permanent: true },
      { source: '/owner/businesses/submissions', destination: '/sahip/isletmeler/basvurular', permanent: true },
      { source: '/owner/businesses/:id', destination: '/sahip/isletmeler/:id', permanent: true },
      { source: '/owner/menus', destination: '/sahip/menuler', permanent: true },
      { source: '/owner/menus/:menuId', destination: '/sahip/menuler/:menuId', permanent: true },
      { source: '/owner/menus/:menuId/edit', destination: '/sahip/menuler/:menuId/duzenle', permanent: true },
      { source: '/owner/menu/translations', destination: '/sahip/menu/ceviriler', permanent: true },
      { source: '/owner/photos', destination: '/sahip/fotograflar', permanent: true },
      { source: '/owner/reviews', destination: '/sahip/yorumlar', permanent: true },
      { source: '/owner/reservations', destination: '/sahip/rezervasyonlar', permanent: true },
      { source: '/owner/analytics', destination: '/sahip/analitik', permanent: true },
      { source: '/owner/marketing', destination: '/sahip/pazarlama', permanent: true },
      { source: '/owner/marketing/:path*', destination: '/sahip/pazarlama/:path*', permanent: true },
      { source: '/owner/qr', destination: '/sahip/karekod', permanent: true },
      { source: '/owner/notifications', destination: '/sahip/bildirimler', permanent: true },
      { source: '/owner/settings', destination: '/sahip/ayarlar', permanent: true },
      { source: '/owner/settings/domain', destination: '/sahip/ayarlar/alan-adi', permanent: true },
      { source: '/owner/settings/hours', destination: '/sahip/ayarlar/saatler', permanent: true },
      { source: '/owner/ai-analysis', destination: '/sahip/yapay-zeka-analizi', permanent: true },
      { source: '/owner/team', destination: '/sahip/ekip', permanent: true },
      { source: '/owner/trash', destination: '/sahip/cop-kutusu', permanent: true },
      { source: '/owner/price-suggestions', destination: '/sahip/fiyat-onerileri', permanent: true },
      { source: '/owner/growth', destination: '/sahip/buyume', permanent: true },
      { source: '/owner/audit', destination: '/sahip/denetim-kaydi', permanent: true },
      { source: '/owner/activity', destination: '/sahip/etkinlik', permanent: true },
      { source: '/owner/requests', destination: '/sahip/istekler', permanent: true },
      { source: '/owner/suspended', destination: '/sahip/askiya-alinanlar', permanent: true },
      { source: '/owner/pricing', destination: '/sahip/fiyatlandirma', permanent: true },
      { source: '/owner/onboarding', destination: '/sahip/baslangic', permanent: true },
```

**Not:** Bu adım artık `/owner/qr/design` ve `/owner/menu/editor`/`/owner/menu/section-editor` için mevcut olan eski redirect girdilerinin ÜZERİNE gelmez — onlar zaten `/owner/qr` ve `/owner/menus`'a yönlendiriyordu, yeni eklenen genel `/owner/qr`→`/sahip/karekod` ve `/owner/menus/:menuId/edit`→`/sahip/menuler/:menuId/duzenle` kuralları zincirleme çalışacak şekilde Next.js redirect sırasını kontrol et (Next.js ilk eşleşen kuralı uygular, üstteki eski spesifik kurallar önce gelmeli — mevcut sırayı bozma, yeni kuralları listenin SONUNA ekle).

- [ ] **Step 3: Build ile redirect syntax'ını doğrula**

Run: `npm run build`
Expected: Build hatasız tamamlanır (redirect array syntax hatası varsa build başında yakalanır).

- [ ] **Step 4: Manuel redirect testi**

`npm run dev` başlat, tarayıcıda `/owner/dashboard`, `/owner/businesses`, `/owner/menus/<gerçek-id>/edit` gibi en az 3 eski URL'yi dene, her birinin doğru `/sahip/...` path'ine yönlendirdiğini doğrula.

- [ ] **Step 5: Commit**

```bash
git add next.config.mjs
git commit -m "feat(web): eski /owner/* path'lerinden yeni /sahip/* path'lerine kalıcı redirect eklendi"
```

---

### Task 19: Eski ağacı ve middleware'i sadeleştir

**Files:**
- Delete: `app/owner/**` (kalan tüm dosyalar)
- Delete: `app/api/owner/**` (Task 4'te taşınmayan/artık kullanılmayan kalanlar)
- Modify: `middleware.ts`

- [ ] **Step 1: app/owner altında kalan dosyaları listele**

```bash
cd /c/yeedoy/uygulamalar/web
find app/owner -type f
```

Bu noktada sadece Task 1-14'te ele alınmayan dosyalar kalmış olmalı (`layout.tsx`, `loading.tsx`, ve varsa gözden kaçan başka dosyalar). Her birini kontrol et: `layout.tsx` sadece `OwnerDashboardShell`'i render ediyorsa doğrudan silinebilir (sahip zaten kendi layout'unu kullanıyor). `loading.tsx` içeriğini kontrol et, sahip'te eşdeğeri (`app/sahip/loading.tsx`) zaten var mı doğrula — yoksa aynı içerikle `app/sahip/loading.tsx` olarak taşı.

- [ ] **Step 2: Kalan her şeyi sil**

```bash
git rm -r app/owner
```

- [ ] **Step 3: app/api/owner altında kalanları kontrol et ve sil**

```bash
find app/api/owner -type f
```

Task 4'te taşınmayan (çünkü zaten `/sunucu/sahip` karşılığı vardı) dosyaları doğrula, hepsinin artık hiçbir sahip sayfası tarafından çağrılmadığından emin ol (`grep -rn "/api/owner/" app/sahip`), sonra sil:

```bash
git rm -r app/api/owner
```

- [ ] **Step 4: middleware.ts'i sadeleştir**

`middleware.ts`'i oku, şu değişiklikleri yap:
- `const OWNER_PREFIX = '/owner';` satırını sil
- `guardPanelRoute` içindeki `isOwnerRoute` hesaplamasını sadeleştir:
  ```js
  const OWNER_PUBLIC_PATHS = [OWNER_LOGIN_PATH, '/sahip'];
  const isOwnerRoute =
    pathname.startsWith(SAHIP_PREFIX) &&
    !OWNER_PUBLIC_PATHS.includes(pathname);
  ```
  (Task 14'te zaten `/sahip` eklenmişti, burada `/owner` referansı tamamen kaldırılıyor)
- `YONETICI_PREFIX`/admin ile ilgili satırlara DOKUNMA — bu proje sadece owner kapsamında, admin Faz 2'de ele alınacak.

- [ ] **Step 5: Typecheck + lint + build**

Run: `npm run typecheck && npm run lint && npm run build`
Expected: Hepsi hatasız geçer.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore(web): eski /owner ağacı tamamen kaldırıldı, middleware sadeleştirildi"
```

---

### Task 20: Final doğrulama

**Files:** (değişiklik yok, sadece doğrulama)

- [ ] **Step 1: Tam otomatik doğrulama paketi**

Run: `npm run typecheck && npm run lint && npm run test:unit && npm run build`
Expected: Hepsi başarılı (CLAUDE.md minimum doğrulama tablosu — Web değişikliği gereksinimi).

- [ ] **Step 2: Manuel owner akışı — uçtan uca**

`npm run dev` başlat, tarayıcıda şu akışı takip et ve her adımda hata olmadığını doğrula:
1. Çıkış yapmış halde `/sahip`'e git → landing page görünür
2. "Giriş Yap" → `/giris`'e gider, owner/login tasarımıyla tutarlı görünür
3. Giriş yap → `/sahip/gosterge-panosu`'na yönlenir, KPI grid + (varsa) pending-claim banner + owner'ın görsel bölümü görünür
4. Sidebar'dan İşletmeler → Menüler → bir menüyü düzenle (spesiyel toggle çalışıyor mu kontrol et) → Rezervasyonlar → Analitik (hem trafik kaynağı hem Yoğun Saatler görünüyor mu) → Yorumlar (hazır şablonlar + Yeni rozeti + helpful_count görünüyor mu) → Ayarlar (5 sekme + saatler/domain linkleri) → Karekod (hub → QR Studio → gerçek QR listesi)
5. Çıkış yap

- [ ] **Step 3: Redirect doğrulaması**

En az 5 eski `/owner/...` URL'sini tarayıcıda dene (Task 18 Step 4'te test edilenlerden farklı 5 tane), hepsinin doğru `/sahip/...`'e düştüğünü doğrula.

- [ ] **Step 4: Kalan referans taraması**

```bash
cd /c/yeedoy/uygulamalar/web
grep -rn "/owner/\|app/owner\b" app src middleware.ts next.config.mjs --include="*.ts" --include="*.tsx" --include="*.mjs"
```

Expected: Sonuç boş olmalı (redirect kaynak path'leri hariç — `next.config.mjs` içindeki `source: '/owner/...'` girdileri beklenen tek sonuç).

- [ ] **Step 5: Final commit (varsa küçük düzeltmeler)**

Eğer Step 1-4'te herhangi bir düzeltme yapıldıysa:

```bash
git add -A
git commit -m "fix(web): owner Türkçeleştirme final doğrulama düzeltmeleri"
```
