'use client';

import { useState, useTransition } from 'react';

const SEGMENTS = [
  { value: 'all_followers', label: 'Tüm Takipçiler', desc: 'Seçili işletmenin tüm takipçileri' },
  { value: 'loyal_top20',   label: 'Sadık İlk %20',  desc: 'En güçlü takipçi segmenti' },
  { value: 'inactive_30d',  label: 'Pasif (30+ Gün)', desc: '30 gündür etkileşim kurmayan takipçiler' },
  { value: 'new_30d',       label: 'Son 30 Gün Yeni', desc: 'Son 30 günde gelen takipçiler' },
];

const TEMPLATES = [
  { title: '🎉 Yeni Özellik', body: 'Yeedoy\'da yeni özellikler sizi bekliyor. Keşfedin!' },
  { title: '🍽️ Sizi Kaçırdık', body: 'Uzun süredir görünmüyorsunuz. Yeni menüler ve fırsatlar sizi bekliyor!' },
  { title: '⭐ Yorum Yapın', body: 'Son ziyaretinizi değerlendirin ve topluluğa katkı sağlayın.' },
  { title: '💰 Özel İndirim', body: 'Sizi özel bir fırsatla karşılıyoruz. Hemen kontrol edin!' },
];

export function PushKampanyaFormu({
  totalUsers, activeUsers, newUsers, businesses,
}: { totalUsers: number; activeUsers: number; newUsers: number; businesses: Array<{ id: string; name: string }> }) {
  const [isPending, startTransition] = useTransition();
  const [businessId, setBusinessId] = useState(businesses[0]?.id ?? '');
  const [segment, setSegment] = useState('all_followers');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [scheduled, setScheduled] = useState('');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  const estimatedReach: Record<string, number> = {
    all_followers: totalUsers,
    loyal_top20:   Math.round(totalUsers * 0.2),
    inactive_30d:  Math.max(0, totalUsers - activeUsers),
    new_30d:       newUsers,
  };

  const applyTemplate = (t: typeof TEMPLATES[number]) => {
    setTitle(t.title);
    setBody(t.body);
  };

  const send = () => {
    if (!businessId) { setError('Önce işletme seçin'); return; }
    if (!title.trim() || !body.trim()) { setError('Başlık ve içerik zorunludur'); return; }
    setError('');
    startTransition(async () => {
      const res = await fetch('/sunucu/yonetici/push-kampanyalari', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId, title: title.trim(), body: body.trim(), segment, scheduledAt: scheduled || null }),
      });
      if (res.ok) {
        setSent(true);
        setTitle(''); setBody(''); setScheduled('');
      } else {
        setError('Gönderim sırasında hata oluştu');
      }
    });
  };

  if (sent) return (
    <div className="flex flex-col items-center gap-3 py-8">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5"><polyline points="20 6 9 17 4 12" /></svg>
      </div>
      <p className="font-extrabold text-textStrong">Kampanya gönderildi!</p>
      <button onClick={() => setSent(false)} className="text-sm font-semibold text-primary">Yeni Kampanya Oluştur</button>
    </div>
  );

  return (
    <div className="flex flex-col gap-5">
      {/* Templates */}
      <div>
        <p className="mb-2 text-xs font-bold text-muted">Hazır Şablonlar</p>
        <div className="flex flex-wrap gap-2">
          {TEMPLATES.map((t, i) => (
            <button
              key={i}
              onClick={() => applyTemplate(t)}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted hover:border-primary hover:text-primary"
            >
              {t.title}
            </button>
          ))}
        </div>
      </div>

      {/* Segment selection */}
      <div>
        <label className="mb-1 block text-xs font-bold text-muted">İşletme</label>
        <select
          value={businessId}
          onChange={e => setBusinessId(e.target.value)}
          className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-textStrong focus:border-primary focus:outline-hidden"
        >
          {businesses.length === 0 ? (
            <option value="">Aktif işletme yok</option>
          ) : businesses.map((business) => (
            <option key={business.id} value={business.id}>{business.name}</option>
          ))}
        </select>
      </div>

      <div>
        <p className="mb-2 text-xs font-bold text-muted">Hedef Segment</p>
        <div className="grid gap-2 sm:grid-cols-2">
          {SEGMENTS.map(s => (
            <label
              key={s.value}
              className={`flex cursor-pointer items-start gap-3 rounded-xl border-2 p-3 transition-colors ${segment === s.value ? 'border-primary bg-primary/5' : 'border-border hover:border-border/70'}`}
            >
              <input type="radio" name="segment" value={s.value} checked={segment === s.value} onChange={() => setSegment(s.value)} className="mt-0.5" />
              <div>
                <p className="text-sm font-bold text-textStrong">{s.label}</p>
                <p className="text-xs text-muted">{s.desc}</p>
                <p className="mt-1 text-xs font-extrabold text-primary">~{(estimatedReach[s.value] ?? 0).toLocaleString('tr-TR')} kişi</p>
              </div>
            </label>
          ))}
        </div>
      </div>

      {/* Title */}
      <div>
        <label className="mb-1 block text-xs font-bold text-muted">Bildirim Başlığı</label>
        <input
          value={title}
          onChange={e => setTitle(e.target.value)}
          maxLength={80}
          placeholder="Ör: Yeni menüler keşfedin!"
          className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden"
        />
        <p className="mt-0.5 text-right text-[10px] text-muted">{title.length}/80</p>
      </div>

      {/* Body */}
      <div>
        <label className="mb-1 block text-xs font-bold text-muted">Bildirim İçeriği</label>
        <textarea
          value={body}
          onChange={e => setBody(e.target.value)}
          maxLength={200}
          rows={3}
          placeholder="Ör: En yakın işletmelerde özel fırsatlar sizi bekliyor."
          className="w-full resize-none rounded-lg border border-border bg-surface px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden"
        />
        <p className="mt-0.5 text-right text-[10px] text-muted">{body.length}/200</p>
      </div>

      {/* Schedule (optional) */}
      <div>
        <label className="mb-1 block text-xs font-bold text-muted">Zamanlama (opsiyonel)</label>
        <input
          type="datetime-local"
          value={scheduled}
          onChange={e => setScheduled(e.target.value)}
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-textStrong focus:border-primary focus:outline-hidden"
        />
      </div>

      {error && <p className="text-xs font-bold text-red-600">{error}</p>}

      <button
        disabled={isPending}
        onClick={send}
        className="rounded-xl bg-primary px-5 py-2.5 text-sm font-extrabold text-white hover:bg-primary/90 disabled:opacity-50"
      >
        {isPending ? 'Gönderiliyor…' : `${scheduled ? 'Zamanla' : 'Şimdi Gönder'} — ~${(estimatedReach[segment] ?? 0).toLocaleString('tr-TR')} kişi`}
      </button>
    </div>
  );
}
