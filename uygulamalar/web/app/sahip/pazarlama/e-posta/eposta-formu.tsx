'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Sablon = { icon: string; baslik: string; konu: string; icerik: string };

type SendState =
  | { status: 'idle' }
  | { status: 'submitting' }
  | { status: 'success'; sentTo: number; providerNotConfigured: boolean }
  | { status: 'error'; message: string };

const MAX_SUBJECT = 200;
const MAX_BODY = 3000;

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
  const [state, setState] = useState<SendState>({ status: 'idle' });

  const isSubmitting = state.status === 'submitting';

  function sablonSec(s: Sablon) {
    setKonu(s.konu);
    setIcerik(s.icerik);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (isSubmitting || !biz || !konu.trim() || !icerik.trim()) return;

    setState({ status: 'submitting' });

    try {
      const res = await fetch('/sunucu/sahip/eposta-kampanya', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId: biz, subject: konu.trim(), body: icerik.trim() }),
      });

      const json = (await res.json()) as {
        ok?: boolean;
        error?: string;
        sent_to?: number;
        provider_not_configured?: boolean;
      };

      if (!res.ok || !json.ok) {
        const msg =
          res.status === 429
            ? 'Çok fazla istek. Saatte en fazla 3 kampanya gönderilebilir.'
            : json.error === 'invalid_input'
              ? 'Lütfen konu ve içerik alanlarını doldurun.'
              : 'Kampanya gönderilemedi. Lütfen tekrar deneyin.';
        setState({ status: 'error', message: msg });
        return;
      }

      setState({
        status: 'success',
        sentTo: json.sent_to ?? 0,
        providerNotConfigured: json.provider_not_configured ?? false,
      });

      setKonu('');
      setIcerik('');
      router.refresh();
    } catch {
      setState({ status: 'error', message: 'Ağ hatası. Lütfen internet bağlantınızı kontrol edin.' });
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      {/* Şablon seçici */}
      <div>
        <label className="mb-2 block text-sm font-[700] text-textStrong">Hazır Şablonlar</label>
        <div className="flex flex-wrap gap-2">
          {sablonlar.map((s, i) => (
            <button
              key={i}
              type="button"
              onClick={() => sablonSec(s)}
              disabled={isSubmitting}
              className="flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong transition-colors hover:border-primary/30 disabled:opacity-50"
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
          <label className="text-sm font-[700] text-textStrong">İşletme</label>
          <select
            value={biz}
            onChange={(e) => setBiz(e.target.value)}
            disabled={isSubmitting}
            className="input-yd rounded-xl px-3 py-2.5 text-sm disabled:opacity-50"
          >
            {businesses.map((b) => (
              <option key={b.id} value={b.id}>{b.name}</option>
            ))}
          </select>
        </div>
      )}

      {/* Konu */}
      <div className="flex flex-col gap-1.5">
        <label htmlFor="eposta-konu" className="text-sm font-[700] text-textStrong">
          E-posta Konusu <span className="text-red-500" aria-hidden="true">*</span>
        </label>
        <input
          id="eposta-konu"
          type="text"
          value={konu}
          onChange={(e) => setKonu(e.target.value)}
          placeholder="Örn: Bugün özel fırsat!"
          maxLength={MAX_SUBJECT}
          required
          disabled={isSubmitting}
          className="input-yd rounded-xl px-3 py-2.5 text-sm disabled:opacity-50"
        />
        <span className="self-end text-xs text-muted">{konu.length}/{MAX_SUBJECT}</span>
      </div>

      {/* İçerik */}
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center justify-between">
          <label htmlFor="eposta-icerik" className="text-sm font-[700] text-textStrong">
            Mesaj İçeriği <span className="text-red-500" aria-hidden="true">*</span>
          </label>
          <button
            type="button"
            onClick={() => setOnizleme(!onizleme)}
            className="text-xs font-[700] text-primary hover:underline"
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
            id="eposta-icerik"
            value={icerik}
            onChange={(e) => setIcerik(e.target.value)}
            placeholder="E-posta içeriğinizi yazın... Kişiselleştirme için {isim}, {isletme_adi} gibi değişkenler kullanabilirsiniz."
            rows={8}
            maxLength={MAX_BODY}
            required
            disabled={isSubmitting}
            className="input-yd resize-none rounded-xl px-3 py-2.5 text-sm disabled:opacity-50"
          />
        )}
        <p className="text-right text-[11px] text-muted">{icerik.length}/{MAX_BODY}</p>
      </div>

      {/* Success banner */}
      {state.status === 'success' && (
        <div
          role="status"
          className="rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-[700] text-green-800"
        >
          {state.providerNotConfigured ? (
            <>E-posta servisi henüz yapılandırılmamış. Kampanya kaydedildi ancak e-posta gönderilmedi.</>
          ) : state.sentTo > 0 ? (
            `Kampanya gönderildi. ${state.sentTo} kişiye ulaştı.`
          ) : (
            'Kampanya kaydedildi. E-posta izni veren takipçi bulunamadı.'
          )}
        </div>
      )}

      {/* Error banner */}
      {state.status === 'error' && (
        <div
          role="alert"
          className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-[700] text-red-800"
        >
          {state.message}
        </div>
      )}

      <div className="flex items-center justify-between gap-3">
        <p className="text-xs text-muted">Yalnızca e-posta iznini onaylayan takipçilere gönderilir.</p>
        <button
          type="submit"
          disabled={isSubmitting || !konu.trim() || !icerik.trim() || !biz}
          className="btn-primary shrink-0 rounded-xl px-5 py-2.5 text-sm font-[700] text-white disabled:opacity-50"
        >
          {isSubmitting ? 'Gönderiliyor…' : 'Kampanya Gönder'}
        </button>
      </div>
    </form>
  );
}
