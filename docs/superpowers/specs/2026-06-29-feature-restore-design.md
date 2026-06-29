# Feature Restore & Wiring Design
**Tarih:** 2026-06-29  
**Kapsam:** Akıllı akış, zincir işletmeler, profil yorumları, owner domain doğrulama

---

## Görev 1 — Akıllı Akış: Mobil

**Değişiklikler:**
- `uygulamalar/mobil/lib/app/router.dart` — `/feed` rotasından `enablePhotoFeed` flag kontrolü kaldırılır; rota her zaman aktif.
- `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` — Mevcut `_QuickActionRow`'a "Akıllı Akış" hücresi eklenir; `Icons.dynamic_feed_outlined`, route `/feed`.
- `uygulamalar/mobil/lib/features/shared/ui/labs_page.dart` — `/feed` labs listesinden çıkarılır.

**Kabul kriteri:** Profil sayfasında "Akıllı Akış" butonuna tıklamak `SmartFeedPage`'i açar. `flutter analyze` hata yok.

---

## Görev 2 — Akıllı Akış: Web

**Değişiklikler:**
- `uygulamalar/web/app/(kimlik)/akilli-akis/page.tsx` — `redirect` kaldırılır; SSR ile `get_smart_feed_v2(p_limit:20, p_offset:0)` çağrılır, `AkilliAkisIstemcisi` client component'ına iletilir.
- `uygulamalar/web/src/ui/bolumler/akilli-akis-istemcisi.tsx` (yeni) — Infinite scroll client component. Her kart: event_type badge + ikon, işletme adı (link), payload özet, relative time. "Daha fazla yükle" IntersectionObserver ile tetiklenir.
- Auth: `(kimlik)` layout zaten auth guard sağlıyor — ek guard gerekmez.
- `(auth)/smart-feed/page.tsx` stub'ı aynı kalır (EN redirect mirror).

**Veri şeması:** `SmartFeedEvent { event_type, business_id, business_name, created_at, ref_type, ref_id, payload }`  
**RPC:** `get_smart_feed_v2` — authenticated GRANT'li, DB'de mevcut.

**Kabul kriteri:** `/akilli-akis` sayfası eventi listeler; scroll sonu "daha fazla" yükler; `npm run typecheck` hata yok.

---

## Görev 3 — Zincir İşletmeler: Mobil (Chain Band)

**Migration:**
- `supabase/migrations/YYYYMMDD_get_business_chain_info_v1.sql` (yeni)
  ```sql
  CREATE OR REPLACE FUNCTION public.get_business_chain_info_v1(p_business_id uuid)
  RETURNS TABLE(chain_id uuid, chain_name text)
  LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
    SELECT c.id, c.name
    FROM public.businesses b
    JOIN public.chains c ON c.id = b.chain_id
    WHERE b.id = p_business_id AND b.chain_id IS NOT NULL
    LIMIT 1;
  $$;
  GRANT EXECUTE ON FUNCTION public.get_business_chain_info_v1(uuid) TO anon, authenticated;
  ```

**Mobil değişiklikler:**
- `uygulamalar/mobil/lib/features/business/data/business_repository.dart` — `fetchChainInfo(String businessId)` metodu eklenir; `get_business_chain_info_v1` çağırır; nullable `ChainInfo` döner.
- `uygulamalar/mobil/lib/features/business/domain/business_models.dart` — `ChainInfo({String chainId, String chainName})` model eklenir.
- İşletme detay sayfasında hero altına `_ChainBand` widget: "Bu işletme **[chainName]** zincirinin parçasıdır → Tüm Şubeleri Gör". `FutureProvider` ile yüklenir; chain yoksa `SizedBox.shrink()`. Tap: `context.push('/chain/$chainId')`.

**Kabul kriteri:** Zincire bağlı işletmede band görünür, tıklamak `ChainPage`'i açar; chain'siz işletmede band yok. `flutter analyze` hata yok.

---

## Görev 4 — Zincir İşletmeler: Web Sayfası

**Değişiklikler:**
- `uygulamalar/web/app/(genel)/zincir/[slug]/page.tsx` — `redirect` kaldırılır; `slug` param'ı chain UUID olarak kullanılır; `get_chain_overview_v2(p_chain_id: slug)` RPC çağrılır.
- UI: Chain adı + açıklaması header. Şube listesi: şube adı (business_name), branch_label badge, şehir/ilçe, adres, açık/kapalı badge, fiyat farkı chip (price_delta_pct). Her şube işletme sayfasına link (slug ile).
- `(genel)/zincirler/page.tsx` stub olarak kalır (liste sayfası kapsam dışı).

**RPC:** `get_chain_overview_v2` — anon GRANT'li, DB'de mevcut.

**Kabul kriteri:** `/zincir/[chain-uuid]` sayfası şubeleri gösterir; `npm run typecheck` hata yok.

---

## Görev 5 — Profil "Yorumlarım" Navigasyon: Mobil

**Değişiklikler:**
- `uygulamalar/mobil/lib/features/reviews/ui/my_reviews_page.dart` (yeni) — Kullanıcının kendi yorumlarını listeleyen minimal sayfa. `ReviewsRepository` üzerinden `user_id` filtresiyle sorgular. Mevcut `ReviewCard` widget'ı kullanır.
- `uygulamalar/mobil/lib/app/router.dart` — `/my-reviews` rotası eklenir → `MyReviewsPage`.
- `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` — `onTap: () {/* TODO */}` → `context.push('/my-reviews')`.

**Mevcut altyapı:** `ReviewsRepository`, `ReviewCard` mevcut — yeni sayfa bunları kullanır.

**Kabul kriteri:** Profilde "Yorumlarım" tıklamak yorum listesini açar; `flutter analyze` hata yok.

---

## Görev 6 — Owner Domain Doğrulama: Web

**Değişiklikler:**
- `uygulamalar/web/app/api/owner/domain/route.ts` (yeni) — `POST {business_id, domain}`: Zod doğrulama, auth kontrol, rate limit (3/saat). `custom_domains` tablosuna `dns_txt_token = gen_random_uuid()` ile insert; token'ı döner.
- `uygulamalar/web/app/owner/settings/domain/page.tsx` — Server component kalır (işletme listesi için). Her işletme kartına `DomainVerifyCard` client component eklenir.
- `uygulamalar/web/src/ui/bilesenler/domain-verify-card.tsx` (yeni) — 3 aşamalı UI: (1) Domain input + "Ekle" → API çağrısı → (2) TXT token göster + DNS talimatları + "Doğrula" → `verify-domain` edge function çağrısı → (3) Başarı/hata durumu.

**Kabul kriteri:** Domain eklenip TXT token alınabilir; "Doğrula" edge function'ı çağırır; `npm run typecheck` hata yok.

---

## Paralel Ajan Planı

| Ajan | Görevler | Worktree Branch | Tip |
|------|----------|-----------------|-----|
| mobile-profile | 1 + 5 (profil, router) | `feat/mobile-feed-reviews` | `mobile-developer` |
| mobile-chain | 3 (chain band + migration) | `feat/mobile-chain-band` | `mobile-developer` |
| web-feed | 2 (akıllı akış sayfası) | `feat/web-akilli-akis` | `nextjs-developer` |
| web-chain | 4 (zincir sayfası) | `feat/web-zincir-sayfasi` | `nextjs-developer` |
| web-domain | 6 (owner domain) | `feat/web-owner-domain` | `nextjs-developer` |
