# Owner Analitik Sayfası Görsel Yenileme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `app/owner/(panel)/analytics/` sayfasının görsel tasarımını, kullanıcının paylaştığı mockup'ın stiline uydur; her gösterilen metriğin gerçek bir veri kaynağı olmasını garanti et (bkz. `docs/superpowers/specs/2026-07-17-owner-analitik-tasarim-yenileme-design.md`).

**Architecture:** Yeni pure aggregation fonksiyonları (`src/lib/veri/owner/analitik-yardimcilari.ts`) `page.tsx`'in mevcut ham event/tablo sorgularını yeni şekillere dönüştürür; `analytics-client.tsx` bu şekilleri mockup'ın kart/renk/grid düzenine göre render eder. Hiçbir yeni Supabase RPC/migration gerekmiyor — tüm veriler zaten var olan `analytics_events` ve `reservations` tablolarından.

**Tech Stack:** Next.js 15 App Router (server component `page.tsx`), React client component (`analytics-client.tsx`), Recharts, Vitest (pure fonksiyon testleri).

---

## Dosya haritası

- **Create:** `uygulamalar/web/src/lib/veri/owner/analitik-yardimcilari.ts` — pure aggregation fonksiyonları (gün×saat ısı haritası, en iyi gün/saat, rezervasyon durum dağılımı)
- **Create:** `uygulamalar/web/test/lib/analitik-yardimcilari.test.ts` — yukarıdakinin vitest testleri
- **Modify:** `uygulamalar/web/app/owner/(panel)/analytics/page.tsx` — yeni sorgular + yeni helper çağrıları + yeni prop'lar
- **Modify:** `uygulamalar/web/app/owner/(panel)/analytics/analytics-client.tsx` — KPI renkleri, donut toplam/adet, Rezervasyon Durumu kartı, birleşik saat ısı haritası, Eylemler listesi, Performans Özeti güncellemesi

---

### Task 1: Pure aggregation helper'ları + testleri

**Files:**
- Create: `uygulamalar/web/src/lib/veri/owner/analitik-yardimcilari.ts`
- Test: `uygulamalar/web/test/lib/analitik-yardimcilari.test.ts`

- [ ] **Step 1: Testleri yaz (henüz implementasyon yok, başarısız olmalı)**

`uygulamalar/web/test/lib/analitik-yardimcilari.test.ts` dosyasını oluştur:

```typescript
import { describe, expect, it } from 'vitest';
import {
  buildHourBucketHeatmap,
  findBestDay,
  findBestHourRange,
  reservationStatusBreakdown,
} from '@/src/lib/veri/owner/analitik-yardimcilari';

// 2026-07-13 Pazartesi, 2026-07-19 Pazar (Pzt=index0, Paz=index6)
const MONDAY_9AM   = new Date(2026, 6, 13, 9, 0, 0).toISOString();
const MONDAY_9AM_2 = new Date(2026, 6, 13, 9, 15, 0).toISOString();
const MONDAY_9AM_3 = new Date(2026, 6, 13, 9, 30, 0).toISOString();
const MONDAY_9PM   = new Date(2026, 6, 13, 21, 0, 0).toISOString();
const MONDAY_9PM_2 = new Date(2026, 6, 13, 21, 30, 0).toISOString();
const SUNDAY_1AM   = new Date(2026, 6, 19, 1, 0, 0).toISOString();

describe('buildHourBucketHeatmap', () => {
  it('gün×saat bloğuna göre doğru grid üretir (6 satır × 7 sütun)', () => {
    const rows = buildHourBucketHeatmap([
      { created_at: MONDAY_9AM },
      { created_at: MONDAY_9AM_2 },
      { created_at: MONDAY_9AM_3 },
      { created_at: MONDAY_9PM },
      { created_at: MONDAY_9PM_2 },
      { created_at: SUNDAY_1AM },
    ]);

    expect(rows).toHaveLength(6);
    expect(rows.map((r) => r.bucketLabel)).toEqual([
      '00:00', '04:00', '08:00', '12:00', '16:00', '20:00',
    ]);

    // 08:00 bloğu (saat 8-11), Pazartesi sütunu (index 0) → 3 olay
    expect(rows[2].counts[0]).toBe(3);
    // 20:00 bloğu (saat 20-23), Pazartesi sütunu (index 0) → 2 olay
    expect(rows[5].counts[0]).toBe(2);
    // 00:00 bloğu (saat 0-3), Pazar sütunu (index 6) → 1 olay
    expect(rows[0].counts[6]).toBe(1);

    // norms: max=3 → 08:00/Pzt=100, 20:00/Pzt=round(2/3*100)=67, 00:00/Paz=round(1/3*100)=33
    expect(rows[2].norms[0]).toBe(100);
    expect(rows[5].norms[0]).toBe(67);
    expect(rows[0].norms[6]).toBe(33);
  });

  it('boş girdi için tüm hücreleri sıfır döndürür', () => {
    const rows = buildHourBucketHeatmap([]);
    expect(rows).toHaveLength(6);
    for (const row of rows) {
      expect(row.counts).toEqual([0, 0, 0, 0, 0, 0, 0]);
      expect(row.norms).toEqual([0, 0, 0, 0, 0, 0, 0]);
    }
  });
});

describe('findBestDay', () => {
  it('en yüksek current değerine sahip günün etiketini döndürür', () => {
    const result = findBestDay([
      { label: '13 Tem', current: 5 },
      { label: '14 Tem', current: 12 },
      { label: '15 Tem', current: 3 },
    ]);
    expect(result).toBe('14 Tem');
  });

  it('tüm değerler sıfırsa null döndürür', () => {
    const result = findBestDay([
      { label: '13 Tem', current: 0 },
      { label: '14 Tem', current: 0 },
    ]);
    expect(result).toBeNull();
  });
});

describe('findBestHourRange', () => {
  it('en yoğun bloğun saat aralığını döndürür', () => {
    const rows = buildHourBucketHeatmap([
      { created_at: MONDAY_9PM },
      { created_at: MONDAY_9PM_2 },
    ]);
    expect(findBestHourRange(rows)).toBe('20:00–24:00');
  });

  it('tüm hücreler sıfırsa null döndürür', () => {
    const rows = buildHourBucketHeatmap([]);
    expect(findBestHourRange(rows)).toBeNull();
  });
});

describe('reservationStatusBreakdown', () => {
  it('durumlara göre sayım ve yüzde hesaplar, sabit sırayla döner', () => {
    const result = reservationStatusBreakdown([
      { status: 'confirmed' },
      { status: 'confirmed' },
      { status: 'pending' },
      { status: 'cancelled' },
    ]);

    expect(result).toEqual([
      { status: 'confirmed', label: 'Onaylandı',     count: 2, pct: 50 },
      { status: 'pending',   label: 'Bekliyor',       count: 1, pct: 25 },
      { status: 'completed', label: 'Tamamlandı',     count: 0, pct: 0 },
      { status: 'cancelled', label: 'İptal Edildi',   count: 1, pct: 25 },
    ]);
  });

  it('boş dizi için tüm sayım/yüzdeleri sıfır döndürür', () => {
    const result = reservationStatusBreakdown([]);
    expect(result.every((r) => r.count === 0 && r.pct === 0)).toBe(true);
    expect(result).toHaveLength(4);
  });
});
```

- [ ] **Step 2: Testleri çalıştır, başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && npm run test:unit -- analitik-yardimcilari`
Expected: FAIL — `Cannot find module '@/src/lib/veri/owner/analitik-yardimcilari'`

- [ ] **Step 3: Implementasyonu yaz**

`uygulamalar/web/src/lib/veri/owner/analitik-yardimcilari.ts` dosyasını oluştur:

```typescript
export type RawTimestampRow = { created_at: string };

export type HourBucketRow = {
  bucketLabel: string;
  counts: number[];
  norms: number[];
};

export type ReservationStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed';

export type ReservationStatusRow = {
  status: ReservationStatus;
  label: string;
  count: number;
  pct: number;
};

// JS Date.getDay() (0=Pazar..6=Cumartesi) → görüntü sütun sırası: Pzt,Sal,Çar,Per,Cum,Cmt,Paz
const DOW_ORDER = [1, 2, 3, 4, 5, 6, 0];

const HOUR_BUCKETS = [
  { label: '00:00', start: 0,  end: 4 },
  { label: '04:00', start: 4,  end: 8 },
  { label: '08:00', start: 8,  end: 12 },
  { label: '12:00', start: 12, end: 16 },
  { label: '16:00', start: 16, end: 20 },
  { label: '20:00', start: 20, end: 24 },
];

/** Ham event zaman damgalarını gün(Pzt-Paz)×4-saatlik-blok ısı haritasına çevirir. */
export function buildHourBucketHeatmap(rows: RawTimestampRow[]): HourBucketRow[] {
  const grid = HOUR_BUCKETS.map(() => Array(7).fill(0));

  for (const row of rows) {
    const d = new Date(row.created_at);
    const hour = d.getHours();
    const dowIndex = DOW_ORDER.indexOf(d.getDay());
    const bucketIndex = HOUR_BUCKETS.findIndex((b) => hour >= b.start && hour < b.end);
    if (bucketIndex === -1 || dowIndex === -1) continue;
    grid[bucketIndex][dowIndex]++;
  }

  const max = Math.max(...grid.flat(), 1);

  return HOUR_BUCKETS.map((bucket, i) => ({
    bucketLabel: bucket.label,
    counts: grid[i],
    norms: grid[i].map((c) => Math.round((c / max) * 100)),
  }));
}

/** dailyData içinden en yüksek `current` değerine sahip günün etiketini döndürür. */
export function findBestDay(dailyData: { label: string; current: number }[]): string | null {
  let best: { label: string; current: number } | null = null;
  for (const point of dailyData) {
    if (point.current > 0 && (best === null || point.current > best.current)) {
      best = point;
    }
  }
  return best?.label ?? null;
}

/** Isı haritasındaki en yoğun 4 saatlik bloğun aralığını "16:00–20:00" formatında döndürür. */
export function findBestHourRange(rows: HourBucketRow[]): string | null {
  let bestIndex = -1;
  let bestTotal = 0;
  rows.forEach((row, i) => {
    const total = row.counts.reduce((a, b) => a + b, 0);
    if (total > bestTotal) {
      bestTotal = total;
      bestIndex = i;
    }
  });
  if (bestIndex === -1) return null;

  const bucket = HOUR_BUCKETS[bestIndex];
  const endLabel = bucket.end === 24 ? '24:00' : `${bucket.end.toString().padStart(2, '0')}:00`;
  return `${bucket.label}–${endLabel}`;
}

const RESERVATION_STATUS_LABELS: Record<ReservationStatus, string> = {
  confirmed: 'Onaylandı',
  pending:   'Bekliyor',
  completed: 'Tamamlandı',
  cancelled: 'İptal Edildi',
};

const RESERVATION_STATUS_ORDER: ReservationStatus[] = [
  'confirmed', 'pending', 'completed', 'cancelled',
];

/** Rezervasyon satırlarını (sadece `status` alanı yeterli) durum bazlı sayım+yüzdeye çevirir. */
export function reservationStatusBreakdown(rows: { status: string }[]): ReservationStatusRow[] {
  const counts: Record<string, number> = { pending: 0, confirmed: 0, cancelled: 0, completed: 0 };
  for (const r of rows) {
    if (r.status in counts) counts[r.status]++;
  }
  const total = rows.length;

  return RESERVATION_STATUS_ORDER.map((status) => ({
    status,
    label: RESERVATION_STATUS_LABELS[status],
    count: counts[status],
    pct: total > 0 ? Math.round((counts[status] / total) * 1000) / 10 : 0,
  }));
}
```

- [ ] **Step 4: Testleri çalıştır, geçtiğini doğrula**

Run: `cd uygulamalar/web && npm run test:unit -- analitik-yardimcilari`
Expected: PASS — 8 test, hepsi yeşil

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/veri/owner/analitik-yardimcilari.ts uygulamalar/web/test/lib/analitik-yardimcilari.test.ts
git commit -m "feat(web): owner analitik için gün×saat ısı haritası ve rezervasyon durum helper'ları ekle"
```

---

### Task 2: `page.tsx` veri katmanı güncellemesi

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/analytics/page.tsx` (tüm dosya değiştirilecek)

- [ ] **Step 1: Dosyanın tamamını aşağıdakiyle değiştir**

`uygulamalar/web/app/owner/(panel)/analytics/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import {
  buildHourBucketHeatmap,
  findBestDay,
  findBestHourRange,
  reservationStatusBreakdown,
} from '@/src/lib/veri/owner/analitik-yardimcilari';
import { AnalyticsClient } from './analytics-client';
import type { DailyPoint, TrafficSource, ActionMetric } from './analytics-client';

export const metadata: Metadata = {
  title: 'İstatistikler | Owner Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ period?: string }> };

// Real source values → display labels
const SOURCE_LABELS: Record<string, string> = {
  web_next_public: 'Doğrudan',
  menu_page:       'Menü',
  discover:        'Keşfet',
  discover_search: 'Keşfet',
  discover_list:   'Keşfet',
};
const SRC_COLORS = ['#7f1d1d', '#dc2626', '#ef4444', '#fca5a5', '#fde8e8'];

export default async function OwnerAnalyticsPage({ searchParams }: Props) {
  const { period: periodParam } = await searchParams;
  const period = ['7d', '30d', '90d'].includes(periodParam ?? '') ? (periodParam as string) : '30d';
  const days = period === '7d' ? 7 : period === '90d' ? 90 : 30;

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: claims } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved') as { data: { business_id: string }[] | null };

  const businessIds = (claims ?? []).map((c) => c.business_id);

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Owner" title="İstatistikler" description="İşletme performans analitiği" />
        <div className="px-6 pt-6">
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-[#e5e7eb] bg-[#fafafa] py-20 text-center">
            <p className="text-base font-[800] text-[#1a1a2e]">İşletme bulunamadı</p>
            <p className="mt-1 text-sm text-[#94a3b8]">İstatistikleri görmek için önce bir işletme ekleyin.</p>
          </div>
        </div>
      </div>
    );
  }

  const now = Date.now();
  const since     = new Date(now - days * 86400000).toISOString();
  const sincePrev = new Date(now - 2 * days * 86400000).toISOString();

  const VIEW_EVENTS = ['menu_view', 'business_impression', 'menu_link_opened', 'business_page_view'];

  // ── Parallel queries ──────────────────────────────────────────────────────
  const [
    viewsCurr,   viewsPrev_,
    favCurr,     favPrev_,
    profileCurr, profilePrev_,
    phoneCurr,   phonePrev_,
    dirCurr,     dirPrev_,
    menuViewCurr, menuViewPrev_,
    qrCurr,       qrPrev_,
    shareCurr,    sharePrev_,
    resCurr,      resPrev_,
    resStatusRows,
    // Full event rows for aggregation (line chart + traffic sources + hour heatmap)
    rawEvents,
  ] = await Promise.all([
    // KPI counts
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', VIEW_EVENTS).gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', VIEW_EVENTS)
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', since),
    (supabase as any).from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_page_view').gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_page_view')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_phone_click').gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_phone_click')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_directions_click').gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_directions_click')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_view').gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_view')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'qr_scanned').gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'qr_scanned')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_shared').gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_shared')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('reservations').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', since),
    (supabase as any).from('reservations').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('reservations').select('status')
      .in('business_id', businessIds).gte('created_at', since).limit(10000),

    (supabase as any).from('analytics_events')
      .select('created_at, event_name, source')
      .in('business_id', businessIds)
      .gte('created_at', sincePrev)
      .limit(100000),
  ]);

  type RawEvent = { created_at: string; event_name: string; source: string | null };

  const allRaw: RawEvent[] = rawEvents.data ?? [];

  // Split into current and previous period
  const sinceMs = now - days * 86400000;
  const currRaw = allRaw.filter(e => new Date(e.created_at).getTime() >= sinceMs);
  const prevRaw = allRaw.filter(e => new Date(e.created_at).getTime() <  sinceMs);

  // ── Daily line chart data ─────────────────────────────────────────────────
  const VIEW_SET = new Set(VIEW_EVENTS);
  const currDayMap: Record<string, number> = {};
  const prevDayMap: Record<string, number> = {};

  for (const e of currRaw) {
    if (VIEW_SET.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      currDayMap[k] = (currDayMap[k] ?? 0) + 1;
    }
  }
  for (const e of prevRaw) {
    if (VIEW_SET.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      prevDayMap[k] = (prevDayMap[k] ?? 0) + 1;
    }
  }

  const dailyData: DailyPoint[] = Array.from({ length: days }, (_, i) => {
    const d    = new Date(now - (days - 1 - i) * 86400000);
    const curr = d.toISOString().split('T')[0];
    const prev = new Date(d.getTime() - days * 86400000).toISOString().split('T')[0];
    return {
      label:    d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }),
      current:  currDayMap[curr] ?? 0,
      previous: prevDayMap[prev] ?? 0,
    };
  });

  // ── Traffic sources (current period) ─────────────────────────────────────
  const labelMap: Record<string, number> = {};
  for (const e of currRaw) {
    const label = SOURCE_LABELS[e.source ?? ''] ?? 'Diğer';
    labelMap[label] = (labelMap[label] ?? 0) + 1;
  }
  const srcTotal = Object.values(labelMap).reduce((a, b) => a + b, 0);
  const trafficSources: TrafficSource[] = Object.entries(labelMap)
    .sort((a, b) => b[1] - a[1])
    .map(([name, count], i) => ({
      name,
      count,
      value: srcTotal > 0 ? Math.round((count / srcTotal) * 1000) / 10 : 0,
      color: SRC_COLORS[Math.min(i, SRC_COLORS.length - 1)],
    }));

  // ── Popüler saatler: gün × 4 saatlik blok ısı haritası ────────────────────
  const hourBuckets = buildHourBucketHeatmap(
    currRaw.filter((e) => VIEW_SET.has(e.event_name)),
  );

  // ── Eylemler listesi ───────────────────────────────────────────────────────
  const actions: ActionMetric[] = [
    { key: 'menuViews',    value: menuViewCurr.count ?? 0, prev: menuViewPrev_.count ?? 0 },
    { key: 'qrScans',      value: qrCurr.count ?? 0,       prev: qrPrev_.count ?? 0 },
    { key: 'menuShares',   value: shareCurr.count ?? 0,    prev: sharePrev_.count ?? 0 },
    { key: 'reservations', value: resCurr.count ?? 0,      prev: resPrev_.count ?? 0 },
  ];

  const reservationStatus = reservationStatusBreakdown(
    (resStatusRows.data ?? []) as { status: string }[],
  );

  const bestDay = findBestDay(dailyData);
  const bestHourRange = findBestHourRange(hourBuckets);
  const totalInteractions =
    (viewsCurr.count ?? 0) + (favCurr.count ?? 0) + (phoneCurr.count ?? 0) + (dirCurr.count ?? 0);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="İstatistikler"
        description="İşletme performans analitiği — gerçek veriler"
      />
      <AnalyticsClient
        period={period}
        views={viewsCurr.count ?? 0}
        viewsPrev={viewsPrev_.count ?? 0}
        profileVisits={profileCurr.count ?? 0}
        profileVisitsPrev={profilePrev_.count ?? 0}
        phoneCalls={phoneCurr.count ?? 0}
        phoneCallsPrev={phonePrev_.count ?? 0}
        directions={dirCurr.count ?? 0}
        directionsPrev={dirPrev_.count ?? 0}
        favorites={favCurr.count ?? 0}
        favoritesPrev={favPrev_.count ?? 0}
        dailyData={dailyData}
        trafficSources={trafficSources}
        reservationStatus={reservationStatus}
        hourBuckets={hourBuckets}
        bestDay={bestDay}
        bestHourRange={bestHourRange}
        actions={actions}
        totalInteractions={totalInteractions}
      />
    </div>
  );
}
```

- [ ] **Step 2: Typecheck çalıştır (henüz `analytics-client.tsx` eski prop tipini kullandığı için hata bekleniyor)**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: FAIL — `analytics-client.tsx` henüz `profileVisits`, `phoneCalls`, `reservationStatus`, `hourBuckets`, `bestDay`, `bestHourRange`, `actions`, `totalInteractions` prop'larını tanımıyor; `HeatmapRow`/`HourlyPoint`/`reviews`/`searches` importları/kullanımları kırık. Bu beklenen bir ara durumdur — Task 3 düzeltecek.

- [ ] **Step 3: Commit (ara durum, sonraki task ile birlikte anlam kazanacak — commit MESAJI bunu netleştirir)**

Bu adımı commit etme — Task 3 tamamlanmadan `page.tsx` tek başına derlenmez. Task 3'ün sonunda ikisi birlikte tek commit'te gönderilecek (bkz. Task 3 Step son adım).

---

### Task 3: `analytics-client.tsx` görsel yenileme

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/analytics/analytics-client.tsx` (tüm dosya değiştirilecek)

- [ ] **Step 1: Dosyanın tamamını aşağıdakiyle değiştir**

`uygulamalar/web/app/owner/(panel)/analytics/analytics-client.tsx`:

```tsx
'use client';

import { useRouter } from 'next/navigation';
import {
  ResponsiveContainer,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  PieChart, Pie, Cell,
} from 'recharts';
import type { HourBucketRow, ReservationStatusRow } from '@/src/lib/veri/owner/analitik-yardimcilari';

// ── Types (exported — page.tsx uses them) ────────────────────────────────────
export type DailyPoint    = { label: string; current: number; previous: number };
export type TrafficSource = { name: string; value: number; color: string; count: number };
export type ActionMetric  = {
  key: 'menuViews' | 'qrScans' | 'menuShares' | 'reservations';
  value: number;
  prev: number;
};

export interface AnalyticsClientProps {
  period: string;
  views: number;             viewsPrev: number;
  profileVisits: number;     profileVisitsPrev: number;
  phoneCalls: number;        phoneCallsPrev: number;
  directions: number;        directionsPrev: number;
  favorites: number;         favoritesPrev: number;
  dailyData:         DailyPoint[];
  trafficSources:    TrafficSource[];
  reservationStatus: ReservationStatusRow[];
  hourBuckets:       HourBucketRow[];
  bestDay:           string | null;
  bestHourRange:     string | null;
  actions:           ActionMetric[];
  totalInteractions: number;
}

const PERIOD_OPTIONS = [
  { key: '7d',  label: 'Son 7 Gün' },
  { key: '30d', label: 'Son 30 Gün' },
  { key: '90d', label: 'Son 90 Gün' },
];

// ── Helpers ───────────────────────────────────────────────────────────────────
function pct(cur: number, prev: number): number | null {
  if (prev === 0) return null;
  return Math.round(((cur - prev) / prev) * 100);
}
function fmt(n: number) { return n.toLocaleString('tr-TR'); }
function heatColor(v: number) {
  if (v >= 90) return '#7f1d1d';
  if (v >= 70) return '#b91c1c';
  if (v >= 50) return '#dc2626';
  if (v >= 30) return '#f87171';
  if (v >= 10) return '#fca5a5';
  return '#fef2f2';
}

const RESERVATION_STATUS_COLORS: Record<string, string> = {
  confirmed: '#16a34a',
  pending:   '#f59e0b',
  completed: '#2563eb',
  cancelled: '#dc2626',
};

const ACTION_META: Record<ActionMetric['key'], { label: string; iconBg: string; iconColor: string }> = {
  menuViews:    { label: 'Menü Görüntüleme', iconBg: '#eff6ff', iconColor: '#2563eb' },
  qrScans:      { label: 'QR Kod Tarama',     iconBg: '#f5f3ff', iconColor: '#7c3aed' },
  menuShares:   { label: 'Menü Paylaşımı',    iconBg: '#ecfdf5', iconColor: '#059669' },
  reservations: { label: 'Rezervasyon',       iconBg: '#fff7ed', iconColor: '#ea580c' },
};

function actionIcon(key: ActionMetric['key']) {
  switch (key) {
    case 'menuViews':    return <EyeIcon />;
    case 'qrScans':      return <QrIcon />;
    case 'menuShares':   return <ShareIcon />;
    case 'reservations': return <CalendarIcon />;
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────
function KpiCard({ label, value, prev, icon, iconBg, iconColor }: {
  label: string; value: number; prev: number; icon: React.ReactNode;
  iconBg: string; iconColor: string;
}) {
  const p = pct(value, prev);
  const up = p !== null && p >= 0;
  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
      <div className="flex items-center justify-between">
        <span className="flex h-9 w-9 items-center justify-center rounded-xl" style={{ background: iconBg, color: iconColor }}>{icon}</span>
        {p !== null ? (
          <span className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-[800] ${
            up ? 'bg-[#dcfce7] text-[#16a34a]' : 'bg-[#fee2e2] text-[#dc2626]'
          }`}>{up ? '↑' : '↓'} {Math.abs(p)}%</span>
        ) : (
          <span className="rounded-full bg-[#f1f5f9] px-2 py-0.5 text-[11px] font-[700] text-[#94a3b8]">—</span>
        )}
      </div>
      <div>
        <p className="text-[26px] font-[900] text-[#1a1a2e] leading-tight">{fmt(value)}</p>
        <p className="mt-0.5 text-[12px] font-[600] text-[#94a3b8]">{label}</p>
      </div>
      {p !== null && <p className="text-[11px] text-[#94a3b8] font-[600]">Önceki dönem: {fmt(prev)}</p>}
    </div>
  );
}

// ── Section Card ──────────────────────────────────────────────────────────────
function SectionCard({ title, subtitle, children, className = '' }: {
  title: string; subtitle?: string; children: React.ReactNode; className?: string;
}) {
  return (
    <div className={`rounded-2xl border border-[#f0f0f0] bg-white shadow-[0_1px_3px_rgba(0,0,0,0.04)] ${className}`}>
      <div className="border-b border-[#f0f0f0] px-5 py-4">
        <p className="text-[14px] font-[800] text-[#1a1a2e]">{title}</p>
        {subtitle && <p className="mt-0.5 text-[11px] font-[600] text-[#94a3b8]">{subtitle}</p>}
      </div>
      <div className="p-5">{children}</div>
    </div>
  );
}

// ── Donut card (handles empty) ─────────────────────────────────────────────
function DonutCard({ title, subtitle, data }: {
  title: string; subtitle?: string; data: TrafficSource[];
}) {
  if (data.length === 0) {
    return (
      <SectionCard title={title} subtitle={subtitle}>
        <div className="flex flex-col items-center justify-center py-14 text-center">
          <NoDataIcon />
          <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
        </div>
      </SectionCard>
    );
  }
  const total = data.reduce((sum, d) => sum + d.count, 0);
  return (
    <SectionCard title={title} subtitle={subtitle}>
      <div className="relative" style={{ height: 180 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data} cx="50%" cy="50%" innerRadius={52} outerRadius={80} paddingAngle={2} dataKey="value">
              {data.map((d) => <Cell key={d.name} fill={d.color} />)}
            </Pie>
            <Tooltip formatter={(v) => [`${v}%`, '']} />
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
          <p className="text-[11px] font-[700] text-[#94a3b8]">Toplam</p>
          <p className="text-[20px] font-[900] text-[#1a1a2e]">{fmt(total)}</p>
        </div>
      </div>
      <div className="mt-3 flex flex-col gap-1.5">
        {data.map((d) => (
          <div key={d.name} className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: d.color }} />
              <span className="text-[12px] font-[600] text-[#475569]">{d.name}</span>
            </div>
            <span className="text-[12px] font-[800] text-[#1a1a2e]">%{d.value} · {fmt(d.count)}</span>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}

// ── Reservation status card (handles empty) ──────────────────────────────────
function ReservationStatusCard({ rows }: { rows: ReservationStatusRow[] }) {
  const total = rows.reduce((sum, r) => sum + r.count, 0);
  if (total === 0) {
    return (
      <SectionCard title="Rezervasyon Durumu" subtitle="Dönem içindeki dağılım">
        <div className="flex flex-col items-center justify-center py-10 text-center">
          <NoDataIcon />
          <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
        </div>
      </SectionCard>
    );
  }
  return (
    <SectionCard title="Rezervasyon Durumu" subtitle="Dönem içindeki dağılım">
      <div className="flex flex-col gap-3">
        {rows.map((r) => (
          <div key={r.status} className="flex flex-col gap-1">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: RESERVATION_STATUS_COLORS[r.status] }} />
                <span className="text-[12px] font-[600] text-[#475569]">{r.label}</span>
              </div>
              <span className="text-[12px] font-[800] text-[#1a1a2e]">{fmt(r.count)}</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-[#f1f5f9]">
              <div className="h-1.5 rounded-full" style={{ width: `${r.pct}%`, background: RESERVATION_STATUS_COLORS[r.status] }} />
            </div>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}

// ── Hour heatmap card (gün × 4 saatlik blok) ─────────────────────────────────
function HourHeatmapCard({ rows }: { rows: HourBucketRow[] }) {
  const allZero = rows.every((r) => r.counts.every((c) => c === 0));
  return (
    <SectionCard title="Popüler Saatler" subtitle="Gün ve saate göre görüntülenme yoğunluğu">
      {allZero ? (
        <div className="flex flex-col items-center justify-center py-10 text-center">
          <NoDataIcon />
          <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
        </div>
      ) : (
        <>
          <div className="overflow-x-auto">
            <table className="w-full text-[11px]">
              <thead>
                <tr>
                  <th className="w-[60px] pb-2 text-left font-[700] text-[#94a3b8]" />
                  {['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((d) => (
                    <th key={d} className="pb-2 text-center font-[800] text-[#475569]">{d}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.bucketLabel}>
                    <td className="py-1.5 pr-3 font-[700] text-[#475569] whitespace-nowrap">{row.bucketLabel}</td>
                    {row.counts.map((count, ci) => (
                      <td key={ci} className="py-1 px-1 text-center">
                        <div className="mx-auto flex h-8 w-full min-w-[32px] items-center justify-center rounded-lg text-[10px] font-[900]"
                          style={{
                            background: heatColor(row.norms[ci]),
                            color: row.norms[ci] >= 50 ? '#fff' : '#7f1d1d',
                            minWidth: 32,
                          }}>
                          {count}
                        </div>
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="mt-4 flex items-center gap-2">
            <span className="text-[10px] font-[600] text-[#94a3b8]">Az</span>
            {['#fef2f2', '#fca5a5', '#f87171', '#dc2626', '#b91c1c', '#7f1d1d'].map((c) => (
              <span key={c} className="h-3 flex-1 rounded" style={{ background: c }} />
            ))}
            <span className="text-[10px] font-[600] text-[#94a3b8]">Çok</span>
          </div>
        </>
      )}
    </SectionCard>
  );
}

// ── Actions card ───────────────────────────────────────────────────────────
function ActionsCard({ actions }: { actions: ActionMetric[] }) {
  return (
    <SectionCard title="Eylemler" subtitle="Dönem içindeki etkileşimler">
      <div className="flex flex-col gap-3">
        {actions.map((a) => {
          const meta = ACTION_META[a.key];
          const p = pct(a.value, a.prev);
          const up = p !== null && p >= 0;
          return (
            <div key={a.key} className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="flex h-8 w-8 items-center justify-center rounded-lg" style={{ background: meta.iconBg, color: meta.iconColor }}>
                  {actionIcon(a.key)}
                </span>
                <span className="text-[12px] font-[700] text-[#475569]">{meta.label}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-[900] text-[#1a1a2e]">{fmt(a.value)}</span>
                {p !== null && (
                  <span className={`text-[10px] font-[800] ${up ? 'text-[#16a34a]' : 'text-[#dc2626]'}`}>
                    {up ? '↑' : '↓'} %{Math.abs(p)}
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
      <button disabled title="Yakında aktif olacak"
        className="mt-4 flex w-full items-center justify-center gap-1.5 rounded-xl border border-[#e5e7eb] bg-[#fafafa] px-4 py-2.5 text-[12px] font-[800] text-[#94a3b8] opacity-60 cursor-not-allowed">
        Tüm Eylemleri Görüntüle
      </button>
    </SectionCard>
  );
}

// ── Custom Tooltips ───────────────────────────────────────────────────────────
function LineTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-[#f0f0f0] bg-white p-3 shadow-lg text-[12px]">
      <p className="mb-1.5 font-[800] text-[#1a1a2e]">{label}</p>
      {payload.map((p: any) => (
        <p key={p.name} className="font-[600]" style={{ color: p.color }}>
          {p.name === 'current' ? 'Bu Dönem' : 'Önceki Dönem'}: {fmt(p.value)}
        </p>
      ))}
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export function AnalyticsClient({
  period,
  views, viewsPrev,
  profileVisits, profileVisitsPrev,
  phoneCalls, phoneCallsPrev,
  directions, directionsPrev,
  favorites, favoritesPrev,
  dailyData,
  trafficSources,
  reservationStatus,
  hourBuckets,
  bestDay,
  bestHourRange,
  actions,
  totalInteractions,
}: AnalyticsClientProps) {
  const router = useRouter();

  function setPeriod(p: string) { router.push(`/owner/analytics?period=${p}`); }

  const periodLabel = PERIOD_OPTIONS.find((o) => o.key === period)?.label ?? 'Son 30 Gün';
  const compLabel   = period === '7d' ? '7' : period === '90d' ? '90' : '30';
  const xInterval   = dailyData.length > 14 ? Math.floor(dailyData.length / 6) - 1 : 0;

  return (
    <div className="flex flex-col gap-5 px-6 pb-8 pt-2">

      {/* Period selector */}
      <div className="flex items-center gap-2">
        <div className="flex items-center rounded-xl border border-[#e5e7eb] bg-white p-1 gap-1">
          {PERIOD_OPTIONS.map((o) => (
            <button key={o.key} onClick={() => setPeriod(o.key)}
              className={`rounded-lg px-3 py-1.5 text-[12px] font-[800] transition-all cursor-pointer ${
                period === o.key ? 'bg-[#7f1d1d] text-white shadow-sm' : 'text-[#475569] hover:bg-[#f8fafc]'
              }`}>
              {o.label}
            </button>
          ))}
        </div>
        <span className="text-[12px] font-[600] text-[#94a3b8]">Önceki {compLabel} günle karşılaştırma</span>
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5">
        <KpiCard label="Görüntülenme" value={views} prev={viewsPrev}
          icon={<EyeIcon />} iconBg="#eff6ff" iconColor="#2563eb" />
        <KpiCard label="Profil Ziyaretleri" value={profileVisits} prev={profileVisitsPrev}
          icon={<CursorIcon />} iconBg="#f5f3ff" iconColor="#7c3aed" />
        <KpiCard label="Telefon Aramaları" value={phoneCalls} prev={phoneCallsPrev}
          icon={<PhoneIcon />} iconBg="#ecfdf5" iconColor="#059669" />
        <KpiCard label="Yol Tarifi İstekleri" value={directions} prev={directionsPrev}
          icon={<MapIcon />} iconBg="#fff7ed" iconColor="#ea580c" />
        <KpiCard label="Favorilere Ekleme" value={favorites} prev={favoritesPrev}
          icon={<HeartIcon />} iconBg="#fdf2f8" iconColor="#db2777" />
      </div>

      {/* Row 2: Line chart + Traffic sources */}
      <div className="grid gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <SectionCard title="Görüntülenme Grafiği" subtitle={`${periodLabel} — günlük trend`}>
            <div className="mb-3 flex items-center gap-4 text-[11px] font-[700]">
              <span className="flex items-center gap-1.5 text-[#dc2626]">
                <span className="h-0.5 w-5 rounded bg-[#dc2626]" />Bu Dönem
              </span>
              <span className="flex items-center gap-1.5 text-[#94a3b8]">
                <span className="h-px w-5 rounded" style={{ borderTop: '1.5px dashed #94a3b8', display: 'block' }} />Önceki Dönem
              </span>
            </div>
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={dailyData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#94a3b8', fontWeight: 600 }}
                    interval={xInterval} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: '#94a3b8', fontWeight: 600 }}
                    tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip content={<LineTooltip />} />
                  <Line type="monotone" dataKey="current"  stroke="#dc2626" strokeWidth={2}
                    dot={false} activeDot={{ r: 5, fill: '#dc2626' }} />
                  <Line type="monotone" dataKey="previous" stroke="#94a3b8" strokeWidth={1.5}
                    strokeDasharray="5 4" dot={false} activeDot={{ r: 4, fill: '#94a3b8' }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </SectionCard>
        </div>
        <DonutCard title="Ziyaretçi Kaynakları" subtitle="Kaynak bazlı trafik dağılımı" data={trafficSources} />
      </div>

      {/* Row 3: Rezervasyon Durumu | Popüler Saatler | Eylemler */}
      <div className="grid gap-4 xl:grid-cols-3">
        <ReservationStatusCard rows={reservationStatus} />
        <HourHeatmapCard rows={hourBuckets} />
        <ActionsCard actions={actions} />
      </div>

      {/* Summary bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-[#f0f0f0] bg-white px-6 py-4 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
        <div>
          <p className="text-[14px] font-[900] text-[#1a1a2e]">Performans Özeti</p>
          <p className="mt-0.5 text-[12px] font-[600] text-[#94a3b8]">
            {periodLabel} toplam: {fmt(totalInteractions)} etkileşim
            {bestDay && ` · En iyi gün: ${bestDay}`}
            {bestHourRange && ` · En yoğun saat: ${bestHourRange}`}
          </p>
        </div>
        <button disabled title="Yakında aktif olacak"
          className="flex items-center gap-2 rounded-xl border border-[#e5e7eb] bg-[#fafafa] px-4 py-2.5 text-[12px] font-[800] text-[#94a3b8] opacity-60 cursor-not-allowed">
          <DownloadIcon />
          Detaylı Raporu İndir
        </button>
      </div>
    </div>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function EyeIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
function HeartIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>;
}
function MapIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11" /></svg>;
}
function CursorIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z" /></svg>;
}
function PhoneIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>;
}
function QrIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><line x1="14" y1="14" x2="14" y2="21" /><line x1="21" y1="14" x2="21" y2="14.01" /><line x1="14" y1="17.5" x2="17.5" y2="17.5" /><line x1="17.5" y1="14" x2="17.5" y2="21" /><line x1="21" y1="17.5" x2="21" y2="21" /></svg>;
}
function ShareIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" /></svg>;
}
function CalendarIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>;
}
function DownloadIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function NoDataIcon() {
  return <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>;
}
```

- [ ] **Step 2: Typecheck çalıştır**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: PASS — hata yok

- [ ] **Step 3: Lint çalıştır**

Run: `cd uygulamalar/web && npm run lint`
Expected: PASS — hata yok (varsa sadece bu iki dosyaya ait uyarılar düzeltilir)

- [ ] **Step 4: Commit (Task 2 + Task 3 birlikte — page.tsx tek başına derlenmediği için)**

```bash
git add uygulamalar/web/app/owner/"(panel)"/analytics/page.tsx uygulamalar/web/app/owner/"(panel)"/analytics/analytics-client.tsx
git commit -m "feat(web): owner analitik sayfasını mockup tasarımına göre yenile

KPI kartlarına metrik bazlı renk, trafik kaynakları donut'una toplam+adet,
rezervasyon durumu dağılımı, birleşik gün×saat ısı haritası ve eylemler
listesi eklendi. Tüm metrikler gerçek analytics_events/reservations
verisinden geliyor; yaş/cinsiyet demografisi ve görüntülenme süresi gibi
izlenmeyen veriler tasarıma dahil edilmedi."
```

---

### Task 4: Manuel doğrulama

**Files:** (yok — sadece çalıştırma)

- [ ] **Step 1: Dev server'ı başlat**

Run: `cd uygulamalar/web && npm run dev`
Expected: Server `http://localhost:3000` üzerinde ayağa kalkar

- [ ] **Step 2: Owner olarak giriş yapıp `/owner/analytics` sayfasını aç**

Tarayıcıda kontrol et:
- 5 KPI kartı farklı renklerde ikonlarla görünüyor (mavi/mor/yeşil/turuncu/pembe)
- "Yol Tarifi İstekleri" artık 0 değil, gerçek sayı gösteriyor (eğer test verisinde `business_directions_click` event'i varsa)
- Trafik Kaynakları donut'unun ortasında "Toplam" + sayı var, legend'da yüzde yanında gerçek adet var
- Satır 3'te 3 kart yan yana: Rezervasyon Durumu, Popüler Saatler (gün×saat ısı haritası), Eylemler
- Rezervasyon yoksa "Henüz veri yok" empty state görünüyor; varsa durum bazlı progress bar'lar doğru oranda
- Eylemler listesinde 4 satır (Menü Görüntüleme, QR Kod Tarama, Menü Paylaşımı, Rezervasyon) ve "Tüm Eylemleri Görüntüle" butonu disabled/gri
- Performans Özeti'nde "En iyi gün" ve "En yoğun saat" metni görünüyor (veri varsa), "ortalama görüntülenme süresi" gibi bir satır YOK

- [ ] **Step 3: Dar ekran (mobil genişlik) davranışını kontrol et**

Tarayıcı penceresini ~400px genişliğe küçült, satır 3'ün tek sütuna düştüğünü, tabloların yatay kaydırılabilir kaldığını doğrula.

- [ ] **Step 4: Dev server'ı durdur**

---

## Self-Review Notları

- **Spec kapsaması:** Spec'in 7 bölümünün tamamı (KPI, line chart, donut, rezervasyon durumu, ısı haritası, eylemler, performans özeti) Task 2/3'te karşılanıyor.
- **Tip tutarlılığı:** `ActionMetric.key` değerleri (`menuViews`, `qrScans`, `menuShares`, `reservations`) `page.tsx`'teki `actions` dizisi ile `analytics-client.tsx`'teki `ACTION_META`/`actionIcon` switch'i arasında birebir eşleşiyor. `ReservationStatusRow`/`HourBucketRow` tipleri tek bir yerden (`analitik-yardimcilari.ts`) import ediliyor, iki dosyada da aynı.
- **Kapsam dışı hatırlatma:** `app/sahip/analitik` ağacına dokunulmadı; export/rapor indirme özelliği eklenmedi (buton disabled kalıyor).
