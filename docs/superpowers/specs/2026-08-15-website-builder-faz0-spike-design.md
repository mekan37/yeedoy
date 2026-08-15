# Yeedoy Web — Faz 0 Teknik Spike — Design Doc

## Bağlam

`YEEDOY_WEB_Website_Builder_Urun_Teknik_Plan.md` (14 Ağustos 2026, kullanıcı tarafından sağlandı) Yeedoy için yeni bir ücretli ürün öneriyor: restoran/kafe sahiplerinin tema seçip Puck tabanlı basit bir görsel editörle kendi web sitelerini oluşturup `{slug}.yeedoy.com` veya kendi alan adlarında yayınlayabilmesi. Bu, aylar süren, çok bileşenli bir girişim (100 bölümlük plan) — tek bir implementasyon planına sığmaz.

Planı Yeedoy'un gerçek kod tabanına karşı değerlendirmek için üç uzman incelemesi yapıldı:
- **DB/RLS uyumu** (postgres-pro): Yeedoy'da zaten QR-menü özel domain'leri için çalışan bir `custom_domains` tablosu + `get_slug_for_domain_v1` RPC + `proxy.ts`'te host-bazlı çözümleme var — planın önerdiği sıfırdan `site_domains` yerine bunun genişletilmesi önerildi.
- **Güvenlik** (security-auditor): `proxy.ts`'in mevcut host-eşleştirme mantığının normalize edilmemiş olduğu (case-sensitive, trailing-dot yok) ve yeni bir wildcard resolver eklenirken reserved-subdomain guard'ının sıkı tutulması gerektiği bulundu. **Ayrıca bu inceleme sırasında, plan'la ilgisiz, mevcut `custom_domains` özelliğinde iki gerçek production güvenlik açığı bulundu ve düzeltildi** (`get_custom_domain_v1` IDOR + kendi-kendini-doğrulama bypass'ı — bkz. commit `14819589`).
- **Lisans** (license-engineer): Puck **MIT, temiz** — doğrudan bağımlılık olarak kullanılabilir.

Ayrıca §96'daki 12 açık ürün kararı (fiyatlandırma, branding, tema sayısı, tek-sayfa/çoklu-sayfa, vb.) ayrı bir araştırma turuyla netleştirildi (bu doküman kapsamında değil, ürün kararı olarak kayda geçti).

Bu doküman, planın kendi **Faz 0 — Teknik Spike** tanımını (§62) Yeedoy'un gerçek mimarisine uyarlıyor: *"Puck + Yeedoy + tenant routing'in beraber çalıştığını kanıtlamak."*

## Hedefler

- Gerçek Puck paketi, gerçek bir Yeedoy işletmesinin gerçek verisiyle, gerçek bir wildcard subdomain'de uçtan uca çalıştığını kanıtlamak.
- Draft/publish ayrımının (yayınlanmamış değişiklik canlı siteye hemen yansımaz) temel akışını doğrulamak.
- Sonraki fazların (Editor Core, Data Binding, Multi-Tenant) üzerine inşa edeceği somut, çalışan bir temel bırakmak — spike kodu atılmayacak, Faz 1+'ın başlangıç noktası olacak.

## Kapsam Dışı (Faz 0)

- Ödeme, paket/entitlement sistemi (`business_sites.package_code` vb. — henüz yok).
- Custom domain (Faz 5).
- Tema kataloğu / birden fazla tema — tek, sabit bir tema.
- Autosave, revision geçmişi, geri alma (Faz 1).
- 14 P0 component'in tamamı — sadece Hero, Menu, Gallery.
- Gerçek Vercel wildcard domain kurulumu — `*.yeedoy.localhost` ile yerel kanıt yeterli (bkz. Mimari).

## Mimari

```
Owner Panel (gerçek auth, gerçek business_id)
      ↓
/web-builder/[business_id]  (yeni route, Puck editörü — sadece panelde yüklenir)
      ↓ save
site_revisions (draft)
      ↓ "Yayınla"
business_sites.published_revision_id repoint
      ↓
aspava-demo.yeedoy.localhost  (wildcard, proxy.ts resolver)
      ↓
Lightweight renderer (Puck editör bundle'ı YOK — sadece Hero/Menu/Gallery component'leri)
```

**Wildcard kanıtı:** `*.yeedoy.localhost` — modern tarayıcılar bunu otomatik `127.0.0.1`'e çözer, DNS/hosts dosyası değişikliği gerekmez. `proxy.ts`'e eklenen yeni resolver, mevcut `rewriteSubdomainPanel` (isletme.*/ops.*) mantığından **sonra** çalışır ve sabit bir reserved-label listesiyle (`ops`, `isletme`, `www`, `api`, `admin`, `_vercel`, ...) korunur — security-auditor'ın I1 bulgusuna göre.

**Editor/Renderer ayrımı:** Puck editör bundle'ı yalnızca `/web-builder/[business_id]` (panel, auth arkasında) yüklenir. Public render (`aspava-demo.yeedoy.localhost`) hiçbir zaman Puck'ı yüklemez — sadece üç component'i ve `published_revision`'ın `config` JSON'ını render eder.

## Veri Modeli

```sql
-- business_sites — postgres-pro önerisiyle minimal, entitlement alanları Faz 4'e ertelendi
CREATE TABLE public.business_sites (
  id                  uuid primary key default gen_random_uuid(),
  business_id         uuid not null references public.businesses(id) on delete cascade,
  subdomain           text not null unique,
  draft_revision_id   uuid,
  published_revision_id uuid,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  published_at        timestamptz
);

-- site_revisions — draft + published, revision geçmişi yok (Faz 1'e ertelendi, tek satır overwrite)
CREATE TABLE public.site_revisions (
  id            uuid primary key default gen_random_uuid(),
  site_id       uuid not null references public.business_sites(id) on delete cascade,
  schema_version integer not null default 1,
  config        jsonb not null,
  created_by    uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now()
);
```

`business_sites.subdomain`, mevcut `custom_domains.upsert_custom_domain_v1`'deki aynı sanitize/reserved-check/uniqueness deseniyle doldurulur (lowercase, `%.%` değil bu kez düz slug kontrolü, reserved-label listesine karşı kontrol).

Her iki tabloda da `ENABLE ROW LEVEL SECURITY` + `REVOKE ALL ... FROM anon, authenticated` — tüm erişim RPC üzerinden (CRM v2 `customer_notes`/`customer_tags` deseninin aynısı).

## RPC Yüzeyi

```
create_or_get_business_site_v1(p_business_id uuid) → business_sites row
  -- has_business_permission_v1(p_business_id, 'menu_write') kontrolü.
  -- Yoksa oluşturur (subdomain önerisi: business slug'ından türetilir).

save_site_draft_v1(p_site_id uuid, p_config jsonb) → void
  -- Sahiplik kontrolü (business_sites.business_id üzerinden), draft revision'ı
  -- overwrite eder (Faz 0'da versiyon geçmişi yok).

publish_site_v1(p_site_id uuid) → void
  -- Sahiplik kontrolü, draft_revision_id → published_revision_id repoint.

get_published_site_v1(p_subdomain text) → jsonb
  -- SECURITY DEFINER, GRANT TO anon, authenticated (public render için).
  -- Yalnızca published_revision'ın config'ini döner — draft asla görünmez.
```

Draft okuma için ayrı bir public RPC yok (Faz 0'da editör her zaman aynı oturumdaki owner tarafından, sunucu tarafında `service` context olmadan, doğrudan Supabase client + RLS-korumalı RPC üzerinden okur).

**Tek kaynak prensibi (planın §23'ü):** `site_revisions.config` yalnızca yerleşim/metin override'larını tutar (Hero başlığı gibi) — menü/fiyat/foto verisi config içine kopyalanmaz. Hero/Menu/Gallery component'leri render anında mevcut `get_business_detail_v1` gibi RPC'lerden okur. Bu, Faz 0'da bile "Yeedoy'da fiyat değişirse site de değişir" davranışını doğru kurar.

## Güvenlik

- `save_site_draft_v1`/`publish_site_v1`: security-auditor'ın C2 bulgusuyla aynı hatayı tekrarlamamak için ilk satırdan itibaren `has_business_permission_v1` kontrolü zorunlu.
- `get_published_site_v1` **tek** public-okuma yüzeyi — draft'a giden hiçbir yol anon/authenticated'e açık değil.
- `proxy.ts` wildcard resolver'ı: host normalize edilir (`toLowerCase().replace(/\.$/,'')`), reserved-label denylist'e karşı kontrol edilir, mevcut panel-subdomain rewrite'ından sonra çalışır.
- Yeni RPC'lerin hepsinde üçlü REVOKE deseni (`REVOKE ALL FROM PUBLIC` + `REVOKE EXECUTE FROM anon` + `GRANT TO authenticated`, `get_published_site_v1` hariç — o bilerek `anon`'a da açık).

## Test Planı

- **DB:** Yerel smoke test — owner kendi site'ını save/publish edebiliyor, başka bir business'ın owner'ı edemiyor (bu oturumda zincir-çapında görünüm ve custom_domains düzeltmesinde kullanılan aynı 2-rol desen).
- **Wildcard resolver:** `proxy.ts` için unit test — normalize edilmiş/edilmemiş host varyantlarının reserved-list'i doğru bypass etmediğini doğrula (security-auditor I1 bulgusunun regresyon testi).
- **Manuel E2E:** `aspava-demo.yeedoy.localhost` üzerinde gerçek tarayıcıda: panelde Hero başlığını değiştir → kaydet → canlı sitede DEĞİŞMEDİĞİNİ doğrula (draft/publish ayrımı) → yayınla → canlı sitede değiştiğini doğrula.

## Definition of Done

`aspava-demo.yeedoy.localhost` adresinde, panelde Puck ile düzenlenip "Yayınla" denince gerçekten değişen, Yeedoy'un gerçek menü/foto verisini gösteren tek bir sayfa. Ödeme, tema seçimi, custom domain yok — sadece teknik kanıt.
