import Image from 'next/image';
import Link from 'next/link';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { Badge, ButtonLink, Card, SectionHeader } from '@/src/ui/acik/ortak';
import { FavoriteButton, ReportBusinessButton, ShareButton } from '@/src/ui/acik/eylem-istemcisi';
import { Icon } from '@/src/ui/acik/simgeler';
import type { AcikIsletmeKarti } from '@/src/ui/acik/tipler';
import { AcikKapaliRozeti, AdresKopyalaButonu } from '@/src/ui/acik/isletme-istemci';

export type AcikIsletmeDetayi = AcikIsletmeKarti & {
  phone?: string | null;
  website?: string | null;
  lat?: number | null;
  lng?: number | null;
  menuHref?: string | null;
  hours?: Array<{ label: string; value: string; active?: boolean }>;
};

export function IsletmeBasligi({ business }: { business: AcikIsletmeDetayi }) {
  const cover = buildMenuImageUrl(business.coverUrl, { width: 1400, quality: 82 });
  const logo = buildMenuImageUrl(business.logoUrl, { width: 180, quality: 82 });
  return (
    <section className="relative overflow-hidden bg-textStrong">
      <div className="absolute inset-0">
        {cover ? (
          <Image src={cover} alt={business.name} fill priority sizes="100vw" className="object-cover" />
        ) : (
          <div className="h-full w-full" style={{ background: 'linear-gradient(135deg, #5c1515 0%, #7f1d1d 48%, #dc2626 100%)' }} />
        )}
        <div className="absolute inset-0 bg-gradient-to-b from-black/20 via-black/35 to-black/75" />
      </div>
      <div className="relative mx-auto max-w-6xl px-4 pb-8 pt-20 sm:px-6 lg:px-8">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end">
          <div className="flex h-24 w-24 shrink-0 items-center justify-center overflow-hidden rounded-[24px] border border-white/30 bg-white/15 text-4xl font-[900] text-white shadow-yd3 backdrop-blur">
            {logo ? <Image src={logo} alt={`${business.name} logo`} width={96} height={96} className="h-full w-full object-cover" /> : business.name.charAt(0)}
          </div>
          <div className="min-w-0 flex-1">
            <div className="mb-3 flex flex-wrap gap-2">
              {business.isVerified ? <Badge tone="success"><Icon name="check" size={13} /> Doğrulanmış</Badge> : null}
              {business.isOpenNow != null ? <IsletmeDurumRozeti open={business.isOpenNow} /> : null}
              {business.category ? <Badge>{business.category}</Badge> : null}
            </div>
            <h1 className="max-w-4xl text-3xl font-[900] leading-tight text-white sm:text-5xl">{business.name}</h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-white/78 sm:text-base">
              {[business.district, business.city, business.address].filter(Boolean).join(' · ') || business.description || 'Yeedoy public işletme sayfası'}
            </p>
          </div>
          <div className="flex flex-wrap gap-2 sm:justify-end">
            <FavoriteButton className="bg-white/95" />
            <ShareButton title={business.name} className="bg-white/95" />
          </div>
        </div>
      </div>
    </section>
  );
}

export function IsletmeBilgiPaneli({ business }: { business: AcikIsletmeDetayi }) {
  return (
    <Card className="p-5">
      <div className="grid gap-4 sm:grid-cols-3">
        <PuanOzet avgRating={business.avgRating} reviewCount={business.reviewCount} />
        <div>
          <p className="text-xs font-[900] uppercase text-muted">Konum</p>
          <p className="mt-1 text-sm font-[900] text-textStrong">{[business.district, business.city].filter(Boolean).join(', ') || 'Konum bilgisi bekleniyor'}</p>
        </div>
        <div>
          <p className="text-xs font-[900] uppercase text-muted">Fiyat şeffaflığı</p>
          <p className="mt-1 text-sm font-[900] text-textStrong">{business.recentPriceVerifiedCount ? `${business.recentPriceVerifiedCount} doğrulama` : 'Menü fiyatları listelenir'}</p>
        </div>
      </div>
      <div className="mt-5 flex flex-wrap gap-2">
        {business.menuHref ? <ButtonLink href={business.menuHref} className="min-h-11"><Icon name="menu" size={16} /> Menüyü Gör</ButtonLink> : null}
        <ButtonLink href={`/isletme/${business.slug}/yorumlar`} variant="secondary" className="min-h-11">Yorumlar</ButtonLink>
        <ReportBusinessButton businessId={business.id} businessName={business.name} />
      </div>
    </Card>
  );
}

export function IsletmeDurumRozeti({ open }: { open: boolean }) {
  return <Badge tone={open ? 'success' : 'neutral'}><Icon name="clock" size={13} /> {open ? 'Şu an açık' : 'Şu an kapalı'}</Badge>;
}

export function DogrulanmisRozeti() {
  return <Badge tone="success"><Icon name="check" size={13} /> Onaylı işletme</Badge>;
}

export function PuanOzet({ avgRating, reviewCount }: { avgRating?: number | null; reviewCount?: number | null }) {
  return (
    <div>
      <p className="text-xs font-[900] uppercase text-muted">Puan</p>
      <p className="mt-1 inline-flex items-center gap-1 text-sm font-[900] text-textStrong">
        <Icon name="star" size={15} className="text-warning" />
        {avgRating ? avgRating.toFixed(1) : 'Yeni'}
        {reviewCount ? <span className="font-[700] text-muted">({reviewCount})</span> : null}
      </p>
    </div>
  );
}

export function IsletmeSaatleriBolumu({ hours }: { hours?: AcikIsletmeDetayi['hours'] }) {
  if (!hours || hours.length === 0) return null;
  const todayRow = hours.find((r) => r.active);
  return (
    <Card className="p-5">
      <div className="mb-4 flex items-center justify-between gap-2">
        <SectionHeader title="Çalışma saatleri" />
        <AcikKapaliRozeti todayValue={todayRow?.value} />
      </div>
      <div className="grid gap-2">
        {hours.map((row) => (
          <div key={row.label} className={row.active ? 'flex justify-between rounded-2xl bg-[var(--yd-color-primary-soft)] px-3 py-2 text-sm font-[900] text-primary' : 'flex justify-between px-3 py-2 text-sm text-muted'}>
            <span>{row.label}</span>
            <span>{row.value}</span>
          </div>
        ))}
      </div>
    </Card>
  );
}

export function IsletmeKonumBolumu({ business }: { business: AcikIsletmeDetayi }) {
  const mapsHref = business.lat && business.lng
    ? `https://maps.google.com/?q=${business.lat},${business.lng}`
    : business.address
      ? `https://maps.google.com/?q=${encodeURIComponent(`${business.address} ${business.city ?? ''}`)}`
      : null;
  return (
    <Card className="p-5">
      <SectionHeader title="Konum ve güven" className="mb-4" />
      <div className="space-y-3 text-sm">
        <div className="flex items-start justify-between gap-2">
          <p className="leading-6 text-textStrong">{business.address || [business.district, business.city].filter(Boolean).join(', ') || 'Adres bilgisi henüz eklenmedi.'}</p>
          {(business.address || business.district) && (
            <AdresKopyalaButonu address={business.address || [business.district, business.city].filter(Boolean).join(', ')} />
          )}
        </div>
        <div className="flex flex-wrap gap-2">
          {business.isVerified ? <DogrulanmisRozeti /> : <Badge>Topluluk doğrulaması bekleniyor</Badge>}
          {business.phone ? <Badge>Telefon var</Badge> : null}
        </div>
        {mapsHref ? (
          <a href={mapsHref} target="_blank" rel="noopener noreferrer" className="inline-flex min-h-11 items-center gap-2 rounded-2xl border border-border px-4 font-[900] text-textStrong hover:border-primary/30">
            <Icon name="pin" size={16} /> Haritada aç
          </a>
        ) : null}
      </div>
    </Card>
  );
}

export function SahiplenmeCagri({ businessSlug }: { businessSlug?: string }) {
  const href = businessSlug ? `/sahiplen?business=${encodeURIComponent(businessSlug)}` : '/sahiplen';
  return (
    <Card className="bg-cardAlt p-5">
      <p className="font-[900] text-textStrong">Bu işletmenin sahibi misin?</p>
      <p className="mt-2 text-sm leading-6 text-muted">Menü, marka ve QR yönetimi panelde kalır. Public sayfadan sadece güvenli sahiplenme yönlendirmesi yapılır.</p>
      <ButtonLink href={href} className="mt-4 min-h-11">Sahiplenme başlat</ButtonLink>
    </Card>
  );
}

export type FiyatKarsilastirmaItem = {
  item_name?: string | null;
  our_price_cents?: number | null;
  city_avg_price_cents?: number | null;
  diff_pct?: number | null;
  currency?: string | null;
};

export function BolgeselFiyatEndeksi({ comparison }: { comparison: FiyatKarsilastirmaItem[] }) {
  if (!comparison || comparison.length === 0) return null;

  function formatFiyat(cents?: number | null, currency?: string | null) {
    if (!cents) return null;
    const symbol = currency === 'TRY' || !currency ? '₺' : currency;
    return `${symbol}${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
  }

  function formatDiff(pct?: number | null) {
    if (pct == null) return null;
    const abs = Math.abs(Math.round(pct * 100));
    if (pct < 0) return { label: `Bölge ortalamasından %${abs} daha ucuz`, tone: 'cheaper' as const };
    if (pct > 0) return { label: `Bölge ortalamasından %${abs} daha pahalı`, tone: 'expensive' as const };
    return { label: 'Bölge ortalamasıyla aynı', tone: 'neutral' as const };
  }

  return (
    <Card className="p-5">
      <SectionHeader title="Fiyat Karşılaştırması" className="mb-4" />
      <div className="grid gap-3">
        {comparison.map((item, index) => {
          const diff = formatDiff(item.diff_pct);
          const ourPrice = formatFiyat(item.our_price_cents, item.currency);
          const avgPrice = formatFiyat(item.city_avg_price_cents, item.currency);
          return (
            <div key={index} className="rounded-2xl border border-border px-4 py-3">
              <p className="truncate text-sm font-[900] text-textStrong">{item.item_name ?? 'Ürün'}</p>
              <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
                <div className="text-xs text-muted">
                  {ourPrice ? <span className="mr-2 font-[900] text-textStrong">{ourPrice}</span> : null}
                  {avgPrice ? <span>Ort. {avgPrice}</span> : null}
                </div>
                {diff ? (
                  <span
                    className={
                      diff.tone === 'cheaper'
                        ? 'text-xs font-[900] text-success'
                        : diff.tone === 'expensive'
                          ? 'text-xs font-[900] text-danger'
                          : 'text-xs font-[900] text-muted'
                    }
                  >
                    {diff.label}
                  </span>
                ) : null}
              </div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}

// ─── Fiyat Geçmişi Sparkline ────────────────────────────────────────────────

export type FiyatGecmisiItem = {
  ay?: string | null;
  median_price_cents?: number | null;
  item_count?: number | null;
};

export function FiyatGecmisiSparkline({ history }: { history: FiyatGecmisiItem[] }) {
  if (!history || history.length < 2) return null;

  const values = history.map((h) => h.median_price_cents ?? 0).filter(Boolean);
  if (values.length < 2) return null;

  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;
  const W = 200;
  const H = 48;
  const step = W / (values.length - 1);

  const points = values
    .map((v, i) => `${i * step},${H - ((v - min) / range) * (H - 6) - 3}`)
    .join(' ');

  const lastVal = values[values.length - 1];
  const firstVal = values[0];
  const diff = lastVal - firstVal;
  const pct = firstVal > 0 ? Math.round((diff / firstVal) * 100) : 0;
  const trend = diff > 0 ? 'up' : diff < 0 ? 'down' : 'flat';

  function fmtFiyat(cents: number) {
    return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
  }

  return (
    <Card className="p-5">
      <SectionHeader title="Fiyat Geçmişi" className="mb-4" />
      <div className="flex items-end gap-4">
        <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} className="shrink-0" aria-hidden="true">
          <polyline
            fill="none"
            stroke="var(--yd-color-primary)"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            points={points}
          />
          {/* Last point dot */}
          {values.length > 0 && (
            <circle
              cx={(values.length - 1) * step}
              cy={H - ((lastVal - min) / range) * (H - 6) - 3}
              r="3.5"
              fill="var(--yd-color-primary)"
            />
          )}
        </svg>
        <div className="min-w-0 flex-1">
          <p className="text-xl font-[900] text-textStrong">{fmtFiyat(lastVal)}</p>
          <p className="text-xs text-muted">Güncel medyan fiyat</p>
          {pct !== 0 && (
            <p className={`mt-1 text-xs font-[900] ${trend === 'up' ? 'text-danger' : 'text-success'}`}>
              {trend === 'up' ? '↑' : '↓'} %{Math.abs(pct)} ({history.length} ay)
            </p>
          )}
        </div>
      </div>
      <div className="mt-3 flex items-center justify-between text-[11px] text-muted">
        <span>{history[0]?.ay ?? ''}</span>
        <span>{history[history.length - 1]?.ay ?? ''}</span>
      </div>
    </Card>
  );
}

export function ReportBusinessButtonSlot({ businessId, businessName }: { businessId: string; businessName: string }) {
  return <ReportBusinessButton businessId={businessId} businessName={businessName} />;
}

export function KalabalikGostergesi({ count }: { count: number }) {
  const busy = count >= 5;
  return (
    <div className="flex items-center gap-2 rounded-[20px] border border-border bg-card px-4 py-3 shadow-yd1">
      <Icon name="user" size={16} className={busy ? 'text-warning' : 'text-muted'} />
      {count === 0 ? (
        <span className="text-sm font-[900] text-muted">Şu an sessiz görünüyor</span>
      ) : (
        <span className={busy ? 'text-sm font-[900] text-warning' : 'text-sm font-[900] text-textStrong'}>
          {busy ? '🔥 ' : ''}Son 2 saatte {count} kişi burada
        </span>
      )}
    </div>
  );
}

export function YeniUrunlerBolumu({ newItems }: { newItems?: Array<{ id: string; name: string; price_cents?: number | null; currency?: string | null; is_available?: boolean | null }> }) {
  if (!newItems || newItems.length === 0) return null;
  function formatFiyat(cents?: number | null, currency?: string | null) {
    if (!cents) return null;
    const symbol = currency === 'TRY' || !currency ? '₺' : currency;
    return `${symbol}${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
  }
  return (
    <section className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
      <SectionHeader title="Yeni ürünler" className="mb-4" />
      <div className="grid gap-3 sm:grid-cols-2">
        {newItems.map((item) => (
          <div key={item.id} className="flex items-center justify-between gap-3 rounded-2xl border border-border px-4 py-3">
            <span className="min-w-0 flex-1 truncate text-sm font-[900] text-textStrong">{item.name}</span>
            <div className="flex shrink-0 items-center gap-2">
              {formatFiyat(item.price_cents, item.currency) ? (
                <span className="text-sm font-[900] text-primary">{formatFiyat(item.price_cents, item.currency)}</span>
              ) : null}
              <Badge tone={item.is_available ? 'success' : 'neutral'}>{item.is_available ? 'Mevcut' : 'Yok'}</Badge>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}


