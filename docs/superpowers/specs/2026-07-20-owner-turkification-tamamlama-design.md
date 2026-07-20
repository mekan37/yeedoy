# Owner→Sahip Türkçeleştirme Tamamlama — Design Spec

**Tarih:** 2026-07-20
**Durum:** Onaylandı (kullanıcı, 2026-07-20)
**İlişkili dokümanlar:**
- `docs/superpowers/specs/2026-07-13-owner-panel-turkification-design.md` (Faz 1 orijinal denetim)
- `docs/superpowers/plans/2026-07-13-owner-panel-turkification-plan.md` (Faz 1 orijinal plan — Task 1-14 uygulandı, Task 15-20 uygulanmadı)

## Bağlam

13 Temmuz 2026'da yazılan Faz 1 planı, `/owner` (İngilizce, subdomain'de canlı) ve `/sahip` (Türkçe, paralel/hedef) route ağaçlarını `/sahip` altında tek bir kanonik ağaca birleştirip `/owner`'ı silmeyi hedefliyordu. Task 1-14 (sayfa bazlı feature-union birleştirmeleri) büyük ölçüde uygulandı, ancak **Task 15-20 (ölü kod temizliği, nav güncelleme, redirect'ler, `/owner`'ın nihai silinmesi, middleware sadeleştirme, final doğrulama) hiç uygulanmadı.**

Bu doküman için yapılan denetimde iki ek sorun tespit edildi:

1. **`middleware.ts`'teki subdomain rewrite mantığı** (`isletme.yeedoy.com` → `/owner`'a rewrite) orijinal planda hiç ele alınmamış. `/owner` silinirse ve bu rewrite güncellenmezse, canlı `isletme.yeedoy.com` trafiği kırılır.
2. **Faz 1 planı yazıldıktan SONRA `/owner` ağacına yeni/güncellenmiş özellikler eklenmeye devam etmiş** — çünkü subdomain rewrite hâlâ `/owner`'ı canlı sunuyordu, geliştirme oradan test edilmiş. Somut örnekler (git log ile doğrulandı):
   - **Denetim Kaydı**: 17-18 Temmuz'da `/owner/(panel)/audit` altında `business_audit_log` RPC'sine bağlı, filtreli/sayfalamalı, tam çalışan bir sayfa inşa edildi. `/sahip/denetim-kaydi` ise hâlâ Faz 1 öncesinden kalma, var olmayan/yanlış bir tabloyu (`admin_audit_log`) sorgulayan bozuk bir stub.
   - **Analitik**: `/sahip/analitik` 16 Temmuz'da bir kez merge edildi (commit `2422093`), ama 18 Temmuz'da `/owner/(panel)/analytics` ayrıca "mockup tasarımına göre" yeniden tasarlandı (commit `0af2aaa`) — bu son güncelleme `/sahip`'e hiç yansımadı.
   - **Gösterge Panosu**: `/owner/(panel)/dashboard`'da küçük bir link düzeltmesi (commit `71b1a9a`) yapıldı, `/sahip/gosterge-panosu`'na yansımadı.
   - **Mesajlar**: `/owner/(panel)/messages` — hiçbir nav'da linki olmayan, sadece "yakında" yazan placeholder sayfa. Gerçek mantık yok, migrate edilecek bir şey yok.
   - **`/sahip/etkinlik`** (nav'da "Aktivite" etiketiyle): incelendi, bu sayfa audit/denetim konusuyla alakasız, ayrı ve çalışan bir özellik (`business_events` tablosuna bağlı etkinlik/bilet yönetimi). Sadece nav etiketi yanıltıcı ("Aktivite" yerine "Etkinlikler" olmalı) — içerik olarak dokunulmayacak, sadece etiket düzeltmesi kapsamda.

## Hedef

`/owner` ağacını, kayıp özellik olmadan, kalıcı ve sağlam şekilde ortadan kaldırmak; `/sahip` tek kanonik owner paneli olsun ve canlı subdomain trafiği de oraya aksın.

## Kapsam

### Grup A — Faz 1 sonrası yeniden diverge eden sayfaları uzlaştır

1. **Denetim Kaydı**: `/owner/(panel)/audit/page.tsx` + `audit-client.tsx`'in çalışan içeriğini (RPC çağrıları, filtre/sayfalama mantığı) `/sahip/denetim-kaydi/page.tsx`'in üzerine, mevcut bozuk `admin_audit_log` sorgusunun yerine yaz. Türkçe dosya adı/import konvansiyonuna uydur (`app/sahip` altındaki diğer sayfalar gibi `@/src/lib/taban-sunucu`, `@/src/ui/yerlesim/*`, `@/src/ui/bilesenler/*` path'lerini kullan; client component `denetim-kaydi-istemcisi.tsx` olarak adlandırılsın).
2. **Analitik**: `/owner/(panel)/analytics` (18 Temmuz redesign) ile `/sahip/analitik` (16 Temmuz merge) arasında state/fonksiyon/UI bölümü bazında fark analizi yap (Faz 1 Task 6/11'deki yöntemle aynı), sadece owner'da olan yeni bölümleri `/sahip/analitik`'e ekle.
3. **Gösterge Panosu**: `/owner/(panel)/dashboard`'daki link düzeltmesini (muhtemelen "Tüm Aktiviteler" bağlantısının hedefi) `/sahip/gosterge-panosu`'na yansıt.
4. **`/sahip/etkinlik` nav etiketi**: "Aktivite" → "Etkinlikler" olarak düzelt (içerik değişmiyor, sadece nav label'ı — karışıklığı önlemek için).
5. **Mesajlar**: `/owner/(panel)/messages` silinir, `/sahip` tarafına taşınmaz (dead stub, hiçbir yerden linklenmiyor).

### Grup B — Faz 1 planının kalan adımları (Task 15-20, orijinal plandan resume)

6. **Ölü stub route'ları sil**: `app/sahip/crm`, `sponsorluk`, `finansal`, `envanter`, `siparisler` + karşılık gelen `app/sunucu/sahip/` API stub'ları (Faz 1 planındaki Task 15'in aynısı — hâlâ geçerliliğini `.rpc(`/`.from(` grep'i ile doğrula).
7. **Nav güncelle**: `sahip-kabuk-istemcisi.tsx`'e eksik 7 nav item'ı ekle — `/sahip/rezervasyonlar`, `/sahip/fotograflar`, `/sahip/bildirimler`, `/sahip/pazarlama`, `/sahip/buyume`, `/sahip/denetim-kaydi`, `/sahip/yapay-zeka-analizi` (bu route'lar zaten dosya olarak var ama nav'da linksiz). `src/ui/shell/owner-shell-client.tsx`'i sil (kullanılmıyor).
8. **Cross-reference güncellemeleri**: `app/forbidden/page.tsx` ve `app/login/page.tsx`'teki `/owner/...` referanslarını `/sahip/...`'e çevir.
9. **Redirect'ler**: `next.config.mjs`'e Faz 1 planında hazırlanmış ~30 satırlık `/owner/* → /sahip/*` kalıcı redirect listesini ekle (liste zaten plan dokümanında hazır, aynen kullanılabilir).
10. **`/owner` ağacının nihai silinmesi + middleware sadeleştirme (genişletilmiş kapsam)**:
    - `app/owner/**` ve `app/api/owner/**`'ı tamamen sil.
    - `middleware.ts` → `guardPanelRoute` içindeki `OWNER_PREFIX`/`isOwnerRoute` mantığını sadeleştir (sadece `/sahip` kalsın).
    - **`middleware.ts` → `rewriteSubdomainPanel` içindeki `const prefix = isOwnerHost ? '/owner' : '/admin';` satırını `'/sahip'` olacak şekilde güncelle** (Faz 1 planında atlanmış, kullanıcı onayıyla bu işin kapsamına dahil edildi — canlı `isletme.yeedoy.com` trafiğini etkiler, dikkatli test gerektirir).
11. **Final doğrulama**: `npm run typecheck && npm run lint && npm run test:unit && npm run build`, manuel uçtan uca akış (giriş → dashboard → tüm nav item'ları → çıkış), en az 5 eski `/owner/...` URL'sinin doğru redirect ettiğinin testi, subdomain rewrite'ın `/sahip`'e düştüğünün doğrulanması, ve repo genelinde kalan `/owner/` referans taraması.

## Kapsam Dışı

- Admin/yönetici panelindeki (`/admin` ↔ `/yonetici`) benzer bir olası divergence — ayrı bir sonraki faz, bu işin parçası değil.
- `business_audit_log`'a gerçek mutasyon noktalarından `log_business_action_v1` çağrısı eklenmesi (Faz 2, Denetim Kaydı planının kendi notunda zaten kapsam dışı bırakılmıştı).
- `/sahip/etkinlik` sayfasının kendi içeriğinde değişiklik (sadece nav etiketi düzeltiliyor).

## Test Planı

Her task sonunda `npm run typecheck && npm run lint` (CLAUDE.md minimum gereksinimi — Next.js web değişikliği). Task 10 (middleware + `/owner` silme) sonrası ek olarak `npm run build` ve manuel subdomain/redirect doğrulaması zorunlu — bu, canlı domain routing'i etkileyen en riskli adım.

## Riskler

- **Subdomain rewrite değişikliği** canlıyı doğrudan etkiler; local'de `isletme.localhost` gibi bir host simülasyonu olmadan tam test zor olabilir — Task sırasında en azından `curl -H "Host: isletme.localhost"` ile rewrite davranışı doğrulanmalı.
- Analitik fark analizi (Grup A.2) satır satır karşılaştırma gerektiriyor, düşük ihtimalle gözden kaçan bir owner-only bölüm kalabilir — final doğrulamada (madde 11) manuel gözden geçirme bunu telafi eder.
