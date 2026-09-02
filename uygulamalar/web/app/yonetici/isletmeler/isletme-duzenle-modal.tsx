'use client';

import { useEffect, useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import {
  isletmeDetayGetir,
  calismaSaatleriGetir,
  isletmeGuncelle,
  isletmeSaatleriGuncelle,
  type CalismaSaatiSatiri,
} from './isletme-duzenle-islemleri';
import { IsletmeBirlestirBolumu } from './isletme-birlestir-bolumu';

type Tab = 'genel' | 'saatler' | 'birlestir';

interface GenelForm {
  name: string;
  category: string;
  description: string;
  phone: string;
  email: string;
  websiteUrl: string;
  instagramUrl: string;
  facebookUrl: string;
  twitterUrl: string;
  address: string;
  city: string;
  district: string;
  lat: string;
  lng: string;
  logoUrl: string;
  coverUrl: string;
}

const BOS_FORM: GenelForm = {
  name: '', category: '', description: '', phone: '', email: '',
  websiteUrl: '', instagramUrl: '', facebookUrl: '', twitterUrl: '',
  address: '', city: '', district: '', lat: '', lng: '', logoUrl: '', coverUrl: '',
};

// day_of_week: 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi (business_weekly_hours konvansiyonu)
const GUN_SIRASI: Array<{ dow: number; label: string }> = [
  { dow: 1, label: 'Pazartesi' },
  { dow: 2, label: 'Salı' },
  { dow: 3, label: 'Çarşamba' },
  { dow: 4, label: 'Perşembe' },
  { dow: 5, label: 'Cuma' },
  { dow: 6, label: 'Cumartesi' },
  { dow: 0, label: 'Pazar' },
];

function bosSaatler(): CalismaSaatiSatiri[] {
  return GUN_SIRASI.map(({ dow }) => ({ day_of_week: dow, open_time: '09:00', close_time: '22:00', is_closed: false }));
}

export function IsletmeDuzenleModal({
  businessId,
  businessName,
  onClose,
  onSaved,
}: {
  businessId: string;
  businessName: string;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [tab, setTab] = useState<Tab>('genel');
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState<GenelForm>(BOS_FORM);
  const [saatler, setSaatler] = useState<CalismaSaatiSatiri[]>(bosSaatler());
  const [saatlerDegisti, setSaatlerDegisti] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    let iptal = false;
    setLoading(true);
    setError(null);
    setSaatlerDegisti(false);
    Promise.all([isletmeDetayGetir(businessId), calismaSaatleriGetir(businessId)]).then(([detay, saatVerisi]) => {
      if (iptal) return;
      if (detay) {
        setForm({
          name: detay.name ?? '',
          category: detay.category ?? '',
          description: detay.description ?? '',
          phone: detay.phone ?? '',
          email: detay.email ?? '',
          websiteUrl: detay.website_url ?? '',
          instagramUrl: detay.instagram_url ?? '',
          facebookUrl: detay.facebook_url ?? '',
          twitterUrl: detay.twitter_url ?? '',
          address: detay.address ?? '',
          city: detay.city ?? '',
          district: detay.district ?? '',
          lat: detay.lat != null ? String(detay.lat) : '',
          lng: detay.lng != null ? String(detay.lng) : '',
          logoUrl: detay.logo_url ?? '',
          coverUrl: detay.cover_url ?? '',
        });
      } else {
        setError('İşletme bilgileri yüklenemedi.');
      }
      // Her gün kendi getirilen değerini kullanır; yalnızca gerçekten eksik olan
      // günler için varsayılan değer uygulanır. Eskiden `saatVerisi.length === 7`
      // ile tüm-ya-da-hiç kontrolü yapılıyordu — bu, kısmi satırı olan (Google
      // katalog importundan kalma, 1-6 satır) işletmelerde fetch'i tamamen
      // görmezden gelip bosSaatler() varsayılanlarını state'te bırakıyordu; kaydet()
      // sonra bu uydurma saatleri gerçek (kısmi) verinin üzerine yazıyordu.
      const byDow = new Map(saatVerisi.map((s) => [s.day_of_week, s]));
      setSaatler(GUN_SIRASI.map(({ dow }) => byDow.get(dow) ?? { day_of_week: dow, open_time: '09:00', close_time: '22:00', is_closed: false }));
      setLoading(false);
    });
    return () => { iptal = true; };
  }, [businessId]);

  function alanGuncelle<K extends keyof GenelForm>(key: K, value: GenelForm[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function saatGuncelle(dow: number, patch: Partial<CalismaSaatiSatiri>) {
    setSaatlerDegisti(true);
    setSaatler((prev) => prev.map((s) => (s.day_of_week === dow ? { ...s, ...patch } : s)));
  }

  function kaydet() {
    setError(null);
    const lat = form.lat.trim() ? Number.parseFloat(form.lat) : null;
    const lng = form.lng.trim() ? Number.parseFloat(form.lng) : null;
    if (form.lat.trim() && !Number.isFinite(lat)) { setError('Enlem geçersiz.'); return; }
    if (form.lng.trim() && !Number.isFinite(lng)) { setError('Boylam geçersiz.'); return; }

    startTransition(async () => {
      const genelSonuc = await isletmeGuncelle({
        id: businessId,
        name: form.name,
        category: form.category,
        address: form.address,
        city: form.city,
        district: form.district,
        lat,
        lng,
        logoUrl: form.logoUrl,
        coverUrl: form.coverUrl,
        description: form.description,
        phone: form.phone,
        email: form.email,
        websiteUrl: form.websiteUrl,
        instagramUrl: form.instagramUrl,
        facebookUrl: form.facebookUrl,
        twitterUrl: form.twitterUrl,
      });
      if (!genelSonuc.ok) { setError(genelSonuc.error); return; }

      // Saatler sekmesi hiç açılmadıysa / hiçbir saat alanı değiştirilmediyse
      // admin_upsert_business_hours_v1 hiç çağrılmaz — salt "Genel Bilgiler"
      // düzenlemesi business_weekly_hours'a asla dokunmaz (fix #1'e ek savunma katmanı).
      if (saatlerDegisti) {
        const saatSonuc = await isletmeSaatleriGuncelle(businessId, saatler);
        if (!saatSonuc.ok) { setError(saatSonuc.error); return; }
      }

      onSaved();
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="flex max-h-[90vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl border border-border bg-card shadow-yd2"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b border-border px-5 py-4">
          <div className="min-w-0">
            <p className="text-xs font-extrabold uppercase tracking-wide text-muted">İşletme Düzenle</p>
            <p className="truncate text-lg font-black text-textStrong">{businessName}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-muted transition-colors hover:bg-black/6 hover:text-textStrong"
            title="Kapat"
          >
            <CloseIcon />
          </button>
        </div>

        <div className="flex gap-1 border-b border-border px-5 pt-3">
          <TabButton active={tab === 'genel'} onClick={() => setTab('genel')}>Genel Bilgiler</TabButton>
          <TabButton active={tab === 'saatler'} onClick={() => { setTab('saatler'); setSaatlerDegisti(true); }}>Çalışma Saatleri</TabButton>
          <TabButton active={tab === 'birlestir'} onClick={() => setTab('birlestir')}>Birleştir</TabButton>
        </div>

        <div className="flex-1 overflow-y-auto px-5 py-4">
          {loading ? (
            <p className="py-8 text-center text-sm font-bold text-muted">Yükleniyor...</p>
          ) : tab === 'genel' ? (
            <div className="flex flex-col gap-4">
              <div className="grid gap-4 md:grid-cols-2">
                <Field label="İşletme Adı" value={form.name} onChange={(v) => alanGuncelle('name', v)} required />
                <Field label="Kategori" value={form.category} onChange={(v) => alanGuncelle('category', v)} required />
              </div>
              <Field label="Açıklama" value={form.description} onChange={(v) => alanGuncelle('description', v)} multiline rows={3} />
              <div className="grid gap-4 md:grid-cols-2">
                <Field label="Telefon" value={form.phone} onChange={(v) => alanGuncelle('phone', v)} type="tel" />
                <Field label="E-posta" value={form.email} onChange={(v) => alanGuncelle('email', v)} type="email" />
              </div>
              <Field label="Web Sitesi" value={form.websiteUrl} onChange={(v) => alanGuncelle('websiteUrl', v)} type="url" placeholder="https://..." />
              <div className="grid gap-4 md:grid-cols-3">
                <Field label="Instagram" value={form.instagramUrl} onChange={(v) => alanGuncelle('instagramUrl', v)} type="url" placeholder="https://instagram.com/..." />
                <Field label="Facebook" value={form.facebookUrl} onChange={(v) => alanGuncelle('facebookUrl', v)} type="url" placeholder="https://facebook.com/..." />
                <Field label="Twitter / X" value={form.twitterUrl} onChange={(v) => alanGuncelle('twitterUrl', v)} type="url" placeholder="https://x.com/..." />
              </div>
              <Field label="Adres" value={form.address} onChange={(v) => alanGuncelle('address', v)} multiline rows={2} />
              <div className="grid gap-4 md:grid-cols-2">
                <Field label="Şehir" value={form.city} onChange={(v) => alanGuncelle('city', v)} />
                <Field label="İlçe" value={form.district} onChange={(v) => alanGuncelle('district', v)} />
              </div>
              <div className="grid gap-4 md:grid-cols-2">
                <Field label="Enlem" value={form.lat} onChange={(v) => alanGuncelle('lat', v)} placeholder="41.008200" />
                <Field label="Boylam" value={form.lng} onChange={(v) => alanGuncelle('lng', v)} placeholder="28.978400" />
              </div>
              <div className="grid gap-4 md:grid-cols-2">
                <Field label="Logo URL" value={form.logoUrl} onChange={(v) => alanGuncelle('logoUrl', v)} placeholder="https://..." />
                <Field label="Kapak Görseli URL" value={form.coverUrl} onChange={(v) => alanGuncelle('coverUrl', v)} placeholder="https://..." />
              </div>
            </div>
          ) : tab === 'saatler' ? (
            <div className="flex flex-col gap-2">
              {GUN_SIRASI.map(({ dow, label }) => {
                const satir = saatler.find((s) => s.day_of_week === dow);
                const kapali = satir?.is_closed ?? false;
                return (
                  <div key={dow} className="flex flex-wrap items-center gap-3 rounded-xl border border-border bg-bg px-3 py-2.5">
                    <span className="w-24 shrink-0 text-sm font-extrabold text-textStrong">{label}</span>
                    <input
                      type="time"
                      value={satir?.open_time ?? ''}
                      disabled={kapali}
                      onChange={(e) => saatGuncelle(dow, { open_time: e.target.value })}
                      className="min-h-9 rounded-lg border border-border bg-card px-2 text-sm text-textStrong disabled:opacity-40 focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                    />
                    <span className="text-xs font-bold text-muted">—</span>
                    <input
                      type="time"
                      value={satir?.close_time ?? ''}
                      disabled={kapali}
                      onChange={(e) => saatGuncelle(dow, { close_time: e.target.value })}
                      className="min-h-9 rounded-lg border border-border bg-card px-2 text-sm text-textStrong disabled:opacity-40 focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                    />
                    <label className="ml-auto flex items-center gap-1.5 text-xs font-bold text-muted">
                      <input
                        type="checkbox"
                        checked={kapali}
                        onChange={(e) => saatGuncelle(dow, { is_closed: e.target.checked })}
                        className="h-4 w-4 rounded border-border"
                      />
                      Kapalı
                    </label>
                  </div>
                );
              })}
            </div>
          ) : (
            <IsletmeBirlestirBolumu
              duplicateId={businessId}
              duplicateName={businessName}
              onMerged={onSaved}
            />
          )}
        </div>

        <div className="flex items-center gap-3 border-t border-border px-5 py-4">
          {tab !== 'birlestir' && (
            <PanelActionButton variant="primary" loading={isPending} disabled={loading} onClick={kaydet}>
              Kaydet
            </PanelActionButton>
          )}
          <PanelActionButton variant="secondary" onClick={onClose} disabled={isPending}>
            Vazgeç
          </PanelActionButton>
          {error && <p className="text-xs font-bold text-(--yd-color-danger)">{error}</p>}
        </div>
      </div>
    </div>
  );
}

function TabButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-t-lg px-4 py-2 text-sm font-extrabold transition-colors ${
        active ? 'border-b-2 border-primary text-primary' : 'text-muted hover:text-textStrong'
      }`}
    >
      {children}
    </button>
  );
}

function Field({
  label,
  value,
  onChange,
  required,
  multiline,
  rows = 3,
  type = 'text',
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  required?: boolean;
  multiline?: boolean;
  rows?: number;
  type?: string;
  placeholder?: string;
}) {
  const base =
    'w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong ' +
    'placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 ' +
    'transition-shadow duration-150';

  return (
    <div>
      <label className="mb-1 block text-xs font-bold uppercase tracking-wide text-muted">
        {label}
        {required && <span className="ml-1 text-(--yd-color-danger)">*</span>}
      </label>
      {multiline ? (
        <textarea value={value} onChange={(e) => onChange(e.target.value)} rows={rows} className={`${base} resize-none`} placeholder={placeholder} />
      ) : (
        <input value={value} onChange={(e) => onChange(e.target.value)} type={type} required={required} className={base} placeholder={placeholder} />
      )}
    </div>
  );
}

function CloseIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}
