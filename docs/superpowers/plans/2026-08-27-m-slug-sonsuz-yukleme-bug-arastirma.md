# /m/[slug] Menüsüz İşletmelerde Sonsuz Yükleme Bug'ı — Araştırma ve Düzeltme Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menüsü olmayan bir işletmenin `/m/[slug]` (karekod menü) sayfasının, gerçek 404 (`not-found.tsx`) göstermek yerine sonsuza kadar yükleme iskeletinde (skeleton) takılı kalmasının kök nedenini bulup düzeltmek.

**Architecture:** Önce `PublicMenuPage` bileşeninin kendi `if (!data) notFound()` kontrolünün gerçekten çalışıp çalışmadığını (yerel dev + production Supabase'e bağlı `.env.local` üzerinden) geçici log ile doğrula. Sonuca göre iki olası kök nedenden (stale `unstable_cache` girdisi ya da Next.js 15'in `notFound()`+streaming/Suspense etkileşimindeki bilinen davranış) hangisi doğrulanırsa onu düzelt.

**Tech Stack:** Next.js 16.2.11 App Router (`notFound()`, `unstable_cache`), yerel `next dev` (production Supabase'e `.env.local` üzerinden bağlı).

---

## Bağlam — Bu Oturumda Doğrulanmış Bulgular

- Test edilen işletme: **"MAVİŞ DÖNER Mehmet Usta"** (`slug: mavi-d-ner-mehmet-usta`, `business_id: 000147a8-e3ed-4a9c-8a83-34d2238e73ca`). DB'de doğrudan sorgulandı: **`menus` tablosunda bu işletmeye ait hiç kayıt yok** (`menu_id: null`).
- `app/(genel)/m/[slug]/page.tsx`'teki `generateMetadata` fonksiyonu (satır 327-341) bunu doğru tespit ediyor: `generatePublicMenuMetadata` içindeki `getPublicMenuPageData` çağrısı `null` dönüyor → `notFound()` fırlıyor → dıştaki `try/catch` bunu yakalayıp `{}` (boş metadata) döndürüyor. **Bu kısım tasarlandığı gibi çalışıyor.**
- Ama aynı dosyadaki `PublicMenuPage` bileşeni (satır 343-346):
  ```ts
  const data = await getPublicMenuPageData({ businessSlugOrId: slug }).catch(() => null);
  if (!data) notFound();
  ```
  Bu kontrolün de aynı şekilde `notFound()` fırlatıp `not-found.tsx`'i göstermesi beklenir. **Ama gerçekte:**
  - Tarayıcıda (`mcp__claude-in-chrome` ile canlı test edildi) sayfa **sonsuza kadar yükleme iskeletinde kalıyor** — `document.body.innerText` 5+ saniye sonra hâlâ boş, `"Menü bulunamadı"` metni hiç görünmüyor.
  - HTTP durum kodu **200** (curl ile doğrulandı) — 404 DEĞİL. Next.js'in kendi not-found mekanizması hiç devreye girmemiş.
- `getPublicMenuData` (`src/lib/veri/menu-okuma.ts:553`) → `getMenuForBusiness` (satır 280) → `getMenuForBusinessCached` (satır 256, `unstable_cache(['public-business-menu'], {revalidate:120})` ile sarılı) — bu zincirde `if (!menu) return null` (satır 565) var.
- **İki olası kök neden, henüz hiçbiri doğrulanmadı:**
  1. `getMenuForBusinessCached`'in bu işletme için **stale/eski bir cache girdisi** döndürmesi (ör. geçmişte menü varken silinmiş/draft'a alınmış olabilir, cache 120sn'de bir yenilense de ilk yenilenme henüz olmamış veya cache invalidation eksik) — bu durumda sayfa BAŞARILI bir menü nesnesi görüp render etmeye çalışıyor ama `renderPublicMenuRoute` içindeki başka bir async adım (ör. `getBusinessHoursInfo`, menü item'ları) sonsuza kadar asılı kalıyor olabilir.
  2. Next.js 15/16'nın `notFound()`'u bir Suspense-streamed async server component ağacı içinde çağırmakla ilgili bilinen bir davranış sorunu — kodun kendi yorumu (satır 329-330) zaten metadata bağlamında BENZER bir Next.js 15 bug'ını belgeliyor ("notFound() çağrısı metadata context'inde 500'e yol açabilir"); sayfa bağlamında da farklı bir belirtiyle (500 yerine sonsuz asılı kalma) aynı kök ailesinden bir sorun olabilir.
- Geçici `console.error` debug log'u SADECE `generateMetadata`'nın catch bloğuna eklenip test edildi (gerçek hatayı `NEXT_HTTP_ERROR_FALLBACK;404` olarak doğruladı) ve sonra temizlendi — `PublicMenuPage`'in kendi `if (!data) notFound()` satırına HENÜZ log eklenmedi, bu planın ilk görevi bu.

---

### Task 1: Aynı bug'ın kaç işletmeyi etkilediğini ölç

**Files:** Yok (sadece SQL sorgusu + curl)

- [ ] **Step 1: Menüsüz işletme sayısını ve örneklerini çıkar**

```sql
select b.id, b.slug, b.name
from businesses b
left join menus m on m.business_id = b.id
where b.is_active = true and m.id is null
limit 20;
```

- [ ] **Step 2: Bu listeden 3-5 farklı işletmenin `/m/[slug]` sayfasını curl ile kontrol et**

```bash
for slug in <adım-1-den-gelen-slug-lar>; do
  curl -s -o /dev/null -w "%{http_code} $slug\n" "https://www.yeedoy.com/m/$slug"
done
```

Hepsi 200 dönüyorsa (404 değil), bu evrensel bir bug demektir — tek işletmeye özgü bir veri garipliği değil. Bulguyu not al.

---

### Task 2: `PublicMenuPage`'in kendi `notFound()` kontrolünü canlı olarak doğrula

**Files:**
- Modify (geçici): `uygulamalar/web/app/(genel)/m/[slug]/page.tsx:343-346`

- [ ] **Step 1: Geçici debug log ekle**

```ts
export default async function PublicMenuPage({ params, searchParams }: MenuPageProps) {
  const [{ slug }, rawSearchParams] = await Promise.all([params, searchParams]);
  const data = await getPublicMenuPageData({ businessSlugOrId: slug }).catch(() => null);
  console.error('[DEBUG m/slug page]', slug, 'data is null:', !data, 'menu:', data?.menu ?? 'N/A');
  if (!data) notFound();
  ...
```

- [ ] **Step 2: Yerel dev server'da test et (production Supabase'e `.env.local` üzerinden bağlı)**

```bash
cd uygulamalar/web
pnpm run dev
# ayrı terminalde:
curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:3000/m/mavi-d-ner-mehmet-usta"
```

Dev server log'unda `[DEBUG m/slug page]` satırını oku:
- `data is null: true` çıkarsa → `notFound()` çağrılıyor ama Next.js bunu düzgün işlemiyor demektir → **Task 3A**'ya geç (Next.js/Suspense hipotezi).
- `data is null: false` (yani `data.menu` gerçekten dolu bir nesne) çıkarsa → cache stale/poisoned demektir → **Task 3B**'ye geç (cache hipotezi).

- [ ] **Step 3: Debug log'u kaldır, dosyayı temiz haline getir**

`git diff` ile sadece bu geçici satırın kaldığını doğrula, commit etme.

---

### Task 3A: Next.js notFound()/Suspense hipotezi doğrulanırsa

**Files:** `uygulamalar/web/app/(genel)/m/[slug]/page.tsx`

- [ ] **Step 1: `renderPublicMenuRoute`'un çağrıldığı yerde bir Suspense sınırı olup olmadığını kontrol et**

`grep -n "Suspense" uygulamalar/web/app/\(genel\)/m/\[slug\]/page.tsx` ve `layout.tsx`. Eğer `PublicMenuPage`'in return'ü bir `<Suspense>` içinde sarılıyorsa (üst `layout.tsx` üzerinden), `notFound()`'un bu sınırın DIŞINDA (en üst seviyede, `Suspense` render edilmeden ÖNCE) çağrıldığından emin ol — gerekirse veri fetch'ini `Suspense`'ten önceki senkron/erken bir noktaya taşı.

- [ ] **Step 2: Next.js sürümüne özgü bilinen issue'ları kontrol et**

`node_modules/next/package.json`'daki sürümü not al, GitHub'da `next.js` reposunda "notFound Suspense hang" / "notFound infinite loading" gibi terimlerle mevcut issue'ları ara (WebSearch veya `gh` ile, sadece okuma amaçlı).

- [ ] **Step 3: Düzeltmeyi uygula ve yerel doğrula**

Bulunan spesifik nedene göre (muhtemelen: `notFound()` çağrısını bileşen ağacında daha erken bir noktaya taşımak, ya da `export const dynamic = 'force-dynamic'` gibi bir ayarla streaming davranışını değiştirmek). Sonra:

```bash
curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:3000/m/mavi-d-ner-mehmet-usta"
# 404 dönmeli
```

---

### Task 3B: Stale cache hipotezi doğrulanırsa

**Files:** `uygulamalar/web/src/lib/veri/menu-okuma.ts:256-278`

- [ ] **Step 1: `getMenuForBusinessCached`'in cache key'ini incele**

Mevcut: `unstable_cache(fn, ['public-business-menu'], { revalidate: 120 })` — `businessId` parametresi fonksiyon argümanı olarak otomatik cache key'e dahil olsa da, **cache tag'i eklenmemiş** (`tags` opsiyonu yok), bu yüzden bir menü silindiğinde/durumu değiştiğinde `revalidateTag` ile anlık invalidasyon YAPILAMIYOR — sadece 120sn'lik pasif TTL'e güveniliyor.

- [ ] **Step 2: Cache tag ekle ve menü durumu değiştiğinde invalidasyon tetikle**

```ts
const getMenuForBusinessCached = unstable_cache(
  async (businessId: string) => { /* ... mevcut içerik ... */ },
  ['public-business-menu'],
  { revalidate: 120, tags: ['public-business-menu'] },
);
```

Menü oluşturma/silme/durum-değiştirme RPC'lerinin çağrıldığı route handler'larda (`grep -rn "menus" uygulamalar/web/app/sunucu` ile bul) `revalidateTag('public-business-menu')` çağrısı ekle.

- [ ] **Step 3: Yerel doğrula**

Aynı business için önce menüyü var say (cache'i ısıt), sonra DB'den sil, `revalidateTag` tetiklendiğini ve sayfanın artık doğru şekilde 404 döndüğünü doğrula.

---

### Task 4: Deploy ve production doğrulama

**Files:** Task 3A veya 3B'de değişen dosyalar

- [ ] **Step 1: Typecheck + lint**

```bash
cd uygulamalar/web
pnpm run typecheck
pnpm run lint
```

- [ ] **Step 2: Commit + push**

```bash
git add <değişen dosyalar>
git commit -m "fix(web): /m/[slug] menüsüz işletmelerde sonsuz yükleme bug'ı"
git push origin main
```

- [ ] **Step 3: Vercel deploy'unu bekle, production'da doğrula**

```bash
curl -s -o /dev/null -w "%{http_code}\n" "https://www.yeedoy.com/m/mavi-d-ner-mehmet-usta"
# 404 dönmeli, ve gövdede "Menü bulunamadı" metni olmalı
curl -s "https://www.yeedoy.com/m/mavi-d-ner-mehmet-usta" | grep -o "Menü bulunamadı"
```

- [ ] **Step 4: Task 1'de bulunan diğer menüsüz işletmelerden 2-3 tanesini de aynı şekilde doğrula**

---

## Notlar

- Bu bug, performans denetiminden (bkz. `2026-08-27-anasayfa-performans-arastirma.md`) tamamen bağımsız — ayrı bir kök neden ailesi (fonksiyonel/routing, performans değil).
- `generateMetadata`'daki mevcut `try/catch` davranışına DOKUNULMUYOR — o zaten doğru çalışıyor, sadece sayfa bileşenindeki asıl bug hedefleniyor.
