'use client';

import { useState } from 'react';

interface Props {
  businessId: string;
  businessName: string;
}

type SendState =
  | { status: 'idle' }
  | { status: 'submitting' }
  | { status: 'success'; sentTo: number; providerNotConfigured: boolean }
  | { status: 'error'; message: string };

const MAX_SUBJECT = 200;
const MAX_BODY = 3000;

export function EmailCampaignForm({ businessId, businessName }: Props) {
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [state, setState] = useState<SendState>({ status: 'idle' });

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (state.status === 'submitting') return;

    setState({ status: 'submitting' });

    try {
      const res = await fetch('/sunucu/sahip/eposta-kampanya', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId, subject: subject.trim(), body: body.trim() }),
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

      // Reset form
      setSubject('');
      setBody('');
    } catch {
      setState({ status: 'error', message: 'Ağ hatası. Lütfen internet bağlantınızı kontrol edin.' });
    }
  }

  const isSubmitting = state.status === 'submitting';

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-border bg-card p-5">
      {/* Business context */}
      <div className="flex items-center gap-2 border-b border-border pb-3">
        <MailIconSmall />
        <span className="text-sm font-[700] text-textStrong">{businessName}</span>
        <span className="ml-auto text-xs text-muted">Kampanya Gönder</span>
      </div>

      {/* Success banner */}
      {state.status === 'success' && (
        <div
          role="status"
          className="rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm font-[700] text-green-800"
        >
          {state.providerNotConfigured ? (
            <>
              E-posta servisi henüz yapılandırılmamış. Kampanya kaydedildi ancak e-posta
              gönderilmedi.{' '}
              <span className="font-[400]">
                Aktif etmek için <code className="font-mono text-xs">RESEND_API_KEY</code> ortam
                degiskenini ekleyin.
              </span>
            </>
          ) : state.sentTo > 0 ? (
            `Kampanya gonderildi. ${state.sentTo} kisiye ulasti.`
          ) : (
            'Kampanya kaydedildi. E-posta izni veren takipci bulunamadi.'
          )}
        </div>
      )}

      {/* Error banner */}
      {state.status === 'error' && (
        <div
          role="alert"
          className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-[700] text-red-800"
        >
          {state.message}
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        {/* Subject */}
        <div className="flex flex-col gap-1.5">
          <label htmlFor="email-subject" className="text-sm font-[700] text-textStrong">
            Konu <span className="text-red-500" aria-hidden="true">*</span>
          </label>
          <input
            id="email-subject"
            type="text"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            maxLength={MAX_SUBJECT}
            required
            placeholder="Örn: Bu hafta sonu özel indirim!"
            disabled={isSubmitting}
            className="h-10 w-full rounded-lg border border-border bg-bg px-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:opacity-50"
          />
          <span className="self-end text-xs text-muted">
            {subject.length}/{MAX_SUBJECT}
          </span>
        </div>

        {/* Body */}
        <div className="flex flex-col gap-1.5">
          <label htmlFor="email-body" className="text-sm font-[700] text-textStrong">
            Mesaj <span className="text-red-500" aria-hidden="true">*</span>
          </label>
          <textarea
            id="email-body"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            maxLength={MAX_BODY}
            required
            rows={6}
            placeholder="Müşterilerinize iletmek istediğiniz mesajı buraya yazın..."
            disabled={isSubmitting}
            className="w-full resize-y rounded-lg border border-border bg-bg px-3 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:opacity-50"
          />
          <span className="self-end text-xs text-muted">
            {body.length}/{MAX_BODY}
          </span>
        </div>

        <div className="flex items-center gap-3 border-t border-border pt-4">
          <button
            type="submit"
            disabled={isSubmitting || !subject.trim() || !body.trim()}
            className="inline-flex h-10 items-center gap-2 rounded-lg bg-primary px-5 text-sm font-[700] text-white transition-opacity hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {isSubmitting ? (
              <>
                <SpinnerIcon />
                Gönderiliyor...
              </>
            ) : (
              <>
                <SendIcon />
                Kampanya Gönder
              </>
            )}
          </button>
          <p className="text-xs text-muted">
            Yalnızca e-posta iznini onaylayan takipçilere gönderilir.
          </p>
        </div>
      </form>
    </div>
  );
}

// ---- icons ----

function MailIconSmall() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22,6 12,13 2,6" />
    </svg>
  );
}

function SendIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <line x1="22" y1="2" x2="11" y2="13" />
      <polygon points="22 2 15 22 11 13 2 9 22 2" />
    </svg>
  );
}

function SpinnerIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      className="animate-spin"
    >
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
  );
}
