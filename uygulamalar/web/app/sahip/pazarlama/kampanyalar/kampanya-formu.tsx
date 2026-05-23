'use client';

import { useState } from 'react';
import { clsx } from 'clsx';

interface Business {
  id: string;
  name: string;
  followerCount: number;
}

export function KampanyaFormu({ businesses }: { businesses: Business[] }) {
  const [selectedBiz, setSelectedBiz] = useState(businesses[0]?.id ?? '');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; sent?: number; error?: string } | null>(null);

  const biz = businesses.find((b) => b.id === selectedBiz);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedBiz || !title.trim() || !message.trim()) return;
    setLoading(true);
    setResult(null);
    try {
      const res = await fetch('/sunucu/sahip/bildirim-gonder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId: selectedBiz, title: title.trim(), message: message.trim() }),
      });
      const json = await res.json();
      if (!res.ok) {
        setResult({ ok: false, error: json.error === 'rate_limited_daily' ? 'Günlük bildirim limitine ulaştınız (3/gün).' : json.error });
      } else {
        setResult({ ok: true, sent: json.sent });
        setTitle('');
        setMessage('');
      }
    } catch {
      setResult({ ok: false, error: 'Bağlantı hatası' });
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      {businesses.length > 1 && (
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">İşletme</label>
          <select
            value={selectedBiz}
            onChange={(e) => setSelectedBiz(e.target.value)}
            className="input-yd px-3 py-2.5 text-sm rounded-xl"
          >
            {businesses.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name} ({b.followerCount} takipçi)
              </option>
            ))}
          </select>
        </div>
      )}

      {biz && (
        <p className="text-xs text-muted">
          Bu bildirim <span className="font-[800] text-primary">{biz.followerCount} takipçiye</span> gönderilecek.
        </p>
      )}

      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-[700] text-textStrong">Başlık</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Örn: Bu hafta sonu özel fırın çıkışı!"
          maxLength={60}
          required
          className="input-yd px-3 py-2.5 text-sm rounded-xl"
        />
        <p className="text-right text-[11px] text-muted">{title.length}/60</p>
      </div>

      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-[700] text-textStrong">Mesaj</label>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Örn: Cumartesi 10:00–14:00 arası özel kuzu tandır. Yerinizi ayırtın!"
          maxLength={160}
          rows={3}
          required
          className="input-yd resize-none px-3 py-2.5 text-sm rounded-xl"
        />
        <p className="text-right text-[11px] text-muted">{message.length}/160</p>
      </div>

      {result && (
        <div className={clsx(
          'rounded-xl border px-4 py-3 text-sm font-[700]',
          result.ok
            ? 'border-success/20 bg-success/[0.08] text-success'
            : 'border-danger/20 bg-danger/[0.08] text-danger',
        )}>
          {result.ok
            ? `Bildirim ${result.sent} takipçiye gönderildi!`
            : result.error ?? 'Bir hata oluştu'}
        </div>
      )}

      <button
        type="submit"
        disabled={loading || !title.trim() || !message.trim() || !selectedBiz}
        className="btn-primary rounded-xl px-4 py-3 text-sm font-[800] text-white disabled:cursor-not-allowed disabled:opacity-50"
      >
        {loading ? 'Gönderiliyor…' : 'Takipçilere Gönder'}
      </button>
    </form>
  );
}
