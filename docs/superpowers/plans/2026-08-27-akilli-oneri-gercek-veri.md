# Akıllı Öneri Sayfası — Gerçek Veri Dönüşümü Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/oneri` ("Akıllı Öneri") sayfasındaki tüm uydurma/sahte kişiselleştirme verilerini (hash tabanlı %Uyum skoru, herkese aynı görünen sahte aktivite akışı, sabit 88/100 puan) giriş yapmış kullanıcının gerçek favori/yorum/ziyaret geçmişinden hesaplanan gerçek verilerle değiştirmek — tasarım/JSX yapısı değişmeden.

**Architecture:** İki yeni "bana özel" RPC (`get_my_recent_activity_v1`, `get_my_category_preferences_v1`) kullanıcının favorites/reviews/visits tablolarındaki gerçek etkileşimlerini birleştirip son aktiviteleri ve kategori tercih dağılımını döndürür. Sayfa (server component) oturum durumuna göre dallanır: giriş yapmışsa bu RPC'leri + zaten etkileşimde bulunduğu işletmeleri (hariç tutmak için) çeker ve saf bir fonksiyonla (yeni dosya, birim testli) her kart için gerçek bir %Uyum skoru hesaplar; giriş yapmamışsa sadece mevcut genel en-iyi listesini (zaten gerçek) gösterir, kişisel bölümler tamamen gizlenip yerlerine giriş CTA'sı gelir. Hiçbir gerçek veri kaynağı bulunmayan "Bugünkü Öneri Puanın" kartı kaldırılır (kullanıcı onayladı — bkz. Bağlam).

**Tech Stack:** Next.js server component + Supabase RPC (SQL), React client component (mevcut `oneri-canli.tsx`), Vitest (saf eşleşme-skoru fonksiyonu için birim test).

---

## Bağlam — Kullanıcı Kararları (2026-08-27)

- Kişisel bölümler (Zevklerine Göre / Son Aktivitelerin / %Uyum) **sadece giriş yapmış kullanıcıda** görünür. Giriş yapmamış ziyaretçi genel (kişiselleştirilmemiş) en-iyi işletme listesini + giriş CTA'sını görür. (Kullanıcı onayı: "Genel en-iyi listesi, kişisel kısımlar gizli".)
- "Bugünkü Öneri Puanın: 88/100" kartının arkasında hiçbir gerçek veri yok (analitik/izleme altyapısı gerektirir, hiç yok) — **kart tamamen kaldırılıyor**, yerine başka bir sahte sayı konmuyor.
- "Durumuna Göre Öneriler" (⚡ Hızlı Bir Şeyler / 🌙 Gece Atıştırmalık vb.) bölümüne dokunulmuyor — bunlar veri iddiası taşımayan statik gezinme kısayolları (hepsi `/kesif`'e yönlendiriyor), sahte veri değil.

## Bağlam — Mevcut Durum (bu oturumda doğrulandı)

- `app/(genel)/oneri/page.tsx`: `businesses_with_stats`'tan puan+yorum sayısına göre sıralı ilk 32 işletmeyi çekiyor (**gerçek**), `OneriCanli`'ye `businesses` prop'u olarak veriyor.
- `src/ui/acik/oneri-canli.tsx`: `uyumYuzde()` işletme ID'sinin hash'inden %82-99 arası rastgele bir sayı üretiyor; `kategoriDagilim` aynı global 32'lik listenin kategori dağılımını gösteriyor (kullanıcıya özel değil, herkes aynısını görüyor); `aktiviteler` yine aynı listeden ilk 3 işletmeyi alıp sabit `AKTIVITE_TURLERI`/`ZAMAN` dizileriyle "Favorilere eklendi · 2 gün önce" gibi tamamen uydurma bir akış gösteriyor; "Bugünkü Öneri Puanın" kartı `88` sabit değeriyle hardcoded.
- Gerçek ham veri zaten var: `favorites` (user_id, business_id, created_at), `reviews` (user_id, business_id, created_at — bu oturumda `business_reviews`'dan `reviews`'a taşındı), `visits` (user_id, business_id, created_at) — hepsi `favoriler/page.tsx` ve `profil/page.tsx`'te zaten kullanılıyor.
- Mobildeki `get_smart_recommendations_v2` RPC'si bütçe/parti-büyüklüğü/konum bazlı genel bir filtre — kullanıcı geçmişine dayalı kişiselleştirme yapmıyor, bu görev için uygun değil.
- Session-aware sunucu client'ı bu repoda baskın konvansiyon `@/src/lib/taban-sunucu`'dur (167 kullanım; `@/src/lib/supabaseServer` sadece 8 kullanımlı eski bir paralel — yeni kod baskın olanı kullanmalı).

---

### Task 1: "Bana özel" RPC'leri oluştur

**Files:**
- Create: `supabase/migrations/20260827000004_my_activity_and_preferences_rpc.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
-- Akıllı Öneri sayfasındaki sahte "Son Aktivitelerin" ve "Senin Zevklerine Göre"
-- bölümlerini gerçek kullanıcı geçmişiyle değiştirmek için: favorites/reviews/visits
-- tablolarındaki gerçek etkileşimleri birleştiren iki "bana özel" RPC.

CREATE OR REPLACE FUNCTION public.get_my_recent_activity_v1(p_limit int DEFAULT 3)
RETURNS TABLE(business_id uuid, activity_type text, created_at timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT business_id, 'favorite'::text AS activity_type, created_at
  FROM public.favorites WHERE user_id = auth.uid()
  UNION ALL
  SELECT business_id, 'review'::text, created_at
  FROM public.reviews WHERE user_id = auth.uid()
  UNION ALL
  SELECT business_id, 'visit'::text, created_at
  FROM public.visits WHERE user_id = auth.uid()
  ORDER BY created_at DESC
  LIMIT GREATEST(p_limit, 1);
$$;

REVOKE ALL ON FUNCTION public.get_my_recent_activity_v1(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_recent_activity_v1(int) TO authenticated;
COMMENT ON FUNCTION public.get_my_recent_activity_v1 IS
  'Kullanıcının favorites/reviews/visits birleşimindeki en son etkileşimleri. Called by: app/(genel)/oneri/page.tsx.';

CREATE OR REPLACE FUNCTION public.get_my_category_preferences_v1(p_limit int DEFAULT 3)
RETURNS TABLE(category text, interaction_count int, pct numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH interactions AS (
    SELECT business_id FROM public.favorites WHERE user_id = auth.uid()
    UNION ALL
    SELECT business_id FROM public.reviews WHERE user_id = auth.uid()
    UNION ALL
    SELECT business_id FROM public.visits WHERE user_id = auth.uid()
  ),
  by_category AS (
    SELECT b.category, count(*)::int AS interaction_count
    FROM interactions i
    JOIN public.businesses b ON b.id = i.business_id
    WHERE b.category IS NOT NULL
    GROUP BY b.category
  ),
  total AS (
    SELECT sum(interaction_count)::numeric AS n FROM by_category
  )
  SELECT
    bc.category,
    bc.interaction_count,
    round(bc.interaction_count / NULLIF((SELECT n FROM total), 0) * 100, 0) AS pct
  FROM by_category bc
  ORDER BY bc.interaction_count DESC
  LIMIT GREATEST(p_limit, 1);
$$;

REVOKE ALL ON FUNCTION public.get_my_category_preferences_v1(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_category_preferences_v1(int) TO authenticated;
COMMENT ON FUNCTION public.get_my_category_preferences_v1 IS
  'Kullanıcının favorites/reviews/visits birleşiminden gerçek kategori tercih dağılımı (en sık N kategori, yüzde ile). Called by: app/(genel)/oneri/page.tsx.';
```

- [ ] **Step 2: Production'a uygula**

```bash
cd C:/yeedoy
supabase db push --linked
```

- [ ] **Step 3: Anon çağrısının boş/reddedilmiş döndüğünü, authenticated çağrının çalıştığını doğrula**

```bash
KEY=$(grep "^NEXT_PUBLIC_SUPABASE_ANON_KEY=" uygulamalar/web/.env.local | cut -d= -f2-)
curl -s -X POST "https://wvofyimbjndxtxitsjpd.supabase.co/rest/v1/rpc/get_my_recent_activity_v1" \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d '{}'
```
Beklenen: anon (oturumsuz) çağrı `401`/`permission denied` döner (fonksiyon `authenticated`'e GRANT'lı, `anon`'a değil) — bu doğru davranıştır, sonraki adımlarda gerçek bir kullanıcı oturumuyla tarayıcıdan test edilecek.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260827000004_my_activity_and_preferences_rpc.sql
git commit -m "feat(db): Akıllı Öneri için gerçek kullanıcı aktivite/tercih RPC'leri"
```

---

### Task 2: Saf eşleşme-skoru (%Uyum) fonksiyonunu yaz + birim test

**Files:**
- Create: `uygulamalar/web/src/lib/oneri-eslesme.ts`
- Create: `uygulamalar/web/src/lib/oneri-eslesme.test.ts`

- [ ] **Step 1: Başarısız testi yaz**

```typescript
// uygulamalar/web/src/lib/oneri-eslesme.test.ts
import { describe, it, expect } from 'vitest';
import { eslesmeYuzdesiHesapla } from './oneri-eslesme';

describe('eslesmeYuzdesiHesapla', () => {
  it('tercih edilen kategoride, yüksek puanlı işletmeye yüksek skor verir', () => {
    const skor = eslesmeYuzdesiHesapla('Kafe', [{ category: 'Kafe', pct: 60 }], 4.8);
    expect(skor).toBeGreaterThanOrEqual(85);
    expect(skor).toBeLessThanOrEqual(99);
  });

  it('tercih listesinde olmayan kategoriye taban skor + puan bonusu verir', () => {
    const skor = eslesmeYuzdesiHesapla('Mekan', [{ category: 'Kafe', pct: 60 }], 3.0);
    expect(skor).toBe(70);
  });

  it('tercih/puan verisi yoksa taban skoru döner', () => {
    const skor = eslesmeYuzdesiHesapla(null, [], null);
    expect(skor).toBe(70);
  });

  it('skor her zaman 60-99 aralığında kalır', () => {
    const skor = eslesmeYuzdesiHesapla('Kafe', [{ category: 'Kafe', pct: 100 }], 5);
    expect(skor).toBeLessThanOrEqual(99);
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

```bash
cd uygulamalar/web
pnpm run test:unit -- oneri-eslesme
```
Beklenen: FAIL — `oneri-eslesme.ts` henüz yok.

- [ ] **Step 3: Fonksiyonu yaz**

```typescript
// uygulamalar/web/src/lib/oneri-eslesme.ts

/**
 * Kullanıcının gerçek kategori tercih dağılımı (favorites/reviews/visits'ten,
 * get_my_category_preferences_v1 RPC'si) ve işletmenin gerçek ortalama puanından
 * deterministik bir %Uyum skoru hesaplar. Rastgelelik/hash yok — aynı girdi her
 * zaman aynı skoru üretir.
 */
export function eslesmeYuzdesiHesapla(
  category: string | null,
  preferences: Array<{ category: string; pct: number }>,
  avgRating: number | null,
): number {
  const taban = 70;
  const tercih = category ? preferences.find((p) => p.category === category) : undefined;
  const tercihBonusu = tercih ? Math.round(tercih.pct * 0.25) : 0;
  const puanBonusu = avgRating ? Math.round(((avgRating - 3) / 2) * 10) : 0;
  return Math.max(60, Math.min(99, taban + tercihBonusu + puanBonusu));
}
```

- [ ] **Step 4: Testin geçtiğini doğrula**

```bash
pnpm run test:unit -- oneri-eslesme
```
Beklenen: PASS (4/4).

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/oneri-eslesme.ts uygulamalar/web/src/lib/oneri-eslesme.test.ts
git commit -m "feat(web): gerçek verilerden deterministik %Uyum skoru hesaplayan saf fonksiyon"
```

---

### Task 3: `page.tsx` — oturum durumuna göre gerçek veri toplama

**Files:**
- Modify: `uygulamalar/web/app/(genel)/oneri/page.tsx`

- [ ] **Step 1: Dosyayı yeniden yaz**

```tsx
import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { eslesmeYuzdesiHesapla } from '@/src/lib/oneri-eslesme';
import { OneriCanli } from '@/src/ui/acik/oneri-canli';
import type { OneriIsletme, OneriAktivite, OneriTercih } from '@/src/ui/acik/oneri-canli';

export const metadata: Metadata = {
  title: 'Akıllı Öneri | Yeedoy',
  description: 'Zevklerine ve alışkanlıklarına göre senin için seçtik!',
  openGraph: { title: 'Akıllı Öneri | Yeedoy', description: 'Zevklerine göre kişisel restoran önerileri.' },
  alternates: { canonical: '/oneri' },
};

export const revalidate = 0; // giriş yapmış kullanıcıya özel veri içerdiği için sayfa cache'lenmez

type BusinessRow = {
  id: string; name: string; category: string | null; city: string | null; district: string | null;
  is_verified: boolean | null; reviews_count: number | null; avg_rating: string | number | null;
};
type DetailRow = { id: string; slug: string | null; public_slug: string | null; logo_url: string | null; cover_url: string | null };

function toOneriIsletme(row: BusinessRow, det: DetailRow | undefined, eslesmeYuzde: number | null): OneriIsletme {
  return {
    id: row.id,
    name: row.name,
    slug: det?.public_slug ?? det?.slug ?? row.id,
    category: row.category ?? null,
    city: row.city ?? null,
    district: row.district ?? null,
    logoUrl: det?.logo_url ?? null,
    coverUrl: det?.cover_url ?? null,
    isVerified: row.is_verified ?? false,
    reviewsCount: row.reviews_count ?? 0,
    avgRating: row.avg_rating ? parseFloat(String(row.avg_rating)) : null,
    eslesmeYuzde,
  };
}

export default async function OneriPage() {
  const pub = createSupabasePublicClient() as unknown as { from: (t: string) => any };
  const auth = await createSupabaseServerClient();
  const { data: { user } } = await auth.auth.getUser();
  const authAny = auth as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any };

  // 1. Genel en-iyi işletme listesi (herkese açık, gerçek veri — değişmedi)
  const { data: statsRows } = await pub
    .from('businesses_with_stats')
    .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
    .eq('is_active', true)
    .order('avg_rating',    { ascending: false, nullsFirst: false })
    .order('reviews_count', { ascending: false, nullsFirst: false })
    .limit(32) as { data: BusinessRow[] | null };

  const rows = statsRows ?? [];
  const ids = rows.map((r) => r.id);
  const { data: details } = ids.length > 0
    ? await pub.from('businesses').select('id,slug,public_slug,logo_url,cover_url').in('id', ids) as { data: DetailRow[] | null }
    : { data: [] as DetailRow[] };
  const detMap = new Map((details ?? []).map((d) => [d.id, d]));

  let tercihler: OneriTercih[] = [];
  let secilmisler: OneriIsletme[] = [];
  let denemeler: OneriIsletme[] = [];
  let aktiviteler: OneriAktivite[] = [];

  if (!user) {
    // Giriş yapmamış: kişiselleştirme yok, sadece genel liste, %Uyum badge'i yok.
    secilmisler = rows.slice(0, 8).map((r) => toOneriIsletme(r, detMap.get(r.id), null));
  } else {
    const [{ data: prefRows }, { data: actRows }, favRes, revRes, visRes] = await Promise.all([
      authAny.rpc('get_my_category_preferences_v1', { p_limit: 3 }) as Promise<{ data: OneriTercih[] | null }>,
      authAny.rpc('get_my_recent_activity_v1', { p_limit: 3 }) as Promise<{ data: Array<{ business_id: string; activity_type: string; created_at: string }> | null }>,
      authAny.from('favorites').select('business_id').eq('user_id', user.id) as Promise<{ data: Array<{ business_id: string }> | null }>,
      authAny.from('reviews').select('business_id').eq('user_id', user.id) as Promise<{ data: Array<{ business_id: string }> | null }>,
      authAny.from('visits').select('business_id').eq('user_id', user.id) as Promise<{ data: Array<{ business_id: string }> | null }>,
    ]);

    tercihler = prefRows ?? [];

    const etkilesimliIdler = new Set([
      ...(favRes.data ?? []).map((r) => r.business_id),
      ...(revRes.data ?? []).map((r) => r.business_id),
      ...(visRes.data ?? []).map((r) => r.business_id),
    ]);

    secilmisler = rows.slice(0, 8).map((r) => {
      const det = detMap.get(r.id);
      const skor = eslesmeYuzdesiHesapla(r.category, tercihler, r.avg_rating ? parseFloat(String(r.avg_rating)) : null);
      return toOneriIsletme(r, det, skor);
    });

    denemeler = rows
      .filter((r) => !etkilesimliIdler.has(r.id))
      .slice(0, 8)
      .map((r) => {
        const det = detMap.get(r.id);
        const skor = eslesmeYuzdesiHesapla(r.category, tercihler, r.avg_rating ? parseFloat(String(r.avg_rating)) : null);
        return toOneriIsletme(r, det, skor);
      });

    const aktRows = actRows ?? [];
    const aktBusinessIds = aktRows.map((a) => a.business_id);
    const { data: aktDetails } = aktBusinessIds.length > 0
      ? await pub.from('businesses').select('id,name,slug,public_slug,logo_url').in('id', aktBusinessIds) as { data: Array<DetailRow & { name: string }> | null }
      : { data: [] as Array<DetailRow & { name: string }> };
    const aktBizMap = new Map((aktDetails ?? []).map((d) => [d.id, d]));

    aktiviteler = aktRows
      .map((a) => {
        const biz = aktBizMap.get(a.business_id);
        if (!biz) return null;
        return {
          businessId: a.business_id,
          businessName: biz.name,
          slug: biz.public_slug ?? biz.slug ?? a.business_id,
          activityType: a.activity_type as OneriAktivite['activityType'],
          createdAt: a.created_at,
        } satisfies OneriAktivite;
      })
      .filter((a): a is OneriAktivite => a !== null);
  }

  return (
    <PublicShell>
      <OneriCanli
        loggedIn={!!user}
        secilmisler={secilmisler}
        denemeler={denemeler}
        tercihler={tercihler}
        aktiviteler={aktiviteler}
      />
    </PublicShell>
  );
}
```

- [ ] **Step 2: Bu adımda typecheck HATA VERECEK** (çünkü `oneri-canli.tsx` henüz eski prop şeklini bekliyor — `OneriAktivite`/`OneriTercih` tipleri yok, `businesses` prop'u kaldırıldı). Bu beklenen bir ara durumdur, Task 4'te düzelecek. Şimdi devam et, Task 4 bitmeden commit ATMA.

---

### Task 4: `oneri-canli.tsx` — gerçek veriyi tüket, sahte üretim mantığını kaldır

**Files:**
- Modify: `uygulamalar/web/src/ui/acik/oneri-canli.tsx`

- [ ] **Step 1: Tipleri ve sahte veri üreten kodu değiştir**

Kaldırılacaklar: `hash()`, `uyumYuzde()`, `ETIKET_MAP` (kategori bazlı sabit metin — kalabilir, gerçek `category` alanına bağlı bir *sunum* eşlemesi, veri fabrikasyonu değil), `AKTIVITE_TURLERI`, `ZAMAN` sabit dizileri, "Bugünkü Öneri Puanın" kartı ve ona ait JSX bloğu.

`OneriIsletme` tipine `eslesmeYuzde: number | null` eklenir. Yeni tipler:

```typescript
export type OneriTercih = { category: string; interaction_count: number; pct: number };

export type OneriAktivite = {
  businessId: string;
  businessName: string;
  slug: string;
  activityType: 'favorite' | 'review' | 'visit';
  createdAt: string;
};
```

`Props`:

```typescript
type Props = {
  loggedIn: boolean;
  secilmisler: OneriIsletme[];
  denemeler: OneriIsletme[];
  tercihler: OneriTercih[];
  aktiviteler: OneriAktivite[];
};

export function OneriCanli({ loggedIn, secilmisler, denemeler, tercihler, aktiviteler }: Props) {
```

- [ ] **Step 2: `OneriKarti`'daki %Uyum rozetini gerçek veriye bağla**

```tsx
function OneriKarti({ biz, tip }: { biz: OneriIsletme; tip: 'secilmis' | 'deneme' }) {
  const img = buildMenuImageUrl(biz.coverUrl ?? biz.logoUrl ?? null, { width: 480, quality: 78 })
    ?? '/category-images/restoran.webp';
  const etiket = ETIKET_MAP[biz.category ?? ''] ?? { text: 'Sık tercih ettiğin mekan', color: '#7f1d1d' };

  return (
    <Link href={`/isletme/${biz.slug}`} className="group flex w-[220px] shrink-0 flex-col overflow-hidden rounded-2xl border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
      <div className="relative h-[140px] w-full overflow-hidden">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={img} alt={biz.name} className="h-full w-full object-cover transition-transform group-hover:scale-105" loading="lazy" />

        {biz.eslesmeYuzde != null ? (
          <div className="absolute left-2 top-2 rounded-full bg-success px-2.5 py-1 text-[11px] font-black text-white shadow-xs">
            %{biz.eslesmeYuzde} Uyum
          </div>
        ) : (
          <div className="absolute left-2 top-2 rounded-full bg-primary px-2.5 py-1 text-[11px] font-black text-white shadow-xs">
            Popüler
          </div>
        )}
        {tip === 'deneme' && (
          <div className="absolute left-2 top-9 rounded-full px-2.5 py-1 text-[11px] font-black text-white shadow-xs" style={{ background: '#7c3aed' }}>
            Yeni
          </div>
        )}

        {/* Favori butonu — değişmedi */}
        <button
          type="button"
          aria-label="Favorilere ekle"
          onClick={(e) => e.preventDefault()}
          className="absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-white/90 text-muted shadow-sm backdrop-blur-sm transition-colors hover:text-primary"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
          </svg>
        </button>
      </div>

      <div className="flex flex-1 flex-col gap-1.5 p-3">
        <p className="line-clamp-1 text-sm font-black text-textStrong group-hover:text-primary">{biz.name}</p>
        <p className="line-clamp-1 text-[11px] font-bold text-muted">
          {biz.category ?? '—'}
          {biz.district ? ` · ${biz.district}` : biz.city ? ` · ${biz.city}` : ''}
        </p>
        {biz.avgRating && biz.avgRating > 0 ? (
          <div className="flex items-center gap-1.5 text-[11px] font-extrabold">
            <span className="flex items-center gap-0.5 text-amber-500">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
              {biz.avgRating.toFixed(1)}
            </span>
            {biz.reviewsCount > 0 && <span className="text-muted">({biz.reviewsCount.toLocaleString('tr-TR')})</span>}
          </div>
        ) : null}
        <div className="mt-auto pt-1.5">
          <span className="inline-block rounded-full px-2.5 py-1 text-[10px] font-extrabold" style={{ background: `${etiket.color}18`, color: etiket.color }}>
            {etiket.text}
          </span>
        </div>
      </div>
    </Link>
  );
}
```

(Not: `tip==='deneme'` rozetinin sol-üst ikinci satıra taşınması, %Uyum/Popüler rozetiyle çakışmaması içindir — tek görsel ekleme, kart boyutu/yerleşimi değişmiyor.)

- [ ] **Step 3: Aktivite zaman biçimlendirme yardımcısı ekle**

```typescript
function zamanFarki(iso: string): string {
  const gun = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
  if (gun < 1) return 'Bugün';
  if (gun < 7) return `${gun} gün önce`;
  const hafta = Math.floor(gun / 7);
  if (hafta < 5) return `${hafta} hafta önce`;
  return `${Math.floor(gun / 30)} ay önce`;
}

const AKTIVITE_ETIKET: Record<OneriAktivite['activityType'], string> = {
  favorite: 'Favorilere eklendi',
  review:   'Yorum yaptın',
  visit:    'Ziyaret ettin',
};
```

- [ ] **Step 4: Sidebar'ı `loggedIn`'e göre dallandır — kişisel kartlar ya da giriş CTA'sı**

Mevcut "Senin Zevklerine Göre" ve "Son Aktivitelerin" kartlarının `kategoriDagilim`/`aktiviteler` useMemo'ları silinir (artık prop olarak geliyor). "Bugünkü Öneri Puanın" kartı tamamen silinir. Sidebar JSX'i:

```tsx
{/* Sol sidebar */}
<aside className="w-full space-y-5 lg:w-64 lg:shrink-0 lg:sticky lg:top-20 lg:self-start">
  {loggedIn ? (
    <>
      {tercihler.length > 0 && (
        <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
          <h2 className="mb-3 text-sm font-black text-textStrong">Senin Zevklerine Göre</h2>
          <div className="space-y-3">
            {tercihler.map(({ category, pct }) => {
              const KatIcon = KAT_ICON[category] ?? Utensils;
              return (
                <div key={category} className="flex items-center gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/5 text-primary">
                    <KatIcon size={18} aria-hidden="true" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-black text-textStrong leading-tight">{category}</p>
                  </div>
                  <span className="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-black text-primary">
                    %{pct}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {aktiviteler.length > 0 && (
        <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
          <h2 className="mb-3 text-sm font-black text-textStrong">Son Aktivitelerin</h2>
          <div className="space-y-3">
            {aktiviteler.map((a) => (
              <Link key={`${a.businessId}-${a.createdAt}`} href={`/isletme/${a.slug}`} className="flex items-center gap-2.5 hover:opacity-80">
                <AktiviteIkon tip={a.activityType === 'favorite' ? 'heart' : a.activityType === 'review' ? 'star' : 'eye'} />
                <div className="min-w-0 flex-1">
                  <p className="line-clamp-1 text-sm font-black text-textStrong">{a.businessName}</p>
                  <p className="text-[11px] font-bold text-muted">{AKTIVITE_ETIKET[a.activityType]}</p>
                </div>
                <span className="shrink-0 text-[11px] font-bold text-muted">{zamanFarki(a.createdAt)}</span>
              </Link>
            ))}
          </div>
        </div>
      )}

      {tercihler.length === 0 && aktiviteler.length === 0 && (
        <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
          <h2 className="mb-1.5 text-sm font-black text-textStrong">Henüz veri yok</h2>
          <p className="text-[12px] font-bold text-muted">
            Favorilerine ekle, yorum yap veya ziyaretlerini işaretle — sana özel önerileri burada göreceksin.
          </p>
        </div>
      )}
    </>
  ) : (
    <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4 shadow-yd1">
      <h2 className="mb-1.5 text-sm font-black text-textStrong">Sana özel öneriler için giriş yap</h2>
      <p className="mb-3 text-[12px] font-bold text-muted">
        Zevklerine göre eşleşme skorları ve son aktivitelerin burada görünsün.
      </p>
      <Link href="/giris" className="flex h-10 items-center justify-center rounded-xl bg-primary text-sm font-black text-white transition-all hover:brightness-110">
        Giriş Yap / Üye Ol
      </Link>
    </div>
  )}
</aside>
```

- [ ] **Step 5: Ana içerikte "Denemeni Öneririz" bölümünü sadece giriş yapmış + veri varsa göster**

```tsx
{secilmisler.length > 0 && (
  <KarouselBolum baslik="Senin İçin Seçtiklerimiz" tip="secilmis" businesses={secilmisler} />
)}

{loggedIn && denemeler.length > 0 && (
  <KarouselBolum
    baslik="Denemeni Öneririz"
    alt="Daha önce gitmediğin ama sevebileceğin mekanlar"
    tip="deneme"
    businesses={denemeler}
  />
)}
```

- [ ] **Step 6: `handleYenile`/`spinning` state'ini kaldır** — sayfa artık sunucu tarafında gerçek veriyle geliyor, client-side "yenile" animasyonunun arkasında hiçbir yeniden-hesaplama olmadığından (sadece 700ms dönen bir ikon) bu da bir tür sahte etkileşimdi. Buton ve state tamamen kaldırılır (başlık satırı sadece `<h1>`+alt yazıdan ibaret kalır).

- [ ] **Step 7: Typecheck + lint**

```bash
cd uygulamalar/web
pnpm run typecheck
pnpm run lint
```
Beklenen: 0 hata.

- [ ] **Step 8: Commit**

```bash
git add uygulamalar/web/app/\(genel\)/oneri/page.tsx uygulamalar/web/src/ui/acik/oneri-canli.tsx
git commit -m "feat(web): Akıllı Öneri sayfası gerçek kullanıcı verisiyle çalışıyor (sahte %Uyum/aktivite/puan kaldırıldı)"
```

---

### Task 5: Manuel doğrulama (giriş yapmış + yapmamış)

**Files:** Yok

- [ ] **Step 1: Giriş yapmamış ziyaretçi olarak `/oneri`'yi aç**

Beklenen: "Senin İçin Seçtiklerimiz" karuseli görünür, her kartta yeşil "Popüler" rozeti var (yeşil "%X Uyum" değil). Sidebar'da "Sana özel öneriler için giriş yap" kartı var. "Denemeni Öneririz" bölümü hiç yok. "Bugünkü Öneri Puanın" kartı hiç yok.

- [ ] **Step 2: Gerçek bir hesapla giriş yap (favorisi/yorumu olan bir test kullanıcısı — örn. bu oturumda incelenen `d1d1d1d1`/`kullanici1` gibi bir demo hesap, veya kendi hesabınız), `/oneri`'yi tekrar aç**

Beklenen: "Senin Zevklerine Göre" gerçek kategori yüzdeleriyle dolu, "Son Aktivitelerin" gerçek işletme adı + doğru "X gün önce" ile dolu, kartlarda "%Uyum" rozeti (yeşil, "Popüler" değil) görünüyor, "Denemeni Öneririz" bölümü (daha önce hiç favorilemediği/yorum yapmadığı/ziyaret etmediği işletmeler) görünüyor.

- [ ] **Step 3: Favori/yorum/ziyaret geçmişi olmayan yeni bir hesapla giriş yap**

Beklenen: Sidebar'da "Henüz veri yok" kartı görünüyor (boş dizi durumu), sayfa çökmüyor.

---

## Notlar

- "Durumuna Göre Öneriler" (⚡/🌙/👥/🎁 statik gezinme kartları) bu planın kapsamı DIŞINDA — kullanıcı onayladı, veri iddiası taşımıyorlar.
- `eslesmeYuzdesiHesapla` formülündeki ağırlıklar (taban 70, tercih bonusu ×0.25, puan bonusu) bir tasarım tercihidir — gerçek girdilerden (kategori tercih yüzdesi + gerçek ortalama puan) deterministik olarak hesaplanır, rastgelelik/hash YOKTUR. İleride ince ayar gerekirse tek dosyada (`oneri-eslesme.ts`) değiştirilir, testler (`oneri-eslesme.test.ts`) korunur.
