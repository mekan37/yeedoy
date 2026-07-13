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

## Denetim bulguları (2026-07-13 tarihli fork denetiminden)

### Route eşleştirmesi

| İngilizce | Türkçe | Durum |
|---|---|---|
| `dashboard` | `gosterge-panosu` | Eşit, ikisi de canlı |
| `businesses/[id]` | `isletmeler/[id]` | owner'da meal-card-editor + branding-editor var, sahip'te yok → taşınacak |
| `menus/[menuId]/edit` (767 satır) | `menuler/[menuId]/duzenle` (792 satır) | İkisi de Temmuz 2026'da büyük güncelleme almış — **satır satır diff gerekiyor**, otomatik seçilemez |
| `reservations` | **yok** | owner'da tam bir rezervasyon sistemi var (3 dosya, 2026-07-11), sahip'te route klasörü bile yok |
| `ai-analysis` | `yapay-zeka-analizi` (2026-06-23) | owner 17 gün daha güncel → owner içeriği kazanır |
| `settings` (13 dosya, 5 sekme) | `ayarlar` (7 dosya) | owner'da bildirim/gizlilik/hesap/rezervasyon sekmeleri var, sahip'te eksik |
| `marketing/*` | `pazarlama/*` | İkisi de dolu → diff + birleştirme gerekiyor |
| `photos` | **yok** | route klasörü sahip'te hiç yok → taşınacak |
| `notifications` | **yok** | route klasörü sahip'te hiç yok → taşınacak |
| `qr`, `team`, `trash`, `price-suggestions`, `growth`, `audit`, `activity`, `requests`, `suspended`, `businesses/submissions`, `businesses/new` | `karekod`, `ekip`, `cop-kutusu`, `fiyat-onerileri`, `buyume`, `denetim-kaydi`, `etkinlik`, `istekler`, `askiya-alinanlar`, `isletmeler/basvurular`, `isletmeler/yeni` | 1:1 karşılığı net, isim eşleşmesi zaten doğru |

### Sadece `sahip` tarafında olan route'lar — ölü kod

`crm`, `sponsorluk`, `finansal`, `envanter`, `siparisler`: hepsi
`redirect('/sahip/gosterge-panosu')` + *"MVP scope dışı: final stratejik
karar raporuna göre kapsam dışı"* yorumu içeren stub'lar. `envanter` (320
satır) ve `siparisler` (216 satır) UI olarak dolu görünse de **0
`.rpc()`/`.from()` çağrısı** var — backend'e hiç bağlı değil. Bunlar
taşınmayacak, silinecek.

`fiyat-raporu` (155 satır, 1 gerçek RPC çağrısı) istisna — ayrıca
incelenip gerçek bir özellikse korunacak/owner'a da eklenecek, değilse o da
silinecek.

### Shell / component katmanı

- Kanonik owner shell: `src/ui/shell/owner-dashboard-shell.tsx` (11 item,
  düz liste), `app/owner/(panel)/layout.tsx` tarafından kullanılıyor.
- Kullanılmayan artık: `owner-shell-client.tsx` — hiçbir yerden import
  edilmiyor.
- Sahip shell: `src/ui/kabuk/sahip-kabuk-istemcisi.tsx` (14 item, 3
  bölümlü, owner shell'den daha kapsamlı), `app/sahip/layout.tsx`
  tarafından kullanılıyor ve zaten çalışır durumda.

## Yaklaşım: Aşamalı tek dal, tek merge

Ayrı bir feature branch üzerinde küçük, bağımsız test edilebilir adımlarla
ilerlenecek; main'e tek merge ile bitirilecek (canlıya kademeli rollout
yok — owner paneli trafiği düşük/kontrollü, prod riski kabul edilebilir
düzeyde).

### Adımlar

1. **İçerik parity — eksikleri `/sahip`'e taşı**
   - `app/owner/(panel)/reservations/**` → yeni `app/sahip/rezervasyonlar/**`
     (dosya içerikleri Türkçeleştirilerek taşınır: değişken/route isimleri,
     kullanıcıya görünen metinler zaten Türkçe olmalı — ARB/i18n kuralına
     uy, CLAUDE.md)
   - `app/owner/(panel)/photos/**` → yeni `app/sahip/fotograflar/**`
   - `app/owner/(panel)/notifications/**` → yeni `app/sahip/bildirimler/**`
   - `ai-analysis` içeriği → `yapay-zeka-analizi` üzerine yazılır (owner
     sürümü kazanır)
   - `settings` eksik sekmeleri (bildirim/gizlilik/hesap/rezervasyon) →
     `ayarlar`'a eklenir

2. **Diff gerektirenleri çöz**
   - Menü editörü: iki dosya satır satır karşılaştırılır, hangi
     değişikliklerin sadece bir tarafta olduğu belirlenir, tek sürümde
     birleştirilir (kaybolan işlevsellik olmamalı)
   - `marketing/*` ↔ `pazarlama/*`: aynı yöntemle diff + birleştirme

3. **Ölü kodu sil** — `sahip/crm`, `sponsorluk`, `finansal`, `envanter`,
   `siparisler`. `fiyat-raporu` için ayrı karar (yukarıda açıklandı).

4. **Shell'i kanonik yap** — `app/sahip/layout.tsx` zaten
   `sahip-kabuk-istemcisi.tsx` kullanıyor; adım 1'deki yeni route'lar
   (rezervasyonlar, fotograflar, bildirimler) nav listesine eklenir.
   Kullanılmayan `owner-shell-client.tsx` silinir.

5. **Referansları güncelle** — repo genelinde `/owner/...` path'lerine
   giden linkler (e-posta şablonları, breadcrumb'lar, admin panelinden
   owner'a linkler, `og`/sitemap üretimi vb.) `/sahip/...`'e çevrilir.

6. **Redirect ekle** — `next.config.mjs`'deki mevcut `redirects()`
   array'ine, projede zaten kullanılan pattern'e uyarak (`permanent: true`)
   her eski `/owner/*` path'i için `/sahip/*` karşılığına yönlendirme
   eklenir. Path parametreli route'lar için (`:id`, `:menuId`) wildcard
   kullanılır.

7. **Eski ağacı sil** — `app/owner/**` tamamen kaldırılır.

8. **Middleware sadeleştir** — `middleware.ts` içindeki
   `OWNER_PREFIX`/`SAHIP_PREFIX` çift-guard mantığı tek prefix'e
   (`SAHIP_PREFIX`) indirilir; `OWNER_LOGIN_PATH` da Türkçe karşılığına
   güncellenir.

9. **Doğrulama**
   - `npm run typecheck && npm run lint && npm run test:unit && npm run build`
     (CLAUDE.md minimum doğrulama tablosu — Web değişikliği)
   - Tarayıcıda gerçek akış testi: giriş → dashboard → işletmeler → menü
     düzenle → rezervasyon → ayarlar → çıkış
   - Eski `/owner/...` URL'lerinin redirect ile doğru `/sahip/...`'e
     düştüğü manuel doğrulanır

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
