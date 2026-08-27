# Ana Sayfa + İşletme Detay Sayfaları Performans Araştırması — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unlighthouse taramasında bulunan düşük Lighthouse performans skorlarının (ana sayfa 60/100, işletme detay sayfaları 52-60/100) kök nedenini kesinleştirip düşük riskli, ölçülebilir bir düzeltme uygulamak.

**Architecture:** Önce gerçek tarayıcıda profil çıkarıp (Chrome DevTools Performance trace) 999ms'lik "Unattributable" long task'ı kaynağına kadar takip et; paralel olarak `ANALYZE=true` bundle analyzer ile paylaşılan 566KB'lık Turbopack chunk'ının (Sentry SDK + Next.js runtime karışık) tam kompozisyonunu çıkar. Bulgulara göre en yüksek etkili tek düzeltmeyi uygula, sonra Lighthouse ile önce/sonra karşılaştır.

**Tech Stack:** Chrome DevTools (Performance panel / `--trace-startup` ya da `mcp__claude-in-chrome`), `@next/bundle-analyzer` (zaten `next.config.mjs`'te kurulu, `ANALYZE=true pnpm run build` ile tetiklenir), `lighthouse` CLI veya Unlighthouse.

---

## Bağlam — Bu Oturumda Doğrulanmış Bulgular

- Ana sayfa Lighthouse performans skoru: 60/100. LCP 4.4sn (skor 0.38), TBT 930ms (skor 0.3).
- Ana iş parçacığında **999ms'lik tek bir "Unattributable" long task** (~1.4sn'de başlıyor) — TBT'nin neredeyse tamamı bu tek görevden geliyor.
- Sayfa 22 script isteği, 383KB JS transfer ediyor (Lighthouse taraması anındaki chunk hash'lerine göre); en büyük paylaşılan chunk'ın (bugün `0rhpp_50ngcxa.js`, 566KB ham boyut) içeriği incelendi — Next.js runtime + Sentry SDK (sentry-trace, captureException, Replay/rrweb, BrowserTracing izleri) karışık halde tek dosyada.
- `instrumentation-client.ts` kontrol edildi: önceki oturumda yapılan Sentry erteleme (Replay `requestIdleCallback` ile, `tracesSampleRate: 0.2`) hâlâ yerinde — bu chunk'ın büyüklüğü Session Replay'in eager yüklenmesinden KAYNAKLANMIYOR, temel SDK + runtime'ın kendisi büyük.
- İşletme detay sayfaları (`/isletme/mavi-d-ner-mehmet-usta`: 60, `/isletme/ekmek-teknesi-unlu-mam-lleri`: 52) aynı düşük performans desenini gösteriyor — muhtemelen aynı paylaşılan chunk + kendi veri-ağırlıklı içerikleri.
- `next.config.mjs`'te `withBundleAnalyzer` zaten kurulu (`ANALYZE=true` ile tetiklenir) — sıfırdan kurulum gerekmiyor.

---

### Task 1: Gerçek tarayıcıda 999ms long task'ı profille

**Files:** Yok (sadece tarayıcı profilleme, kod değişikliği yok)

- [ ] **Step 1: Production ana sayfasında Performance trace kaydet**

Chrome DevTools ile (`mcp__claude-in-chrome__javascript_tool` veya elle):
```
1. https://www.yeedoy.com/ adresine git (temiz profil, cache devre dışı)
2. DevTools > Performance > kayıt başlat > sayfayı yenile > ~5sn sonra durdur
3. "Main" thread track'inde en uzun (kırmızı üçgenli) task'ı bul
4. Call tree / Bottom-Up'ta o task'ın en üstteki (self time en yüksek) fonksiyonunu not al
```

- [ ] **Step 2: Bulunan fonksiyon/bileşeni kaynak koda bağla**

Trace'te görünen dosya adı + satır numarasını (source-mapped ise) `uygulamalar/web` içinde `grep`/`Grep` ile bul. Eğer minified/isimsiz çıkarsa, React DevTools Profiler ile aynı sayfayı ayrıca profille (hangi component'in commit/render süresi en yüksek) ve çapraz doğrula.

- [ ] **Step 3: Bulguyu not al**

Sonucu bu planın altına (Bulgular bölümüne) bir cümleyle ekle: "999ms'lik görev X bileşeninin Y işleminden kaynaklanıyor" — sonraki task bu bulguya göre şekillenecek.

---

### Task 2: Paylaşılan bundle'ın tam kompozisyonunu çıkar

**Files:** Yok (analiz), çıktı: `uygulamalar/web/.next/analyze/*.html`

- [ ] **Step 1: Bundle analyzer'ı çalıştır**

```bash
cd uygulamalar/web
ANALYZE=true pnpm run build
```

- [ ] **Step 2: `client.html` çıktısını aç, en büyük 5 modülü listele**

`.next/analyze/client.html` tarayıcıda açılır (treemap). En büyük 5 modül/paketi (gerçek npm paket adlarıyla) not al — özellikle `@sentry/*` alt modüllerinin toplam payını ve Next.js runtime'ın kendi payını ayır.

- [ ] **Step 3: Task 1 ve Task 2 bulgularını karşılaştır**

İkisi aynı şeye mi işaret ediyor (ör. Sentry init'in kendisi mi ağır, yoksa homepage'e özgü bir client component mi) yoksa farklı iki sorun mu var, netleştir.

---

### Task 3: En yüksek etkili düzeltmeyi uygula

**Files:** Task 1-2 bulgusuna göre değişir — muhtemel adaylar:
- `uygulamalar/web/instrumentation-client.ts` (Sentry init'i daha da geciktirmek/küçültmek)
- `uygulamalar/web/app/page.tsx` + `uygulamalar/web/src/ui/acik/*.tsx` (ana sayfaya özgü ağır bir client component varsa `next/dynamic` ile lazy-load)

- [ ] **Step 1: Bulguya göre TEK bir değişiklik yap**

Task 1-2'de netleşen kök nedene göre en düşük riskli, en yüksek etkili tek değişikliği uygula (ör. Sentry'nin `tracesSampleRate`'ini daha da düşürmek yerine `Sentry.init`'in kendisini `requestIdleCallback`'e almak, ya da ağır bir client component'i `dynamic(() => import(...), { ssr: false })` ile ertelemek). Placeholder yok — bulguya göre gerçek kod satırı yazılacak.

- [ ] **Step 2: Yerel doğrulama**

```bash
cd uygulamalar/web
pnpm run typecheck
pnpm run lint
```

- [ ] **Step 3: Commit**

```bash
git add <değişen dosyalar>
git commit -m "perf(web): <bulunan kök nedene göre kısa açıklama>"
```

---

### Task 4: Önce/sonra karşılaştırması

**Files:** Yok

- [ ] **Step 1: Deploy sonrası tek sayfalık Lighthouse çalıştır**

```bash
npx --yes lighthouse https://www.yeedoy.com/ --output=json --output-path=./lighthouse-after.json --chrome-flags="--headless=new"
```

- [ ] **Step 2: Performans skorunu ve TBT/LCP'yi bu oturumun başındaki değerlerle (60/100, LCP 4.4sn, TBT 930ms) karşılaştır**

İyileşme yoksa Task 1'e geri dön — kök neden yanlış tespit edilmiş olabilir.

---

## Notlar

- Bu plan, **görsel format/AVIF/canonical/erişilebilirlik** bulgularını KAPSAMAZ — onlar zaten bu oturumda düzeltilip production'a deploy edildi.
- `/m/[slug]` sayfasının menüsüz işletmelerde sonsuz loading skeleton'da takılı kalma bug'ı da bu planın KAPSAMI DIŞINDA — o ayrı, fonksiyonel bir bug (performans değil), ayrı bir plan gerektirir.
