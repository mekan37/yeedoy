'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { clsx } from 'clsx';
import { PopulerKonular } from '../destek/bilesenler/populer-konular';
import { YardimKaynaklari } from '../destek/bilesenler/yardim-kaynaklari';
import { SSS_KATEGORILERI, SSS_SORULARI, type SssKategoriId } from './sss-veri';

export function SssIstemcisi() {
  const [arama, setArama] = useState('');
  const [kategori, setKategori] = useState<SssKategoriId | 'tumu'>('tumu');
  const [acikId, setAcikId] = useState<string | null>(SSS_SORULARI[0]?.id ?? null);

  const filtreliSorular = useMemo(() => {
    const q = arama.trim().toLocaleLowerCase('tr-TR');
    return SSS_SORULARI.filter((soru) => {
      if (kategori !== 'tumu' && soru.category !== kategori) return false;
      if (!q) return true;
      return soru.q.toLocaleLowerCase('tr-TR').includes(q) || soru.a.toLocaleLowerCase('tr-TR').includes(q);
    });
  }, [arama, kategori]);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-start gap-3">
        <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          <HelpIcon />
        </span>
        <div>
          <h1 className="text-2xl font-black tracking-tight text-textStrong">Sıkça Sorulan Sorular</h1>
          <p className="mt-1 text-sm text-muted">Yeedoy işletme paneli ile ilgili merak edilen soruların cevaplarını burada bulabilirsiniz.</p>
        </div>
      </div>

      <div className="relative">
        <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
        <input
          value={arama}
          onChange={(e) => setArama(e.target.value)}
          placeholder="Sorunuzu yazın…"
          className="w-full rounded-xl border border-border bg-card py-2.5 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div className="flex flex-wrap gap-2">
        <KategoriButon aktif={kategori === 'tumu'} onClick={() => setKategori('tumu')}>
          Tümü
        </KategoriButon>
        {SSS_KATEGORILERI.map((k) => (
          <KategoriButon key={k.id} aktif={kategori === k.id} onClick={() => setKategori(k.id)}>
            {k.label}
          </KategoriButon>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
        <div className="flex min-w-0 flex-col gap-4">
          <p className="text-xs font-extrabold uppercase tracking-wide text-muted">
            Sıkça Sorulan Sorular ({filtreliSorular.length})
          </p>

          {filtreliSorular.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-6 text-center">
              <p className="text-sm font-bold text-textStrong">&quot;{arama}&quot; ile eşleşen soru bulunamadı.</p>
              <p className="mt-1 text-xs text-muted">Farklı bir kelime deneyin ya da destek ekibimize ulaşın.</p>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              {filtreliSorular.map((soru) => {
                const acik = acikId === soru.id;
                return (
                  <div
                    key={soru.id}
                    className={clsx(
                      'overflow-hidden rounded-2xl border transition-colors',
                      acik ? 'border-primary/25 bg-primary/5' : 'border-border bg-card',
                    )}
                  >
                    <button
                      type="button"
                      onClick={() => setAcikId(acik ? null : soru.id)}
                      aria-expanded={acik}
                      className="flex w-full items-center justify-between gap-3 px-4 py-3.5 text-left"
                    >
                      <span className="text-sm font-extrabold text-textStrong">{soru.q}</span>
                      <span className={clsx('shrink-0 text-muted transition-transform duration-150', acik && 'rotate-180')}>
                        <ChevronDownIcon />
                      </span>
                    </button>
                    {acik && (
                      <p className="px-4 pb-4 text-sm leading-relaxed text-muted">{soru.a}</p>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          <div
            className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
            style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
          >
            <div>
              <p className="font-black text-textStrong">Aradığınız cevabı bulamadınız mı?</p>
              <p className="text-sm text-muted">Destek ekibimiz size yardımcı olmaktan memnuniyet duyar.</p>
            </div>
            <Link
              href="/sahip/destek"
              className="inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
            >
              Destek Talebi Oluştur
            </Link>
          </div>
        </div>

        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4">
            <h3 className="mb-1 text-sm font-black text-textStrong">Yardıma mı ihtiyacınız var?</h3>
            <p className="mb-3 text-xs text-muted">Ekibimiz sorularınızı yanıtlamak için burada.</p>
            <a href="mailto:destek@yeedoy.com" className="flex items-center gap-2 text-xs font-extrabold text-textStrong hover:text-primary">
              <MailIcon /> destek@yeedoy.com
            </a>
            <Link
              href="/sahip/destek"
              className="mt-3 flex min-h-9 items-center justify-center gap-1.5 rounded-lg bg-(--yd-color-primary) px-3 text-[12px] font-extrabold text-white transition-opacity hover:opacity-90"
            >
              Destek Talebi Oluştur
            </Link>
          </div>

          <YardimKaynaklari />
        </div>
      </div>

      <PopulerKonular />
    </div>
  );
}

function KategoriButon({ aktif, onClick, children }: { aktif: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'rounded-full border px-3.5 py-1.5 text-xs font-extrabold transition-colors',
        aktif
          ? 'border-primary bg-primary text-white'
          : 'border-border bg-card text-muted hover:border-primary/30 hover:text-textStrong',
      )}
    >
      {children}
    </button>
  );
}

function HelpIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}>
      <circle cx="11" cy="11" r="7" />
      <path d="m21 21-4.35-4.35" />
    </svg>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}

function MailIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" />
    </svg>
  );
}
