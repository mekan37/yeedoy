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
