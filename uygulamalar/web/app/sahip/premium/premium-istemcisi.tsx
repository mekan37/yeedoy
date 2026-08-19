'use client';

import { useState } from 'react';
import Link from 'next/link';
import { clsx } from 'clsx';
import { PLAN_TANIMLARI, PLAN_OZELLIKLERI, type PlanTierId } from './premium-veri';

export function PremiumIstemcisi({ currentTier }: { currentTier: PlanTierId | null }) {
  const [donem, setDonem] = useState<'ay' | 'yil'>('ay');

  return (
    <div className="flex flex-col gap-8">
      <div className="text-center">
        <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 text-xs font-extrabold text-primary">
          <CrownIcon /> Yeedoy Premium
        </span>
        <h1 className="mt-3 text-2xl font-black tracking-tight text-textStrong">İşletmenize uygun kademeyi seçin</h1>
        <p className="mx-auto mt-1.5 max-w-lg text-sm text-muted">
          Menü limitini kaldırın, QR filigranını kaldırın, sadakat programı ve haritada öne çıkarma gibi özellikleri açın.
        </p>

        <div className="mx-auto mt-5 inline-flex items-center gap-1 rounded-full border border-border bg-card p-1">
          <button
            type="button"
            onClick={() => setDonem('ay')}
            className={clsx('rounded-full px-4 py-1.5 text-xs font-extrabold transition-colors', donem === 'ay' ? 'bg-primary text-white' : 'text-muted')}
          >
            Aylık
          </button>
          <button
            type="button"
            onClick={() => setDonem('yil')}
            className={clsx('flex items-center gap-1.5 rounded-full px-4 py-1.5 text-xs font-extrabold transition-colors', donem === 'yil' ? 'bg-primary text-white' : 'text-muted')}
          >
            Yıllık
            <span className={clsx('rounded-full px-1.5 py-0.5 text-[9px] font-extrabold', donem === 'yil' ? 'bg-white/20 text-white' : 'bg-emerald-50 text-emerald-700')}>
              %20 indirim
            </span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {PLAN_TANIMLARI.map((plan) => {
          const aktif = currentTier === plan.id;
          const fiyat = donem === 'ay' ? plan.monthlyPrice : Math.round(plan.yearlyPrice / 12);
          return (
            <div
              key={plan.id}
              className={clsx(
                'relative flex flex-col gap-4 rounded-2xl border p-5 transition-all',
                plan.highlight ? 'border-primary/40 bg-primary/5 shadow-md' : 'border-border bg-card',
                aktif && 'ring-2 ring-primary',
              )}
            >
              {plan.highlight && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-(--yd-color-primary) px-3 py-1 text-[10px] font-extrabold uppercase tracking-wide text-white">
                  En Popüler
                </span>
              )}
              {aktif && (
                <span className="absolute -top-3 right-4 rounded-full bg-emerald-600 px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wide text-white">
                  Mevcut Plan
                </span>
              )}

              <div>
                <p className="text-sm font-black text-textStrong">{plan.label}</p>
                <p className="text-xs text-muted">{plan.tagline}</p>
              </div>

              <div>
                <span className="text-3xl font-black text-textStrong">
                  {fiyat === 0 ? 'Ücretsiz' : `₺${fiyat.toLocaleString('tr-TR')}`}
                </span>
                {fiyat > 0 && <span className="text-xs font-bold text-muted"> /ay</span>}
                {donem === 'yil' && fiyat > 0 && (
                  <p className="mt-0.5 text-[11px] text-muted">yıllık ₺{plan.yearlyPrice.toLocaleString('tr-TR')} olarak faturalanır</p>
                )}
              </div>

              <div className="flex flex-col gap-2 border-t border-border pt-4">
                {PLAN_OZELLIKLERI.map((ozellik) => (
                  <div key={ozellik.key} className="flex items-start justify-between gap-2 text-xs">
                    <span className="text-muted">{ozellik.label}</span>
                    <span
                      className={clsx(
                        'shrink-0 text-right font-extrabold',
                        ozellik.values[plan.id] === '—' ? 'text-muted/50' : 'text-textStrong',
                      )}
                    >
                      {ozellik.values[plan.id]}
                    </span>
                  </div>
                ))}
              </div>

              {aktif ? (
                <span className="mt-auto flex min-h-9 items-center justify-center rounded-xl border border-border text-xs font-extrabold text-muted">
                  Şu anki planınız
                </span>
              ) : plan.id === 'free' ? (
                <span className="mt-auto flex min-h-9 items-center justify-center rounded-xl border border-border text-xs font-extrabold text-muted">
                  Varsayılan kademe
                </span>
              ) : (
                <Link
                  href="/sahip/destek"
                  className={clsx(
                    'mt-auto flex min-h-9 items-center justify-center rounded-xl px-3 text-xs font-extrabold transition-opacity hover:opacity-90',
                    plan.highlight ? 'bg-(--yd-color-primary) text-white' : 'border border-border text-textStrong',
                  )}
                >
                  Yükseltme Talebi Oluştur
                </Link>
              )}
            </div>
          );
        })}
      </div>

      <p className="text-center text-xs text-muted">
        Ödeme entegrasyonumuz henüz devrede değil — yükseltme talebiniz destek ekibimize düşer, size dönüş yapılır.
        Sorularınız için <a href="mailto:destek@yeedoy.com" className="font-bold text-primary hover:underline">destek@yeedoy.com</a>.
      </p>
    </div>
  );
}

function CrownIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="m2 20 2-11 5 5 3-8 3 8 5-5 2 11Z" />
    </svg>
  );
}
