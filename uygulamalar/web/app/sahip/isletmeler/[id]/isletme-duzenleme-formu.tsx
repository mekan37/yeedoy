'use client';

import { useState, useTransition } from 'react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { LocationPickerMapClient } from '@/src/components/maps/LocationPickerMapClient';
import { updateBusiness } from './isletme-islemleri';

interface BusinessFields {
  id: string;
  name: string;
  category: string;
  description: string | null;
  phone: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  neighborhood: string | null;
  lat: number | null;
  lng: number | null;
  logo_url: string | null;
  cover_url: string | null;
  reservation_url: string | null;
  order_yemeksepeti_url: string | null;
  order_trendyolgo_url: string | null;
  order_getir_url: string | null;
}

interface Props {
  business: BusinessFields;
}

export function BusinessEditForm({ business }: Props) {
  const [isPending, startTransition] = useTransition();
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [logoUrl, setLogoUrl] = useState(business.logo_url ?? '');
  const [coverUrl, setCoverUrl] = useState(business.cover_url ?? '');
  const [lat, setLat] = useState(business.lat?.toString() ?? '');
  const [lng, setLng] = useState(business.lng?.toString() ?? '');

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    fd.set('logoUrl', logoUrl);
    fd.set('coverUrl', coverUrl);
    fd.set('lat', lat);
    fd.set('lng', lng);
    setError(null);
    setSaved(false);
    startTransition(async () => {
      const result = await updateBusiness(business.id, fd);
      if (result?.error) {
        setError(result.error);
      } else {
        setSaved(true);
        setTimeout(() => setSaved(false), 3000);
      }
    });
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <BrandingPanel
        businessId={business.id}
        businessName={business.name}
        logoUrl={logoUrl}
        coverUrl={coverUrl}
        onLogoChange={setLogoUrl}
        onCoverChange={setCoverUrl}
      />

      <div className="grid gap-4 md:grid-cols-2">
        <Field label="İşletme Adı" name="name" defaultValue={business.name} required />
        <Field label="Kategori" name="category" defaultValue={business.category} required />
      </div>
      <Field label="Açıklama" name="description" defaultValue={business.description ?? ''} multiline rows={4} />

      <div className="grid gap-4 md:grid-cols-3">
        <Field label="Telefon" name="phone" defaultValue={business.phone ?? ''} type="tel" />
        <Field label="Şehir" name="city" defaultValue={business.city ?? ''} />
        <Field label="İlçe" name="district" defaultValue={business.district ?? ''} />
      </div>
      <Field label="Mahalle" name="neighborhood" defaultValue={business.neighborhood ?? ''} />
      <Field label="Adres" name="address" defaultValue={business.address ?? ''} multiline rows={3} />

      <LocationPicker
        lat={lat}
        lng={lng}
        address={[business.address, business.district, business.city].filter(Boolean).join(', ')}
        onChange={(nextLat, nextLng) => {
          setLat(nextLat.toFixed(6));
          setLng(nextLng.toFixed(6));
        }}
        onManualChange={(nextLat, nextLng) => {
          setLat(nextLat);
          setLng(nextLng);
        }}
      />

      <div className="grid gap-4 md:grid-cols-2">
        <Field label="Rezervasyon Linki" name="reservationUrl" defaultValue={business.reservation_url ?? ''} type="url" placeholder="https://..." />
        <Field label="Yemeksepeti Linki" name="orderYemeksepetiUrl" defaultValue={business.order_yemeksepeti_url ?? ''} type="url" placeholder="https://..." />
        <Field label="Trendyol GO Linki" name="orderTrendyolgoUrl" defaultValue={business.order_trendyolgo_url ?? ''} type="url" placeholder="https://..." />
        <Field label="Getir Linki" name="orderGetirUrl" defaultValue={business.order_getir_url ?? ''} type="url" placeholder="https://..." />
      </div>

      <div className="sticky bottom-0 z-10 -mx-5 flex items-center gap-3 border-t border-border bg-card/95 px-5 py-4 backdrop-blur">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Kaydet
        </PanelActionButton>
        {saved && <p className="text-sm font-[700] text-green-600">Kaydedildi</p>}
        {error && <p className="text-sm font-[700] text-[color:var(--yd-color-danger)]">{error}</p>}
      </div>
    </form>
  );
}

function BrandingPanel({
  businessId,
  businessName,
  logoUrl,
  coverUrl,
  onLogoChange,
  onCoverChange,
}: {
  businessId: string;
  businessName: string;
  logoUrl: string;
  coverUrl: string;
  onLogoChange: (url: string) => void;
  onCoverChange: (url: string) => void;
}) {
  const coverPreview = buildMenuImageUrl(coverUrl, { width: 1200, quality: 82 });
  const logoPreview = buildMenuImageUrl(logoUrl, { width: 220, quality: 86 });

  return (
    <section className="overflow-hidden rounded-2xl border border-border bg-bg">
      <div
        className="relative min-h-[220px] bg-[linear-gradient(135deg,_#171717,_#404040)]"
        style={coverPreview ? { backgroundImage: `linear-gradient(90deg, rgba(0,0,0,.62), rgba(0,0,0,.18)), url("${coverPreview}")`, backgroundSize: 'cover', backgroundPosition: 'center' } : undefined}
      >
        <div className="absolute inset-x-0 bottom-0 flex items-end gap-4 p-5 text-white">
          <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-white/30 bg-white/15 text-3xl font-[900] shadow-yd2 backdrop-blur">
            {logoPreview ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={logoPreview} alt={businessName} className="h-full w-full object-cover" />
            ) : (
              businessName.charAt(0).toUpperCase()
            )}
          </div>
          <div className="min-w-0 pb-1">
            <p className="truncate text-2xl font-[900]">{businessName}</p>
            <p className="mt-1 text-sm font-[700] text-white/75">Logo ve kapak görseli QR menüde markanın ilk izlenimini belirler.</p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 p-5 md:grid-cols-2">
        <ImageControl
          businessId={businessId}
          type="logo"
          label="Logo"
          value={logoUrl}
          onChange={onLogoChange}
        />
        <ImageControl
          businessId={businessId}
          type="cover"
          label="Kapak Görseli"
          value={coverUrl}
          onChange={onCoverChange}
        />
      </div>
    </section>
  );
}

function ImageControl({
  businessId,
  type,
  label,
  value,
  onChange,
}: {
  businessId: string;
  type: 'logo' | 'cover';
  label: string;
  value: string;
  onChange: (value: string) => void;
}) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function upload(file: File | null) {
    if (!file) return;
    setUploading(true);
    setError(null);
    const body = new FormData();
    body.set('businessId', businessId);
    body.set('type', type);
    body.set('file', file);
    try {
      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body });
      const json = await response.json();
      if (!response.ok) throw new Error(json.error ?? 'Yükleme başarısız');
      onChange(json.data.url);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Yükleme başarısız');
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <label className="mb-2 block text-xs font-[800] uppercase tracking-wide text-muted">{label}</label>
      <input type="hidden" name={type === 'logo' ? 'logoUrl' : 'coverUrl'} value={value} />
      <div className="flex flex-col gap-3">
        <input
          value={value}
          onChange={(event) => onChange(event.target.value)}
          placeholder="https://..."
          className="min-h-[44px] w-full rounded-xl border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
        <label className="inline-flex min-h-[44px] cursor-pointer items-center justify-center rounded-xl border border-border bg-bg px-4 text-sm font-[800] text-textStrong transition-colors hover:border-primary/30">
          {uploading ? 'Yükleniyor...' : 'Bilgisayardan Seç'}
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            className="sr-only"
            onChange={(event) => void upload(event.target.files?.[0] ?? null)}
          />
        </label>
        {error && <p className="text-xs font-[700] text-[color:var(--yd-color-danger)]">{error}</p>}
      </div>
    </div>
  );
}

function LocationPicker({
  lat,
  lng,
  address,
  onChange,
  onManualChange,
}: {
  lat: string;
  lng: string;
  address: string;
  onChange: (lat: number, lng: number) => void;
  onManualChange: (lat: string, lng: string) => void;
}) {
  const parsedLat = Number.parseFloat(lat);
  const parsedLng = Number.parseFloat(lng);
  const hasPoint = Number.isFinite(parsedLat) && Number.isFinite(parsedLng);
  const [geoError, setGeoError] = useState<string | null>(null);

  const mapUrl = hasPoint
    ? `https://www.google.com/maps/search/?api=1&query=${parsedLat},${parsedLng}`
    : null;

  function useCurrentLocation() {
    setGeoError(null);
    if (!navigator.geolocation) {
      setGeoError('Tarayıcı konum seçimini desteklemiyor.');
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => {
        onChange(position.coords.latitude, position.coords.longitude);
      },
      () => setGeoError('Konum izni alınamadı. Haritadan nokta seçebilirsiniz.'),
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  return (
    <section className="rounded-2xl border border-border bg-bg p-4">
      <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs font-[800] uppercase tracking-wide text-muted">Harita Konumu</p>
          <p className="mt-1 text-sm text-textStrong">{address || 'Haritada işaretleyerek konumu belirleyin.'}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button type="button" onClick={useCurrentLocation} className="min-h-[40px] rounded-xl border border-border bg-card px-3 text-xs font-[800] text-textStrong hover:border-primary/30">
            Mevcut Konumum
          </button>
          {mapUrl && (
            <a href={mapUrl} target="_blank" rel="noopener noreferrer" className="inline-flex min-h-[40px] items-center rounded-xl border border-border bg-card px-3 text-xs font-[800] text-textStrong hover:border-primary/30">
              Haritada Aç
            </a>
          )}
        </div>
      </div>

      <LocationPickerMapClient
        initialLat={hasPoint ? parsedLat : undefined}
        initialLng={hasPoint ? parsedLng : undefined}
        onChange={onChange}
      />

      <div className="mt-3 grid gap-3 md:grid-cols-2">
        <Field
          label="Enlem"
          name="lat"
          value={lat}
          onValueChange={(value) => onManualChange(value, lng)}
          placeholder="41.008200"
        />
        <Field
          label="Boylam"
          name="lng"
          value={lng}
          onValueChange={(value) => onManualChange(lat, value)}
          placeholder="28.978400"
        />
      </div>
      {geoError && <p className="mt-2 text-xs font-[700] text-[color:var(--yd-color-danger)]">{geoError}</p>}
      <p className="mt-2 text-[11px] text-muted">Haritaya tıkla veya işaretçiyi sürükle. Bu koordinat QR menüde yol tarifi ve keşif haritası için kullanılır.</p>
    </section>
  );
}

function Field({
  label,
  name,
  defaultValue,
  value,
  onValueChange,
  required,
  multiline,
  rows = 3,
  type = 'text',
  placeholder,
}: {
  label: string;
  name: string;
  defaultValue?: string;
  value?: string;
  onValueChange?: (value: string) => void;
  required?: boolean;
  multiline?: boolean;
  rows?: number;
  type?: string;
  placeholder?: string;
}) {
  const base =
    'w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong ' +
    'placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 ' +
    'transition-shadow duration-150';

  return (
    <div>
      <label className="mb-1 block text-xs font-[700] uppercase tracking-wide text-muted">
        {label}
        {required && <span className="ml-1 text-[color:var(--yd-color-danger)]">*</span>}
      </label>
      {multiline ? (
        <textarea
          name={name}
          defaultValue={defaultValue}
          rows={rows}
          className={`${base} resize-none`}
          placeholder={placeholder}
        />
      ) : (
        <input
          name={name}
          type={type}
          value={value}
          onChange={onValueChange ? (event) => onValueChange(event.target.value) : undefined}
          defaultValue={value === undefined ? defaultValue : undefined}
          required={required}
          className={base}
          placeholder={placeholder}
        />
      )}
    </div>
  );
}
