'use client';

import type { YogunSaatSatiri } from '@/src/lib/veri/owner/mesgul-saatler';

interface Props {
  veriler: YogunSaatSatiri[];
}

export function YogunSaatlerKarti({ veriler }: Props) {
  const hepsiBos = veriler.every((v) => v.eventCount === 0);
  const maxCount = Math.max(...veriler.map((v) => v.eventCount), 1);
  const topSaatler = veriler.filter((v) => v.peakRank >= 1 && v.peakRank <= 3 && v.eventCount > 0);

  if (hepsiBos) {
    return (
      <div className="flex flex-col gap-1">
        <p className="text-xs text-muted">Son 28 gün · analitik + sipariş verisi</p>
        <p className="mt-2 text-sm text-muted">Henüz yeterli veri yok.</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs text-muted">Son 28 gün · analitik + sipariş verisi</p>

      {/* En yoğun 3 saat badge */}
      {topSaatler.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {topSaatler
            .sort((a, b) => a.peakRank - b.peakRank)
            .map((s) => (
              <span
                key={s.hourOfDay}
                className="rounded-xl bg-primary/10 px-3 py-1 text-xs font-[800] text-primary"
              >
                {String(s.hourOfDay).padStart(2, '0')}:00
              </span>
            ))}
        </div>
      )}

      {/* Bar görselleştirme — 24 saat */}
      <div className="space-y-1">
        {veriler.map((v) => {
          const genislik = Math.round((v.eventCount / maxCount) * 100);
          const isTop = v.peakRank >= 1 && v.peakRank <= 3 && v.eventCount > 0;
          return (
            <div key={v.hourOfDay} className="flex items-center gap-2">
              <span className="w-8 shrink-0 text-right text-[10px] tabular-nums text-muted">
                {String(v.hourOfDay).padStart(2, '0')}
              </span>
              <div className="h-2 flex-1 overflow-hidden rounded-full bg-border">
                <div
                  className={`h-full rounded-full transition-all duration-300 ${
                    isTop ? 'bg-primary' : 'bg-primary/30'
                  }`}
                  style={{ width: `${Math.max(genislik, v.eventCount > 0 ? 1 : 0)}%` }}
                />
              </div>
              {isTop ? (
                <span className="w-5 shrink-0 text-[10px] font-[700] text-primary">
                  #{v.peakRank}
                </span>
              ) : (
                <span className="w-5 shrink-0" />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
