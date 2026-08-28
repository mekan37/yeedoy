'use client';

import { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { createSupabaseBrowserClient } from '@/src/lib/taban-istemci';
import { FotoGalerisiTetik, type GaleriPhoto } from '@/src/ui/acik/foto-galerisi-modal';
import { HelpfulVoteButton, ReportReviewButton } from '@/src/ui/acik/eylem-istemcisi';
import { Icon } from '@/src/ui/acik/simgeler';
import { AdresKopyalaButonu } from '@/src/ui/acik/isletme-istemci';
import { OsmHarita } from '@/src/components/maps/OsmHarita';
import type { AcikIsletmeKarti, AcikMenuUrunKarti } from '@/src/ui/acik/tipler';
import { ReservasyonFormu } from './rezervasyon-formu';
import {
  type KampanyaTuru,
  TUR_ETIKETLER,
  TUR_RENK,
  gunKaldiHesapla,
  kampanyaBadge,
} from '@/src/lib/kampanya-sunum';

// ── Types ─────────────────────────────────────────────────────────────────────

export type DetayTab = 'genel' | 'menu' | 'yorumlar' | 'fotograflar' | 'bilgiler' | 'kampanyalar';

export type KampanyaBilgi = {
  id: string;
  title: string;
  description: string | null;
  type: KampanyaTuru;
  discountPercent: number | null;
  imageUrl: string | null;
  endsAt: string | null;
};

export type YorumDetay = {
  id: string;
  rating: number;
  overall_rating: number | null;
  content: string | null;
  title: string | null;
  created_at: string;
  helpful_count: number;
  taste_rating: number | null;
  service_speed_rating: number | null;
  atmosphere_rating: number | null;
  price_performance_rating: number | null;
  cleanliness_rating: number | null;
  owner_reply: string | null;
  user_id?: string | null;
  user_profiles?: { display_name: string; avatar_url: string | null } | null;
  photos?: string[];
};

export type AltPuanOrt = {
  lezzet: number | null;
  servis: number | null;
  temizlik: number | null;
  fiyat: number | null;
  ortam: number | null;
};

export type IsletmeDetayTablariProps = {
  businessId: string;
  businessSlug: string;
  businessName: string;
  businessIsVerified: boolean | null;
  businessCategory: string | null;
  businessCity: string | null;
  businessDistrict: string | null;
  businessAddress: string | null;
  businessPhone: string | null;
  businessWebsite: string | null;
  businessLat: number | null;
  businessLng: number | null;
  businessHours: Array<{ label: string; value: string; active?: boolean }> | null;
  businessAvgRating: number | null;
  businessReviewCount: number | null;
  businessIsOpenNow: boolean | null;
  businessMenuHref: string | null;
  businessDescription: string | null;
  businessLogoUrl: string | null;
  priceSymbol: string | null;
  mapsHref: string | null;
  businessUrl: string;
  coverUrl: string | null;
  popularItems: AcikMenuUrunKarti[];
  menuItems: Array<{ id: string; name: string; price_cents?: number | null; is_available: boolean }>;
  mealCards: Array<{ key: string; name: string }>;
  galleryPhotos: GaleriPhoto[];
  yorumlar: YorumDetay[];
  yorumlarToplam: number;
  yildizDagitimi: Record<string, number>;
  altPuanOrt: AltPuanOrt;
  oneriYuzdesi: number | null;
  oneriKisi: number | null;
  anahrarKelimeler: Array<{ kelime: string; sayi: number }>;
  similar: AcikIsletmeKarti[];
  checkinCount: number;
  todayHours: { label: string; value: string } | null;
  medianPriceCents: number | null;
  acceptsReservations: boolean;
  reservationPhone: string | null;
  reservationMinParty: number;
  reservationMaxParty: number;
  reservationNote: string | null;
  kampanyalar: KampanyaBilgi[];
  initialTab?: DetayTab;
};

// ── Helpers ───────────────────────────────────────────────────────────────────

function zamanFarki(iso: string): string {
  const gun = Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
  if (gun < 1) return 'Bugün';
  if (gun < 7) return `${gun} gün önce`;
  const hafta = Math.floor(gun / 7);
  if (hafta < 5) return `${hafta} hafta önce`;
  const ay = Math.floor(gun / 30);
  if (ay < 12) return `${ay} ay önce`;
  return `${Math.floor(ay / 12)} yıl önce`;
}

function baslHarfler(ad: string): string {
  return ad.split(' ').map((w) => w[0] ?? '').join('').slice(0, 2).toUpperCase();
}

function formatFiyat(cents?: number | null): string | null {
  if (!cents) return null;
  return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
}

const AVATAR_RENKLER = [
  'bg-primary/10 text-primary',
  'bg-blue-100 text-blue-700',
  'bg-green-100 text-green-700',
  'bg-purple-100 text-purple-700',
  'bg-amber-100 text-amber-700',
];

function avatarRenk(isim: string): string {
  const kod = isim.charCodeAt(0) ?? 0;
  return AVATAR_RENKLER[kod % AVATAR_RENKLER.length]!;
}

// ── Small sub-components ──────────────────────────────────────────────────────

function YildizSecici({ value, onChange }: { value: number; onChange: (n: number) => void }) {
  const [hover, setHover] = useState(0);
  return (
    <div className="flex gap-1.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <button
          key={n}
          type="button"
          onClick={() => onChange(n)}
          onMouseEnter={() => setHover(n)}
          onMouseLeave={() => setHover(0)}
          className="text-2xl transition-transform hover:scale-110 focus:outline-hidden"
          aria-label={`${n} yıldız`}
        >
          <span className={(hover || value) >= n ? 'text-amber-400' : 'text-border'}>★</span>
        </button>
      ))}
    </div>
  );
}

function YildizSatiri({ rating, size = 'sm' }: { rating: number; size?: 'sm' | 'md' }) {
  const cls = size === 'md' ? 'text-base' : 'text-sm';
  return (
    <span className={`${cls} font-extrabold text-amber-400`} aria-label={`${rating} yıldız`}>
      {'★'.repeat(rating)}
      <span className="text-border">{'★'.repeat(Math.max(0, 5 - rating))}</span>
    </span>
  );
}

function DagitimCubugu({ yildiz, sayi, toplam }: { yildiz: number; sayi: number; toplam: number }) {
  const pct = toplam > 0 ? Math.round((sayi / toplam) * 100) : 0;
  return (
    <div className="flex items-center gap-2">
      <span className="w-2 shrink-0 text-right text-xs font-black text-textStrong">{yildiz}</span>
      <span className="shrink-0 text-[11px] text-amber-400">★</span>
      <div className="flex-1 h-2 rounded-full bg-border overflow-hidden">
        <div
          className="h-full rounded-full bg-amber-400 transition-all duration-500"
          style={{ width: `${pct}%` }}
        />
      </div>
      <span className="w-7 shrink-0 text-right text-xs font-extrabold text-muted">{sayi}</span>
    </div>
  );
}

function AltPuanCubugu({ label, value }: { label: string; value: number | null }) {
  if (value === null) return null;
  return (
    <div className="flex items-center gap-3">
      <span className="w-32 shrink-0 text-sm font-extrabold text-textStrong">{label}</span>
      <div className="flex-1 h-1.5 rounded-full bg-border overflow-hidden">
        <div
          className="h-full rounded-full bg-primary transition-all duration-500"
          style={{ width: `${(value / 5) * 100}%` }}
        />
      </div>
      <div className="flex w-9 shrink-0 items-center gap-0.5">
        <span className="text-[11px] text-amber-400">★</span>
        <span className="text-xs font-black text-textStrong">{value.toFixed(1)}</span>
      </div>
    </div>
  );
}

function YorumKartiDetay({ yorum, businessId }: { yorum: YorumDetay; businessId: string }) {
  const isim = yorum.user_profiles?.display_name ?? 'Anonim';
  const baslHarf = baslHarfler(isim);
  const renk = avatarRenk(isim);
  const avatarUrl = yorum.user_profiles?.avatar_url;

  const [showReplyForm, setShowReplyForm] = useState(false);
  const [replyText, setReplyText] = useState('');
  const [ownerReply, setOwnerReply] = useState(yorum.owner_reply);
  const [submitting, setSubmitting] = useState(false);
  const [replyError, setReplyError] = useState<string | null>(null);

  const handleYanitlaClick = useCallback(async () => {
    const sb = createSupabaseBrowserClient();
    const { data: { session } } = await sb.auth.getSession();
    if (!session) {
      window.location.href = `/giris?redirect=${encodeURIComponent(window.location.pathname)}`;
      return;
    }
    setReplyText(ownerReply ?? '');
    setReplyError(null);
    setShowReplyForm(true);
  }, [ownerReply]);

  const submitReply = useCallback(async () => {
    const text = replyText.trim();
    if (!text) return;
    setSubmitting(true);
    setReplyError(null);
    try {
      const res = await fetch('/sunucu/sahip/yorumlar/yanit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reviewId: yorum.id, reply: text }),
      });
      const json = await res.json();
      if (!res.ok) {
        if (res.status === 401) {
          window.location.href = `/giris?redirect=${encodeURIComponent(window.location.pathname)}`;
          return;
        }
        throw new Error(
          res.status === 404
            ? 'Bu işletmenin sahibi değilsiniz veya yorum bulunamadı.'
            : (json.error ?? 'Bir hata oluştu.'),
        );
      }
      setOwnerReply(text);
      setShowReplyForm(false);
    } catch (e: any) {
      setReplyError(e.message);
    } finally {
      setSubmitting(false);
    }
  }, [yorum.id, replyText]);

  return (
    <article className="border-b border-border pb-5 last:border-0 last:pb-0">
      {/* User row */}
      <div className="flex items-start gap-3">
        <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-black overflow-hidden ${avatarUrl ? '' : renk}`}>
          {avatarUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={avatarUrl} alt={isim} className="h-full w-full object-cover" />
          ) : baslHarf}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-sm font-black text-textStrong">{isim}</span>
          </div>
          <div className="mt-1 flex items-center gap-2 flex-wrap">
            <YildizSatiri rating={yorum.rating} />
            <span className="text-xs text-muted">{zamanFarki(yorum.created_at)}</span>
          </div>
        </div>
      </div>

      {/* Content */}
      {yorum.title && (
        <p className="mt-3 text-sm font-extrabold text-textStrong">{yorum.title}</p>
      )}
      {yorum.content && (
        <p className="mt-2 text-sm leading-6 text-textStrong line-clamp-4">{yorum.content}</p>
      )}

      {/* Yorum fotoğrafları */}
      {yorum.photos && yorum.photos.length > 0 && (
        <div className="mt-3 flex flex-wrap gap-2">
          {yorum.photos.map((url) => (
            <a key={url} href={url} target="_blank" rel="noopener noreferrer" className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl border border-border">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={url} alt="" className="h-full w-full object-cover" />
            </a>
          ))}
        </div>
      )}

      {/* Owner reply (mevcut yanıt gösterimi) */}
      {ownerReply && !showReplyForm && (
        <div className="mt-3 rounded-[14px] border border-border bg-primary/5 px-4 py-3">
          <p className="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-primary">İşletme Yanıtı</p>
          <p className="text-sm leading-6 text-textStrong">{ownerReply}</p>
        </div>
      )}

      {/* Actions */}
      <div className="mt-3 flex items-center gap-3">
        <HelpfulVoteButton reviewId={yorum.id} initialCount={yorum.helpful_count} />
        <ReportReviewButton reviewId={yorum.id} />
        {!showReplyForm && (
          <button
            type="button"
            onClick={handleYanitlaClick}
            className="inline-flex h-8 items-center gap-1.5 rounded-xl border border-border bg-bg px-3 text-xs font-extrabold text-muted transition-colors hover:border-primary/30 hover:text-primary"
          >
            <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current stroke-2" aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
            </svg>
            {ownerReply ? 'Yanıtı Düzenle' : 'Yanıtla'}
          </button>
        )}
      </div>

      {/* Inline reply form */}
      {showReplyForm && (
        <div className="mt-3">
          <textarea
            value={replyText}
            onChange={(e) => setReplyText(e.target.value)}
            rows={3}
            maxLength={2000}
            placeholder="Yanıtınızı yazın… (maks. 2000 karakter)"
            className="w-full resize-none rounded-[14px] border border-border bg-bg px-3 py-2.5 text-sm text-textStrong placeholder-muted focus:border-primary/40 focus:outline-hidden focus:ring-2 focus:ring-primary/10"
          />
          {replyError && (
            <p className="mt-1 text-xs font-extrabold text-danger">{replyError}</p>
          )}
          <div className="mt-2 flex items-center gap-2">
            <button
              type="button"
              onClick={submitReply}
              disabled={submitting || !replyText.trim()}
              className="inline-flex h-8 items-center rounded-xl px-4 text-xs font-extrabold text-white disabled:opacity-60"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              {submitting ? 'Kaydediliyor…' : 'Yanıtı Kaydet'}
            </button>
            <button
              type="button"
              onClick={() => { setShowReplyForm(false); setReplyError(null); }}
              disabled={submitting}
              className="inline-flex h-8 items-center rounded-xl border border-border bg-bg px-3 text-xs font-extrabold text-muted hover:text-textStrong disabled:opacity-60"
            >
              İptal
            </button>
            <span className="ml-auto text-[11px] text-muted">{replyText.length}/2000</span>
          </div>
        </div>
      )}
    </article>
  );
}

// ── Yorumlar sidebar: Yorum Yap form ─────────────────────────────────────────

type KriterPuanlar = { taste: number; service: number; price: number; cleanliness: number; atmosphere: number };

const KRITERLER: Array<{ key: keyof KriterPuanlar; label: string }> = [
  { key: 'taste', label: 'Lezzet' },
  { key: 'service', label: 'Servis' },
  { key: 'price', label: 'Fiyat/Değer' },
  { key: 'cleanliness', label: 'Temizlik' },
  { key: 'atmosphere', label: 'Ortam' },
];

function MiniKriterSecici({ label, value, onChange }: { label: string; value: number; onChange: (v: number) => void }) {
  const [hover, setHover] = useState(0);
  return (
    <div className="flex items-center gap-2">
      <span className="w-24 shrink-0 text-xs font-extrabold text-textStrong">{label}</span>
      <div className="flex gap-0.5">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            onClick={() => onChange(value === n ? 0 : n)}
            onMouseEnter={() => setHover(n)}
            onMouseLeave={() => setHover(0)}
            className="transition-transform hover:scale-110 focus:outline-hidden"
            aria-label={`${label}: ${n} yıldız`}
          >
            <span className={(hover || value) >= n ? 'text-amber-400' : 'text-border'}>★</span>
          </button>
        ))}
      </div>
      {value > 0 && <span className="text-[11px] font-extrabold text-amber-600">{value}/5</span>}
    </div>
  );
}

const MAKS_FOTOGRAF = 5;

function YorumYapForm({ businessId, businessSlug }: { businessId: string; businessSlug: string }) {
  const router = useRouter();
  const [yildiz, setYildiz] = useState(0);
  const [metin, setMetin] = useState('');
  const [kriterler, setKriterler] = useState<KriterPuanlar>({ taste: 0, service: 0, price: 0, cleanliness: 0, atmosphere: 0 });
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const [basarili, setBasarili] = useState(false);
  const [hata, setHata] = useState<string | null>(null);
  const [fotograflar, setFotograflar] = useState<File[]>([]);
  const dosyaInputRef = useRef<HTMLInputElement>(null);

  const onizlemeler = useMemo(() => fotograflar.map((f) => URL.createObjectURL(f)), [fotograflar]);
  useEffect(() => () => { onizlemeler.forEach((url) => URL.revokeObjectURL(url)); }, [onizlemeler]);

  function fotografSec(files: FileList | null) {
    if (!files || files.length === 0) return;
    setFotograflar((prev) => [...prev, ...Array.from(files)].slice(0, MAKS_FOTOGRAF));
  }

  function fotografKaldir(index: number) {
    setFotograflar((prev) => prev.filter((_, i) => i !== index));
  }

  const gonder = useCallback(async () => {
    if (yildiz === 0) { setHata('Lütfen bir puan seçin.'); return; }
    if (!metin.trim()) { setHata('Lütfen bir yorum yazın.'); return; }
    setGonderiliyor(true);
    setHata(null);
    try {
      const sb = createSupabaseBrowserClient();
      const { data: { session } } = await sb.auth.getSession();
      if (!session) {
        window.location.href = `/giris?redirect=${encodeURIComponent(window.location.pathname)}`;
        return;
      }
      const { data: yeniYorum, error } = await (sb as any).from('reviews').insert({
        business_id: businessId,
        user_id: session.user.id,
        rating: yildiz,
        content: metin.trim(),
        taste_rating: kriterler.taste || null,
        service_speed_rating: kriterler.service || null,
        price_performance_rating: kriterler.price || null,
        cleanliness_rating: kriterler.cleanliness || null,
        atmosphere_rating: kriterler.atmosphere || null,
      }).select('id').single();
      if (error) throw error;

      if (fotograflar.length > 0 && yeniYorum?.id) {
        const yuklenenUrller: string[] = [];
        for (const dosya of fotograflar) {
          const formData = new FormData();
          formData.set('businessId', businessId);
          formData.set('file', dosya);
          const res = await fetch('/sunucu/medya/yorum-yukleme', { method: 'POST', body: formData });
          const payload = (await res.json().catch(() => null)) as { data?: { url?: string } } | null;
          if (res.ok && payload?.data?.url) yuklenenUrller.push(payload.data.url);
        }
        if (yuklenenUrller.length > 0) {
          await (sb as any).from('review_photos').insert(
            yuklenenUrller.map((url) => ({
              review_id: yeniYorum.id,
              business_id: businessId,
              url,
              created_by: session.user.id,
            })),
          );
        }
      }

      setBasarili(true);
      setYildiz(0);
      setMetin('');
      setKriterler({ taste: 0, service: 0, price: 0, cleanliness: 0, atmosphere: 0 });
      setFotograflar([]);
      router.refresh();
    } catch (e: any) {
      setHata(e?.message ?? 'Bir hata oluştu, lütfen tekrar deneyin.');
    } finally {
      setGonderiliyor(false);
    }
  }, [yildiz, metin, kriterler, businessId, fotograflar, router]);

  if (basarili) {
    return (
      <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
        <div className="flex flex-col items-center gap-3 py-4 text-center">
          <span className="text-3xl">🎉</span>
          <p className="text-sm font-black text-success">Yorumun paylaşıldı!</p>
          <p className="text-xs text-muted">Geri bildiriminiz için teşekkürler.</p>
          <button
            type="button"
            onClick={() => setBasarili(false)}
            className="mt-1 text-xs font-extrabold text-primary hover:underline"
          >
            Yeni yorum yaz
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
      <h3 className="mb-0.5 font-black text-textStrong">Yorum Yap</h3>
      <p className="mb-4 text-xs text-muted">Deneyimini paylaş, başkalarına yardımcı ol!</p>

      <YildizSecici value={yildiz} onChange={setYildiz} />

      <textarea
        value={metin}
        onChange={(e) => setMetin(e.target.value)}
        placeholder="Deneyiminizi yazın..."
        maxLength={500}
        rows={4}
        className="mt-4 w-full resize-none rounded-[14px] border border-border bg-bg px-3 py-2.5 text-sm text-textStrong placeholder-muted focus:border-primary/40 focus:outline-hidden focus:ring-2 focus:ring-primary/10"
      />
      <p className="mt-1 text-right text-[11px] text-muted">{metin.length}/500</p>

      {/* Alt kriterler */}
      <div className="mt-4 rounded-[14px] border border-border bg-bg p-3">
        <p className="mb-3 text-[11px] font-black uppercase tracking-wide text-muted">Detaylı Puanlama (isteğe bağlı)</p>
        <div className="grid gap-2.5">
          {KRITERLER.map(({ key, label }) => (
            <MiniKriterSecici
              key={key}
              label={label}
              value={kriterler[key]}
              onChange={(v) => setKriterler((prev) => ({ ...prev, [key]: v }))}
            />
          ))}
        </div>
      </div>

      {/* Fotoğraf ekleme */}
      <input
        ref={dosyaInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple
        onChange={(e) => { fotografSec(e.target.files); e.target.value = ''; }}
        className="sr-only"
      />
      <button
        type="button"
        onClick={() => dosyaInputRef.current?.click()}
        disabled={fotograflar.length >= MAKS_FOTOGRAF}
        className="mt-3 flex w-full items-center gap-2 rounded-[14px] border border-dashed border-border bg-bg px-4 py-2.5 text-xs font-extrabold text-muted transition-colors hover:border-primary/30 hover:text-primary disabled:cursor-not-allowed disabled:opacity-60"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        Fotoğraf Ekle
        <span className="ml-auto text-[10px] font-bold text-muted">{fotograflar.length}/{MAKS_FOTOGRAF}</span>
      </button>

      {onizlemeler.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-2">
          {onizlemeler.map((url, i) => (
            <div key={url} className="relative h-16 w-16 overflow-hidden rounded-xl border border-border">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={url} alt="" className="h-full w-full object-cover" />
              <button
                type="button"
                onClick={() => fotografKaldir(i)}
                aria-label="Fotoğrafı kaldır"
                className="absolute right-0.5 top-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-black/60 text-white"
              >
                <svg viewBox="0 0 24 24" className="h-3 w-3 fill-none stroke-current stroke-[3]" aria-hidden="true">
                  <path strokeLinecap="round" d="M6 6l12 12M18 6L6 18" />
                </svg>
              </button>
            </div>
          ))}
        </div>
      )}

      {hata && <p className="mt-2 text-xs font-extrabold text-danger">{hata}</p>}

      <button
        type="button"
        onClick={gonder}
        disabled={gonderiliyor}
        className="mt-4 flex min-h-[44px] w-full items-center justify-center rounded-[14px] text-sm font-black text-white shadow-(--yd-shadow-primary) transition-all hover:-translate-y-px disabled:opacity-60"
        style={{ background: 'var(--yd-gradient-primary)' }}
      >
        {gonderiliyor ? 'Paylaşılıyor...' : 'Yorumu Paylaş'}
      </button>
    </div>
  );
}

// ── Kampanyalar tab content ────────────────────────────────────────────────────

function KampanyaKartiDetay({ k, onSec }: { k: KampanyaBilgi; onSec: (k: KampanyaBilgi) => void }) {
  const gunKaldi = gunKaldiHesapla(k.endsAt);
  const badge = kampanyaBadge(k.type, k.discountPercent);
  const renk = TUR_RENK[k.type];
  const gorselUrl = buildMenuImageUrl(k.imageUrl, { width: 640, quality: 78 });

  return (
    <button
      type="button"
      onClick={() => onSec(k)}
      className="w-full overflow-hidden rounded-[20px] border border-border bg-card text-left shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2"
    >
      {gorselUrl ? (
        <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={gorselUrl} alt={k.title} className="h-full w-full object-cover" loading="lazy" />
          <div className="absolute inset-x-0 bottom-0 h-12 bg-linear-to-t from-black/50 to-transparent" aria-hidden="true" />
        </div>
      ) : (
        <div className="h-1.5" style={{ background: renk }} />
      )}
      <div className="p-5">
        <div className="mb-3 flex items-start justify-between gap-3">
          <div className="flex flex-wrap items-center gap-1.5">
            {badge.map((line, i) => (
              <span
                key={i}
                className={`rounded-full px-2.5 py-1 font-black text-white ${line.buyuk ? 'text-sm' : 'text-[10px] uppercase tracking-wide'}`}
                style={{ background: renk }}
              >
                {line.metin}
              </span>
            ))}
          </div>
          {gunKaldi != null && (
            <span className="flex shrink-0 items-center gap-1 rounded-full bg-danger/10 px-2.5 py-1 text-[11px] font-black text-danger">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
              </svg>
              {gunKaldi === 0 ? 'Son gün' : `${gunKaldi} gün kaldı`}
            </span>
          )}
        </div>
        <h3 className="mb-1.5 text-base font-black text-textStrong">{k.title}</h3>
        {k.description && (
          <p className="text-sm leading-6 text-muted line-clamp-2">{k.description}</p>
        )}
      </div>
    </button>
  );
}

function KampanyaBrosurPopup({ k, onClose }: { k: KampanyaBilgi; onClose: () => void }) {
  const gunKaldi = gunKaldiHesapla(k.endsAt);
  const badge = kampanyaBadge(k.type, k.discountPercent);
  const renk = TUR_RENK[k.type];
  const gorselUrl = buildMenuImageUrl(k.imageUrl, { width: 960, quality: 82 });

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-xs" onClick={onClose} />
      <div className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card shadow-2xl sm:rounded-2xl">
        <button
          type="button"
          onClick={onClose}
          aria-label="Kapat"
          className="absolute right-3 top-3 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-black/40 text-white backdrop-blur-sm transition hover:bg-black/60"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>

        {gorselUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={gorselUrl} alt={k.title} className="max-h-[420px] w-full object-cover" />
        )}

        <div className="p-6">
          <div className="mb-3 flex flex-wrap items-center gap-1.5">
            {badge.map((line, i) => (
              <span
                key={i}
                className={`rounded-full px-2.5 py-1 font-black text-white ${line.buyuk ? 'text-sm' : 'text-[10px] uppercase tracking-wide'}`}
                style={{ background: renk }}
              >
                {line.metin}
              </span>
            ))}
            {gunKaldi != null && (
              <span className="flex items-center gap-1 rounded-full bg-danger/10 px-2.5 py-1 text-[11px] font-black text-danger">
                {gunKaldi === 0 ? 'Son gün' : `${gunKaldi} gün kaldı`}
              </span>
            )}
          </div>
          <h2 className="mb-2 text-xl font-black text-textStrong">{k.title}</h2>
          {k.description && (
            <p className="text-sm leading-6 text-muted">{k.description}</p>
          )}
        </div>
      </div>
    </div>
  );
}

function KampanyalarIcerik({ kampanyalar }: { kampanyalar: KampanyaBilgi[] }) {
  const [acikKampanya, setAcikKampanya] = useState<KampanyaBilgi | null>(null);

  if (kampanyalar.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-[20px] border border-border bg-card py-16 text-center shadow-yd1">
        <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-cardAlt">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-muted" aria-hidden="true">
            <path d="M20.59 13.41 13.42 20.6a2 2 0 0 1-2.83 0L2.5 12.5V2h10.5l8.09 8.09a2 2 0 0 1 0 2.82z" />
            <circle cx="6.5" cy="6.5" r="1.5" />
          </svg>
        </div>
        <p className="text-sm font-extrabold text-textStrong">Şu an aktif kampanya yok</p>
        <p className="mt-1 text-xs text-muted">Bu işletme yeni bir kampanya oluşturduğunda burada göreceksin.</p>
      </div>
    );
  }

  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2">
        {kampanyalar.map((k) => (
          <KampanyaKartiDetay key={k.id} k={k} onSec={setAcikKampanya} />
        ))}
      </div>
      {acikKampanya && (
        <KampanyaBrosurPopup k={acikKampanya} onClose={() => setAcikKampanya(null)} />
      )}
    </>
  );
}

// ── Yorumlar tab content ──────────────────────────────────────────────────────

function YorumlarIcerik({
  businessId,
  businessSlug,
  businessAvgRating,
  yorumlarToplam,
  yildizDagitimi,
  altPuanOrt,
  oneriYuzdesi,
  oneriKisi,
  anahrarKelimeler,
  ilkYorumlar,
  businessLogoUrl,
  businessName,
}: {
  businessId: string;
  businessSlug: string;
  businessAvgRating: number | null;
  yorumlarToplam: number;
  yildizDagitimi: Record<string, number>;
  altPuanOrt: AltPuanOrt;
  oneriYuzdesi: number | null;
  oneriKisi: number | null;
  anahrarKelimeler: Array<{ kelime: string; sayi: number }>;
  ilkYorumlar: YorumDetay[];
  businessLogoUrl: string | null;
  businessName: string;
}) {
  const [yildizFiltre, setYildizFiltre] = useState<number | null>(null);
  const [siralama, setSiralama] = useState<'yeni' | 'iyi' | 'dogrulandi'>('yeni');
  const [sadeceFotograf, setSadeceFotograf] = useState(false);
  const [yorumlar, setYorumlar] = useState<YorumDetay[]>(ilkYorumlar);
  const [offset, setOffset] = useState(ilkYorumlar.length);
  const [daha, setDaha] = useState(ilkYorumlar.length === 15);
  const [yukleniyor, setYukleniyor] = useState(false);
  const [dogrulanmisIdler, setDogrulanmisIdler] = useState<string[] | null>(null);
  const [fotografliIdler, setFotografliIdler] = useState<string[] | null>(null);

  const fotograflariGetir = useCallback(async (reviewIds: string[]): Promise<Record<string, string[]>> => {
    if (reviewIds.length === 0) return {};
    const sb = createSupabaseBrowserClient();
    const { data } = await (sb as any)
      .from('review_photos')
      .select('review_id, url')
      .in('review_id', reviewIds)
      .order('created_at', { ascending: true });
    const map: Record<string, string[]> = {};
    for (const row of (data ?? []) as Array<{ review_id: string; url: string }>) {
      (map[row.review_id] ??= []).push(row.url);
    }
    return map;
  }, []);

  const getirYorumlar = useCallback(async (
    baslangicOffset: number,
    verifiedIds: string[] | null,
    fotoIds: string[] | null,
  ): Promise<{ data: YorumDetay[]; bitti: boolean }> => {
    if (siralama === 'dogrulandi' && (!verifiedIds || verifiedIds.length === 0)) {
      return { data: [], bitti: true };
    }
    if (sadeceFotograf && (!fotoIds || fotoIds.length === 0)) {
      return { data: [], bitti: true };
    }
    const sb = createSupabaseBrowserClient();
    let q = (sb as any)
      .from('reviews')
      .select('id, rating, overall_rating, content, title, created_at, helpful_count, taste_rating, service_speed_rating, atmosphere_rating, price_performance_rating, cleanliness_rating, owner_reply, user_id')
      .eq('business_id', businessId)
      .eq('status', 'approved')
      .range(baslangicOffset, baslangicOffset + 14);
    if (siralama === 'iyi') q = q.order('helpful_count', { ascending: false });
    else q = q.order('created_at', { ascending: false });
    if (yildizFiltre) q = q.eq('rating', yildizFiltre);
    if (siralama === 'dogrulandi' && verifiedIds) q = q.in('user_id', verifiedIds);
    if (sadeceFotograf && fotoIds) q = q.in('id', fotoIds);
    const { data: reviewsData } = await q;
    if (!reviewsData || reviewsData.length === 0) return { data: [], bitti: true };
    // Profilleri ve fotoğrafları ayrı çek
    const uids = [...new Set(reviewsData.map((r: any) => r.user_id).filter(Boolean))] as string[];
    let pMap: Record<string, { display_name: string; avatar_url: string | null }> = {};
    if (uids.length > 0) {
      const { data: profs } = await (sb as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', uids);
      for (const p of profs ?? []) pMap[p.user_id] = { display_name: p.display_name, avatar_url: p.avatar_url ?? null };
    }
    const photoMap = await fotograflariGetir(reviewsData.map((r: any) => r.id));
    const merged: YorumDetay[] = reviewsData.map((r: any) => ({
      ...r,
      user_profiles: r.user_id ? (pMap[r.user_id] ?? null) : null,
      photos: photoMap[r.id] ?? [],
    }));
    return { data: merged, bitti: reviewsData.length < 15 };
  }, [businessId, siralama, yildizFiltre, sadeceFotograf, fotograflariGetir]);

  const dahayukle = useCallback(async () => {
    setYukleniyor(true);
    try {
      const sonuc = await getirYorumlar(offset, dogrulanmisIdler, fotografliIdler);
      setYorumlar((prev) => [...prev, ...sonuc.data]);
      setOffset((prev) => prev + sonuc.data.length);
      setDaha(!sonuc.bitti);
    } finally {
      setYukleniyor(false);
    }
  }, [offset, dogrulanmisIdler, fotografliIdler, getirYorumlar]);

  // Sıralama, yıldız veya fotoğraf filtresi değiştiğinde listeyi baştan getir.
  const ilkMount = useRef(true);
  useEffect(() => {
    if (ilkMount.current) { ilkMount.current = false; return; }
    let iptal = false;
    (async () => {
      setYukleniyor(true);
      try {
        let verifiedIds = dogrulanmisIdler;
        if (siralama === 'dogrulandi' && verifiedIds === null) {
          const sb = createSupabaseBrowserClient();
          const { data } = await (sb as any).rpc('get_business_checkin_user_ids_v1', { p_business_id: businessId });
          verifiedIds = Array.isArray(data) ? data : [];
          if (iptal) return;
          setDogrulanmisIdler(verifiedIds);
        }
        let fotoIds = fotografliIdler;
        if (sadeceFotograf && fotoIds === null) {
          const sb = createSupabaseBrowserClient();
          const { data } = await (sb as any)
            .from('review_photos')
            .select('review_id')
            .eq('business_id', businessId);
          fotoIds = [...new Set(((data ?? []) as Array<{ review_id: string }>).map((r) => r.review_id))];
          if (iptal) return;
          setFotografliIdler(fotoIds);
        }
        const sonuc = await getirYorumlar(0, verifiedIds, fotoIds);
        if (iptal) return;
        setYorumlar(sonuc.data);
        setOffset(sonuc.data.length);
        setDaha(!sonuc.bitti);
      } finally {
        if (!iptal) setYukleniyor(false);
      }
    })();
    return () => { iptal = true; };
    // dogrulanmisIdler / fotografliIdler kasıtlı olarak dışarıda bırakıldı — bu efekt
    // tarafından yazılıyorlar, tekrar tetiklenmesi gereken bağımlılıklar değil.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [siralama, yildizFiltre, sadeceFotograf, businessId, getirYorumlar]);

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
      {/* Sol — liste */}
      <div className="min-w-0">
        {/* Rating özet */}
        <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
          <div className="flex gap-6">
            {/* Büyük puan */}
            <div className="flex flex-col items-center justify-center shrink-0">
              <span className="text-5xl font-black text-textStrong leading-none">
                {businessAvgRating?.toFixed(1) ?? '—'}
              </span>
              {businessAvgRating != null && (
                <YildizSatiri rating={Math.round(businessAvgRating)} size="md" />
              )}
              <span className="mt-1 text-xs font-extrabold text-muted">{yorumlarToplam.toLocaleString('tr-TR')} yorum</span>
            </div>

            {/* Dağılım */}
            <div className="flex-1 space-y-1.5">
              {[5, 4, 3, 2, 1].map((y) => (
                <DagitimCubugu
                  key={y}
                  yildiz={y}
                  sayi={yildizDagitimi[String(y)] ?? 0}
                  toplam={yorumlarToplam}
                />
              ))}
            </div>
          </div>

          {/* Öneri */}
          {oneriYuzdesi !== null && oneriKisi !== null && (
            <div className="mt-4 flex items-center gap-3 rounded-[14px] border border-border bg-bg px-4 py-3">
              <span className="text-lg">👥</span>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-black text-textStrong">
                  {oneriKisi.toLocaleString('tr-TR')} kişi öneriyor
                </p>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <span className="inline-flex items-center gap-1 rounded-full bg-success/10 px-2.5 py-1 text-xs font-black text-success">
                  Evet %{oneriYuzdesi}
                </span>
                <span className="inline-flex items-center gap-1 rounded-full bg-danger/10 px-2.5 py-1 text-xs font-black text-danger">
                  Hayır %{100 - oneriYuzdesi}
                </span>
              </div>
            </div>
          )}
        </div>

        {/* Filtre chips */}
        <div className="mt-4 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] scrollbar-none [&::-webkit-scrollbar]:hidden">
          <button
            type="button"
            onClick={() => setYildizFiltre(null)}
            className={`shrink-0 rounded-full border px-3 py-1.5 text-sm font-extrabold transition-all ${yildizFiltre === null ? 'border-primary/40 bg-primary/8 text-primary' : 'border-border bg-card text-textStrong hover:border-borderStrong'}`}
          >
            Tümü ({yorumlarToplam.toLocaleString('tr-TR')})
          </button>
          {[5, 4, 3, 2, 1].map((y) => {
            const sayi = yildizDagitimi[String(y)] ?? 0;
            if (sayi === 0) return null;
            return (
              <button
                key={y}
                type="button"
                onClick={() => setYildizFiltre(yildizFiltre === y ? null : y)}
                className={`shrink-0 flex items-center gap-1 rounded-full border px-3 py-1.5 text-sm font-extrabold transition-all ${yildizFiltre === y ? 'border-amber-300 bg-amber-50 text-amber-700' : 'border-border bg-card text-textStrong hover:border-borderStrong'}`}
              >
                <span className="text-amber-400">★</span> {y} ({sayi})
              </button>
            );
          })}
        </div>

        {/* Sıralama */}
        <div className="mt-3 flex items-center gap-2">
          {(['yeni', 'iyi', 'dogrulandi'] as const).map((s) => {
            const etiket = s === 'yeni' ? 'En Yeni' : s === 'iyi' ? 'En İyi' : 'Doğrulanmış';
            return (
              <button
                key={s}
                type="button"
                onClick={() => setSiralama(s)}
                className={`rounded-xl border px-3 py-1.5 text-xs font-extrabold transition-all ${siralama === s ? 'border-primary/40 bg-primary/8 text-primary' : 'border-border bg-card text-muted hover:text-textStrong'}`}
              >
                {etiket}
              </button>
            );
          })}
          <button
            type="button"
            onClick={() => setSadeceFotograf((v) => !v)}
            className={`rounded-xl border px-3 py-1.5 text-xs font-extrabold transition-all ${sadeceFotograf ? 'border-primary/40 bg-primary/8 text-primary' : 'border-border bg-card text-muted hover:text-textStrong'}`}
          >
            📷 Fotoğraflı
          </button>
          <a
            href="#yorum-yaz"
            className="ml-auto inline-flex h-8 items-center gap-1.5 rounded-xl border border-border bg-card px-3 text-xs font-extrabold text-muted transition-colors hover:border-primary/30 hover:text-primary"
          >
            <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current stroke-2" aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            Yorum Yaz
          </a>
        </div>

        {/* Yorum listesi */}
        <div className="mt-5 space-y-5">
          {yorumlar.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted">
              {yildizFiltre
                ? `${yildizFiltre} yıldızlı yorum bulunamadı.`
                : siralama === 'dogrulandi'
                  ? 'Doğrulanmış ziyaretçilerden yorum bulunamadı.'
                  : sadeceFotograf
                    ? 'Fotoğraflı yorum bulunamadı.'
                    : 'Henüz yorum yapılmamış.'}
            </p>
          ) : (
            yorumlar.map((yorum) => (
              <YorumKartiDetay key={yorum.id} yorum={yorum} businessId={businessId} />
            ))
          )}
        </div>

        {/* Daha fazla */}
        {daha && (
          <button
            type="button"
            onClick={dahayukle}
            disabled={yukleniyor}
            className="mt-6 flex w-full items-center justify-center gap-2 rounded-[14px] border border-border bg-card py-3 text-sm font-extrabold text-textStrong transition-all hover:border-primary/30 hover:text-primary disabled:opacity-60"
          >
            {yukleniyor ? 'Yükleniyor...' : (
              <>
                Daha Fazla Yorum Yükle
                <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" aria-hidden="true">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </>
            )}
          </button>
        )}
      </div>

      {/* Sağ — sidebar */}
      <div id="yorum-yaz" className="space-y-4 lg:sticky lg:top-20 lg:self-start">
        <YorumYapForm businessId={businessId} businessSlug={businessSlug} />

        {/* Puanlara Göre */}
        {(altPuanOrt.lezzet || altPuanOrt.servis || altPuanOrt.temizlik || altPuanOrt.fiyat || altPuanOrt.ortam) && (
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <h3 className="mb-4 font-black text-textStrong">Puanlara Göre Yorumlar</h3>
            <div className="space-y-3">
              <AltPuanCubugu label="Lezzet" value={altPuanOrt.lezzet} />
              <AltPuanCubugu label="Servis" value={altPuanOrt.servis} />
              <AltPuanCubugu label="Temizlik" value={altPuanOrt.temizlik} />
              <AltPuanCubugu label="Fiyat/Performans" value={altPuanOrt.fiyat} />
              <AltPuanCubugu label="Ortam" value={altPuanOrt.ortam} />
            </div>
          </div>
        )}

        {/* En Çok Bahsedilenler */}
        {anahrarKelimeler.length > 0 && (
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <h3 className="mb-4 font-black text-textStrong">En Çok Bahsedilenler</h3>
            <div className="flex flex-wrap gap-2">
              {anahrarKelimeler.map(({ kelime, sayi }) => (
                <span
                  key={kelime}
                  className="inline-flex items-center gap-1 rounded-full border border-border bg-bg px-3 py-1 text-xs font-extrabold text-textStrong"
                >
                  {kelime}
                  <span className="text-[10px] text-muted">({sayi})</span>
                </span>
              ))}
            </div>
          </div>
        )}

        {/* İşletme Yanıtları placeholder */}
        {businessLogoUrl && (
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <div className="mb-3 flex items-center justify-between">
              <h3 className="font-black text-textStrong">İşletme Yanıtları</h3>
              <Link href={`/isletme/${businessSlug}/yorumlar`} className="text-xs font-extrabold text-primary hover:underline">
                Tümünü Gör →
              </Link>
            </div>
            <div className="flex items-start gap-3">
              <div className="h-8 w-8 shrink-0 overflow-hidden rounded-full border border-border bg-cardAlt">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={businessLogoUrl} alt={businessName} className="h-full w-full object-cover" />
              </div>
              <div>
                <p className="text-xs font-black text-textStrong">{businessName}</p>
                <p className="text-[11px] text-muted">İşletme Sahibi</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Main component ────────────────────────────────────────────────────────────

export function IsletmeDetayTablari(props: IsletmeDetayTablariProps) {
  const {
    businessId, businessSlug, businessName, businessIsVerified, businessCategory,
    businessCity, businessDistrict, businessAddress, businessPhone, businessWebsite,
    businessLat, businessLng, businessHours, businessAvgRating, businessReviewCount,
    businessMenuHref, businessDescription, businessLogoUrl, priceSymbol, mapsHref,
    businessUrl, coverUrl, popularItems, menuItems, mealCards, galleryPhotos,
    yorumlar, yorumlarToplam, yildizDagitimi, altPuanOrt, oneriYuzdesi, oneriKisi,
    anahrarKelimeler, similar, checkinCount, todayHours, medianPriceCents,
    acceptsReservations, reservationPhone, reservationMinParty, reservationMaxParty, reservationNote,
    kampanyalar, initialTab,
  } = props;

  const [aktifTab, setAktifTab] = useState<DetayTab>(initialTab ?? 'genel');

  const SEKMELER: Array<{ id: DetayTab; label: string; count?: number }> = [
    { id: 'genel', label: 'Genel Bakış' },
    { id: 'menu', label: 'Menü' },
    { id: 'kampanyalar', label: 'Kampanyalar', count: kampanyalar.length > 0 ? kampanyalar.length : undefined },
    { id: 'yorumlar', label: 'Yorumlar', count: yorumlarToplam },
    { id: 'fotograflar', label: 'Fotoğraflar', count: galleryPhotos.length > 0 ? galleryPhotos.length + 1 : undefined },
    { id: 'bilgiler', label: 'Bilgiler' },
  ];

  return (
    <div>
      {/* ── Tab navigation ──────────────────────────────────────────── */}
      <nav
        className="flex overflow-x-auto border-b border-border [-ms-overflow-style:none] scrollbar-none [&::-webkit-scrollbar]:hidden"
        aria-label="Sayfa bölümleri"
      >
        {SEKMELER.map(({ id, label, count }) => (
          <button
            key={id}
            type="button"
            onClick={() => setAktifTab(id)}
            className={`shrink-0 border-b-2 pb-3 pr-6 text-sm font-extrabold transition-colors focus:outline-hidden ${
              aktifTab === id
                ? 'border-primary text-primary'
                : 'border-transparent text-muted hover:text-textStrong'
            }`}
          >
            {label}
            {count != null && count > 0 && (
              <span className="ml-1 text-muted font-bold">({count})</span>
            )}
          </button>
        ))}
      </nav>

      {/* ── Tab content ─────────────────────────────────────────────── */}
      <div className="mt-6">

        {/* Genel Bakış */}
        {aktifTab === 'genel' && (
          <div className="grid gap-8 lg:grid-cols-[1fr_320px]">
            <div className="min-w-0 space-y-8">
              {businessDescription && (
                <section>
                  <h2 className="mb-3 text-xl font-black text-textStrong">Hakkında</h2>
                  <p className="text-sm leading-7 text-muted">{businessDescription}</p>
                </section>
              )}

              {/* Popüler Menüler */}
              {popularItems.length > 0 && (
                <section>
                  <div className="mb-4 flex items-center justify-between">
                    <h2 className="text-xl font-black text-textStrong">Popüler Menüler</h2>
                    {businessMenuHref && (
                      <Link href={businessMenuHref} className="inline-flex items-center gap-1 text-sm font-black text-primary hover:underline">
                        Tümünü Gör <Icon name="chevronRight" size={14} />
                      </Link>
                    )}
                  </div>
                  <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                    {popularItems.map((item) => (
                      <MenuUrunKarti key={item.id} item={item} />
                    ))}
                  </div>
                </section>
              )}

              {/* Yemek kartları */}
              {mealCards.length > 0 && (
                <section>
                  <h2 className="mb-3 text-base font-black text-textStrong">Kabul edilen yemek kartları</h2>
                  <div className="flex flex-wrap gap-2">
                    {mealCards.map((mc) => (
                      <div key={mc.key} className="flex h-8 items-center gap-1.5 rounded-lg border border-border bg-bg px-2.5">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img src={`/meal-cards/meal_card_${mc.key}.png`} alt={mc.name} className="h-4 w-auto max-w-[60px] object-contain" onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none'; }} />
                        <span className="text-xs font-bold text-textStrong">{mc.name}</span>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Rezervasyon */}
              {acceptsReservations && (
                <section>
                  <div className="rounded-2xl border border-border bg-card p-5 shadow-xs">
                    <h2 className="mb-4 text-base font-black text-textStrong">Rezervasyon Yap</h2>
                    <ReservasyonFormu
                      businessId={businessId}
                      businessName={businessName}
                      minParty={reservationMinParty}
                      maxParty={reservationMaxParty}
                      reservationNote={reservationNote}
                      reservationPhone={reservationPhone}
                    />
                  </div>
                </section>
              )}

              {/* Benzer işletmeler */}
              {similar.length > 0 && (
                <section>
                  <h2 className="mb-4 text-xl font-black text-textStrong">Bunlar da ilginizi çekebilir</h2>
                  <div className="overflow-x-auto [-ms-overflow-style:none] scrollbar-none [&::-webkit-scrollbar]:hidden">
                    <div className="flex min-w-max gap-4 pb-2">
                      {similar.map((biz) => (
                        <Link key={biz.id} href={`/isletme/${biz.slug}`} className="group flex w-44 shrink-0 flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-1 hover:shadow-yd2">
                          <div className="relative h-28 bg-cardAlt">
                            {biz.coverUrl ? (
                              <Image src={buildMenuImageUrl(biz.coverUrl, { width: 220, quality: 72 }) ?? biz.coverUrl} alt={biz.name} fill sizes="176px" className="object-cover" />
                            ) : (
                              <div className="h-full w-full" style={{ background: 'linear-gradient(135deg,#5c1515,#7f1d1d)' }} />
                            )}
                          </div>
                          <div className="flex flex-1 flex-col gap-1 p-3">
                            <p className="truncate text-sm font-black text-textStrong group-hover:text-primary">{biz.name}</p>
                            <p className="truncate text-xs text-muted">{[biz.district, biz.city].filter(Boolean).join(', ')}</p>
                            {biz.avgRating != null && (
                              <div className="mt-auto flex items-center gap-1 pt-1">
                                <Icon name="star" size={12} className="stroke-warning fill-warning" />
                                <span className="text-xs font-extrabold text-textStrong">{biz.avgRating.toFixed(1)}</span>
                              </div>
                            )}
                          </div>
                        </Link>
                      ))}
                    </div>
                  </div>
                </section>
              )}
            </div>

            {/* Genel Bakış sidebar */}
            <SayfaSidebar
              businessId={businessId}
              businessSlug={businessSlug}
              businessName={businessName}
              businessPhone={businessPhone}
              businessWebsite={businessWebsite}
              businessAddress={businessAddress}
              businessDistrict={businessDistrict}
              businessCity={businessCity}
              businessLat={businessLat}
              businessLng={businessLng}
              businessHours={businessHours}
              mapsHref={mapsHref}
              businessIsVerified={businessIsVerified}
            />
          </div>
        )}

        {/* Menü */}
        {aktifTab === 'menu' && (
          <div className="grid gap-8 lg:grid-cols-[1fr_320px]">
            <div className="min-w-0">
              {popularItems.length > 0 ? (
                <>
                  <h2 className="mb-4 text-xl font-black text-textStrong">Popüler Ürünler</h2>
                  <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                    {popularItems.map((item) => (
                      <MenuUrunKarti key={item.id} item={item} />
                    ))}
                  </div>
                </>
              ) : menuItems.length > 0 ? (
                <>
                  <h2 className="mb-4 text-xl font-black text-textStrong">Menü</h2>
                  <div className="grid gap-2">
                    {menuItems.slice(0, 20).map((item) => (
                      <div key={item.id} className="flex items-center justify-between gap-3 rounded-[16px] border border-border bg-card px-4 py-3">
                        <span className="min-w-0 flex-1 truncate text-sm font-extrabold text-textStrong">{item.name}</span>
                        {item.price_cents && (
                          <span className="shrink-0 text-sm font-black text-primary">{formatFiyat(item.price_cents)}</span>
                        )}
                      </div>
                    ))}
                  </div>
                </>
              ) : (
                <p className="py-12 text-center text-sm text-muted">Menü bilgisi henüz eklenmedi.</p>
              )}
              {businessMenuHref && (
                <Link href={businessMenuHref} className="mt-6 flex min-h-[44px] w-full items-center justify-center gap-2 rounded-[14px] border border-primary/30 bg-primary/8 text-sm font-black text-primary transition-colors hover:bg-primary/12">
                  <Icon name="menu" size={16} />
                  Tam Menüyü Gör
                </Link>
              )}
            </div>
            <SayfaSidebar
              businessId={businessId}
              businessSlug={businessSlug}
              businessName={businessName}
              businessPhone={businessPhone}
              businessWebsite={businessWebsite}
              businessAddress={businessAddress}
              businessDistrict={businessDistrict}
              businessCity={businessCity}
              businessLat={businessLat}
              businessLng={businessLng}
              businessHours={businessHours}
              mapsHref={mapsHref}
              businessIsVerified={businessIsVerified}
            />
          </div>
        )}

        {/* Kampanyalar */}
        {aktifTab === 'kampanyalar' && (
          <KampanyalarIcerik kampanyalar={kampanyalar} />
        )}

        {/* Yorumlar */}
        {aktifTab === 'yorumlar' && (
          <YorumlarIcerik
            businessId={businessId}
            businessSlug={businessSlug}
            businessAvgRating={businessAvgRating}
            yorumlarToplam={yorumlarToplam}
            yildizDagitimi={yildizDagitimi}
            altPuanOrt={altPuanOrt}
            oneriYuzdesi={oneriYuzdesi}
            oneriKisi={oneriKisi}
            anahrarKelimeler={anahrarKelimeler}
            ilkYorumlar={yorumlar}
            businessLogoUrl={businessLogoUrl}
            businessName={businessName}
          />
        )}

        {/* Fotoğraflar */}
        {aktifTab === 'fotograflar' && (
          <div>
            <h2 className="mb-4 text-xl font-black text-textStrong">Fotoğraflar</h2>
            {(() => {
              const allPhotos: GaleriPhoto[] = [
                ...(coverUrl ? [{ url: coverUrl, name: businessName }] : []),
                ...galleryPhotos,
              ];
              if (allPhotos.length === 0) return (
                <p className="py-12 text-center text-sm text-muted">Henüz fotoğraf eklenmemiş.</p>
              );
              return (
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-4">
                  {allPhotos.map((photo, idx) => (
                    <FotoGalerisiTetik key={idx} photos={allPhotos} index={idx}>
                      <div className="relative aspect-square overflow-hidden rounded-[16px] bg-cardAlt">
                        <Image
                          src={buildMenuImageUrl(photo.url, { width: 300, quality: 78 }) ?? photo.url}
                          alt={photo.name}
                          fill
                          sizes="200px"
                          className="object-cover transition-transform duration-300 group-hover:scale-105"
                        />
                      </div>
                    </FotoGalerisiTetik>
                  ))}
                </div>
              );
            })()}
          </div>
        )}

        {/* Bilgiler */}
        {aktifTab === 'bilgiler' && (
          <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
            <div className="min-w-0 space-y-4">
              {/* İletişim bilgileri */}
              <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
                <h2 className="mb-4 text-base font-black text-textStrong">İletişim</h2>
                <div className="grid gap-4 text-sm sm:grid-cols-2">
                  {businessCategory && <BilgiSatiri label="Kategori" value={businessCategory} />}
                  {(businessDistrict || businessCity) && (
                    <BilgiSatiri label="İlçe / Şehir" value={[businessDistrict, businessCity].filter(Boolean).join(', ')} />
                  )}
                  {businessAddress && (
                    <BilgiSatiri label="Adres" value={businessAddress} className="sm:col-span-2" />
                  )}
                  {businessPhone && (
                    <BilgiSatiri label="Telefon">
                      <a href={`tel:${businessPhone}`} className="font-extrabold text-primary hover:underline">{businessPhone}</a>
                    </BilgiSatiri>
                  )}
                  {businessWebsite && (
                    <BilgiSatiri label="Web Sitesi">
                      <a href={businessWebsite} target="_blank" rel="noopener noreferrer" className="font-extrabold text-primary hover:underline truncate">Web Sitesi</a>
                    </BilgiSatiri>
                  )}
                  {businessLat && businessLng && mapsHref && (
                    <BilgiSatiri label="Konum">
                      <a href={mapsHref} target="_blank" rel="noopener noreferrer" className="font-extrabold text-primary hover:underline">
                        Google Maps&apos;te Aç
                      </a>
                    </BilgiSatiri>
                  )}
                  <BilgiSatiri label="Durum" value={businessIsVerified ? '✓ Doğrulanmış İşletme' : 'Topluluk tarafından eklendi'} />
                  {yorumlarToplam > 0 && (
                    <BilgiSatiri label="Toplam Yorum" value={`${yorumlarToplam.toLocaleString('tr-TR')} yorum`} />
                  )}
                </div>
              </div>

              {/* Çalışma saatleri — ana içerikte de göster */}
              {businessHours && businessHours.length > 0 && (
                <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
                  <h2 className="mb-4 text-base font-black text-textStrong">Çalışma Saatleri</h2>
                  <div className="grid gap-1">
                    {businessHours.map((row) => (
                      <div
                        key={row.label}
                        className={`flex justify-between rounded-xl px-3 py-2 text-sm ${
                          row.active ? 'bg-primary/8 font-black text-primary' : 'font-bold text-muted'
                        }`}
                      >
                        <span>{row.label}</span>
                        <span>{row.value}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Harita */}
              {businessLat && businessLng && (
                <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
                  <h2 className="mb-4 text-base font-black text-textStrong">Konum</h2>
                  <div className="h-56 overflow-hidden rounded-[16px]">
                    <OsmHarita lat={businessLat} lng={businessLng} name={businessName} className="h-full w-full" />
                  </div>
                  {mapsHref && (
                    <a
                      href={mapsHref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-3 flex min-h-[44px] w-full items-center justify-center gap-2 rounded-[14px] border border-danger/30 bg-danger/6 text-sm font-black text-danger transition-colors hover:bg-danger/10"
                    >
                      <Icon name="pin" size={16} />
                      Yol Tarifi Al
                    </a>
                  )}
                </div>
              )}
            </div>

            <SayfaSidebar
              businessId={businessId}
              businessSlug={businessSlug}
              businessName={businessName}
              businessPhone={businessPhone}
              businessWebsite={businessWebsite}
              businessAddress={businessAddress}
              businessDistrict={businessDistrict}
              businessCity={businessCity}
              businessLat={businessLat}
              businessLng={businessLng}
              businessHours={businessHours}
              mapsHref={mapsHref}
              businessIsVerified={businessIsVerified}
            />
          </div>
        )}
      </div>
    </div>
  );
}

// ── Shared sidebar (non-Yorumlar tabs) ───────────────────────────────────────

function SayfaSidebar({
  businessId, businessSlug, businessName, businessPhone, businessWebsite,
  businessAddress, businessDistrict, businessCity, businessLat, businessLng,
  businessHours, mapsHref, businessIsVerified,
}: {
  businessId: string;
  businessSlug: string;
  businessName: string;
  businessPhone: string | null;
  businessWebsite: string | null;
  businessAddress: string | null;
  businessDistrict: string | null;
  businessCity: string | null;
  businessLat: number | null;
  businessLng: number | null;
  businessHours: Array<{ label: string; value: string; active?: boolean }> | null;
  mapsHref: string | null;
  businessIsVerified: boolean | null;
}) {
  const hasContact = businessPhone || businessAddress || businessDistrict || businessWebsite;
  const todayRow = businessHours?.find((r) => r.active);

  return (
    <aside className="grid content-start gap-4 lg:sticky lg:top-20 lg:self-start">
      {/* İletişim */}
      {hasContact && (
        <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
          <h3 className="mb-4 font-black text-textStrong">İletişim</h3>
          <div className="grid gap-3">
            {businessPhone && (
              <div className="flex items-center gap-3">
                <Icon name="pin" size={16} className="shrink-0 text-muted" />
                <a href={`tel:${businessPhone}`} className="flex-1 text-sm font-extrabold text-textStrong hover:text-primary">{businessPhone}</a>
                <AdresKopyalaButonu address={businessPhone} />
              </div>
            )}
            {(businessAddress || businessDistrict) && (
              <div className="flex items-start gap-3">
                <Icon name="pin" size={16} className="mt-0.5 shrink-0 text-muted" />
                <p className="flex-1 text-sm font-bold text-muted">
                  {[businessAddress, businessDistrict, businessCity].filter(Boolean).join(', ')}
                </p>
                <AdresKopyalaButonu address={[businessAddress, businessDistrict, businessCity].filter(Boolean).join(', ')} />
              </div>
            )}
            {businessWebsite && (
              <a href={businessWebsite} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 rounded-[12px] border border-border px-3 py-2.5 text-sm font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                <Icon name="pin" size={16} className="text-muted" />
                Web Sitesi
                <Icon name="chevronRight" size={14} className="ml-auto text-muted" />
              </a>
            )}
          </div>
        </div>
      )}

      {/* Çalışma saatleri */}
      {businessHours && businessHours.length > 0 && (
        <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
          <div className="mb-4 flex items-center justify-between gap-2">
            <h3 className="font-black text-textStrong">Çalışma Saatleri</h3>
            {todayRow && (
              <span className={`rounded-full px-2.5 py-0.5 text-xs font-extrabold ${todayRow.value === 'Kapalı' ? 'bg-danger/10 text-danger' : 'bg-success/10 text-success'}`}>
                {todayRow.value === 'Kapalı' ? 'Bugün Kapalı' : 'Açık'}
              </span>
            )}
          </div>
          <div className="grid gap-2">
            {businessHours.map((row) => (
              <div key={row.label} className={row.active ? 'flex justify-between rounded-2xl bg-primary/8 px-3 py-2 text-sm font-black text-primary' : 'flex justify-between px-3 py-2 text-sm text-muted'}>
                <span>{row.label}</span>
                <span>{row.value}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Konum / Harita */}
      {businessLat && businessLng && (
        <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
          <h3 className="mb-4 font-black text-textStrong">Konum</h3>
          <div className="h-44 overflow-hidden rounded-[16px]">
            <OsmHarita lat={businessLat} lng={businessLng} name={businessName} className="h-full w-full" />
          </div>
          {mapsHref && (
            <a href={mapsHref} target="_blank" rel="noopener noreferrer" className="mt-3 flex min-h-[44px] w-full items-center justify-center gap-2 rounded-[14px] border border-danger/30 bg-danger/6 text-sm font-black text-danger transition-colors hover:bg-danger/10">
              <Icon name="pin" size={16} />
              Yol Tarifi Al
            </a>
          )}
        </div>
      )}

      {/* Sahiplenme CTA */}
      {!businessIsVerified && (
        <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
          <p className="mb-3 text-sm font-extrabold text-textStrong">Bu işletmenin sahibi misiniz?</p>
          <Link href={`/sahiplen/${businessSlug}`} className="flex min-h-[44px] w-full items-center justify-center rounded-[14px] border border-border bg-bg text-sm font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
            İşletmeyi Sahiplen
          </Link>
        </div>
      )}
    </aside>
  );
}

// ── Micro components ──────────────────────────────────────────────────────────

function MenuUrunKarti({ item }: { item: AcikMenuUrunKarti }) {
  return (
    <div className="overflow-hidden rounded-[16px] border border-border bg-card shadow-yd1">
      {item.imageUrl && (
        <div className="relative h-28 overflow-hidden bg-cardAlt">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={item.imageUrl} alt={item.name} className="h-full w-full object-cover" loading="lazy" />
        </div>
      )}
      <div className="p-3">
        <p className="truncate text-sm font-black text-textStrong">{item.name}</p>
        {item.description && <p className="mt-0.5 line-clamp-2 text-xs text-muted">{item.description}</p>}
        <div className="mt-2 flex items-center justify-between">
          <span className="text-sm font-black text-primary">{formatFiyat(item.priceCents) ?? '—'}</span>
        </div>
      </div>
    </div>
  );
}

function BilgiSatiri({ label, value, className, children }: { label: string; value?: string; className?: string; children?: React.ReactNode }) {
  return (
    <div className={`flex flex-col gap-0.5 ${className ?? ''}`}>
      <span className="text-xs font-extrabold uppercase tracking-wide text-muted">{label}</span>
      {children ?? <span className="text-sm font-extrabold text-textStrong">{value}</span>}
    </div>
  );
}
