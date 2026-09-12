'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter, useParams } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { getBlacklistTerms, matchesBlacklist } from '@/src/lib/moderasyon/kara-liste-on-kontrol';
import { escapePostgrestValue } from '@/src/lib/postgrest-yardimcilari';

const CRITERIA = [
  { key: 'taste_rating', label: 'Lezzet' },
  { key: 'service_speed_rating', label: 'Servis' },
  { key: 'price_performance_rating', label: 'Fiyat / Değer' },
  { key: 'cleanliness_rating', label: 'Temizlik' },
  { key: 'atmosphere_rating', label: 'Atmosfer' },
] as const;

type CriteriaKey = (typeof CRITERIA)[number]['key'];

const ERROR_MESSAGES: Record<string, string> = {
  not_authenticated: 'Oturum açmanız gerekiyor.',
  business_required: 'İşletme bulunamadı.',
  bad_rating: 'Geçerli bir puan seçin.',
  content_too_short: 'Yorum en az 8 karakter olmalı.',
  emoji_spam: 'Çok fazla emoji/özel karakter kullanımı tespit edildi.',
  review_daily_rate_limited: 'Günlük yorum limitine ulaştınız, yarın tekrar deneyin.',
  new_account_rate_limited: 'Yeni hesaplar için günlük yorum limiti aşıldı.',
  same_business_cooldown: 'Bu işletmeye kısa süre önce yorum yaptınız, biraz bekleyin.',
};

function YildizSatiri({ value, onChange, label }: { value: number; onChange: (v: number) => void; label: string }) {
  const [hover, setHover] = useState(0);
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="w-28 shrink-0 text-sm text-muted">{label}</span>
      <div className="flex gap-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <button
            key={star} type="button"
            onClick={() => onChange(value === star ? 0 : star)}
            onMouseEnter={() => setHover(star)}
            onMouseLeave={() => setHover(0)}
            aria-label={`${label} ${star} yıldız`}
            className="text-xl transition-colors cursor-pointer focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-primary/40 rounded"
          >
            <svg viewBox="0 0 24 24" className="h-6 w-6" fill={(hover || value) >= star ? '#f59e0b' : 'none'} stroke={(hover || value) >= star ? '#f59e0b' : '#d1d5db'} strokeWidth="1.5" aria-hidden="true">
              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
          </button>
        ))}
      </div>
    </div>
  );
}

export default function YeniYorumSayfasi() {
  const params = useParams<{ slug: string }>();
  const slug = params.slug;
  const router = useRouter();

  const [bizName, setBizName] = useState('');
  const [bizId, setBizId] = useState<string | null>(null);
  const [userId, setUserId] = useState<string | null>(null);
  const [rating, setRating] = useState(0);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [criteria, setCriteria] = useState<Record<CriteriaKey, number>>({
    taste_rating: 0, service_speed_rating: 0, price_performance_rating: 0,
    cleanliness_rating: 0, atmosphere_rating: 0,
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [blacklist, setBlacklist] = useState<string[]>([]);
  const [warnProfanity, setWarnProfanity] = useState(false);

  useEffect(() => {
    getBlacklistTerms().then(setBlacklist);
  }, []);

  useEffect(() => {
    const t = setTimeout(() => {
      setWarnProfanity(content.trim().length > 0 && matchesBlacklist(content, blacklist));
    }, 400);
    return () => clearTimeout(t);
  }, [content, blacklist]);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    Promise.all([
      supabase.auth.getUser(),
      (supabase)
        .from('businesses')
        .select('id, name')
        .or(`slug.eq.${escapePostgrestValue(slug)},public_slug.eq.${escapePostgrestValue(slug)}`)
        .maybeSingle(),
    ]).then(([{ data: { user } }, { data: biz }]) => {
      if (!user) { router.push(`/giris?redirect=/isletme/${slug}/yorumlar/new`); return; }
      setUserId(user.id);
      if (biz) {
        setBizId(biz.id); setBizName(biz.name);
      } else {
        setError('İşletme bulunamadı. Bağlantıyı tekrar kontrol edin.');
      }
    });
  }, [slug, router]);

  function setCriterion(key: CriteriaKey, value: number) {
    setCriteria((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (rating === 0) { setError('Lütfen genel puanınızı seçin'); return; }
    if (content.length < 20) { setError('Yorum en az 20 karakter olmalı'); return; }
    if (!bizId || !userId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };
      const { data, error: err } = await sb.rpc('submit_review_v3', {
        p_business_id: bizId,
        p_overall_rating: rating,
        p_title: title.trim() || null,
        p_content: content,
        p_taste_rating: criteria.taste_rating > 0 ? criteria.taste_rating : null,
        p_service_speed_rating: criteria.service_speed_rating > 0 ? criteria.service_speed_rating : null,
        p_price_performance_rating: criteria.price_performance_rating > 0 ? criteria.price_performance_rating : null,
        p_cleanliness_rating: criteria.cleanliness_rating > 0 ? criteria.cleanliness_rating : null,
        p_atmosphere_rating: criteria.atmosphere_rating > 0 ? criteria.atmosphere_rating : null,
      });
      if (err) throw err;
      const sonuc = data as { ok?: boolean; error?: string } | null;
      if (!sonuc?.ok) {
        const kod = sonuc?.error ?? 'unknown_error';
        setError(ERROR_MESSAGES[kod] ?? 'Yorum gönderilemedi, tekrar deneyin.');
        return;
      }
      router.push(`/isletme/${slug}/yorumlar`);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href={`/isletme/${slug}`}
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary">
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
          {bizName || 'İşletmeye'} Dön
        </Link>
        <h1 className="mb-1 text-2xl font-black text-textStrong">Yorum Yaz</h1>
        {bizName && <p className="mb-6 text-sm text-muted">{bizName}</p>}

        <form onSubmit={handleSubmit} className="flex flex-col gap-6">

          {/* Overall rating */}
          <div className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
            <p className="mb-3 text-sm font-black text-textStrong">Genel Puan <span className="text-danger">*</span></p>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} type="button" onClick={() => setRating(star)}
                  aria-label={`${star} yıldız`}
                  className="focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-primary/40 rounded cursor-pointer">
                  <svg viewBox="0 0 24 24" className="h-8 w-8 transition-transform hover:scale-110" fill={star <= rating ? '#f59e0b' : 'none'} stroke={star <= rating ? '#f59e0b' : '#d1d5db'} strokeWidth="1.5" aria-hidden="true">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                  </svg>
                </button>
              ))}
            </div>
          </div>

          {/* Criteria ratings */}
          <div className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
            <p className="mb-4 text-sm font-black text-textStrong">Detaylı Değerlendirme <span className="text-[11px] font-normal text-muted">(isteğe bağlı)</span></p>
            <div className="flex flex-col gap-3">
              {CRITERIA.map(({ key, label }) => (
                <YildizSatiri key={key} value={criteria[key]} onChange={(v) => setCriterion(key, v)} label={label} />
              ))}
            </div>
          </div>

          {/* Title */}
          <div>
            <label className="mb-2 block text-sm font-bold text-textStrong">Başlık <span className="text-[11px] font-normal text-muted">(isteğe bağlı)</span></label>
            <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} maxLength={80}
              placeholder="Kısa bir başlık ekleyin…"
              className="w-full rounded-2xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
          </div>

          {/* Content */}
          <div>
            <label className="mb-2 block text-sm font-bold text-textStrong">Yorumunuz <span className="text-danger">*</span></label>
            <textarea value={content} onChange={(e) => setContent(e.target.value)} rows={5} required minLength={20}
              placeholder="Deneyiminizi paylaşın… (en az 20 karakter)"
              className="w-full resize-none rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
            <p className={`mt-1 text-right text-[11px] ${content.length >= 20 ? 'text-success' : 'text-muted'}`}>
              {content.length} / 20+ karakter
            </p>
            {warnProfanity && (
              <p className="mt-1 text-xs font-bold text-danger">
                Yorumunuzda uygunsuz içerik olabilir — gönderdiğinizde inceleme sırasına alınabilir.
              </p>
            )}
          </div>

          {error && (
            <div className="rounded-xl border border-danger/20 bg-danger/8 px-4 py-3 text-sm font-bold text-danger">
              {error}
            </div>
          )}

          <button type="submit" disabled={loading || !bizId}
            className="min-h-[52px] w-full rounded-2xl text-base font-extrabold text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] disabled:opacity-60 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
            style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
            {loading ? 'Gönderiliyor…' : 'Yorumu Gönder'}
          </button>
        </form>
      </div>
    </main>
  );
}

