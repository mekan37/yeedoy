'use client';

import { useState } from 'react';
import type { AppLang, MenuCopy } from '@/src/lib/i18n';

type FeedbackCategory = 'menu' | 'price' | 'service' | 'app' | 'other';

type Props = {
  businessId: string;
  lang: AppLang;
  labels: MenuCopy;
};

export function FeedbackWidget({ businessId, labels }: Props) {
  const [open, setOpen] = useState(false);
  const [rating, setRating] = useState(0);
  const [category, setCategory] = useState<FeedbackCategory>('menu');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  const categoryOptions: Array<{ value: FeedbackCategory; label: string }> = [
    { value: 'menu', label: labels.feedbackCategoryMenu },
    { value: 'price', label: labels.feedbackCategoryPrice },
    { value: 'service', label: labels.feedbackCategoryService },
    { value: 'app', label: labels.feedbackCategoryApp },
    { value: 'other', label: labels.feedbackCategoryOther },
  ];

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (rating === 0) return;
    setStatus('loading');

    try {
      const res = await fetch('/api/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          businessId,
          rating,
          category,
          message: message.trim() || undefined,
        }),
      });

      if (!res.ok) throw new Error('failed');
      setStatus('success');
      setTimeout(() => {
        setOpen(false);
        setStatus('idle');
        setRating(0);
        setMessage('');
        setCategory('menu');
      }, 2000);
    } catch {
      setStatus('error');
      setTimeout(() => setStatus('idle'), 3000);
    }
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 shadow-xs transition hover:bg-slate-50"
        aria-label={labels.feedbackButtonLabel}
      >
        <span aria-hidden="true">💬</span>
        {labels.feedbackButtonLabel}
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 sm:items-center"
          onClick={(e) => e.target === e.currentTarget && setOpen(false)}
        >
          <div className="w-full max-w-sm rounded-t-2xl bg-white p-6 shadow-xl sm:rounded-2xl">
            {status === 'success' ? (
              <div className="flex flex-col items-center gap-3 py-6 text-center">
                <span className="text-3xl" aria-hidden="true">✅</span>
                <p className="font-semibold text-slate-700">{labels.feedbackSuccess}</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                <h2 className="text-base font-bold text-slate-800">{labels.feedbackTitle}</h2>

                {/* Star rating */}
                <div className="flex gap-1" role="group" aria-label="Rating">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <button
                      key={star}
                      type="button"
                      onClick={() => setRating(star)}
                      className={`text-2xl transition ${star <= rating ? 'text-amber-400' : 'text-slate-200 hover:text-amber-300'}`}
                      aria-label={`${star} star`}
                      aria-pressed={star <= rating}
                    >
                      ★
                    </button>
                  ))}
                </div>

                {/* Category */}
                <div>
                  <label className="mb-1.5 block text-xs font-semibold text-slate-500">
                    {labels.feedbackCategory}
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {categoryOptions.map((opt) => (
                      <button
                        key={opt.value}
                        type="button"
                        onClick={() => setCategory(opt.value)}
                        className={`rounded-full border px-3 py-1 text-xs font-semibold transition ${
                          category === opt.value
                            ? 'border-red-800 bg-red-50 text-red-800'
                            : 'border-slate-200 text-slate-600 hover:border-slate-300'
                        }`}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Message */}
                <div>
                  <label className="mb-1.5 block text-xs font-semibold text-slate-500">
                    {labels.feedbackMessage}
                  </label>
                  <textarea
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    maxLength={500}
                    rows={3}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 p-3 text-sm text-slate-700 outline-hidden focus:border-red-800 focus:ring-1 focus:ring-red-800"
                    placeholder="..."
                  />
                </div>

                {status === 'error' && (
                  <p className="text-xs text-red-600">{labels.feedbackError}</p>
                )}

                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setOpen(false)}
                    className="flex-1 rounded-xl border border-slate-200 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
                  >
                    {labels.close}
                  </button>
                  <button
                    type="submit"
                    disabled={rating === 0 || status === 'loading'}
                    className="flex-1 rounded-xl bg-red-800 py-2 text-sm font-semibold text-white transition hover:bg-red-900 disabled:opacity-50"
                  >
                    {status === 'loading' ? '…' : labels.feedbackSubmit}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </>
  );
}
