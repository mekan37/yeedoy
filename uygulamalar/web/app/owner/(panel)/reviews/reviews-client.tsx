'use client';

import { useEffect, useState } from 'react';

const LS_KEY = 'owner_reviews_last_seen_at';

export interface ReviewRow {
  id: string;
  business_id: string;
  rating: number;
  title: string | null;
  content: string;
  helpful_count: number;
  created_at: string;
  status: string;
  reply_id: string | null;
  reply_content: string | null;
  reply_at: string | null;
}

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  approved: { label: 'Onaylı',     color: 'bg-emerald-50 text-emerald-700' },
  pending:  { label: 'Bekleyen',   color: 'bg-amber-50 text-amber-700' },
  rejected: { label: 'Reddedilen', color: 'bg-zinc-100 text-zinc-500' },
};

interface Props {
  reviews: ReviewRow[];
  businessMap: Record<string, string>;
  showBusinessName: boolean;
}

export function ReviewsClient({ reviews, businessMap, showBusinessName }: Props) {
  // lastSeenAt: önceki ziyarette localStorage'a yazılan timestamp
  // Sayfadan çıkıldığında güncellenir → bir sonraki girişte "Yeni" sıfırlanır
  const [lastSeenAt, setLastSeenAt] = useState<number>(0);

  useEffect(() => {
    const stored = localStorage.getItem(LS_KEY);
    if (stored) setLastSeenAt(parseInt(stored, 10));

    // Unmount = kullanıcı sayfadan çıktı → şimdiki zamanı kaydet
    return () => {
      localStorage.setItem(LS_KEY, Date.now().toString());
    };
  }, []);

  if (reviews.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border bg-[#fafafa] py-16 text-center">
        <StarIconLg />
        <p className="mt-3 text-base font-[800] text-textStrong">Yorum bulunamadı</p>
        <p className="mt-1 text-sm text-muted">Seçili filtreyle eşleşen yorum yok.</p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card">
      <div className="flex items-center justify-between border-b border-border px-5 py-3">
        <p className="text-sm font-[700] text-textStrong">{reviews.length} yorum</p>
      </div>
      <ul className="divide-y divide-border">
        {reviews.map((r) => (
          <ReviewItem
            key={r.id}
            review={r}
            businessName={showBusinessName ? businessMap[r.business_id] : undefined}
            isNew={lastSeenAt > 0 && new Date(r.created_at).getTime() > lastSeenAt}
          />
        ))}
      </ul>
    </div>
  );
}

function ReviewItem({ review, businessName, isNew }: { review: ReviewRow; businessName?: string; isNew?: boolean }) {
  const [showForm, setShowForm]       = useState(false);
  const [replyText, setReplyText]     = useState(review.reply_content ?? '');
  const [submitting, setSubmitting]   = useState(false);
  const [error, setError]             = useState<string | null>(null);
  const [reply, setReply] = useState<{
    content: string | null;
    at: string | null;
    id: string | null;
  }>({
    content: review.reply_content,
    at: review.reply_at,
    id: review.reply_id,
  });

  const statusInfo = STATUS_LABELS[review.status] ?? STATUS_LABELS['pending'];

  async function handleSubmit() {
    if (replyText.trim().length < 10) return;
    setSubmitting(true);
    setError(null);
    try {
      const res = await fetch('/api/owner/review-reply', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reviewId: review.id, content: replyText.trim() }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        setError(data.error === 'not_authorized' ? 'Bu yoruma yanıt verme yetkiniz yok.' : 'Yanıt gönderilemedi.');
        return;
      }
      const data = await res.json();
      setReply({ content: replyText.trim(), at: new Date().toISOString(), id: data.reply_id });
      setShowForm(false);
    } catch {
      setError('Bağlantı hatası, tekrar deneyin.');
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete() {
    setSubmitting(true);
    setError(null);
    try {
      const res = await fetch('/api/owner/review-reply', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reviewId: review.id }),
      });
      if (!res.ok) { setError('Yanıt silinemedi.'); return; }
      setReply({ content: null, at: null, id: null });
      setReplyText('');
    } catch {
      setError('Bağlantı hatası.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <li className="px-5 py-4">
      <div className="flex items-start gap-3">
        {/* Rating avatar */}
        <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-xs font-[800] ${ratingBg(review.rating)}`}>
          {review.rating}★
        </div>

        <div className="min-w-0 flex-1">
          {/* Header row */}
          <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5">
            <StarRating rating={review.rating} />
            <span className="text-xs text-muted">
              {new Date(review.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
            </span>
            {businessName && (
              <span className="text-xs text-muted">· {businessName}</span>
            )}
          </div>

          {/* Başlık */}
          {review.title && (
            <p className="mt-1 text-sm font-[700] text-textStrong">{review.title}</p>
          )}

          {/* İçerik */}
          <p className="mt-1 text-sm leading-relaxed text-text">{review.content}</p>

          {/* Rozetler */}
          <div className="mt-2 flex flex-wrap items-center gap-2">
            {isNew && (
              <span className="inline-flex items-center rounded-full bg-[#7f1d1d] px-2 py-0.5 text-[11px] font-[800] text-white">
                Yeni
              </span>
            )}
            <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-[700] ${statusInfo.color}`}>
              {statusInfo.label}
            </span>
            {review.helpful_count > 0 && (
              <span className="text-[11px] text-muted">{review.helpful_count} kişi faydalı buldu</span>
            )}
          </div>

          {/* Mevcut yanıt */}
          {reply.content && !showForm && (
            <div className="mt-3 rounded-xl border-l-2 border-[#7f1d1d] bg-[#7f1d1d]/5 px-4 py-3">
              <p className="text-[11px] font-[800] uppercase tracking-wider text-[#7f1d1d]">İşletme Yanıtı</p>
              {reply.at && (
                <p className="text-[11px] text-muted">
                  {new Date(reply.at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                </p>
              )}
              <p className="mt-1.5 text-sm leading-relaxed text-text">{reply.content}</p>
              <div className="mt-2 flex gap-3">
                <button
                  onClick={() => { setReplyText(reply.content!); setShowForm(true); }}
                  disabled={submitting}
                  className="text-xs font-[600] text-muted hover:text-textStrong"
                >
                  Düzenle
                </button>
                <button
                  onClick={handleDelete}
                  disabled={submitting}
                  className="text-xs font-[600] text-red-500 hover:text-red-700"
                >
                  {submitting ? 'Siliniyor…' : 'Sil'}
                </button>
              </div>
            </div>
          )}

          {/* Yanıt yaz butonu */}
          {!reply.content && !showForm && (
            <button
              onClick={() => setShowForm(true)}
              className="mt-2 text-xs font-[700] text-[#7f1d1d] hover:underline"
            >
              + Yanıt Yaz
            </button>
          )}

          {/* Yanıt formu */}
          {showForm && (
            <div className="mt-3 rounded-xl border border-border bg-[#fafafa] p-4">
              <p className="mb-2 text-xs font-[800] text-textStrong">
                {reply.content ? 'Yanıtı Düzenle' : 'Yanıt Yaz'}
              </p>
              <textarea
                value={replyText}
                onChange={(e) => setReplyText(e.target.value)}
                placeholder="Müşteriye yanıtınızı yazın… (en az 10 karakter)"
                rows={4}
                maxLength={2000}
                className="w-full resize-none rounded-xl border border-border bg-card px-4 py-3 text-sm text-text placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-[#7f1d1d]/20"
              />
              <div className="mt-1 flex items-center justify-between">
                <span className="text-[11px] text-muted">{replyText.length}/2000</span>
              </div>
              {error && (
                <p className="mt-1 text-xs text-red-500">{error}</p>
              )}
              <div className="mt-3 flex justify-end gap-2">
                <button
                  onClick={() => { setShowForm(false); setError(null); setReplyText(reply.content ?? ''); }}
                  className="rounded-xl px-4 py-1.5 text-sm text-muted hover:text-textStrong"
                >
                  İptal
                </button>
                <button
                  onClick={handleSubmit}
                  disabled={submitting || replyText.trim().length < 10}
                  className="rounded-xl bg-[#7f1d1d] px-5 py-1.5 text-sm font-[700] text-white disabled:opacity-40"
                >
                  {submitting ? 'Gönderiliyor…' : 'Gönder'}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </li>
  );
}

function ratingBg(rating: number) {
  if (rating >= 5) return 'bg-emerald-100 text-emerald-700';
  if (rating >= 4) return 'bg-green-100 text-green-700';
  if (rating >= 3) return 'bg-amber-100 text-amber-700';
  if (rating >= 2) return 'bg-orange-100 text-orange-700';
  return 'bg-red-100 text-red-700';
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <svg key={n} width="12" height="12" viewBox="0 0 24 24"
          fill={n <= rating ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2"
          className={n <= rating ? 'text-amber-400' : 'text-zinc-300'}>
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  );
}

function StarIconLg() {
  return (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"
      strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
