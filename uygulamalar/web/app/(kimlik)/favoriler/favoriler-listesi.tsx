'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { Heart, Star, MapPin, ThumbsUp, Utensils } from 'lucide-react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

// ── Tipler ───────────────────────────────────────────────────────────────────

export type FavIsletme = {
  business_id: string;
  created_at: string;
  businesses: {
    id: string;
    name: string;
    slug: string | null;
    category: string | null;
    city: string | null;
    district: string | null;
    logo_url: string | null;
    cover_url: string | null;
    avg_rating?: number | null;
    reviews_count?: number | null;
    price_level?: string | null;
    is_verified: boolean;
  } | null;
};

// ── Yardımcılar ──────────────────────────────────────────────────────────────

const KATEGORI_RENK: Record<string, string> = {
  Kafe:      'bg-amber-100 text-amber-700',
  Restoran:  'bg-red-100 text-red-700',
  Tatlıcı:  'bg-violet-100 text-violet-700',
  'Fast Food': 'bg-orange-100 text-orange-700',
  Diğer:     'bg-slate-100 text-slate-600',
};

function tabKategori(cat: string | null): string {
  if (!cat) return 'Diğer';
  const l = cat.toLowerCase();
  if (l.includes('restoran') || l.includes('restaurant')) return 'Restoran';
  if (l.includes('kafe') || l.includes('cafe') || l.includes('kahve')) return 'Kafe';
  if (l.includes('tatlı') || l.includes('pasta') || l.includes('dessert')) return 'Tatlıcı';
  if (l.includes('fast') || l.includes('burger') || l.includes('döner') || l.includes('doner')) return 'Fast Food';
  return 'Diğer';
}

function fiyatSembolu(pl: string | null): string {
  if (!pl) return '';
  if (pl === 'budget') return '₺';
  if (pl === 'mid') return '₺₺';
  if (pl === 'premium') return '₺₺₺';
  if (pl === 'luxury') return '₺₺₺₺';
  return pl;
}

function formatZaman(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const gun = Math.floor(diff / 86_400_000);
  if (gun === 0) return 'Bugün';
  if (gun === 1) return '1 gün önce';
  if (gun < 7) return `${gun} gün önce`;
  if (gun < 30) return `${Math.floor(gun / 7)} hafta önce`;
  if (gun < 365) return `${Math.floor(gun / 30)} ay önce`;
  return `${Math.floor(gun / 365)} yıl önce`;
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

type Props = {
  favoriler: FavIsletme[];
  yorumSayisi: number;
  ziyaretSayisi: number;
  helpfulSayisi: number;
};

type SortKey = 'yeni' | 'puan' | 'isim';

export function FavorilerListesi({ favoriler, yorumSayisi, ziyaretSayisi, helpfulSayisi }: Props) {
  const [aktifKat, setAktifKat] = useState('Tümü');
  const [sort, setSort] = useState<SortKey>('yeni');
  const [kaldirildi, setKaldirildi] = useState<Set<string>>(new Set());

  // Kategori sayıları
  const katSayilari = useMemo(() => {
    const map: Record<string, number> = { Tümü: 0, Restoran: 0, Kafe: 0, Tatlıcı: 0, 'Fast Food': 0, Diğer: 0 };
    for (const f of favoriler) {
      if (!f.businesses || kaldirildi.has(f.business_id)) continue;
      map['Tümü']++;
      const tk = tabKategori(f.businesses.category);
      map[tk] = (map[tk] ?? 0) + 1;
    }
    return map;
  }, [favoriler, kaldirildi]);

  // Filtrelenmiş + sıralanmış liste
  const liste = useMemo(() => {
    let arr = favoriler.filter((f) => f.businesses && !kaldirildi.has(f.business_id));
    if (aktifKat !== 'Tümü') arr = arr.filter((f) => tabKategori(f.businesses!.category) === aktifKat);
    if (sort === 'puan') arr = [...arr].sort((a, b) => (b.businesses!.avg_rating ?? 0) - (a.businesses!.avg_rating ?? 0));
    if (sort === 'isim') arr = [...arr].sort((a, b) => (a.businesses!.name ?? '').localeCompare(b.businesses!.name ?? '', 'tr'));
    return arr;
  }, [favoriler, aktifKat, sort, kaldirildi]);

  async function favoriKaldir(businessId: string) {
    setKaldirildi((prev) => new Set([...prev, businessId]));
    try {
      const sb = createSupabaseBrowserClient();
      const { data: { session } } = await sb.auth.getSession();
      if (!session) return;
      await (sb as any).from('favorites').delete()
        .eq('user_id', session.user.id)
        .eq('business_id', businessId);
    } catch {
      setKaldirildi((prev) => { const next = new Set(prev); next.delete(businessId); return next; });
    }
  }

  const toplam = favoriler.filter((f) => !kaldirildi.has(f.business_id)).length;
  const TABS = ['Tümü', 'Restoran', 'Kafe', 'Tatlıcı', 'Fast Food', 'Diğer'];

  return (
    <div className="space-y-5">

      {/* Başlık + görünüm toggle */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-red-100">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="#ef4444" aria-hidden="true">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
              </svg>
            </div>
            <h1 className="text-2xl font-black text-textStrong">Favorilerim</h1>
          </div>
          <p className="mt-1 text-[13px] font-bold text-muted">Beğendiğin mekanları burada kolayca görüntüle.</p>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          {/* Liste / Harita toggle */}
          <div className="flex overflow-hidden rounded-xl border border-border bg-card shadow-yd1">
            <button type="button" className="flex h-9 items-center gap-1.5 px-4 text-[13px] font-black text-primary bg-primary/8 border-r border-border">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
              Liste
            </button>
            <Link href="/kesif/harita" className="flex h-9 items-center gap-1.5 px-4 text-[13px] font-extrabold text-textStrong hover:text-primary transition-colors">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/><line x1="9" y1="3" x2="9" y2="18"/><line x1="15" y1="6" x2="15" y2="21"/></svg>
              Harita
            </Link>
          </div>

          {/* Sıralama */}
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value as SortKey)}
            className="h-9 rounded-xl border border-border bg-card px-3 pr-7 text-[13px] font-extrabold text-textStrong shadow-yd1 focus:outline-hidden focus:ring-2 focus:ring-primary/30">
            <option value="yeni">En Yeni Eklenen</option>
            <option value="puan">En Yüksek Puan</option>
            <option value="isim">İsme Göre A-Z</option>
          </select>
        </div>
      </div>

      {/* İstatistik satırı */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 rounded-2xl border border-border bg-card p-5 shadow-yd1">
        {[
          { icon: Heart, color: 'bg-red-100',    value: toplam,         label: 'Favori Mekan' },
          { icon: Star, color: 'bg-amber-100',  value: yorumSayisi,    label: 'Değerlendirme' },
          { icon: MapPin, color: 'bg-green-100',  value: ziyaretSayisi,  label: 'Ziyaret Edildi' },
          { icon: ThumbsUp, color: 'bg-blue-100',   value: helpfulSayisi,  label: 'Yorum Beğenisi' },
        ].map(({ icon: StatIcon, color, value, label }) => (
          <div key={label} className="flex items-center gap-3">
            <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-full ${color}`}>
              <StatIcon className="h-5 w-5" aria-hidden="true" />
            </div>
            <div>
              <p className="text-2xl font-black text-textStrong tabular-nums leading-none">{value}</p>
              <p className="mt-0.5 text-[11px] font-bold text-muted">{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Kategori filtreleri */}
      <div className="flex flex-wrap gap-2">
        {TABS.map((tab) => {
          const count = katSayilari[tab] ?? 0;
          if (tab !== 'Tümü' && count === 0) return null;
          const aktif = aktifKat === tab;
          return (
            <button
              key={tab}
              type="button"
              onClick={() => setAktifKat(tab)}
              className={`flex h-10 items-center gap-1.5 rounded-xl px-4 text-[13px] font-extrabold transition-all ${
                aktif
                  ? 'bg-primary text-white shadow-xs'
                  : 'border border-border bg-card text-textStrong hover:border-primary/30 hover:text-primary'
              }`}>
              {tab === 'Tümü' && (
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
              )}
              {tab} ({count})
            </button>
          );
        })}
      </div>

      {/* Liste */}
      {liste.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border bg-card py-16 text-center">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-red-100 text-2xl">❤️</div>
          <p className="font-black text-textStrong">
            {aktifKat === 'Tümü' ? 'Henüz favori eklemediniz' : `${aktifKat} kategorisinde favori yok`}
          </p>
          <p className="text-[13px] font-bold text-muted">Menüleri keşfedip favori işletmelerinizi buraya ekleyin.</p>
          <Link href="/kesif"
            className="mt-2 flex h-10 items-center rounded-xl bg-primary px-6 text-[13px] font-black text-white shadow-xs transition hover:brightness-110">
            Keşfetmeye Başla →
          </Link>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {liste.map((fav) => (
            <FavoriKart key={fav.business_id} fav={fav} onRemove={() => favoriKaldir(fav.business_id)} />
          ))}
        </div>
      )}

      {/* Alt CTA */}
      {liste.length > 0 && (
        <div className="flex flex-col items-start gap-4 rounded-2xl border border-red-100 bg-red-50 p-5 sm:flex-row sm:items-center">
          <div className="flex items-center gap-3 flex-1">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-red-100 text-xl">❤️</div>
            <div>
              <p className="font-black text-red-900">Daha fazla mekan keşfet</p>
              <p className="mt-0.5 text-[13px] font-bold text-red-600">Beğenebileceğin yeni mekanları keşfetmeye devam et.</p>
            </div>
          </div>
          <Link href="/kesif"
            className="flex h-11 shrink-0 items-center gap-2 rounded-xl bg-primary px-6 text-[14px] font-black text-white shadow-xs transition hover:brightness-110">
            Keşfetmeye Git
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
          </Link>
        </div>
      )}
    </div>
  );
}

// ── Favori kart bileşeni ─────────────────────────────────────────────────────

function FavoriKart({ fav, onRemove }: { fav: FavIsletme; onRemove: () => void }) {
  const [removing, setRemoving] = useState(false);
  const biz = fav.businesses!;
  const img = biz.cover_url ?? biz.logo_url ?? null;
  const tabKat = tabKategori(biz.category);
  const renk = KATEGORI_RENK[tabKat] ?? KATEGORI_RENK['Diğer'];
  const fiyat = fiyatSembolu(biz.price_level ?? null);
  const href = biz.slug ? `/m/${biz.slug}` : '/kesif';

  async function handleRemove() {
    setRemoving(true);
    await onRemove();
  }

  return (
    <div className={`flex gap-4 rounded-2xl border border-border bg-card p-4 shadow-yd1 transition hover:shadow-yd2 ${removing ? 'opacity-50' : ''}`}>
      {/* Görsel */}
      <Link href={href} className="h-[100px] w-[100px] shrink-0 overflow-hidden rounded-xl bg-cardAlt">
        {img ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={img} alt={biz.name} className="h-full w-full object-cover transition-transform duration-300 hover:scale-105" />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-muted"><Utensils className="h-8 w-8" aria-hidden="true" /></div>
        )}
      </Link>

      {/* Bilgi */}
      <div className="min-w-0 flex-1 py-0.5">
        <div className="flex flex-wrap items-center gap-2">
          <Link href={href} className="text-[15px] font-black text-textStrong hover:text-primary transition-colors">
            {biz.name}
          </Link>
          {biz.category && (
            <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold ${renk}`}>
              {biz.category}
            </span>
          )}
          {biz.is_verified && (
            <svg width="14" height="14" viewBox="0 0 24 24" fill="#3b82f6" aria-label="Doğrulanmış">
              <path d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
            </svg>
          )}
        </div>

        {/* Konum */}
        <div className="mt-1.5 flex items-center gap-1 text-[12px] font-bold text-muted">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
          <span>{[biz.district, biz.city].filter(Boolean).join(', ') || '—'}</span>
        </div>

        {/* Puan + fiyat */}
        <div className="mt-1 flex items-center gap-2 text-[12px] font-bold text-muted">
          {biz.avg_rating != null && (
            <>
              <div className="flex items-center gap-1">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true">
                  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                </svg>
                <span className="font-black text-textStrong">{biz.avg_rating.toFixed(1)}</span>
                {biz.reviews_count != null && (
                  <span>({biz.reviews_count.toLocaleString('tr-TR')})</span>
                )}
              </div>
              {fiyat && <span>·</span>}
            </>
          )}
          {fiyat && <span className="font-extrabold text-textStrong">{fiyat}</span>}
        </div>

        {/* Eklenme tarihi */}
        <p className="mt-1.5 text-[11px] font-bold text-muted">
          {formatZaman(fav.created_at)} eklendi
        </p>
      </div>

      {/* Sağ: Bookmark + menü */}
      <div className="flex shrink-0 flex-col items-center gap-2 pt-0.5">
        <button
          type="button"
          onClick={handleRemove}
          disabled={removing}
          title="Favorilerden kaldır"
          aria-label="Favorilerden kaldır"
          className="flex h-9 w-9 items-center justify-center rounded-xl bg-red-50 text-red-500 transition hover:bg-red-100 disabled:opacity-50">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
          </svg>
        </button>
        <button
          type="button"
          title="Seçenekler"
          aria-label="Seçenekler"
          className="flex h-9 w-9 items-center justify-center rounded-xl border border-border text-muted transition hover:border-primary/30 hover:text-textStrong">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/>
          </svg>
        </button>
      </div>
    </div>
  );
}
