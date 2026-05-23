'use client';

import { useState, useRef } from 'react';
import { clsx } from 'clsx';

interface YorumSatiriProps {
  reviewId: string;
  businessName: string;
  rating: number;
  content: string | null;
  displayName: string | null;
  createdAt: string;
  isVisible: boolean;
  ownerReply: string | null;
  ownerRepliedAt: string | null;
}

export function YorumSatiri({
  reviewId,
  businessName,
  rating,
  content,
  displayName,
  createdAt,
  isVisible,
  ownerReply: initialReply,
  ownerRepliedAt: initialRepliedAt,
}: YorumSatiriProps) {
  const [showForm, setShowForm] = useState(false);
  const [reply, setReply] = useState(initialReply ?? '');
  const [savedReply, setSavedReply] = useState(initialReply);
  const [repliedAt, setRepliedAt] = useState(initialRepliedAt);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showTemplates, setShowTemplates] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const REPLY_TEMPLATES = [
    { label: '🙏 Teşekkür', text: 'Değerli yorumunuz için çok teşekkür ederiz! Sizi ağırlamaktan büyük mutluluk duyduk. Tekrar görüşmek dileğiyle, iyi günler!' },
    { label: '😊 Olumlu Yanıt', text: 'Güzel yorumunuz için teşekkürler! Ekibimizle paylaşacağız. Sizi tekrar görmek dileğiyle!' },
    { label: '🙋 Özür & İyileştirme', text: 'Yaşadığınız deneyim için özür dileriz. Geri bildiriminizi dikkate alıp hizmetimizi geliştireceğiz. Tekrar fırsat vermenizi umuyoruz.' },
    { label: '⭐ Detay Sorusu', text: 'Yorumunuz için teşekkürler! Daha iyi hizmet verebilmek için deneyiminizi biraz daha anlatabilir misiniz? İletişime geçebilirsiniz.' },
  ];

  async function submitReply() {
    const text = reply.trim();
    if (!text) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/sunucu/sahip/yorumlar/yanit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reviewId, reply: text }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Hata oluştu');
      setSavedReply(text);
      setRepliedAt(json.repliedAt ?? new Date().toISOString());
      setShowForm(false);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  async function deleteReply() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/sunucu/sahip/yorumlar/yanit', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reviewId }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Hata oluştu');
      setSavedReply(null);
      setRepliedAt(null);
      setReply('');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  function openEditForm() {
    setReply(savedReply ?? '');
    setShowForm(true);
    setTimeout(() => textareaRef.current?.focus(), 50);
  }

  return (
    <li className="px-5 py-4">
      {/* Yorum başlığı */}
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <StarRating rating={rating} />
            <span className="text-xs font-[700] text-textStrong">
              {displayName ?? 'Anonim'}
            </span>
            {businessName && (
              <span className="text-xs text-muted">· {businessName}</span>
            )}
          </div>
          {content && (
            <p className="mt-1.5 text-sm leading-relaxed text-text">{content}</p>
          )}
        </div>
        <div className="shrink-0 text-right">
          <p className="text-xs text-muted">
            {new Date(createdAt).toLocaleDateString('tr-TR')}
          </p>
          {isVisible === false && (
            <span className="mt-1 inline-block rounded-full bg-border px-2 py-0.5 text-[11px] font-[700] text-muted">
              Gizli
            </span>
          )}
        </div>
      </div>

      {/* Mevcut sahip yanıtı */}
      {savedReply && (
        <div className="mt-3 rounded-xl border border-border bg-[var(--yd-color-primary-soft)] px-4 py-3">
          <p className="mb-1 text-[11px] font-[800] uppercase tracking-wider text-primary">
            İşletme Yanıtı
            {repliedAt && (
              <span className="ml-2 font-[600] normal-case tracking-normal text-muted">
                · {new Date(repliedAt).toLocaleDateString('tr-TR')}
              </span>
            )}
          </p>
          <p className="text-sm leading-relaxed text-text">{savedReply}</p>
          <div className="mt-2 flex gap-3">
            <button
              onClick={openEditForm}
              disabled={loading}
              className="text-[11px] font-[800] text-primary underline-offset-2 hover:underline disabled:opacity-50"
            >
              Düzenle
            </button>
            <button
              onClick={deleteReply}
              disabled={loading}
              className="text-[11px] font-[800] text-danger underline-offset-2 hover:underline disabled:opacity-50"
            >
              Yanıtı Sil
            </button>
          </div>
        </div>
      )}

      {/* Yanıt formu */}
      {showForm ? (
        <div className="mt-3">
          {/* Reply templates */}
          <div className="mb-2">
            <button onClick={() => setShowTemplates(!showTemplates)}
              className="text-xs font-[700] text-primary hover:underline">
              {showTemplates ? '▲ Şablonları Kapat' : '▼ Hazır Şablon Kullan'}
            </button>
            {showTemplates && (
              <div className="mt-2 flex flex-wrap gap-2">
                {REPLY_TEMPLATES.map(t => (
                  <button key={t.label} onClick={() => { setReply(t.text); setShowTemplates(false); textareaRef.current?.focus(); }}
                    className="rounded-lg border border-border bg-card px-2.5 py-1 text-xs font-[700] text-muted hover:border-primary hover:text-primary">
                    {t.label}
                  </button>
                ))}
              </div>
            )}
          </div>

          <textarea
            ref={textareaRef}
            value={reply}
            onChange={(e) => setReply(e.target.value)}
            rows={3}
            maxLength={2000}
            placeholder="Yanıtınızı yazın… (maks. 2000 karakter)"
            className={clsx(
              'input-yd w-full resize-none rounded-xl px-3 py-2.5 text-sm',
              error && 'border-danger/60',
            )}
          />
          {error && (
            <p className="mt-1 text-xs font-[700] text-danger">{error}</p>
          )}
          <div className="mt-2 flex items-center gap-2">
            <button
              onClick={submitReply}
              disabled={loading || !reply.trim()}
              className="btn-primary inline-flex min-h-[36px] items-center rounded-xl px-4 text-sm font-[800] text-white disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Kaydediliyor…' : 'Yanıtı Kaydet'}
            </button>
            <button
              onClick={() => { setShowForm(false); setError(null); setShowTemplates(false); }}
              disabled={loading}
              className="inline-flex min-h-[36px] items-center rounded-xl border border-border bg-card px-4 text-sm font-[700] text-textStrong hover:bg-textStrong/[0.05] disabled:opacity-50"
            >
              İptal
            </button>
            <span className="ml-auto text-[11px] text-muted">{reply.length}/2000</span>
          </div>
        </div>
      ) : !savedReply ? (
        <div className="mt-2">
          <button
            onClick={() => { setShowForm(true); setTimeout(() => textareaRef.current?.focus(), 50); }}
            className="text-xs font-[800] text-primary underline-offset-2 hover:underline"
          >
            + Yanıtla
          </button>
        </div>
      ) : null}
    </li>
  );
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <svg
          key={n}
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill={n <= rating ? 'currentColor' : 'none'}
          stroke="currentColor"
          strokeWidth="2"
          className={n <= rating ? 'text-amber-400' : 'text-zinc-300'}
        >
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  );
}
