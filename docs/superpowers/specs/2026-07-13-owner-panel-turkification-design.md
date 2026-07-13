# Owner Paneli Türkçeleştirme — Faz 1 (`/owner` ↔ `/sahip` Uzlaştırması)

## Arka plan

Proje daha önce owner ve admin panellerini Türkçe isimlendirmeye geçirmişti
(`app/sahip`, `app/yonetici`). Sonrasında bir araç (codex) yanlışlıkla dosyaları
sildi; proje sahibi GitHub'dan eski (İngilizce) sürümü geri çekti
(`app/owner`, `app/admin`). O andan itibaren **her iki ağaca da** commit
gitmeye devam etti:

- Gerçek navigasyon (`src/ui/shell/owner-dashboard-shell.tsx`,
  `app/login/page.tsx → /owner/businesses` redirect'i) İngilizce ağacı
  (`app/owner`) kullanıyor ve yeni özellikler (örn. rezervasyon sistemi)
  oraya eklendi.
- Türkçe ağaç (`app/sahip`, `app/giris`) hiçbir yerden link'lenmiyor ama
  bazı sayfalarda İngilizce ağaçta olmayan içerik/route'lar birikti.

Bu durum sadece owner/admin'de değil, tüm web app'te var
(`(genel)`↔`(public)`, `(kimlik)`↔`(auth)`), ancak bu proje **sadece owner
panelini** kapsıyor. Admin (`/admin`↔`/yonetici`) ve public/auth ikilikleri
ayrı, sonraki fazlardır.

## Hedef

`app/sahip` tek kanonik owner paneli olacak. `app/owner` tamamen
kaldırılacak; eski URL'ler için kalıcı (301/308) redirect eklenecek.
Owner/admin panelleri zaten `robots: { index: false, follow: false }` ile
noindex — bu değişikliğin SEO etkisi yoktur, amaç kod tabanı tutarlılığı ve
bakım kolaylığıdır.

## Denetim bulguları (2026-07-13, iki turlu fork denetimi + doğrudan doğrulama)

**Önemli düzeltme:** İlk (özet) denetimin "owner daha yeni → owner kazanır"
genellemesi **yanlış** çıktı. İkinci, içerik-seviyesi denetimde her iki
tarafın da bağımsız, gerçek özellik geliştirmesi aldığı görüldü. Birçok
alanda basit "kazanan seç" değil, **gerçek iki-yönlü feature-union
birleştirmesi** gerekiyor.

### Route eşleştirmesi — düz taşıma (net, tek yönlü)

| İngilizce | Türkçe | Aksiyon |
|---|---|---|
| `reservations` (3 dosya, 2026-07-11) | **yok** | owner'daki rezervasyon sistemi `sahip/rezervasyonlar`'a taşınır |
| `photos` | **yok** | owner'daki içerik `sahip/fotograflar`'a taşınır |
| `notifications` (gerçek, `NotificationsClient` bileşeni var) | **yok** | owner'daki içerik `sahip/bildirimler`'a taşınır |
| `messages` | **yok** | **Ölü kod** — sadece "Yakında" placeholder'ı, sıfır backend bağlantısı, nav'da linki yok. Taşınmayacak. |
| `ai-analysis` (2026-07-10) | `yapay-zeka-analizi` (2026-06-23) | owner içeriği 17 gün daha güncel → owner kazanır, üzerine yazılır |
| `businesses/[id]` | `isletmeler/[id]` | owner'daki `meal-card-editor.tsx` + `branding-editor.tsx` sahip'te yok → taşınır |
| `team` (salt-okunur liste) | `ekip` (tam CRUD: `addTeamMember`, `upsert_team_member_v1` RPC, rol seçimi, **vardiya planı UI'ı**) | **Sahip kazanır** — owner'dan taşınacak bir şey yok |
| `qr`, `trash`, `price-suggestions`, `growth`, `audit`, `activity`, `requests`, `suspended`, `businesses/submissions`, `businesses/new` (isim eşleşmesi net olanlar) | `karekod`, `cop-kutusu`, `fiyat-onerileri`, `buyume`, `denetim-kaydi`, `etkinlik`, `istekler`, `askiya-alinanlar`, `isletmeler/basvurular`, `isletmeler/yeni` | 1:1, çoğunlukla değişiklik gerekmez (qr istisna, aşağıda) |

### Gerçek iki-yönlü birleştirme gereken alanlar

| Alan | Owner'a özgü | Sahip'e özgü | Aksiyon |
|---|---|---|---|
| **`qr`↔`karekod`** | Tek-işletme QR yöneticisi, çalışan `owner_list_qr_codes_v1` RPC, tam `QrPageClient` | Çok-işletmeli hub/index sayfası (işletme listesi → "QR Studio" butonu) ama **hedef `/karekod/[id]` route'u dosya sisteminde yok — link kırık** | Owner'ın çalışan tek-işletme mantığını `sahip/karekod/[businessId]/` altına taşı; sahip'in hub sayfasını (`karekod/page.tsx`) index olarak koru |
| **`analytics`↔`analitik`** | Trafik kaynağı kırılımı, haftanın günü heatmap'i, önceki döneme göre % değişim | **"Yoğun Saatler" widget'ı** (gerçek `getYogunSaatler` RPC), `whatsapp_click`/`qr_scan` event tracking, saatlik dağılım grafiği | Feature-union: her iki özellik seti de `sahip/analitik`'te birleştirilir, hiçbiri atılmaz |
| **`menu/translations`↔`menu/ceviriler`** | **Manuel çeviri editörü** (`CeviriEditor`, dil bazlı tamamlanma yüzdesi) | **Otomatik çeviri tetikleyici** (DeepL/OpenAI) + salt-okunur tablo | Feature-union: otomatik çeviri butonu KORUNUR + manuel editör eklenir, tek sayfada |
| **Dashboard** (`dashboard` 92 satır ↔ `gosterge-panosu` 180 satır) | Tek işletmeye odaklı, görsel-ağırlıklı (cover/logo, son 3 yorum önizlemesi, Premium banner) | Çok işletmeli KPI grid, QR-tarama sparkline, 7 günlük view chart, **"onay bekleniyor" (pending claim) banner'ı** | Feature-union: sahip'in çoklu-işletme/pending-claim mantığı KORUNUR, owner'ın görsel zenginliği eklenir |
| **`reviews`↔`yorumlar`** | "Yeni" rozeti (localStorage last-seen), `helpful_count`, durum rozetleri (onaylı/bekleyen/reddedilen), `/api/owner/review-reply` | **Hazır yanıt şablonları** (4 canned reply), `displayName`/anonim gösterimi, "Gizli" (isVisible) rozeti, `/sunucu/sahip/yorumlar/yanit` (route dosyası mevcut, çalışıyor) | Feature-union: her iki özellik seti birleştirilir; hangi API endpoint'in kanonik kalacağına (muhtemelen `/sunucu/sahip/yorumlar/yanit`, çünkü zaten çalışan bir route) implementasyon sırasında karar verilir |
| **`settings`↔`ayarlar`** | Tam sekme mimarisi: `settings-client.tsx` + `settings-right-sidebar.tsx` + `actions.ts` + 5 sekme (`bildirim-ayarlari`, `gizlilik-guvenlik`, `hesap-ayarlari`, `isletme-profili`, `rezervasyon-ayarlari`) | Sadece 2 linkten oluşan basit bir menü sayfası (domain/saatler zaten ayrı alt-route olarak var, kayıp değil) | Owner'ın tüm tabs mimarisi `sahip/ayarlar`'a taşınır |
| **Kök sayfa** (`app/owner/page.tsx` + `owner-landing-search.tsx`, 345 satır) | Tam pazarlama/landing sayfası: hero, 6 özellik kartı, işletme arama widget'ı, 3 adım süreç, SSS, footer | `app/sahip/page.tsx` sadece `redirect('/sahip/gosterge-panosu')` — **içerik tamamen kayıp** | Owner'ın tüm landing page içeriği + `owner-landing-search.tsx` `sahip/page.tsx`'e taşınır; middleware'deki `OWNER_PUBLIC_PATHS`'e `/sahip` eklenir ki girişsiz ziyaretçi bu sayfayı görebilsin |
| **Login** (`app/owner/login/page.tsx` — owner'a özel adanmış form) ↔ (`app/giris/page.tsx` — genel giriş+kayıt, owner'a özel değil) | Owner'a özel, adanmış görsel tasarım | Genel/herkese açık, tab'lı giriş+kayıt, zaten `/sahip` path normalizasyonu var | **Karar (onaylandı):** `/giris` kanonik login sayfası olur (hem public hem owner için); TÜM `/giris` sayfasının görsel tasarımı `owner/login`'in tasarımına göre güncellenir (layout, renk, bileşen stili). `middleware.ts`'deki `OWNER_LOGIN_PATH` → `/giris` olarak güncellenir. `app/owner/login/page.tsx` bu taşıma sonrası silinir. |

### API route katmanı — kapsam dahil

Sayfa katmanının ötesinde bir de API route ikiliği var:
`app/api/owner/**` (10 dosya: `ai-analyze`, `business-branding`,
`businesses`, `businesses/[id]`, `domain`, `menus`, `menus/[menuId]`,
`photos`, `review-reply`) ↔ `app/sunucu/sahip/**` (15 dosya: yukarıdakilerin
çoğuna karşılık gelenler + `bildirim-gonder`, `ceviriler-otomatik`,
`envanter`, `eposta-kampanya`, `etkinlik`, `finansal-csv`, `sadakat`,
`siparis-listesi`, `spesiyel`). Bu, "site-geneli lib" kapsamının dışında —
owner sayfalarının hangi backend'e bağlı olduğunu doğrudan belirlediği için
**bu projenin parçası**. `sahip` sayfaları zaten büyük ölçüde
`/sunucu/sahip/*` endpoint'lerini çağırıyor (çalışır durumda); owner'a özgü
ve sahip'te karşılığı olmayan endpoint'ler (`ai-analyze`, `business-branding`,
`photos`, `review-reply`'nin owner sürümü) taşınacak sayfalarla birlikte
`/sunucu/sahip/` altına taşınır/oluşturulur. Ölü sayfalarla eşleşen ölü API
stub'ları (`envanter`, `siparis-listesi`, `finansal-csv` vb. — sadece
kullanılmayan sayfaların backend'i) sayfalarla birlikte silinir.

### Sadece `sahip` tarafında olan route'lar — ölü kod (çoğunlukla)

`crm`, `sponsorluk`, `finansal`, `envanter`, `siparisler`: hepsi
`redirect('/sahip/gosterge-panosu')` + *"MVP scope dışı: final stratejik
karar raporuna göre kapsam dışı"* yorumu içeren stub'lar. `envanter` (320
satır) ve `siparisler` (216 satır) UI olarak dolu görünse de **0
`.rpc()`/`.from()` çağrısı** var — backend'e hiç bağlı değil. Bunlar
taşınmayacak, silinecek.

**Düzeltme:** `fiyat-raporu` **canlı ve sahip nav'ında aktif olarak
linkli** (gerçek RPC çağrısı var) — önceki "belirsiz/muhtemelen silinecek"
notu yanlıştı. Silinmeyecek, korunacak.

`spesiyel-toggle.tsx` (sahip'e özgü, menü öğesini "Bugünün Spesiyali" olarak
işaretleme, gerçek `/sunucu/sahip/spesiyel` API çağrısı) — gerçek bir
özellik, sahip zaten kanonik olacağı için dokunulmaz, sadece menü editörü
birleştirmesi sırasında import/kullanımının bozulmadığından emin olunur.

### Nav listeleri — mevcut durum

**Owner (`owner-dashboard-shell.tsx`, düz liste, 11 item):** dashboard,
businesses, menus, photos, reviews, reservations, analytics,
marketing/campaigns, qr, notifications, settings.

**Sahip (`sahip-kabuk-istemcisi.tsx`, 3 bölüm, 14 item):** gosterge-panosu,
isletmeler, menuler, baslangic, analitik, fiyat-raporu, yorumlar, karekod,
ekip, fiyat-onerileri, istekler, etkinlik, cop-kutusu, ayarlar.

**Nav'da eksik olanlar** (route dosyası var ama sidebar linki yok):
sahip nav'ında `pazarlama`, `buyume`, `denetim-kaydi`, `yapay-zeka-analizi`
zaten dosya olarak var ama nav'dan erişilemiyor — birleştirme sonrası
kanonik nav'a bunlar da (yeni taşınan `rezervasyonlar`, `fotograflar`,
`bildirimler` ile birlikte) eklenmeli.

### Shell / component katmanı

- Kanonik owner shell: `src/ui/shell/owner-dashboard-shell.tsx` (11 item,
  düz liste), `app/owner/(panel)/layout.tsx` tarafından kullanılıyor.
- Kullanılmayan artık: `owner-shell-client.tsx` — hiçbir yerden import
  edilmiyor.
- Sahip shell: `src/ui/kabuk/sahip-kabuk-istemcisi.tsx` (14 item, 3
  bölümlü, owner shell'den daha kapsamlı), `app/sahip/layout.tsx`
  tarafından kullanılıyor ve zaten çalışır durumda.

### Diğer cross-reference bulguları

- `app/forbidden/page.tsx` içinde `/owner/dashboard` ve `/owner/login`'e
  linkler var → `/sahip/gosterge-panosu` ve `/giris`'e güncellenir.
- `app/robots.ts` zaten hem `/owner/` hem `/sahip/` hem `/yonetici/`'yi
  disallow listesinde kapsıyor — değişiklik gerekmez (owner silinince ilgili
  girdi opsiyonel temizlenebilir, işlevsel etkisi yok).
- `app/login/page.tsx` (kök, `/login`) → `/owner/businesses`'a redirect
  ediyor; bu da `/sahip/isletmeler`'e güncellenmeli (veya adım login
  kararına göre `/giris`'e yönlendirilip oradan devam etmeli).

## Yaklaşım: Aşamalı tek dal, tek merge

Ayrı bir feature branch üzerinde küçük, bağımsız test edilebilir adımlarla
ilerlenecek; main'e tek merge ile bitirilecek (canlıya kademeli rollout
yok — owner paneli trafiği düşük/kontrollü, prod riski kabul edilebilir
düzeyde).

### Adımlar

1. **Düz taşımalar** — reservations→rezervasyonlar, photos→fotograflar,
   notifications→bildirimler (yeni route'lar), ai-analysis içeriği
   yapay-zeka-analizi üzerine yazılır, businesses/[id]'nin meal-card-editor
   + branding-editor'ı isletmeler/[id]'ye taşınır. `team`↔`ekip`: sahip
   zaten kazanan, dokunulmaz. Karşılık gelen `app/api/owner/*` endpoint'leri
   `app/sunucu/sahip/*` altına taşınır/eşlenir.

2. **Feature-union birleştirmeleri** (her biri: iki dosyayı tam oku, yukarıdaki
   "Gerçek iki-yönlü birleştirme" tablosundaki özellik listelerini koruyarak
   tek sürümde birleştir, sonra ilgili build/typecheck ile doğrula):
   - `qr`↔`karekod`: owner'ın çalışan tek-işletme mantığını
     `sahip/karekod/[businessId]/` altına taşı, sahip'in hub sayfasını koru
   - `analytics`↔`analitik`: trafik kaynağı + heatmap + % değişim (owner) ile
     Yoğun Saatler + whatsapp/qr_scan tracking (sahip) birleştirilir
   - `menu/translations`↔`menu/ceviriler`: manuel editör (owner) + otomatik
     çeviri butonu (sahip) birleştirilir
   - Dashboard: sahip'in çoklu-işletme KPI/pending-claim mantığı korunur,
     owner'ın görsel zenginliği (cover/logo, review-preview, premium banner)
     eklenir
   - `reviews`↔`yorumlar`: "Yeni" rozeti/helpful_count/durum rozetleri
     (owner) + hazır yanıt şablonları/displayName/Gizli rozeti (sahip)
     birleştirilir; kanonik API endpoint kararlaştırılır
   - `settings`↔`ayarlar`: owner'ın 5 sekmelik tabs mimarisi sahip'e taşınır
   - Menü editörü (`menus/[menuId]/edit` ↔ `menuler/[menuId]/duzenle`):
     satır satır karşılaştırılıp tek sürümde birleştirilir,
     `spesiyel-toggle.tsx`'in kullanımı bozulmaz
   - `marketing/*` ↔ `pazarlama/*`: aynı yöntemle diff + birleştirme

3. **Login birleştirmesi** — `app/giris/page.tsx`'in tüm görsel tasarımı
   `app/owner/login/page.tsx`'in tasarımına göre güncellenir (layout, renk,
   bileşen stili) — hem public hem owner girişi için geçerli tek sayfa.
   `middleware.ts`'deki `OWNER_LOGIN_PATH` → `/giris`. `app/owner/login/`
   silinir.

4. **Landing page taşıması** — `app/owner/page.tsx` + `owner-landing-search.tsx`
   içeriği `app/sahip/page.tsx`'in yerine geçer (mevcut bare redirect
   kaldırılır). `middleware.ts`'deki `OWNER_PUBLIC_PATHS` mantığına `/sahip`
   eklenir ki girişsiz ziyaretçi landing page'i görebilsin.

5. **Ölü kodu sil** — `sahip/crm`, `sponsorluk`, `finansal`, `envanter`,
   `siparisler` sayfaları + bunlara karşılık gelen ölü `app/sunucu/sahip/*`
   API stub'ları (`envanter`, `siparis-listesi`, `finansal-csv` vb.).
   `fiyat-raporu` KORUNUR (canlı, nav'da linkli).

6. **Shell'i kanonik yap** — `sahip-kabuk-istemcisi.tsx` nav listesine yeni
   taşınan route'lar (rezervasyonlar, fotograflar, bildirimler) ve
   nav'dan erişilemeyen mevcut route'lar (pazarlama, buyume, denetim-kaydi,
   yapay-zeka-analizi) eklenir. Kullanılmayan `owner-shell-client.tsx`
   silinir.

7. **Referansları güncelle** — `app/forbidden/page.tsx` (`/owner/dashboard`→
   `/sahip/gosterge-panosu`, `/owner/login`→`/giris`), `app/login/page.tsx`
   kök redirect hedefi (`/owner/businesses`→`/sahip/isletmeler` veya
   `/giris`), ve repo genelinde başka `/owner/...` referansı kalmadığından
   emin olunur (grep ile doğrulanır).

8. **Redirect ekle** — `next.config.mjs`'deki mevcut `redirects()`
   array'ine (`permanent: true`) her eski `/owner/*` path'i için `/sahip/*`
   karşılığına yönlendirme eklenir; parametreli route'lar için wildcard.

9. **Eski ağacı sil** — `app/owner/**` ve karşılığı olan `app/api/owner/**`
   (taşınmayan/ölü kalanlar) tamamen kaldırılır.

10. **Middleware sadeleştir** — `OWNER_PREFIX`/`SAHIP_PREFIX` çift-guard
    mantığı tek prefix'e (`SAHIP_PREFIX`) indirilir.

11. **Doğrulama**
    - `npm run typecheck && npm run lint && npm run test:unit && npm run build`
      (CLAUDE.md minimum doğrulama tablosu — Web değişikliği)
    - Tarayıcıda gerçek akış testi: `/giris` → dashboard → işletmeler →
      menü düzenle → rezervasyon → ayarlar → analitik → yorumlar → çıkış
    - Eski `/owner/...` URL'lerinin redirect ile doğru `/sahip/...`'e
      düştüğü manuel doğrulanır
    - Girişsiz ziyaretçi `/sahip`'e gittiğinde landing page'i gördüğü
      doğrulanır

### Yeni Türkçe route isimleri

Sahip ağacında henüz karşılığı olmayan route'lar için, mevcut isimlendirme
deseniyle (ASCII, kebab-case, Türkçe karakter yok — `isletme-yolu.ts` gibi
mevcut örneklerle tutarlı) türetilen yeni isimler:

- `reservations` → `rezervasyonlar`
- `photos` → `fotograflar`
- `notifications` → `bildirimler`

## Kapsam dışı (sonraki fazlar)

- Admin paneli (`/admin` ↔ `/yonetici`) — owner kadar net bir 1:1 eşleşme
  çıkmadı, kendi başına ayrı bir derin denetim + spec gerektiriyor.
- Public/auth ikiliği (`(genel)`↔`(public)`, `(kimlik)`↔`(auth)`) — ayrı,
  daha büyük bir proje.
- `src/lib/` katmanındaki genel (owner/admin'e özel olmayan) Türkçe/İngilizce
  dosya çiftleri (`supabaseServer.ts`↔`taban-sunucu.ts` gibi) — bunlar
  zaten birbirine yönlenen ince shim'ler, owner/admin kapsamında kritik
  değil; site-geneli bir "lib katmanı uzlaştırması" projesi olarak ayrı ele
  alınmalı.

## Test planı

- Otomatik: `npm run typecheck`, `npm run lint`, `npm run test:unit`,
  `npm run build` — hepsi geçmeli.
- Menü editörü ve pazarlama birleştirmesi için: birleştirme sonrası
  ilgili varsa mevcut unit testler (`test/lib/menu-baglantilari.test.ts`
  gibi) hâlâ geçmeli; yoksa manuel doğrulama yeterli.
- Manuel: tarayıcıda tam owner akışı (yukarıda adım 9'da listelendi) +
  en az 3 eski `/owner/...` URL'sinin redirect ile çalıştığının kontrolü.
- Regresyon riski en yüksek alanlar: rezervasyon (yeni taşınan, kritik iş
  akışı), menü editörü (en büyük/en çok diverge etmiş dosya).
