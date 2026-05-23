'use client';

import { useState } from 'react';

export function SadakatProgramFormu({ businesses }: { businesses: Array<{ id: string; name: string }> }) {
  const [biz, setBiz] = useState(businesses[0]?.id ?? '');
  const [name, setName] = useState('');
  const [stamps, setStamps] = useState(10);
  const [reward, setReward] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; msg: string } | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!biz || !name.trim() || !reward.trim()) return;
    setLoading(true);
    setResult(null);
    try {
      const res = await fetch('/sunucu/sahip/sadakat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId: biz, name: name.trim(), stampsNeeded: stamps, rewardDesc: reward.trim() }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Hata');
      setResult({ ok: true, msg: 'Program oluşturuldu!' });
      setName('');
      setReward('');
    } catch (e: any) {
      setResult({ ok: false, msg: e.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      {businesses.length > 1 && (
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">İşletme</label>
          <select value={biz} onChange={(e) => setBiz(e.target.value)} className="input-yd px-3 py-2.5 text-sm rounded-xl">
            {businesses.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
      )}
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-[700] text-textStrong">Program Adı</label>
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Kahve Sadakat Kartı" maxLength={60} required className="input-yd px-3 py-2.5 text-sm rounded-xl" />
      </div>
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-[700] text-textStrong">Damga Sayısı: {stamps}</label>
        <input type="range" min={3} max={20} value={stamps} onChange={(e) => setStamps(+e.target.value)} className="accent-primary" />
        <p className="text-xs text-muted">{stamps} damgada ödül kazanılır</p>
      </div>
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-[700] text-textStrong">Ödül</label>
        <input type="text" value={reward} onChange={(e) => setReward(e.target.value)} placeholder="1 bedava filtre kahve" maxLength={100} required className="input-yd px-3 py-2.5 text-sm rounded-xl" />
      </div>
      {result && (
        <p className={`rounded-xl border px-4 py-2.5 text-sm font-[700] ${result.ok ? 'border-success/20 bg-success/[0.08] text-success' : 'border-danger/20 bg-danger/[0.08] text-danger'}`}>
          {result.msg}
        </p>
      )}
      <button type="submit" disabled={loading || !name.trim() || !reward.trim()} className="btn-primary rounded-xl px-4 py-3 text-sm font-[800] text-white disabled:opacity-50">
        {loading ? 'Oluşturuluyor…' : 'Programı Oluştur'}
      </button>
    </form>
  );
}
