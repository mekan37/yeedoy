# CSP style-src Sertleştirme + price_level Backfill — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** İki bağımsız, önceki oturumlarda bilerek kapsam dışı bırakılmış maddeyi kapatmak: (1) `proxy.ts`'teki CSP `style-src`'den `'unsafe-inline'`'ı kaldırmak (291 satır inline `style={{...}}` kullanımı, 118 dosya), (2) `businesses.price_level` kolonunu gerçek verilerle doldurmak (şu an tüm satırlarda NULL, `PriceLevelBadge` bu yüzden hiçbir yerde görünmüyor).

**Architecture:** style-src işi önce bir AUDIT (291 kullanımı kategorilere ayırma) ile başlıyor, çünkü bazıları (örn. `opengraph-image.tsx`) tarayıcı CSP'sinden muaf (Next.js `next/og` satori render'ı), bazıları saf statik (doğrudan Tailwind class'ına çevrilebilir), bazıları gerçekten dinamik (yüzde/renk — CSS custom property + statik class gerektirir). price_level işi ise zaten var olan `batch_recompute_price_levels_v1` RPC'sini şehir bazında parçalı çağırmaktan ibaret.

**Tech Stack:** Next.js CSP nonce mekanizması (`proxy.ts`, script-src'de zaten kurulu), Tailwind CSS custom property pattern (`style={{'--x': val}}` + `class="[width:var(--x)]"` veya statik utility class), Supabase RPC (`batch_recompute_price_levels_v1`, zaten var).

---

## Bölüm A — CSP style-src Sertleştirme

### Bağlam — Doğrulanmış Bulgular

- `uygulamalar/web/proxy.ts:24`: `"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com"`.
- Kod tabanında tam **291** adet `style={{` kullanımı, **118** dosyada (`grep -rn "style={{" uygulamalar/web/src uygulamalar/web/app | wc -l` ile doğrulandı).
- Bazı kullanımlar tarayıcı CSP'sinden **muaf**: `app/(genel)/isletme/[slug]/opengraph-image.tsx` gibi `next/og` `ImageResponse` dosyaları satori ile sunucu tarafında PNG'ye render ediliyor, hiç HTML/CSP'ye tabi değil — bunlar audit'te ELENMELİ, dokunulmamalı.
- Örnek kalıplar: tamamen statik (`style={{ background: 'var(--yd-gradient-primary)' }}` → doğrudan class'a çevrilebilir), yarı-statik (`style={{ margin:'0 0 12px', fontSize:12, ... }}` → Tailwind class'larına çevrilebilir), gerçekten dinamik (`style={{ width: \`${percent}%\` }}`, `style={{ background: renk }}` → CSS custom property gerektirir, `'unsafe-inline'` kaldırıldığında `style=""` attribute'u CSP'nin `style-src` kısıtına hâlâ tabidir; nonce SADECE `<style>` blok elementlerine uygulanır, `style=""` attribute'una uygulanamaz — bu yüzden dinamik değerler CSS custom property (`style={{'--w': val}}`) + değeri tüketen statik bir class (`className="w-[var(--w)]"` ya da düz CSS'te `width: var(--w)`) ile çözülmeli).

### Task A1: 291 kullanımı kategorilere ayır

**Files:** Yok (sadece analiz), çıktı: bu planın altına eklenecek bir liste

- [ ] **Step 1: Tam listeyi çıkar ve dosya bazında grupla**

```bash
cd uygulamalar/web
grep -rn "style={{" src app > /tmp/style-inline-audit.txt
wc -l /tmp/style-inline-audit.txt
cut -d: -f1 /tmp/style-inline-audit.txt | sort | uniq -c | sort -rn
```

- [ ] **Step 2: `next/og`/`ImageResponse` dosyalarını ele**

```bash
grep -rl "ImageResponse" uygulamalar/web/app | grep -f - /tmp/style-inline-audit.txt -F
```

Bu dosyalardaki (`opengraph-image.tsx`, varsa `twitter-image.tsx`) kullanımları audit'ten çıkar — dokunulmayacak.

- [ ] **Step 3: Kalan kullanımları üç gruba ayır (elle, dosya dosya gözden geçirerek)**

- Grup 1 — Statik (JS değişkeni yok, sabit değer): doğrudan Tailwind class'ına taşınabilir.
- Grup 2 — Yarı-statik (birden fazla sabit CSS özelliği tek `style` objesinde): Tailwind class demetine çevrilebilir.
- Grup 3 — Gerçek dinamik (JS değişkeni/hesaplama içeriyor: yüzde, renk kodu, hesaplanan boyut): CSS custom property gerektirir.

Bu üç grubun dosya/satır listesini bu planın "Bulgular" bölümüne ekle (Task A2-A4'ün kapsamını netleştirir).

### Task A2: Grup 1 + 2 (statik/yarı-statik) — Tailwind class'ına çevir

**Files:** Task A1'de belirlenen dosyalar (örnek: `src/ui/acik/harita-istemcisi.tsx`, `app/yonetici/*/page.tsx` içindeki `style={{ background: 'var(--yd-gradient-primary)' }}` gibi sabit kullanımlar)

- [ ] **Step 1: Her dosyada `style={{...}}`'i eşdeğer Tailwind class'ıyla değiştir**

Örnek dönüşüm (`src/ui/acik/eylem-istemcisi.tsx:119`):
```tsx
// Önce
<div style={{ background: 'var(--yd-gradient-primary)' }} />
// Sonra
<div className="bg-[image:var(--yd-gradient-primary)]" />
```

- [ ] **Step 2: Her dosya değişikliğinden sonra görsel regresyon kontrolü**

`pnpm run dev` ile ilgili sayfayı aç, class değişikliğinin görsel olarak birebir aynı sonucu verdiğini doğrula (özellikle `harita-istemcisi.tsx` gibi harita bileşenlerinde — bunlar Tailwind class'ı çalışmayan bir 3. parti kütüphane DOM'una inline stil basıyor olabilir, bu durumda o dosya Grup 3'e taşınmalı).

### Task A3: Grup 3 (gerçek dinamik) — CSS custom property'ye taşı

**Files:** Task A1'de belirlenen dosyalar (örnek: `app/yonetici/fiyat-onerileri/fiyat-oneri-satiri.tsx:41`, `*/page.tsx` içindeki `style={{ background: renk }}` kullanımları)

- [ ] **Step 1: Dinamik değeri CSS custom property'ye taşı**

Örnek dönüşüm (`app/yonetici/fiyat-onerileri/fiyat-oneri-satiri.tsx:41`):
```tsx
// Önce
<div className="h-full bg-primary" style={{ width: `${Math.round((row.qualityConfidence ?? 0) * 100)}%` }} />
// Sonra
<div className="h-full bg-primary [width:var(--yd-w)]" style={{ '--yd-w': `${Math.round((row.qualityConfidence ?? 0) * 100)}%` } as React.CSSProperties} />
```

`background: renk` gibi renk kullanımları için aynı desen: `style={{ '--yd-bg': renk }}` + `className="[background:var(--yd-bg)]"`.

- [ ] **Step 2: `harita-istemcisi.tsx` özel durumu**

Harita bileşeni muhtemelen bir 3. parti kütüphanenin (maplibre/leaflet) kendi DOM elementlerine stil basıyor olabilir — bu durumda o kütüphanenin kendi CSP gereksinimlerini kontrol et (bazı harita kütüphaneleri kendi inline stillerini üretir, bunlar bizim kontrolümüz dışında olabilir; gerekirse bu dosyayı `style-src`'ye eklenecek bir `'unsafe-hashes'` istisnası ya da ayrı bir `<style nonce>` bloğuna taşımayı değerlendir).

### Task A4: CSP header'ı sertleştir

**Files:** `uygulamalar/web/proxy.ts:24`

- [ ] **Step 1: `'unsafe-inline'`'ı kaldır**

```ts
// Önce
"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
// Sonra
"style-src 'self' https://fonts.googleapis.com",
```

- [ ] **Step 2: Tam site taraması — konsol hatası kontrolü**

`pnpm run dev` ile ana sayfa, kesif, isletme detay, harita, yonetici ve sahip panellerini gerçek tarayıcıda gez (`mcp__claude-in-chrome` ile), her sayfada `read_console_messages` ile CSP ihlali (`Refused to apply inline style...`) hatası olmadığını doğrula.

- [ ] **Step 3: Commit + deploy + production doğrulama**

```bash
cd uygulamalar/web && pnpm run typecheck && pnpm run lint
git add proxy.ts src app
git commit -m "fix(web): CSP style-src'den unsafe-inline kaldırıldı — 291 inline style Tailwind/CSS custom property'ye taşındı"
git push origin main
```

Deploy sonrası SecurityHeaders.com / MDN HTTP Observatory ile yeniden tara, puan artışını doğrula.

---

## Bölüm B — price_level Backfill

### Bağlam — Doğrulanmış Bulgular

- `businesses.price_level` kolonu tüm satırlarda NULL (önceki oturumda tespit edildi, bilerek ertelendi).
- Hesaplama RPC'si zaten var: `public.batch_recompute_price_levels_v1(p_city text DEFAULT NULL, p_category text DEFAULT NULL) RETURNS TABLE(updated int, set_null int)` (`supabase/migrations/20260603000002_compute_price_level_rpc.sql:134`). Sadece `service_role` veya admin çalıştırabilir.
- **Yeni bulgu:** `PriceLevelBadge` bileşeni de aynı `price_level` alanını okuyor — yani bu rozet (₺/₺₺/₺₺₺) şu an sitenin hiçbir yerinde görünmüyor. Bu backfill'den sonra otomatik olarak görünür hale gelecek, ayrı bir kod değişikliği gerekmiyor.
- Risk düşük: alan zaten NULL, dolduruluyor olması hiçbir mevcut davranışı bozmaz (sadece rozetin görünür olmasını sağlar).

### Task B1: Küçük bir örneklemde dry-run

**Files:** Yok (SQL çağrısı)

- [ ] **Step 1: Tek bir şehir için çalıştır, sonucu gözle**

```sql
select * from public.batch_recompute_price_levels_v1(p_city := 'Adana');
```

`updated`/`set_null` sayılarının mantıklı olduğunu doğrula (ör. menüsü olmayan işletmeler `set_null` sonucu verir — bu beklenen, çünkü fiyat hesaplanacak veri yok).

- [ ] **Step 2: O şehirden 2-3 işletmenin `/isletme/[slug]` sayfasında `PriceLevelBadge`'in gerçekten göründüğünü doğrula**

Tarayıcıda (`mcp__claude-in-chrome`) ilgili işletme sayfalarını aç, ₺ rozetinin render olduğunu teyit et.

### Task B2: Tüm şehirler için sırayla çalıştır

**Files:** Yok (SQL çağrısı, script)

- [ ] **Step 1: Şehir listesini çıkar, her biri için RPC'yi çağır**

```sql
select distinct city from public.businesses where is_active = true and city is not null order by city;
```

Her şehir için ayrı ayrı çağır (tek seferde 42K+ işletmeyi tek transaction'da işlemek yerine, olası uzun-çalışma/timeout riskini azaltmak için):

```sql
select * from public.batch_recompute_price_levels_v1(p_city := '<şehir>');
```

- [ ] **Step 2: Toplam `updated`/`set_null` sayılarını topla, rapor et**

Beklenen: `updated` sayısı gerçek menüsü/fiyat verisi olan işletme sayısına yakın olmalı (bu oturumda menü verisi olan işletme sayısı çok düşük bulunmuştu — `menus` tablosunda sadece birkaç kayıt — bu yüzden `set_null` sayısının `updated`'dan çok daha yüksek çıkması BEKLENEN bir sonuç, hata değil).

### Task B3: Sonucu doğrula, periyodik çalıştırma ihtiyacını değerlendir

**Files:** Yok

- [ ] **Step 1: Birkaç gerçek menüsü olan işletmenin fiyat rozetini production'da kontrol et**

- [ ] **Step 2: Bu RPC'nin ileride otomatik (cron/pg_cron) çalıştırılıp çalıştırılmayacağına karar ver**

Şu an sadece tek seferlik bir backfill mi, yoksa yeni menü/fiyat eklendiğinde periyodik olarak mı yeniden hesaplanmalı — kullanıcıyla netleştirilmeli. Eğer periyodik gerekiyorsa, `pg_cron` job'ı olarak eklenmesi ayrı bir küçük görev (mevcut `pg_cron` job'larının listesi için `supabase/migrations` içinde `cron.schedule` araması yapılabilir).

---

## Notlar

- Bölüm A ve B tamamen bağımsız — istenirse ayrı ayrı, farklı sıralarda uygulanabilir.
- Bölüm A, kapsamı itibarıyla (118 dosya) bu oturumdaki diğer düzeltmelerden daha büyük ve daha yüksek riskli — her adımda gerçek tarayıcı doğrulaması şart.

## Sonuç (2026-08-27'de uygulandı)

**Bölüm A — style-src:** Tam mekanik dönüşüm yerine `style-src`, `style-src-elem` (sıkı, `'self'` + fonts) ve `style-src-attr` (`'unsafe-inline'` bilerek bırakıldı) olarak ikiye ayrıldı — çünkü CSP nonce'u `style=""` HTML özniteliğine hiç uygulanamıyor (spec kısıtı), bu yüzden dinamik değerler için tam eleme pratik değil. `harita-istemcisi.tsx`'teki 2 inline `<style>` bloğu (tek gerçek `style-src-elem` ihlali kaynağı, kod tabanında başka yok) kaldırıldı, ~30 statik/sonlu-varyantlı kullanım da Tailwind class'ına taşındı. Kalan ~230 `style={{}}` kullanımına dokunulmadı — artık gerekli değil.

**Bölüm B — price_level backfill:** `batch_recompute_price_levels_v1()` tüm işletmeler için tek seferde çalıştırıldı (37 şehire ayrı ayrı gerek kalmadı, timeout olmadı). **Sonuç: `updated: 0, set_null: 41998`** — sistemde HİÇBİR işletme price_level almadı. Kök neden bug değil, veri: fonksiyon aynı şehir+kategori grubunda en az 3 farklı işletmenin her birinin en az 3 fiyatlı menü ürününe sahip olmasını şart koşuyor; sistemde gerçek menü verisi olan tek işletme (`ornek-yeedoy`) bile bu "3 peer işletme" şartını sağlayamıyor. **`PriceLevelBadge` gerçek menü/fiyat verisi birden fazla işletmede birikene kadar hiçbir yerde görünmeyecek** — bu, daha fazla işletmenin gerçek menü eklemesini bekleyen bir veri olgunluğu meselesi, kod değişikliğiyle çözülemez.
