'use client';

import { useState, useTransition } from 'react';

const SMS_TEMPLATES = [
  { label: '🎉 Özel Fırsat', msg: 'Merhaba! [İŞLETME] olarak size özel bir fırsat sunuyoruz. Bugün ziyaret edin, sizi bekliyoruz!' },
  { label: '📢 Yeni Menü', msg: 'Yeni menümüzü keşfetmeye davet ediyoruz! Lezzetli yenilikler [İŞLETME]\'de sizi bekliyor.' },
  { label: '⭐ Yorum İsteği', msg: 'Son ziyaretiniz için teşekkürler! Deneyiminizi Yeedoy\'da paylaşır mısınız? [LINK]' },
  { label: '🎁 Sadakat Ödülü', msg: 'Tebrikler! Sadakat kartınız tamamlandı. Ödülünüzü almak için [İŞLETME]\'yi ziyaret edin.' },
];

const MAX_SMS_CHARS = 160;

export function SmsGonderimFormu({
  bizIds,
  followerCount,
  loyaltyCount,
  optOutCount = 0,
}: {
  bizIds: string[];
  followerCount: number;
  loyaltyCount: number;
  optOutCount?: number;
}) {
  const [isPending, startTransition] = useTransition();
  const [segment, setSegment] = useState<'followers' | 'loyalty' | 'all'>('followers');
  const [message, setMessage] = useState('');
  const [scheduledAt, setScheduledAt] = useState('');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  const reach = Math.max(0, (segment === 'followers' ? followerCount : segment === 'loyalty' ? loyaltyCount : Math.max(followerCount, loyaltyCount)) - optOutCount);
  const smsUnits = Math.ceil(message.length / MAX_SMS_CHARS);

  const send = () => {
    if (!message.trim()) { setError('Mesaj boş olamaz'); return; }
    if (message.length > 480) { setError('Mesaj çok uzun (maks. 3 SMS birimi = 480 karakter)'); return; }
    setError('');
    startTransition(async () => {
      const res = await fetch('/sunucu/sahip/sms-kampanya', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bizIds, segment, message: message.trim(), scheduledAt: scheduledAt || null }),
      });
      if (res.ok) { setSent(true); setMessage(''); setScheduledAt(''); }
      else setError('SMS gönderilemedi. Lütfen Netgsm/Twilio yapılandırmasını kontrol edin.');
    });
  };

  if (sent) return (
    <div className="flex flex-col items-center gap-3 py-8">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5"><polyline points="20 6 9 17 4 12" /></svg>
      </div>
      <p className="font-[800] text-textStrong">SMS Kampanyası Oluşturuldu!</p>
      <p className="text-sm text-muted">Netgsm/Twilio entegrasyonu aktif olduğunda otomatik gönderilecek.</p>
      <button onClick={() => setSent(false)} className="text-sm font-[600] text-primary">Yeni SMS Oluştur</button>
    </div>
  );

  return (
    <div className="flex flex-col gap-5">
      {/* Templates */}
      <div>
        <p className="mb-2 text-xs font-[700] text-muted">Hazır Şablonlar</p>
        <div className="flex flex-wrap gap-2">
          {SMS_TEMPLATES.map(t => (
            <button key={t.label} onClick={() => setMessage(t.msg)}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:border-primary hover:text-primary">
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* Segment */}
      <div>
        <p className="mb-2 text-xs font-[700] text-muted">Hedef Kitle</p>
        <div className="flex gap-2">
          {([['followers', 'Takipçiler', followerCount], ['loyalty', 'Sadakat Kartlılar', loyaltyCount], ['all', 'Tümü', Math.max(followerCount, loyaltyCount)]] as const).map(([val, label, count]) => (
            <label key={val} className={`flex cursor-pointer items-center gap-2 rounded-xl border-2 px-3 py-2 transition-colors ${segment === val ? 'border-primary bg-primary/5' : 'border-border'}`}>
              <input type="radio" name="segment" value={val} checked={segment === val} onChange={() => setSegment(val)} />
              <div>
                <p className="text-sm font-[700] text-textStrong">{label}</p>
                <p className="text-xs text-primary">{count.toLocaleString('tr-TR')} kişi</p>
              </div>
            </label>
          ))}
        </div>
      </div>

      {/* Message */}
      <div>
        <label className="mb-1 block text-xs font-[700] text-muted">Mesaj İçeriği</label>
        <textarea
          value={message}
          onChange={e => setMessage(e.target.value)}
          rows={4}
          maxLength={480}
          placeholder="Mesajınızı yazın… [İŞLETME] ve [LINK] yer tutucuları otomatik doldurulur."
          className="w-full resize-none rounded-lg border border-border bg-surface px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:border-primary focus:outline-none"
        />
        <div className="mt-0.5 flex justify-between text-[10px] text-muted">
          <span>{message.length} karakter</span>
          <span>{smsUnits > 1 ? `${smsUnits} SMS birimi` : '1 SMS birimi'} · tahmini ücret: ₺{(reach * smsUnits * 0.08).toFixed(2)}</span>
        </div>
      </div>

      {/* Schedule */}
      <div>
        <label className="mb-1 block text-xs font-[700] text-muted">Zamanlama (opsiyonel)</label>
        <input type="datetime-local" value={scheduledAt} onChange={e => setScheduledAt(e.target.value)}
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-textStrong focus:border-primary focus:outline-none" />
      </div>

      {error && <p className="text-xs font-[700] text-red-600">{error}</p>}

      <button onClick={send} disabled={isPending || !message.trim()}
        className="rounded-xl bg-primary px-5 py-2.5 text-sm font-[800] text-white hover:bg-primary/90 disabled:opacity-50">
        {isPending ? 'İşleniyor…' : `${scheduledAt ? 'Zamanla' : 'Kampanya Oluştur'} — ${reach.toLocaleString('tr-TR')} kişi`}
      </button>
    </div>
  );
}
