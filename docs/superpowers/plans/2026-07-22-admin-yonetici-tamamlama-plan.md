# Admin→Yönetici Türkçeleştirme Tamamlama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `app/admin` ağacını, kayıp özellik olmadan kalıcı olarak kaldırmak; `/yonetici` tek kanonik admin paneli olsun ve canlı `ops.yeedoy.com` subdomain trafiği de oraya aksın.

**Architecture:** Next.js 15 App Router. Kapsamlı bir denetim (`docs/superpowers/specs/2026-07-22-admin-yonetici-tamamlama-design.md`) 31 eşleşen bölümün 28'ini içerik bazında doğruladı (zaten `/yonetici` tarafı daha gelişmiş) ve sadece 3 gerçek eksik buldu: işletme oluşturma akışları, toplu-işlemler nav linki, zincir yönetimi. Bu owner/sahip migrasyonuna göre çok daha küçük kapsamlı bir iş.

**Tech Stack:** Next.js 15 (App Router), TypeScript, Supabase, Tailwind (semantic token sınıfları).

**Referans:** `docs/superpowers/specs/2026-07-22-admin-yonetici-tamamlama-design.md` (bu planın kaynağı). Owner/sahip migrasyonunun tam süreci (`docs/superpowers/plans/2026-07-20-owner-turkification-tamamlama-plan.md`) format/desen referansı olarak kullanılabilir.

**Önemli — owner/sahip'ten öğrenilen ders:** İlk denetimde "eşleşiyor" sanılan sayfaların sonradan taşınmamış çıktığı defalarca görüldü. Bu plandaki denetim daha kapsamlı yapıldı (her çift içerik bazında okundu), ama yine de **Task 6 (app/admin silme)** öncesi implementer'a son bir bağımsız doğrulama yaptırılacak — hiçbir şey "muhtemelen güvenli" diye silinmeyecek.

---

## Dosya Yapısı Özeti

**Oluşturulacak:**
- `app/yonetici/zincirler/page.tsx`, `app/yonetici/zincirler/[id]/page.tsx` (admin/chains portu)
- `app/yonetici/isletmeler/yeni/**` (admin/businesses/new portu)
- `app/yonetici/isletmeler/[id]/menuler/yeni/**` (admin/businesses/[id]/menus/new portu)
- `app/sunucu/yonetici/isletmeler/route.ts` (app/api/admin/businesses portu)
- `app/sunucu/yonetici/isletmeler/[id]/menuler/route.ts` (app/api/admin/businesses/[id]/menus portu)

**Değiştirilecek:**
- `src/ui/kabuk/yonetici-kabuk-istemcisi.tsx` (nav'a Zincirler + Toplu İşlemler eklenir)
- `next.config.mjs` (redirect'ler eklenir)
- `middleware.ts` (guard sadeleşir, subdomain rewrite `/yonetici`'ye çevrilir)

**Silinecek:**
- `app/admin/**` (tüm ağaç)
- `app/api/admin/**`

---

### Task 1: Zincirler (chains) — admin'den yönetici'ye taşı

**Files:**
- Read: `app/admin/chains/page.tsx` (204 satır), `app/admin/chains/[id]/page.tsx` (234 satır)
- Create: `app/yonetici/zincirler/page.tsx`, `app/yonetici/zincirler/[id]/page.tsx`

**Bağlam:** Admin'de tam CRUD var (`admin_list_chains_v1`, `admin_get_chain_detail_v1` RPC'leri), yönetici'de hiç karşılığı yok. Liste sayfasındaki "Yeni Zincir" butonu `/admin/chains/new`'e link veriyor — bu route'un admin tarafında bile var olup olmadığını (find ile `app/admin/chains` altında `new` klasörü bulunamadı) Step 1'de doğrula; muhtemelen kendisi de kırık bir link, bu durumda yönetici tarafında da aynı (kırık ama görünür) haliyle taşınabilir, ya da düzeltme fırsatı olarak değerlendirilebilir — kapsamı Step 2'de netleştir.

- [ ] **Step 1: Kaynak dosyaları tam oku, "Yeni Zincir" linkinin gerçekten çalışıp çalışmadığını doğrula**

`app/admin/chains/page.tsx` ve `app/admin/chains/[id]/page.tsx`'i tam oku. `find "app/admin/chains" -type d` ile `new` alt klasörünün var olup olmadığını doğrula. Yoksa, bu "Yeni Zincir" butonu admin tarafında da kırık demektir — raporunda bunu belirt, yönetici portunda da aynı (kırık) haliyle bırak (bu task'ın kapsamı sadece mevcut liste+detay sayfalarını taşımak, admin'de hiç var olmayan bir "create" akışını icat etmek değil).

- [ ] **Step 2: `app/yonetici/zincirler/page.tsx`'i oluştur**

`admin/chains/page.tsx`'in birebir Türkçe portu: import path'leri Türkçe konvansiyona çevir (`@/src/lib/supabaseServer` → `@/src/lib/taban-sunucu`; `PanelPageHeader`/`PanelContentSurface`/`PanelSectionCard`/`PanelEmptyState`/`PanelActionButton` → sırasıyla `PanelSayfaBasligi` (`@/src/ui/yerlesim/panel-page-header`), `PanelIcerikYuzeyi`/`PanelBolumKarti` (`@/src/ui/yerlesim/panel-section-card`), `PanelEmptyState` (`@/src/ui/bilesenler/panel-bos-durum`), `PanelActionButton` (`@/src/ui/bilesenler/panel-eylem-dugmesi`) — bu path'leri diğer zaten-taşınmış `app/yonetici/**` sayfalarından (örn. `app/yonetici/isletmeler/page.tsx`) doğrulayarak kullan). Link hedeflerini `/admin/chains/...` → `/yonetici/zincirler/...` yap. `eyebrow="Admin"` → mevcut yönetici sayfalarının kullandığı eyebrow konvansiyonuna bak (muhtemelen "Yönetici" veya "Admin" — bir referans sayfadan kontrol et).

- [ ] **Step 3: `app/yonetici/zincirler/[id]/page.tsx`'i oluştur**

Aynı şekilde `admin/chains/[id]/page.tsx`'in portu. RPC çağrısı (`admin_get_chain_detail_v1`) aynen korunur.

- [ ] **Step 4: Typecheck + lint**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 5: Commit**

```bash
git add app/yonetici/zincirler
git commit -m "feat(web): zincir yönetimi sayfası yönetici paneline taşındı"
```

---

### Task 2: İşletme oluşturma akışları — admin'den yönetici'ye taşı

**Files:**
- Read: `app/admin/businesses/new/page.tsx`, `new-business-client.tsx`; `app/admin/businesses/[id]/menus/new/page.tsx`, `new-menu-client.tsx`; `app/api/admin/businesses/route.ts` (POST+GET), `app/api/admin/businesses/[id]/menus/route.ts`
- Create: `app/yonetici/isletmeler/yeni/page.tsx`, `yeni-isletme-istemcisi.tsx`; `app/yonetici/isletmeler/[id]/menuler/yeni/page.tsx`, `yeni-menu-istemcisi.tsx`; `app/sunucu/yonetici/isletmeler/route.ts`
- Modify: `app/yonetici/isletmeler/page.tsx` (yeni işletme linki eklenir)

**Bağlam:** Admin, `/admin/businesses` liste sayfasından "Yeni İşletme" ve her işletme için "Menü Ekle" akışlarına sahip; yönetici tarafında bu akışlar hiç yok (sadece liste var). Backing API route'ları da (`/api/admin/businesses` POST, `/api/admin/businesses/[id]/menus`) yönetici tarafında karşılıksız.

- [ ] **Step 1: Tüm kaynak dosyaları tam oku**

`app/admin/businesses/new/page.tsx`, `new-business-client.tsx`, `app/admin/businesses/[id]/menus/new/page.tsx`, `new-menu-client.tsx`, `app/api/admin/businesses/route.ts` (POST — yeni işletme oluşturma; GET bu task'ta gerekmiyor çünkü yönetici zaten kendi liste sorgusunu server-side yapıyor, sadece POST'u taşı), `app/api/admin/businesses/[id]/menus/route.ts`. Ayrıca `app/yonetici/isletmeler/page.tsx`'i oku (yeni işletme linkinin ekleneceği yer).

- [ ] **Step 2: `/sunucu/yonetici/isletmeler` POST route'unu oluştur**

`app/api/admin/businesses/route.ts`'in POST handler'ının Türkçe portu (`app/sunucu/yonetici/isletmeler/route.ts`): aynı zod şeması, aynı admin-rol kontrolü (`ADMIN_ROLES`), aynı rate limit, aynı slug oluşturma mantığı, aynı `logAudit` çağrısı. Import path'lerini Türkçe konvansiyona çevir (`@/src/lib/supabase/server` → `@/src/lib/taban-sunucu`, `@/src/lib/supabase/service` → `@/src/lib/taban/hizmet`, vb. — diğer `app/sunucu/yonetici/**` route'larından referans al).

- [ ] **Step 3: `/sunucu/yonetici/isletmeler/[id]/menuler` route'unu oluştur**

`app/api/admin/businesses/[id]/menus/route.ts`'in aynı şekilde Türkçe portu.

- [ ] **Step 4: `app/yonetici/isletmeler/yeni/page.tsx` + istemci component'i oluştur**

`admin/businesses/new/page.tsx` + `new-business-client.tsx`'in Türkçe portu, yeni oluşturulan `/sunucu/yonetici/isletmeler` endpoint'ine POST eden bir form. Component adı `YeniIsletmeIstemcisi`, dosya `yeni-isletme-istemcisi.tsx`.

- [ ] **Step 5: `app/yonetici/isletmeler/[id]/menuler/yeni/page.tsx` + istemci component'i oluştur**

Aynı şekilde `admin/businesses/[id]/menus/new/**`'in portu.

- [ ] **Step 6: `app/yonetici/isletmeler/page.tsx`'e "Yeni İşletme" linkini ekle**

Liste sayfasının header'ına, admin'in kendi listesinde (varsa) benzer bir buton olup olmadığını `admin/businesses/page.tsx`'ten kontrol ederek, `/yonetici/isletmeler/yeni`'ye giden bir `PanelActionButton` ekle.

- [ ] **Step 7: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 8: Commit**

```bash
git add app/yonetici/isletmeler app/sunucu/yonetici/isletmeler
git commit -m "feat(web): işletme ve menü oluşturma akışları yönetici paneline taşındı"
```

---

### Task 3: Toplu İşlemler nav linkini ekle

**Files:**
- Modify: `src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`

**Bağlam:** `app/yonetici/toplu-islemler/page.tsx` gerçek ve çalışan bir sayfa (483 satır, redirect/stub değil) ama nav'da hiç linki yok.

- [ ] **Step 1: `app/yonetici/toplu-islemler/page.tsx`'i kısaca oku**

Sayfanın ne yaptığını (başlık, amaç) anla, uygun bir nav etiketi ve ikon seç.

- [ ] **Step 2: Nav'a ekle**

`src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`'teki uygun bölüme (muhtemelen "Operasyon" veya "Güvenlik/Sistem" — mevcut bölüm yapısına bak) `{ href: '/yonetici/toplu-islemler', label: 'Toplu İşlemler', icon: <...Icon /> }` satırını ekle. Gerekirse yeni bir ikon component'i tanımla (dosyanın sonundaki mevcut ikon fonksiyonlarının yanına).

- [ ] **Step 3: Typecheck**

Run: `npm run typecheck`
Expected: Hata yok.

- [ ] **Step 4: Commit**

```bash
git add src/ui/kabuk/yonetici-kabuk-istemcisi.tsx
git commit -m "fix(web): toplu işlemler sayfası yönetici nav'ına eklendi"
```

---

### Task 4: Ölü/stub route taraması

**Files:** (değişiklik yok, sadece doğrulama — bulgu varsa ek adım)

**Bağlam:** Owner/sahip'te 5 tane tamamen ölü stub route (crm/sponsorluk/finansal/envanter/siparisler) bulunmuştu. Admin/yönetici denetiminde `b2b-exports`/`b2b-dis-aktarim` simetrik kasıtlı stub olarak doğrulandı (silinmeyecek), ama başka gözden kaçan ölü route olup olmadığı teyit edilmedi.

- [ ] **Step 1: Her admin ve yönetici sayfasının gerçek içerik içerdiğini tara**

```bash
cd uygulamalar/web
grep -L "\.rpc(\|\.from(\|redirect(" app/admin/*/page.tsx app/yonetici/*/page.tsx
```

Bu, ne RPC/tablo sorgusu ne de redirect içeren (yani muhtemelen boş/placeholder) sayfaları listeler. Bulunan her sayfayı aç ve gerçekten boş/placeholder mu yoksa client component'e mi delege ediyor kontrol et.

- [ ] **Step 2: Bulgu varsa raporla, silme kararını kullanıcıya bırak**

Eğer gerçekten ölü/placeholder bir sayfa bulunursa, onu SİLME — sadece raporunda belirt (bu plan bunu öngörmüyor, kapsam dışı bir bulgu olur, ayrı değerlendirilmeli).

- [ ] **Step 3: Commit gerekmiyorsa atla**

Bu task'ta kod değişikliği beklenmiyor — sadece doğrulama. Değişiklik yapılmadıysa commit atma.

---

### Task 5: `next.config.mjs`'e redirect'leri ekle

**Files:**
- Modify: `next.config.mjs`

- [ ] **Step 1: Mevcut `redirects()` array'ini oku**

`next.config.mjs`'in tam içeriğini oku. Şu an hiç `/admin` veya `/yonetici` redirect'i yok — yeni blok array'in sonuna eklenecek.

- [ ] **Step 2: Admin→yönetici redirect'lerini ekle**

Admin'in 32 bölümünün her biri için `/admin/X → /yonetici/Y` redirect'i ekle (aşağıdaki eşleştirme tablosunu kullan — bu tablo denetimde doğrulanmıştır):

```js
      // Admin paneli Türkçeleştirme — eski İngilizce path'lerden yenilerine
      { source: '/admin', destination: '/yonetici', permanent: true },
      { source: '/admin/dashboard', destination: '/yonetici/gosterge-panosu', permanent: true },
      { source: '/admin/analytics', destination: '/yonetici/analitik', permanent: true },
      { source: '/admin/appeals', destination: '/yonetici/itirazlar', permanent: true },
      { source: '/admin/audit', destination: '/yonetici/denetim-kaydi', permanent: true },
      { source: '/admin/b2b-exports', destination: '/yonetici/b2b-dis-aktarim', permanent: true },
      { source: '/admin/business-submissions', destination: '/yonetici/isletme-basvurulari', permanent: true },
      { source: '/admin/businesses', destination: '/yonetici/isletmeler', permanent: true },
      { source: '/admin/businesses/new', destination: '/yonetici/isletmeler/yeni', permanent: true },
      { source: '/admin/businesses/:id/menus/new', destination: '/yonetici/isletmeler/:id/menuler/yeni', permanent: true },
      { source: '/admin/chains', destination: '/yonetici/zincirler', permanent: true },
      { source: '/admin/chains/:id', destination: '/yonetici/zincirler/:id', permanent: true },
      { source: '/admin/claims', destination: '/yonetici/itirazlar/claims', permanent: true },
      { source: '/admin/dev-tools', destination: '/yonetici/gelistirme-araclari', permanent: true },
      { source: '/admin/group-requests', destination: '/yonetici/grup-istekleri', permanent: true },
      { source: '/admin/growth', destination: '/yonetici/buyume', permanent: true },
      { source: '/admin/incidents', destination: '/yonetici/olaylar', permanent: true },
      { source: '/admin/locations', destination: '/yonetici/konumlar', permanent: true },
      { source: '/admin/observability', destination: '/yonetici/gozlemlenebilirlik', permanent: true },
      { source: '/admin/price-suggestions', destination: '/yonetici/fiyat-onerileri', permanent: true },
      { source: '/admin/queue', destination: '/yonetici/kuyruk', permanent: true },
      { source: '/admin/receipt-submissions', destination: '/yonetici/fis-basvurulari', permanent: true },
      { source: '/admin/reports', destination: '/yonetici/raporlar', permanent: true },
      { source: '/admin/reviews', destination: '/yonetici/yorumlar', permanent: true },
      { source: '/admin/roles', destination: '/yonetici/roller', permanent: true },
      { source: '/admin/search', destination: '/yonetici/arama', permanent: true },
      { source: '/admin/sponsorship-leads', destination: '/yonetici/sponsor-adaylari', permanent: true },
      { source: '/admin/sponsorship-packages', destination: '/yonetici/sponsor-paketleri', permanent: true },
      { source: '/admin/sponsorships', destination: '/yonetici/sponsorluklar', permanent: true },
      { source: '/admin/suggestions', destination: '/yonetici/oneriler', permanent: true },
      { source: '/admin/suspended', destination: '/yonetici/askiya-alinanlar', permanent: true },
      { source: '/admin/table-feedback', destination: '/yonetici/masa-geri-bildirimleri', permanent: true },
      { source: '/admin/temp-uploads', destination: '/yonetici/gecici-yuklemeler', permanent: true },
      { source: '/admin/trash', destination: '/yonetici/cop-kutusu', permanent: true },
      { source: '/admin/users', destination: '/yonetici/kullanicilar', permanent: true },
      { source: '/admin/verified', destination: '/yonetici/isletmeler?status=verified', permanent: true },
```

- [ ] **Step 3: Build ile redirect syntax'ını doğrula**

Run: `npm run build`
Expected: Build hatasız tamamlanır.

- [ ] **Step 4: Manuel redirect testi**

`npm run dev` başlat (arka planda), `curl -s -D - -o /dev/null http://localhost:3000/admin/dashboard` gibi en az 3 eski URL'yi dene, her birinin doğru `/yonetici/...`'ye 308 döndürdüğünü doğrula. Dev server'ı durdur.

- [ ] **Step 5: Commit**

```bash
git add next.config.mjs
git commit -m "feat(web): eski /admin/* path'lerinden yeni /yonetici/* path'lerine kalıcı redirect eklendi"
```

---

### Task 6: `app/admin`'i tamamen sil, middleware'i sadeleştir + subdomain rewrite düzelt

**Files:**
- Delete: `app/admin/**`, `app/api/admin/**`
- Modify: `middleware.ts`

**⚠️ Riskli adım:** Bu task'ın son adımı canlı `ops.yeedoy.com` subdomain trafiğinin hedefini değiştiriyor. Dikkatli test şart.

- [ ] **Step 1: Her admin dosyasını son bir kez bağımsız doğrula**

```bash
cd uygulamalar/web
find app/admin -type f
```

Her dosya için — güvenip geçme, gerçekten kontrol et — şunlardan birine net şekilde girdiğini doğrula:
(a) gerçek, çalışan bir `/yonetici` karşılığı var (Task 1-3'te taşınanlar dahil — bu üç task'ın gerçekten commit edildiğini doğrula),
(b) kasıtlı, belgeli bir MVP-scope-dışı stub (`b2b-exports` gibi — iki tarafta da aynı doküman referansı olmalı),
(c) kanıtlanmış ölü/erişilemez kod (`next.config.mjs`'teki bir redirect zaten önce devreye giriyor).

**Herhangi bir dosya bu üç kategoriden birine net girmiyorsa DUR, silme, ne bulduğunu raporla.** Task 1-3'te taşınan `chains`/`businesses/new`/`businesses/[id]/menus/new`'in gerçekten yönetici tarafında çalışır durumda olduğunu özellikle doğrula (dosyaların var olduğunu görmek yetmez, içeriğin gerçek olduğunu oku).

- [ ] **Step 2: `app/admin`'i sil**

```bash
git rm -r app/admin
```

- [ ] **Step 3: `app/api/admin`'i kontrol et ve sil**

```bash
find app/api/admin -type f
grep -rn "/api/admin/" app/yonetici
```

`businesses` ve `businesses/[id]/menus` route'larının Task 2'de `/sunucu/yonetici`'ye taşındığını (artık hiçbir yerden `/api/admin/...` çağrılmadığını) doğrula. `b2b-export`, `claims`, `moderation` route'larının da (denetimde doğrulanan) `/sunucu/yonetici` karşılıklarının olduğunu veya gerçekten kullanılmadığını (b2b-export) teyit et. Temizse:

```bash
git rm -r app/api/admin
```

- [ ] **Step 4: `middleware.ts`'i sadeleştir — guard mantığı**

`middleware.ts` içinde:
- `const ADMIN_PREFIX = '/admin';` satırını sil.
- `guardPanelRoute` içindeki `isAdminRoute` hesaplamasını sadeleştir:
  ```ts
  const isAdminRoute = pathname.startsWith(YONETICI_PREFIX);
  ```

- [ ] **Step 5: `middleware.ts`'i sadeleştir — subdomain rewrite (⚠️ production-impacting)**

`rewriteSubdomainPanel` fonksiyonundaki:
```ts
  const prefix = isOwnerHost ? '/sahip' : '/admin';
```
satırını:
```ts
  const prefix = isOwnerHost ? '/sahip' : '/yonetici';
```
yap. Bu satır `ops.yeedoy.com` subdomain'inin gerçekte nereye rewrite edildiğini kontrol ediyor — `app/admin` silindiği için bu değişiklik zorunlu, aksi halde subdomain 404 verir.

- [ ] **Step 6: Typecheck + lint + build**

Run: `npm run typecheck && npm run lint && npm run build`
Expected: Hepsi hatasız (veya sadece bilinen pre-existing lint hataları) geçer.

- [ ] **Step 7: Repo genelinde kalan `/admin/` referans taraması**

```bash
grep -rn "'/admin/\|\"/admin/\|\`/admin/\|/api/admin/" app src middleware.ts next.config.mjs --include="*.ts" --include="*.tsx" --include="*.mjs"
```

Expected: Sadece `next.config.mjs`'teki kasıtlı redirect kaynak path'leri. Başka bir şey bulunursa araştır, görmezden gelme. (`app/robots.ts`'in `/admin/` disallow girişi ve varsa benzer JSDoc yorumları — owner/sahip'te olduğu gibi — düşük öncelikli, bloklamaz ama raporunda not et.)

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore(web): eski /admin ağacı tamamen kaldırıldı, middleware ve subdomain rewrite yönetici'ye göre sadeleştirildi

Canlı ops.yeedoy.com subdomain rewrite'ı artık /admin yerine /yonetici'ye
rewrite ediyor. Bu, app/admin'ın tamamen silinmesiyle birlikte gereken
bir değişiklik - aksi halde subdomain 404 verirdi."
```

---

### Task 7: Final doğrulama

**Files:** (değişiklik yok, sadece doğrulama)

- [ ] **Step 1: Tam otomatik doğrulama paketi**

Run: `npm run typecheck && npm run lint && npm run test:unit && npm run build`
Expected: Hepsi başarılı (bilinen pre-existing lint hataları hariç).

- [ ] **Step 2: Manuel yönetici akışı — kod okuma simülasyonu (owner/sahip Task 11'deki yöntemle aynı)**

Tarayıcı yerine kod okuyarak doğrula: `/yonetici`'ye girişsiz erişim → guard davranışı; giriş sonrası `/yonetici/gosterge-panosu`; nav'daki her linkin (`yonetici-kabuk-istemcisi.tsx`) gerçek bir `page.tsx`'e gittiğini mekanik olarak doğrula (her href'i listele, her birinin dosya olarak var olduğunu kontrol et); Task 1-3'te eklenen 3 özelliğin (zincirler, işletme/menü oluşturma, toplu işlemler) gerçekten çalışır göründüğünü (stub değil) teyit et.

- [ ] **Step 3: Redirect doğrulaması**

En az 5 eski `/admin/...` URL'sini (Task 5 Step 4'te test edilenlerden farklı) dene, doğru `/yonetici/...`'ye düştüğünü doğrula.

- [ ] **Step 4: Kalan referans taraması**

```bash
cd uygulamalar/web
grep -rn "/admin/\|app/admin\b" app src middleware.ts next.config.mjs --include="*.ts" --include="*.tsx" --include="*.mjs"
```

Expected: Sonuç boş olmalı (redirect kaynak path'leri hariç).

- [ ] **Step 5: Final commit (varsa küçük düzeltmeler)**

Eğer Step 1-4'te herhangi bir düzeltme yapıldıysa:

```bash
git add -A
git commit -m "fix(web): admin-yönetici türkçeleştirme tamamlama final doğrulama düzeltmeleri"
```
