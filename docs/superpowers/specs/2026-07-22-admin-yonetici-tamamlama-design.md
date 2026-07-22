# Admin→Yönetici Türkçeleştirme Tamamlama — Design Spec

**Tarih:** 2026-07-22
**Durum:** Onaylandı (kullanıcı, 2026-07-22)
**İlişkili dokümanlar:**
- `docs/superpowers/specs/2026-07-20-owner-turkification-tamamlama-design.md` (owner→sahip fazı — tamamlandı, merge+push edildi)
- `docs/superpowers/plans/2026-07-20-owner-turkification-tamamlama-plan.md`

## Bağlam

Owner→sahip Türkçeleştirmesi tamamlandıktan sonra aynı ikilik admin panelinde de mevcut: `app/admin` (İngilizce, `ops.yeedoy.com` subdomain rewrite'ı ile hâlâ canlı) ve `app/yonetici` (Türkçe, hedef ağaç). Kapsamlı bir denetim yapıldı (32 admin bölümü, 39 yonetici bölümü karşılaştırıldı, her "eşleşen" çift içerik bazında doğrulandı — sadece dosya adı/satır sayısı benzerliğine güvenilmedi, owner/sahip denetiminde bunun yanıltıcı olduğu görülmüştü).

**Owner/sahip'ten farklı olarak**: `/yonetici` zaten `/admin`'den daha büyük ve gelişmiş (67 dosya/39 bölüm vs 47 dosya/32 bölüm) — 9 bölüm (ab-test, api-anahtarlari, feature-flags, finansal-yonetim, fraud-tespiti, kvkk-gdpr, musteri-destek, push-kampanyalari, toplu-islemler) doğrudan Türkçe inşa edilmiş, hiç İngilizce karşılığı olmamış yeni özellikler — bunlar taşınacak bir şey değil, zaten doğru yönde.

## Denetim Bulguları

**Doğrulanmış tam eşleşme (31 çiftten 28'i)**: analytics/analitik, audit/denetim-kaydi, business-submissions/isletme-basvurulari, dev-tools/gelistirme-araclari, group-requests/grup-istekleri, incidents/olaylar, locations/konumlar, queue/kuyruk, dashboard/gosterge-panosu, reviews/yorumlar, table-feedback/masa-geri-bildirimleri, price-suggestions/fiyat-onerileri, receipt-submissions/fis-basvurulari, users/kullanicilar, search/arama, sponsorships/sponsorluklar, roles/roller, sponsorship-leads/sponsor-adaylari, growth/buyume, observability/gozlemlenebilirlik, sponsorship-packages/sponsor-paketleri, appeals/itirazlar (+ `itirazlar/claims` alt klasörü = admin'in `claims`'i), suggestions/oneriler, trash/cop-kutusu, suspended/askiya-alinanlar, reports/raporlar, temp-uploads/gecici-yuklemeler, b2b-exports/b2b-dis-aktarim (simetrik, kasıtlı MVP-scope-dışı stub, aynı doküman referansı iki tarafta da var).

**verified/dogrulanmis-isletmeler**: yönetici tarafı `isletmeler?status=verified` filtresine redirect ediyor — farklı mimari ama aynı yetenek, kayıp değil.

## Kapsam

### Grup A — Gerçek özellik eksikleri

1. **`businesses` → `isletmeler` eksik akışlar**: admin'de "yeni işletme oluştur" (`admin/businesses/new`) ve "işletme adına menü oluştur" (`admin/businesses/[id]/menus/new`) akışları var, yönetici'de sadece liste sayfası var. Backing API route'ları (`app/api/admin/businesses/route.ts`, `app/api/admin/businesses/[id]/menus/route.ts`) da yönetici tarafında karşılıksız. Bu iki akışı `app/yonetici/isletmeler/**` altına taşımak gerekiyor.
2. **`toplu-islemler` nav eksikliği**: sayfa gerçek ve çalışır durumda (483 satır, gerçek Supabase sorguları, redirect/stub değil) ama admin/yönetici nav'larının hiçbirinde linki yok — owner'daki rezervasyonlar/fotoğraflar/bildirimler ile aynı "unutulmuş erişilemez sayfa" deseni. Sadece nav linki eklenmesi yeterli, içerik taşımaya gerek yok.
3. **`chains` (işletme zinciri/franchise yönetimi)**: admin'de tam CRUD var (RPC: `admin_list_chains_v1`, liste + detay + yeni-zincir akışları), yönetici'de hiç karşılığı yok. Tamamen yeni bir taşıma gerekiyor.

### Grup B — Faz 1'in kalan adımları (owner/sahip'teki Task 15-20'nin admin muadili)

4. Ölü/stub route'ları doğrula ve gerekiyorsa temizle (owner'daki crm/sponsorluk/finansal/envanter/siparisler'e benzer bir tarama — henüz yapılmadı, plan aşamasında netleştirilecek).
5. Admin/yönetici nav'ını güncelle (toplu-islemler dahil, varsa başka unutulmuş linkler).
6. Cross-reference güncellemeleri (varsa `/admin/...` referansları içeren forbidden/login sayfaları — kontrol edilecek).
7. `next.config.mjs`'e `/admin/* → /yonetici/*` kalıcı redirect'leri ekle (owner/sahip'teki desenin aynısı).
8. **`app/admin` + `app/api/admin`'i tamamen sil; `middleware.ts`'i sadeleştir** — `ADMIN_PREFIX` kaldırılır, `isAdminRoute` sadece `YONETICI_PREFIX`'e bakar, **ve en kritik satır**: `rewriteSubdomainPanel`'daki `isOwnerHost ? '/sahip' : '/admin'` satırının `/admin` kolu `/yonetici` olur (`ops.yeedoy.com` subdomain'i artık `/yonetici`'ye rewrite eder).
9. Final doğrulama (typecheck/lint/test/build + manuel akış + redirect testi + kalan referans taraması) — owner/sahip'teki Task 11 ile aynı.

## Kapsam Dışı

- 9 yönetici-only bölüm (ab-test, api-anahtarlari, feature-flags, finansal-yonetim, fraud-tespiti, kvkk-gdpr, musteri-destek, push-kampanyalari) — doğrulandı, taşınacak bir şey yok.
- b2b-exports/b2b-dis-aktarim — kasıtlı simetrik stub, dokunulmayacak.

## Test Planı

Her task sonunda `npm run typecheck && npm run lint` (CLAUDE.md minimum gereksinimi). Madde 8 (app/admin silme + middleware) sonrası ek olarak `npm run build` ve subdomain rewrite doğrulaması zorunlu — owner/sahip'teki Task 10 ile aynı risk profili.

## Riskler

- Owner/sahip denetiminde, "önceden taşınmış" sanılan sayfaların aslında hiç taşınmamış olduğu birden fazla kez keşfedildi (rezervasyonlar/fotoğraflar/bildirimler, ayarlar 5 sekmesi, QR analitiği, vb. — toplam 7 gerçek eksik, ilk denetimde sadece 0-1'i öngörülmüştü). Bu denetim daha kapsamlı yapıldı (her "eşleşen" çift içerik bazında doğrulandı, sadece isim/satır sayısı değil) ama **`app/admin` silinmeden hemen önce, tıpkı owner/sahip'teki Task 10'da olduğu gibi, implementer'a son bir güvenlik doğrulaması yaptırılacak** — herhangi bir dosya güvenli 3 kategoriden birine (gerçek karşılık / kasıtlı stub / ölü kod) net girmiyorsa silme durdurulup kullanıcıya danışılacak.
- Subdomain rewrite değişikliği yine canlıyı doğrudan etkiler — aynı dikkatli test gerekiyor.
