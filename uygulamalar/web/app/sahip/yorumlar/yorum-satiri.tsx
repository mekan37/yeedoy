'use client';

import { useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { clsx } from 'clsx';
import { HeartHandshake, Smile, HandHelping, Star, type LucideIcon } from 'lucide-react';

export type YorumDurumu = 'pending' | 'approved' | 'rejected';

interface YorumSatiriProps {
  reviewId: string;
  businessName: string;
  showBranchBadge: boolean;
  rating: number;
  content: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
  status: YorumDurumu;
  ownerReply: string | null;
  ownerRepliedAt: string | null;
}

function zamanOnce(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const gun = Math.floor(diffMs / 86400000);
  if (gun <= 0) return 'Bugün';
  if (gun === 1) return 'Dün';
  if (gun < 7) return `${gun} gün önce`;
  if (gun < 30) return `${Math.floor(gun / 7)} hafta önce`;
  if (gun < 365) return `${Math.floor(gun / 30)} ay önce`;
  return `${Math.floor(gun / 365)} yıl önce`;
}

export function YorumSatiri({
  reviewId,
  businessName,
  showBranchBadge,
  rating,
  content,
  displayName,
  avatarUrl,
  createdAt,
  status,
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
  const router = useRouter();

  const REPLY_TEMPLATES: { icon: LucideIcon; label: string; text: string }[] = [
    { icon: HeartHandshake, label: 'Teşekkür', text: 'Değerli yorumunuz için çok teşekkür ederiz! Sizi ağırlamaktan büyük mutluluk duyduk. Tekrar görüşmek dileğiyle, iyi günler!' },
    { icon: Smile, label: 'Olumlu Yanıt', text: 'Güzel yorumunuz için teşekkürler! Ekibimizle paylaşacağız. Sizi tekrar görmek dileğiyle!' },
    { icon: HandHelping, label: 'Özür & İyileştirme', text: 'Yaşadığınız deneyim için özür dileriz. Geri bildiriminizi dikkate alıp hizmetimizi geliştireceğiz. Tekrar fırsat vermenizi umuyoruz.' },
    { icon: Star, label: 'Detay Sorusu', text: 'Yorumunuz için teşekkürler! Daha iyi hizmet verebilmek için deneyiminizi biraz daha anlatabilir misiniz? İletişime geçebilirsiniz.' },
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
      // Yan menüdeki yanıtsız yorum rozeti /sahip/layout.tsx'te hesaplanıyor —
      // bu fetch bir server action olmadığından revalidate tetiklemiyor, o yüzden
      // rozetin gerçek sayıyı yansıtması için layout'u elle tazeliyoruz.
      router.refresh();
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
      router.refresh();
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
    <li id={`yorum-${reviewId}`} className="px-5 py-4">
      {/* Yorum başlığı */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex min-w-0 flex-1 items-start gap-3">
          <ReviewerAvatar avatarUrl={avatarUrl} displayName={displayName} />
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-xs font-bold text-textStrong">
                {displayName ?? 'Anonim'}
              </span>
              <StarRating rating={rating} />
              <span className="text-xs text-muted">· {zamanOnce(createdAt)}</span>
            </div>
            {content && (
              <p className="mt-1.5 text-sm leading-relaxed text-text">{content}</p>
            )}
          </div>
        </div>
        <div className="flex shrink-0 flex-col items-end gap-2">
          <div className="flex flex-wrap items-center justify-end gap-1.5">
            {showBranchBadge && businessName && (
              <span className="rounded-full border border-border bg-bg px-2 py-0.5 text-[11px] font-bold text-muted">
                {businessName}
              </span>
            )}
            <StatusBadge status={status} hasReply={Boolean(savedReply)} />
          </div>
          {status === 'approved' && !savedReply && !showForm && (
            <button
              onClick={() => { setShowForm(true); setTimeout(() => textareaRef.current?.focus(), 50); }}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-extrabold text-primary hover:bg-bg"
            >
              Yanıtla
            </button>
          )}
          <p className="text-[11px] text-muted">
            {new Date(createdAt).toLocaleDateString('tr-TR')} {new Date(createdAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
          </p>
        </div>
      </div>

      {/* Mevcut sahip yanıtı */}
      {savedReply && (
        <div className="mt-3 rounded-xl border border-border bg-(--yd-color-primary-soft) px-4 py-3">
          <p className="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-primary">
            İşletme Yanıtı
            {repliedAt && (
              <span className="ml-2 font-semibold normal-case tracking-normal text-muted">
                · {new Date(repliedAt).toLocaleDateString('tr-TR')}
              </span>
            )}
          </p>
          <p className="text-sm leading-relaxed text-text">{savedReply}</p>
          <div className="mt-2 flex gap-3">
            <button
              onClick={openEditForm}
              disabled={loading}
              className="text-[11px] font-extrabold text-primary underline-offset-2 hover:underline disabled:opacity-50"
            >
              Düzenle
            </button>
            <button
              onClick={deleteReply}
              disabled={loading}
              className="text-[11px] font-extrabold text-danger underline-offset-2 hover:underline disabled:opacity-50"
            >
              Yanıtı Sil
            </button>
          </div>
        </div>
      )}

      {/* Yanıt formu */}
      {showForm && (
        <div className="mt-3">
          {/* Reply templates */}
          <div className="mb-2">
            <button onClick={() => setShowTemplates(!showTemplates)}
              className="text-xs font-bold text-primary hover:underline">
              {showTemplates ? '▲ Şablonları Kapat' : '▼ Hazır Şablon Kullan'}
            </button>
            {showTemplates && (
              <div className="mt-2 flex flex-wrap gap-2">
                {REPLY_TEMPLATES.map(t => (
                  <button key={t.label} onClick={() => { setReply(t.text); setShowTemplates(false); textareaRef.current?.focus(); }}
                    className="inline-flex items-center gap-1 rounded-lg border border-border bg-card px-2.5 py-1 text-xs font-bold text-muted hover:border-primary hover:text-primary">
                    <t.icon className="h-3.5 w-3.5" aria-hidden="true" /> {t.label}
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
            <p className="mt-1 text-xs font-bold text-danger">{error}</p>
          )}
          <div className="mt-2 flex items-center gap-2">
            <button
              onClick={submitReply}
              disabled={loading || !reply.trim()}
              className="btn-primary inline-flex min-h-[36px] items-center rounded-xl px-4 text-sm font-extrabold text-white disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Kaydediliyor…' : 'Yanıtı Kaydet'}
            </button>
            <button
              onClick={() => { setShowForm(false); setError(null); setShowTemplates(false); }}
              disabled={loading}
              className="inline-flex min-h-[36px] items-center rounded-xl border border-border bg-card px-4 text-sm font-bold text-textStrong hover:bg-textStrong/[0.05] disabled:opacity-50"
            >
              İptal
            </button>
            <span className="ml-auto text-[11px] text-muted">{reply.length}/2000</span>
          </div>
        </div>
      )}
    </li>
  );
}

function StatusBadge({ status, hasReply }: { status: YorumDurumu; hasReply: boolean }) {
  if (status === 'rejected') {
    return <span className="rounded-full bg-red-50 px-2.5 py-1 text-[11px] font-extrabold text-red-700">Reddedildi</span>;
  }
  if (status === 'pending') {
    return <span className="rounded-full bg-zinc-100 px-2.5 py-1 text-[11px] font-extrabold text-zinc-600">Onay Bekliyor</span>;
  }
  if (!hasReply) {
    return <span className="rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-extrabold text-amber-700">Yanıt Bekliyor</span>;
  }
  return <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-extrabold text-emerald-700">Yayınlandı</span>;
}

function ReviewerAvatar({ avatarUrl, displayName }: { avatarUrl: string | null; displayName: string | null }) {
  const initial = (displayName ?? 'K').charAt(0).toUpperCase();
  if (avatarUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={avatarUrl}
        alt={displayName ?? 'Kullanıcı'}
        className="h-9 w-9 shrink-0 rounded-full border border-border object-cover"
      />
    );
  }
  return (
    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bg text-[13px] font-black text-textStrong">
      {initial}
    </div>
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
