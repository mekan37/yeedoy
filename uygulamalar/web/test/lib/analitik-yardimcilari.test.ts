import { describe, expect, it } from 'vitest';
import {
  buildHourBucketHeatmap,
  findBestDay,
  findBestHourRange,
  reservationStatusBreakdown,
} from '@/src/lib/veri/owner/analitik-yardimcilari';

// 2026-07-13 Pazartesi, 2026-07-19 Pazar (Pzt=index0, Paz=index6)
// Europe/Istanbul UTC+3 sabit (DST yok) olduğu için tüm zamanlar açık UTC ISO string olarak
// -3 saat kaydırılmış şekilde yazılıyor; böylece test, çalıştırılan makinenin/CI'ın yerel saat
// dilimine bağlı olmadan Istanbul yerel saatiyle deterministik biçimde eşleşiyor.
const MONDAY_9AM   = '2026-07-13T06:00:00.000Z'; // Pzt 09:00 İstanbul
const MONDAY_9AM_2 = '2026-07-13T06:15:00.000Z'; // Pzt 09:15 İstanbul
const MONDAY_9AM_3 = '2026-07-13T06:30:00.000Z'; // Pzt 09:30 İstanbul
const MONDAY_9PM   = '2026-07-13T18:00:00.000Z'; // Pzt 21:00 İstanbul
const MONDAY_9PM_2 = '2026-07-13T18:30:00.000Z'; // Pzt 21:30 İstanbul
const SUNDAY_1AM   = '2026-07-18T22:00:00.000Z'; // Paz 01:00 İstanbul (Cmt 22:00 UTC)
// Gün sınırı bug'ı: Pazartesi 22:30 UTC == Salı 01:30 İstanbul (+3) — UTC ile hesaplanırsa
// yanlışlıkla Pazartesi sütununa düşerdi, doğrusu Salı sütunudur.
const MONDAY_DAY_BOUNDARY = '2026-07-13T22:30:00.000Z'; // Sal 01:30 İstanbul

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

  it('gün sınırını UTC yerine İstanbul saatine göre hesaplar (timezone bug regresyonu)', () => {
    // 2026-07-13T22:30:00.000Z → UTC'de Pazartesi 22:30, ama İstanbul'da (+3) Salı 01:30.
    // Sunucu process'i UTC'de çalışıyorsa eski kod bunu yanlışlıkla Pazartesi sütununa
    // (index 0) koyardı; doğrusu Salı sütunudur (index 1).
    const rows = buildHourBucketHeatmap([{ created_at: MONDAY_DAY_BOUNDARY }]);

    // 00:00 bloğu (saat 0-3), Salı sütunu (index 1) → 1 olay
    expect(rows[0].counts[1]).toBe(1);
    // Pazartesi sütununa (index 0) hiç düşmedi
    expect(rows[0].counts[0]).toBe(0);
    // Toplamda tek bir olay var
    expect(rows.reduce((sum, r) => sum + r.counts.reduce((a, b) => a + b, 0), 0)).toBe(1);
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
