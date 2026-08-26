# CSP script-src Nonce Sertleştirmesi — Tasarım Dokümanı

## Kök Neden ve Motivasyon

İki bağımsız güvenlik tarama aracı (SecurityHeaders.com — A notu, ve MDN HTTP Observatory — B+/80 puan) aynı bulguyu işaretledi: production CSP'sinin `script-src` yönergesinde `'unsafe-inline'` var. Bu, CSP'nin asıl amacı olan "HTML enjeksiyonu (stored XSS) durumunda inline script çalışmasını engelleme" korumasını devre dışı bırakıyor. Yeedoy canlıda gerçek kullanıcı içeriği (yorumlar, işletme başvuruları, admin/owner panel girdileri) işlediği için bu teorik değil, gerçek bir savunma-katmanı eksikliği.

## Mevcut Durum Analizi

- CSP şu an `uygulamalar/web/next.config.mjs`'nin statik `headers()` fonksiyonunda üretiliyor (build-time sabit, istekten bağımsız).
- `script-src 'self' 'unsafe-inline' https://vercel-scripts.com https://va.vercel-scripts.com` (dev'de ayrıca `'unsafe-eval'`).
- Tek inline script kullanım deseni: **JSON-LD yapılandırılmış veri** (`<script type="application/ld+json" dangerouslySetInnerHTML={{__html: ...}}>`), 8 sayfada: `isletme/[slug]`, `[sehir]/page`, `[sehir]/[slug]/page`, `[sehir]/[slug]/[kategori]/page`, `m/[slug]/page`, `fiyat-endeksi/page`, `b/[slug]/page`.
- Harici `<script src="...">` etiketi kod tabanında yok — Vercel Analytics/Speed Insights platform tarafından otomatik enjekte ediliyor (harici domain, nonce gerektirmiyor), Google Maps/harita npm paketleri (maplibre-gl vb.) üzerinden bundle'a dahil, ayrı bir `<script src>` değil.
- `proxy.ts` (Next.js 16'nın middleware-eşdeğeri) zaten mevcut — subdomain rewrite ve rate-limit mantığı burada.
- `EmbedCSP` (frame-ancestors '*' istisnası) `/embed/:businessId*` rotası için ayrı üretiliyor, korunmalı.
- `style-src`'deki `'unsafe-inline'` **kapsam dışı** — hiçbir tarama aracı bunu puan kırıcı olarak işaretlemedi, Tailwind/inline style kullanımını taramak gereksiz kapsam genişletmesi olur.

## Değerlendirilen Yaklaşım

Tek yaklaşım değerlendirildi ve seçildi (alternatif yok — nonce tabanlı CSP, `unsafe-inline`'ı kaldırmanın Next.js'in resmi desteklediği tek yolu):

**Nonce tabanlı CSP, `proxy.ts` üzerinden üretilir.** Her istekte kriptografik olarak rastgele bir nonce üretilir (`crypto.randomUUID()` tabanlı, base64 kodlanmış). Bu nonce hem `x-nonce` request header'ına (Server Component'lerin `headers()` ile okuması için) hem CSP response header'ındaki `script-src`'ye (`'nonce-{değer}'` olarak, `'unsafe-inline'` yerine) yazılır. Next.js, response'daki CSP header'ından nonce'u otomatik ayrıştırıp kendi hydration/runtime script'lerine uygular — bu, projenin kullandığı Next.js 16.2.11 sürümünde **lokalde bizzat doğrulanacak**, varsayılmayacak.

## Mimari

1. `proxy.ts`'e nonce üretim mantığı eklenir, CSP header'ı (ana + embed varyantı) burada, her istek için dinamik olarak inşa edilir.
2. `next.config.mjs`'nin `headers()` fonksiyonundan `Content-Security-Policy` satırı kaldırılır (diğer statik header'lar — HSTS, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, X-Frame-Options — olduğu gibi kalır).
3. 8 sayfadaki JSON-LD `<script>` etiketi, `headers()` ile okunan nonce'u `nonce={nonce}` prop'u olarak alacak şekilde güncellenir.
4. `style-src` **değiştirilmez** (`'unsafe-inline'` kalır).

## Test Planı

- Lokalde `pnpm run dev`: anasayfa, bir işletme detay sayfası (JSON-LD içeren), bir embed sayfası açılıp tarayıcı konsolunda CSP ihlali olmadığı doğrulanır; CSP header'ındaki nonce değerinin her sayfa yenilemesinde değiştiği kontrol edilir.
- `pnpm run typecheck`, `pnpm run lint` temiz olmalı.
- Mevcut `pnpm run test:e2e` (Playwright) suite'i regresyon için çalıştırılır.
- Deploy sonrası: `curl -I https://www.yeedoy.com/` ile CSP header'ı doğrulanır; SecurityHeaders.com ve MDN HTTP Observatory ile tekrar taranıp CSP testinin artık geçtiği (A+/100'e yakın puan) doğrulanır.

## Bilinen Riskler

- **Next.js'in otomatik nonce algılama davranışı bu sürümde gerçekten çalışıyor mu** — resmi dokümantasyonda tarif edilen mekanizma, ama proje sürümüne (16.2.11) özgü bir regresyon/quirk olabilir. Implementasyon sırasında lokalde bizzat doğrulanacak, çalışmazsa Next.js'in kendi script'leri için ek bir çözüm (örn. manuel nonce injection) araştırılacak.
- **Embed sayfaları** (`/embed/:businessId*`) farklı bir CSP varyantı (frame-ancestors `*`) kullanıyor — nonce mantığı bu varyanta da doğru şekilde uygulanmalı, aksi halde embed'ler bozulabilir.
- **Dev modu**: `'unsafe-eval'` sadece dev'de ekleniyor, nonce mekanizmasıyla birlikte çalışmaya devam etmeli (React Fast Refresh için gerekli).
