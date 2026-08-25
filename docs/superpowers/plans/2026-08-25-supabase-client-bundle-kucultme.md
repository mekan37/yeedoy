# Supabase İstemci Bundle Küçültme — Analiz ve Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PageSpeed'in mobilde işaretlediği ~60 KiB'lik "neredeyse tamamen kullanılmayan" JS chunk'ının kaynağını (Supabase Auth/Realtime SDK'sı) güvenli şekilde küçültmek.

**Architecture:** Tek monolitik `createSupabaseBrowserClient()` çağrısını, gerçekten ihtiyaç duyulan yerlerde (oturum yönetimi) tutup, sadece anonim/genel-okuma yapan çağrı noktalarında `@supabase/postgrest-js`'in hafif, bağımsız istemcisiyle değiştiriyoruz.

**Tech Stack:** `@supabase/supabase-js@2.110.8`, `@supabase/ssr@0.12.3`, `@supabase/postgrest-js` (zaten transitive bağımlılık olarak node_modules'te mevcut).

---

## Kök Neden — Doğrulanmış Bulgular

1. **`@supabase/ssr`'in `createBrowserClient()`'ı → `@supabase/supabase-js`'in `createClient()`'ını çağırıyor.** `SupabaseClient` constructor'ı (`src/SupabaseClient.ts:381`) `RealtimeClient`'ı **koşulsuz olarak** oluşturuyor (`this.realtime = this._initRealtimeClient(...)`), `.channel()` hiç çağrılmasa bile. Yani realtime-js kodu her `createSupabaseBrowserClient()` çağrısında bundle'a giriyor — lazy/tree-shakeable değil.
2. **`@supabase/auth-js`, WebAuthn/passkey desteğini SDK'nın içine gömülü olarak taşıyor.** Uygulama kod tabanında (`grep -ri webauthn`) tek bir gerçek kullanım yok — bu tamamen ölü kod, ama auth-js'in ayrılmaz bir parçası olduğu için elenmiyor.
3. **Anasayfada (ve her sayfada) tam istemciyi tetikleyen gerçek, meşru ihtiyaçlar var:**
   - `src/ui/bilesenler/kullanici-dropdown.tsx` (header'daki `UserDropdown`, `genel-baslik.tsx`'te her sayfada render ediliyor) — `.auth.signOut()`
   - `src/ui/bilesenler/oturum-suresi-uyarisi.tsx` (`src/lib/uygulama-saglayicilari.tsx`'te global olarak her sayfada render ediliyor) — `.auth.getSession()`, `.auth.refreshSession()`, `.auth.signOut()`
   - Bu ikisi olduğu sürece, **auth-js'in çekirdek session-yönetimi** her sayfada gerekli — WebAuthn kısmı hariç.
4. **Realtime gerçekten kullanılıyor ama SADECE `/gelen-kutusu` (inbox) sayfasında** (`app/(kimlik)/gelen-kutusu/realtime-yenileyici.tsx`). Anasayfa dahil diğer tüm sayfalar için tamamen gereksiz.
5. Anasayfanın kendi client bileşenleri (`AnlikArama`, `YakindakiIsletmeler`, `KonumIzniIstemcisi`) **doğrudan Supabase istemcisi kullanmıyor** — kendi API route'larına (`/api/harita-arama`, `/api/yakin-isletmeler`) `fetch` atıyorlar. Yani anasayfaya özgü ek bir yük yok; asıl yük **her sayfada ortak olan header/session bileşenlerinden** geliyor.

**Sonuç:** "Kullanılmayan JS" etiketi kısmen yanıltıcı — auth çekirdeği (oturum kontrolü) gerçekten kullanılıyor ve her sayfada gerekli. Gerçek kazanç iki noktada:
- **WebAuthn kodu** (auth-js'in bir alt modülü, tamamen ölü) — SDK'yı değiştirmeden çıkarılamaz.
- **Realtime-js** (~60 KiB'lik ikinci chunk'ın büyük kısmı) — sadece `/gelen-kutusu`'nda gerekli, ama her sayfada eagerly oluşturuluyor.

---

## Değerlendirilen Seçenekler

### Seçenek A — Hiçbir şey yapma
WebAuthn kodu Auth-js'in ayrılmaz parçası; kaldırmak SDK fork'lamayı gerektirir. Kabul edilebilir ama iyileşme sağlamaz.

### Seçenek B — Realtime'ı sadece ihtiyaç duyan sayfada izole etmek (ÖNERİLEN)
`kullanici-dropdown.tsx` ve `oturum-suresi-uyarisi.tsx` gibi **sadece auth işlemi yapan, realtime'a hiç dokunmayan** çağrı noktalarında, tam `createSupabaseBrowserClient()` yerine **sadece `@supabase/auth-js`'in `GoTrueClient`'ını doğrudan** kullanmak. Bu, `SupabaseClient` sarmalayıcısını (ve onun eagerly kurduğu `RealtimeClient`'ı) tamamen devre dışı bırakır.

`/gelen-kutusu` sayfası ve diğer gerçek postgrest/realtime ihtiyacı olan yerler (yorum yazma, favoriler vb.) **mevcut tam istemciyi kullanmaya devam eder** — dinamik route'larda zaten kendi JS chunk'larına ayrılıyorlar, bu yüzden ana/paylaşılan bundle'ı şişirmiyorlar.

**Risk:** `GoTrueClient`'ı doğrudan instantiate etmek, `@supabase/ssr`'in cookie senkronizasyon mantığını (SSR session paylaşımı) manuel olarak yeniden kurmayı gerektirir — dikkatli test edilmeli, oturum senkronizasyonunu bozma riski var.

### Seçenek C — Anonim/genel-okuma çağrı noktalarını `@supabase/postgrest-js` ile değiştirmek
Şu an anasayfada doğrudan supabase çağrısı yapan bir client component tespit edilmedi (hepsi kendi API route'larına fetch atıyor), bu yüzden bu seçeneğin **anasayfa için** somut bir kazancı yok. Yalnızca ileride başka client component'ler doğrudan Supabase sorgusu yapmaya başlarsa (yeni bir arama kutusu gibi), bu deseni standart olarak benimsemek faydalı olur.

---

## Uygulama Görevleri (Seçenek B)

### Görev 1: `oturum-suresi-uyarisi.tsx` ve `kullanici-dropdown.tsx`'i hafif auth istemcisine taşı

**Dosyalar:**
- Oluştur: `src/lib/taban/hafif-auth-istemcisi.ts` — `@supabase/auth-js`'in `GoTrueClient`'ını `@supabase/ssr` ile aynı cookie storage adaptörüyle saran, ama `SupabaseClient`/`RealtimeClient` içermeyen minimal bir factory.
- Değiştir: `src/ui/bilesenler/oturum-suresi-uyarisi.tsx`, `src/ui/bilesenler/kullanici-dropdown.tsx` — `createSupabaseBrowserClient()` yerine yeni hafif istemciyi kullan.

- [ ] `@supabase/ssr`'in `createBrowserClient`'ının cookie/storage adaptörünü nasıl kurduğunu (`src/lib/taban/istemci.ts` → `createBrowserClient` kaynağı) incele, aynı davranışı `GoTrueClient` için manuel kur
- [ ] Yeni `hafif-auth-istemcisi.ts`'i yaz, local'de giriş/çıkış/oturum-yenileme akışlarını test et (gerçek prod DB'ye karşı, mevcut oturum çalışması pattern'i ile)
- [ ] `oturum-suresi-uyarisi.tsx` ve `kullanici-dropdown.tsx`'i güncelle
- [ ] Build sonrası `_next/static/chunks/` içinde realtime-js/webauthn string'lerinin bu iki bileşenin bulunduğu paylaşılan chunk'tan kalktığını doğrula (bkz. bu oturumdaki `grep -oE 'sentryReplaySession'` yöntemi)
- [ ] Gerçek tarayıcıda: oturum açma, oturum kapatma, "oturum süresi doluyor" uyarısının hâlâ doğru tetiklendiğini manuel doğrula

### Görev 2: Regresyon taraması

- [ ] `createSupabaseBrowserClient` kullanan kalan ~13 dosyayı (bkz. analiz) tek tek gözden geçir — hangileri gerçekten sadece auth, hangileri postgrest/realtime de kullanıyor; sadece-auth olanları aynı şekilde taşımayı değerlendir (opsiyonel ikinci dalga)
- [ ] `pnpm run test:unit`, `pnpm run typecheck`, `pnpm run lint`, `pnpm run test:e2e` (giriş/çıkış akışını kapsayan varsa) çalıştır

### Görev 3: PageSpeed ile doğrula

- [ ] Production'a deploy sonrası mobil+masaüstü PageSpeed'i tekrar çalıştır, "Kullanılmayan JavaScript" bulgusundaki KiB miktarının azaldığını doğrula

---

## Bilinen Riskler

- **Cookie/session senkronizasyon riski**: `@supabase/ssr`'in `createBrowserClient`'ı, sunucu tarafındaki oturum çerezleriyle istemci tarafını senkronize eden özel bir storage adaptörü kullanıyor. `GoTrueClient`'ı manuel kurarken bu adaptörü birebir doğru kurmazsak, oturum durumu server/client arasında tutarsız hale gelebilir (kullanıcı aslında giriş yapmışken header'da "Giriş Yap" görünmesi gibi). **Bu yüzden Görev 1'in test adımı atlanmamalı.**
- **Kazanç tahmini mütevazı olabilir**: WebAuthn kodu her durumda kalacağı için, kazanç sadece realtime-js'in çıkarılmasından gelecek — tahmini 20-40 KiB civarı (60 KiB'lik chunk'ın tamamı değil, auth-js'in geri kalanı hâlâ gerekli).
