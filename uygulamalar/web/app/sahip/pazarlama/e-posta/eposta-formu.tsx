'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Sablon = { icon: string; baslik: string; konu: string; icerik: string };

export function EPostaKampanyaFormu({
  businesses,
  sablonlar,
}: {
  businesses: Array<{ id: string; name: string }>;
  sablonlar: Sablon[];
}) {
  const router = useRouter();
  const [biz, setBiz] = useState(businesses[0]?.id ?? '');
  const [konu, setKonu] = useState('');
  const [icerik, setIcerik] = useState('');
  const [onizleme, setOnizleme] = useState(false);
  const [loading, setLoading] = useState(false);
  const [sonuc, setSonuc] = useState<{ ok: boolean; msg: string } | null>(null);

  function sablonSec(s: Sablon) {
    setKonu(s.konu);
    setIcerik(s.icerik);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!biz || !konu.trim() || !icerik.trim()) return;
    setLoading(true);
    setSonuc(null);
    try {
      const res = await fetch('/sunucu/sahip/eposta-kampanya', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId: biz, subject: konu.trim(), body: icerik.trim() }),
      });
      const json = await res.json() as { ok: boolean; error?: string; sent_to?: number };
      if (json.ok) {
        setSonuc({ ok: true, msg: `${json.sent_to ?? 0} kişiye e-posta gönderildi.` });
        setKonu('');
        setIcerik('');
        router.refresh();
      } else {
        setSonuc({ ok: false, msg: json.error ?? 'Hata oluştu' });
      }
    } catch {
      setSonuc({ ok: false, msg: 'Bağlantı hatası' });
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      {/* Şablon seçici */}
      <div>
        <label className="mb-2 block text-sm font-bold text-textStrong">Hazır Şablonlar</label>
        <div className="flex flex-wrap gap-2">
          {sablonlar.map((s, i) => (
            <button
              key={i}
              type="button"
              onClick={() => sablonSec(s)}
              className="flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-bold text-textStrong transition-colors hover:border-primary/30"
            >
              <span>{s.icon}</span>
              <span>{s.baslik}</span>
            </button>
          ))}
        </div>
      </div>

      {/* İşletme seçici */}
      {businesses.length > 1 && (
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-bold text-textStrong">İşletme</label>
          <select value={biz} onChange={e => setBiz(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
            {businesses.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
      )}

      {/* Konu */}
      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-bold text-textStrong">E-posta Konusu</label>
        <input
          type="text"
          value={konu}
          onChange={e => setKonu(e.target.value)}
          placeholder="Örn: Bugün özel fırsat!"
          maxLength={150}
          required
          className="input-yd rounded-xl px-3 py-2.5 text-sm"
        />
      </div>

      {/* İçerik */}
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center justify-between">
          <label className="text-sm font-bold text-textStrong">Mesaj İçeriği</label>
          <button
            type="button"
            onClick={() => setOnizleme(!onizleme)}
            className="text-xs font-bold text-primary hover:underline"
          >
            {onizleme ? 'Düzenle' : 'Önizle'}
          </button>
        </div>
        {onizleme ? (
          <div className="min-h-[180px] rounded-xl border border-border bg-cardAlt p-4 text-sm text-textStrong whitespace-pre-wrap">
            {icerik || <span className="text-muted italic">İçerik boş</span>}
          </div>
        ) : (
          <textarea
            value={icerik}
            onChange={e => setIcerik(e.target.value)}
            placeholder="E-posta içeriğinizi yazın... Kişiselleştirme için {isim}, {isletme_adi} gibi değişkenler kullanabilirsiniz."
            rows={8}
            maxLength={5000}
            required
            className="input-yd resize-none rounded-xl px-3 py-2.5 text-sm"
          />
        )}
        <p className="text-[11px] text-muted text-right">{icerik.length}/5000</p>
      </div>

      {sonuc && (
        <div className={`rounded-xl px-4 py-3 text-sm font-bold ${
          sonuc.ok ? 'bg-success/8 text-success border border-success/25' : 'bg-danger/8 text-danger border border-danger/25'
        }`}>
          {sonuc.msg}
        </div>
      )}

      <div className="flex justify-end">
        <button
          type="submit"
          disabled={loading || !konu.trim() || !icerik.trim()}
          className="btn-primary rounded-xl px-5 py-2.5 text-sm font-bold text-white disabled:opacity-50"
        >
          {loading ? 'Gönderiliyor…' : 'Kampanya Gönder'}
        </button>
      </div>
    </form>
  );
}
