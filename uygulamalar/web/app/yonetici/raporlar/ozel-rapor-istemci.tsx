'use client';

import { useState, useTransition } from 'react';

const ENTITIES = [
  { value: 'users',      label: 'Kullanıcılar' },
  { value: 'businesses', label: 'İşletmeler' },
  { value: 'reviews',    label: 'Yorumlar' },
  { value: 'orders',     label: 'Siparişler' },
  { value: 'reports',    label: 'Şikayet Raporları' },
  { value: 'events',     label: 'Analitik Olayları' },
];

const PERIODS = [
  { value: '7d',  label: 'Son 7 Gün' },
  { value: '30d', label: 'Son 30 Gün' },
  { value: '90d', label: 'Son 90 Gün' },
  { value: '1y',  label: 'Son 1 Yıl' },
  { value: 'all', label: 'Tüm Zamanlar' },
];

const FORMATS = [
  { value: 'csv',  label: 'CSV' },
  { value: 'json', label: 'JSON' },
];

export function OzelRaporOlusturucu() {
  const [isPending, startTransition] = useTransition();
  const [entity, setEntity] = useState('users');
  const [period, setPeriod] = useState('30d');
  const [format, setFormat] = useState('csv');
  const [customStart, setCustomStart] = useState('');
  const [customEnd, setCustomEnd] = useState('');
  const [generated, setGenerated] = useState<{ url: string; rowCount: number } | null>(null);

  const generate = () => {
    startTransition(async () => {
      const params = new URLSearchParams({ entity, period, format });
      if (period === 'custom' && customStart) params.set('from', customStart);
      if (period === 'custom' && customEnd) params.set('to', customEnd);
      // Simulate generation (would call /sunucu/yonetici/ozel-rapor in production)
      await new Promise(r => setTimeout(r, 800));
      setGenerated({ url: `/sunucu/yonetici/ozel-rapor?${params.toString()}`, rowCount: Math.floor(Math.random() * 10000) + 100 });
    });
  };

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">Platform verilerini seçili parametrelerle özel rapor olarak oluşturun.</p>

      <div className="grid gap-4 sm:grid-cols-3">
        {/* Entity */}
        <div>
          <label className="mb-1.5 block text-xs font-[700] text-muted">Veri Kaynağı</label>
          <select value={entity} onChange={e => setEntity(e.target.value)}
            className="w-full rounded-xl border border-border bg-surface px-3 py-2 text-sm text-textStrong focus:border-primary focus:outline-none">
            {ENTITIES.map(e => <option key={e.value} value={e.value}>{e.label}</option>)}
          </select>
        </div>

        {/* Period */}
        <div>
          <label className="mb-1.5 block text-xs font-[700] text-muted">Zaman Aralığı</label>
          <select value={period} onChange={e => setPeriod(e.target.value)}
            className="w-full rounded-xl border border-border bg-surface px-3 py-2 text-sm text-textStrong focus:border-primary focus:outline-none">
            {PERIODS.map(p => <option key={p.value} value={p.value}>{p.label}</option>)}
            <option value="custom">Özel Aralık</option>
          </select>
        </div>

        {/* Format */}
        <div>
          <label className="mb-1.5 block text-xs font-[700] text-muted">Format</label>
          <div className="flex gap-2">
            {FORMATS.map(f => (
              <label key={f.value} className={`flex flex-1 cursor-pointer items-center justify-center rounded-xl border-2 py-2 text-sm font-[700] transition-colors ${format === f.value ? 'border-primary bg-primary/5 text-primary' : 'border-border text-muted'}`}>
                <input type="radio" name="format" value={f.value} checked={format === f.value} onChange={() => setFormat(f.value)} className="hidden" />
                {f.label}
              </label>
            ))}
          </div>
        </div>
      </div>

      {/* Custom date range */}
      {period === 'custom' && (
        <div className="grid gap-3 sm:grid-cols-2">
          <div>
            <label className="mb-1 block text-xs font-[700] text-muted">Başlangıç Tarihi</label>
            <input type="date" value={customStart} onChange={e => setCustomStart(e.target.value)}
              className="w-full rounded-xl border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1 block text-xs font-[700] text-muted">Bitiş Tarihi</label>
            <input type="date" value={customEnd} onChange={e => setCustomEnd(e.target.value)}
              className="w-full rounded-xl border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-none" />
          </div>
        </div>
      )}

      {/* Summary */}
      <div className="flex items-center gap-4">
        <button onClick={generate} disabled={isPending}
          className="rounded-xl bg-primary px-5 py-2.5 text-sm font-[800] text-white hover:bg-primary/90 disabled:opacity-50">
          {isPending ? 'Oluşturuluyor…' : 'Rapor Oluştur'}
        </button>
        {generated && (
          <div className="flex items-center gap-3">
            <span className="text-xs text-green-600 font-[700]">✓ {generated.rowCount.toLocaleString('tr-TR')} satır hazır</span>
            <a href={generated.url}
              className="rounded-xl border border-green-300 bg-green-50 px-4 py-2 text-sm font-[800] text-green-700 hover:bg-green-100">
              ↓ İndir ({format.toUpperCase()})
            </a>
          </div>
        )}
      </div>

      {/* Schedule info */}
      <div className="rounded-xl border border-border bg-zinc-50 px-4 py-3 dark:bg-zinc-900/30">
        <p className="text-xs font-[700] text-muted">Zamanlanmış Rapor</p>
        <p className="mt-0.5 text-xs text-muted">Raporları belirli aralıklarla otomatik oluşturmak için <span className="font-[700] text-primary">Gözlemlenebilirlik → Alert Konfigürasyonu</span> bölümünden webhook ayarlayın. Aylık finansal raporlar otomatik e-posta ile gönderilebilir.</p>
      </div>
    </div>
  );
}
