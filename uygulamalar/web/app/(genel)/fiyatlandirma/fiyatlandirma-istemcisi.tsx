'use client';

import { useState } from 'react';
import Link from 'next/link';
import { clsx } from 'clsx';
import { CheckCircle2, Crown } from 'lucide-react';
import { PLAN_TANIMLARI, PLAN_OZELLIKLERI, type PlanTierId } from '@/src/lib/plan/plan-tanimlari';

/**
 * Herkese açık fiyatlandırma karşılaştırma tablosu — `/sahip/premium`'un
 * (oturum açmış sahip için) genel-kullanıcı karşılığı. Burada "mevcut plan"
 * kavramı yok; ziyaretçi henüz Yeedoy'a kayıtlı değil.
 *
 * Plan seçimi, kayıt akışına `plan` query param'ıyla taşınır. Kayıt/onboarding
 * tarafı şu an bu parametreyi okumuyor — ileride "seçtiğiniz plan: Standart"
 * gibi bir bağlam göstermek istenirse burası zaten hazır.
 */
export function FiyatlandirmaIstemcisi() {
  const [donem, setDonem] = useState<'ay' | 'yil'>('ay');

  return (
    <div className="flex flex-col gap-8">
      <div className="text-center">
        <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 text-xs font-extrabold text-primary">
          <Crown size={12} aria-hidden="true" /> Yeedoy Premium
        </span>
        <h1 className="mt-3 text-3xl font-black tracking-tight text-textStrong sm:text-4xl">
          İşletmenize uygun kademeyi seçin
        </h1>
        <p className="mx-auto mt-2 max-w-xl text-sm text-muted sm:text-base">
          Her işletme ücretsiz kademeyle başlar. Menü limitini kaldırmak, QR filigranını kaldırmak, sadakat programı
          ve haritada öne çıkarma gibi özellikleri açmak isterseniz üç premium kadememiz var.
        </p>

        <div className="mx-auto mt-6 inline-flex items-center gap-1 rounded-full border border-border bg-card p-1">
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
          const fiyat = donem === 'ay' ? plan.monthlyPrice : Math.round(plan.yearlyPrice / 12);
          const kayitHref = plan.id === 'free' ? '/giris?tab=kayit' : `/giris?tab=kayit&plan=${plan.id}`;
          return (
            <div
              key={plan.id}
              className={clsx(
                'relative flex flex-col gap-4 rounded-2xl border p-5 transition-all',
                plan.highlight ? 'border-primary/40 bg-primary/5 shadow-md' : 'border-border bg-card',
              )}
            >
              {plan.highlight && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-(--yd-color-primary) px-3 py-1 text-[10px] font-extrabold uppercase tracking-wide text-white">
                  En Popüler
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

              <Link
                href={kayitHref}
                className={clsx(
                  'mt-auto flex min-h-11 items-center justify-center rounded-xl px-3 text-xs font-extrabold transition-opacity hover:opacity-90',
                  plan.highlight ? 'bg-(--yd-color-primary) text-white' : 'border border-border text-textStrong',
                )}
              >
                {plan.id === 'free' ? 'Ücretsiz Başla' : 'Bu Planla Başla'}
              </Link>
            </div>
          );
        })}
      </div>

      {/* Dürüstlük bandı — ince baskı değil, görünür bir bilgi kutusu */}
      <div className="mx-auto flex max-w-2xl items-start gap-3 rounded-2xl border border-border bg-cardAlt p-4 text-left sm:items-center sm:text-center">
        <CheckCircle2 size={18} className="mt-0.5 shrink-0 text-primary sm:mt-0" aria-hidden="true" />
        <p className="text-xs leading-relaxed text-muted sm:text-sm">
          Ödeme entegrasyonumuz henüz devrede değil. Ücretsiz kaydolduktan ve işletmenizi ekledikten sonra panelinizden
          bir yükseltme talebi oluşturursunuz; destek ekibimiz size dönüş yapar ve kademenizi birlikte etkinleştiririz.
          Kart bilgisi istemiyoruz, otomatik ödeme başlatmıyoruz.
        </p>
      </div>
    </div>
  );
}
