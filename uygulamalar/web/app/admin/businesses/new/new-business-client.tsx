'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { adminBusinessCopy } from '@/src/lib/i18n';

const t = adminBusinessCopy.tr;

const BUSINESS_CATEGORIES = [
  'Restoran',
  'Kafe',
  'Bar',
  'Fast Food',
  'Pastane & Tatlı',
  'Fırın',
  'Pizzacı',
  'Dönerci',
  'Balık Restoranı',
  'Et Restoranı',
  'Vegan & Vejetaryen',
  'Kahvaltı Salonu',
  'Nargile Kafe',
  'Pub',
  'Kokteyl Bar',
  'Çay Bahçesi',
  'Büfe',
  'Sandviç & Dürüm',
  'Sushi',
  'Diğer',
] as const;

type CreatedBusiness = { id: string; name: string; slug: string | null };

type FormState = {
  name: string;
  category: string;
  city: string;
  district: string;
  address: string;
  phone: string;
  website: string;
  description: string;
  price_level: '' | 'budget' | 'mid' | 'premium';
  lat: string;
  lng: string;
  is_active: boolean;
};

const EMPTY_FORM: FormState = {
  name: '',
  category: '',
  city: '',
  district: '',
  address: '',
  phone: '',
  website: '',
  description: '',
  price_level: '',
  lat: '',
  lng: '',
  is_active: true,
};

function FieldLabel({ htmlFor, children, required }: { htmlFor: string; children: React.ReactNode; required?: boolean }) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-[13px] font-[700] text-textStrong">
      {children}
      {required && <span className="ml-0.5 text-[color:var(--yd-color-danger)]">*</span>}
    </label>
  );
}

function TextInput({ id, value, onChange, placeholder, type = 'text' }: {
  id: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string;
}) {
  return (
    <input
      id={id}
      type={type}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      className="w-full rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
    />
  );
}

export function NewBusinessClient() {
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [globalError, setGlobalError] = useState<string | null>(null);
  const [created, setCreated] = useState<CreatedBusiness | null>(null);
  const [isPending, startTransition] = useTransition();

  function set<K extends keyof FormState>(key: K) {
    return (value: FormState[K]) => setForm((f) => ({ ...f, [key]: value }));
  }

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!form.name.trim() || form.name.trim().length < 2) errs.name = 'En az 2 karakter gerekli';
    if (!form.category) errs.category = 'Kategori seçiniz';
    if (!form.city.trim()) errs.city = 'Şehir zorunlu';
    if (form.website && form.website.trim()) {
      try { new URL(form.website); } catch { errs.website = 'Geçerli bir URL girin (https://...)'; }
    }
    if (form.lat && isNaN(parseFloat(form.lat))) errs.lat = 'Geçerli bir sayı girin';
    if (form.lng && isNaN(parseFloat(form.lng))) errs.lng = 'Geçerli bir sayı girin';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;

    setGlobalError(null);
    startTransition(async () => {
      try {
        const body: Record<string, unknown> = {
          name: form.name.trim(),
          category: form.category,
          city: form.city.trim(),
          is_active: form.is_active,
        };
        if (form.district.trim()) body.district = form.district.trim();
        if (form.address.trim()) body.address = form.address.trim();
        if (form.phone.trim()) body.phone = form.phone.trim();
        if (form.website.trim()) body.website = form.website.trim();
        if (form.description.trim()) body.description = form.description.trim();
        if (form.price_level) body.price_level = form.price_level;
        if (form.lat.trim()) body.lat = parseFloat(form.lat);
        if (form.lng.trim()) body.lng = parseFloat(form.lng);

        const res = await fetch('/api/admin/businesses', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        });

        const json = await res.json();

        if (!res.ok) {
          if (json.issues) {
            const fieldErrors: Record<string, string> = {};
            for (const [field, msgs] of Object.entries(json.issues)) {
              fieldErrors[field] = (msgs as string[])[0] ?? 'Hatalı değer';
            }
            setErrors(fieldErrors);
          }
          setGlobalError(json.error ?? t.errorGeneric);
          return;
        }

        setCreated(json.data);
      } catch {
        setGlobalError(t.errorGeneric);
      }
    });
  }

  function handleReset() {
    setForm(EMPTY_FORM);
    setErrors({});
    setGlobalError(null);
    setCreated(null);
  }

  // ── Adım 2: başarı ekranı ───────────────────────────────────────────────────
  if (created) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Admin" title={t.step2Label} />
        <PanelContentSurface className="pt-6">
          <PanelSectionCard>
            <div className="flex flex-col items-start gap-6">
              {/* Başarı mesajı */}
              <div className="flex items-center gap-3">
                <span className="flex h-10 w-10 items-center justify-center rounded-full bg-green-50 text-green-600">
                  <CheckIcon />
                </span>
                <div>
                  <p className="text-[15px] font-[800] text-textStrong">
                    &ldquo;{created.name}&rdquo; {t.newBusinessSaved}
                  </p>
                  {created.slug && (
                    <p className="text-xs text-muted">slug: {created.slug}</p>
                  )}
                </div>
              </div>

              {/* Aksiyon butonları */}
              <div className="flex flex-wrap gap-3">
                <Link href={`/admin/businesses/${created.id}/menus/new`}>
                  <PanelActionButton variant="primary" icon={<PlusIcon />}>
                    {t.newBusinessAddMenu}
                  </PanelActionButton>
                </Link>
                <PanelActionButton variant="secondary" onClick={handleReset} icon={<PlusIcon />}>
                  {t.newBusinessAddAnother}
                </PanelActionButton>
                <Link href="/admin/businesses">
                  <PanelActionButton variant="ghost" icon={<ListIcon />}>
                    {t.newBusinessGoToList}
                  </PanelActionButton>
                </Link>
              </div>
            </div>
          </PanelSectionCard>
        </PanelContentSurface>
      </div>
    );
  }

  // ── Adım 1: form ─────────────────────────────────────────────────────────────
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title={t.newBusinessTitle}
        description={t.step1Label}
        actions={
          <Link href="/admin/businesses">
            <PanelActionButton variant="ghost" icon={<ListIcon />}>
              {t.newBusinessGoToList}
            </PanelActionButton>
          </Link>
        }
      />
      <PanelContentSurface className="pt-6">
        <form onSubmit={handleSubmit} noValidate>
          <div className="grid gap-6 lg:grid-cols-2">
            {/* Sol sütun */}
            <div className="flex flex-col gap-5">
              <PanelSectionCard title="Temel Bilgiler">
                {/* İsim */}
                <div className="mb-4">
                  <FieldLabel htmlFor="name" required>{t.fieldName}</FieldLabel>
                  <TextInput
                    id="name"
                    value={form.name}
                    onChange={set('name')}
                    placeholder="Örn. Süvari Kahvesi"
                  />
                  {errors.name && <p className="mt-1 text-xs text-[color:var(--yd-color-danger)]">{errors.name}</p>}
                </div>

                {/* Kategori */}
                <div className="mb-4">
                  <FieldLabel htmlFor="category" required>{t.fieldCategory}</FieldLabel>
                  <select
                    id="category"
                    value={form.category}
                    onChange={(e) => set('category')(e.target.value)}
                    className="w-full rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                  >
                    <option value="">Kategori seçin...</option>
                    {BUSINESS_CATEGORIES.map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                  {errors.category && <p className="mt-1 text-xs text-[color:var(--yd-color-danger)]">{errors.category}</p>}
                </div>

                {/* Fiyat seviyesi */}
                <div className="mb-4">
                  <FieldLabel htmlFor="price_level">{t.fieldPriceLevel}</FieldLabel>
                  <div className="flex gap-2">
                    {(
                      [
                        { value: 'budget', label: t.priceBudget, symbol: '₺' },
                        { value: 'mid', label: t.priceMid, symbol: '₺₺' },
                        { value: 'premium', label: t.pricePremium, symbol: '₺₺₺' },
                      ] as const
                    ).map(({ value, label, symbol }) => (
                      <button
                        key={value}
                        type="button"
                        onClick={() => set('price_level')(form.price_level === value ? '' : value)}
                        className={`flex-1 rounded-xl border px-3 py-2 text-xs font-[700] transition-colors ${
                          form.price_level === value
                            ? 'border-primary bg-primary text-white'
                            : 'border-border bg-card text-muted hover:text-textStrong'
                        }`}
                      >
                        <span className="block text-base leading-none">{symbol}</span>
                        <span className="block mt-0.5">{label}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Açıklama */}
                <div>
                  <FieldLabel htmlFor="description">{t.fieldDescription}</FieldLabel>
                  <textarea
                    id="description"
                    value={form.description}
                    onChange={(e) => set('description')(e.target.value)}
                    placeholder="Kısa tanıtım metni..."
                    rows={3}
                    className="w-full rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 resize-none"
                  />
                </div>
              </PanelSectionCard>

              {/* Aktif toggle */}
              <PanelSectionCard>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-[13px] font-[700] text-textStrong">{t.fieldIsActive}</p>
                    <p className="text-xs text-muted">İşletme hemen yayınlansın mı?</p>
                  </div>
                  <button
                    type="button"
                    role="switch"
                    aria-checked={form.is_active}
                    onClick={() => set('is_active')(!form.is_active)}
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                      form.is_active ? 'bg-green-500' : 'bg-zinc-300'
                    }`}
                  >
                    <span
                      className={`inline-block h-4 w-4 rounded-full bg-white shadow transition-transform ${
                        form.is_active ? 'translate-x-6' : 'translate-x-1'
                      }`}
                    />
                  </button>
                </div>
              </PanelSectionCard>
            </div>

            {/* Sağ sütun */}
            <div className="flex flex-col gap-5">
              <PanelSectionCard title="Konum ve İletişim">
                {/* Şehir + İlçe */}
                <div className="mb-4 grid grid-cols-2 gap-3">
                  <div>
                    <FieldLabel htmlFor="city" required>{t.fieldCity}</FieldLabel>
                    <TextInput
                      id="city"
                      value={form.city}
                      onChange={set('city')}
                      placeholder="İstanbul"
                    />
                    {errors.city && <p className="mt-1 text-xs text-[color:var(--yd-color-danger)]">{errors.city}</p>}
                  </div>
                  <div>
                    <FieldLabel htmlFor="district">{t.fieldDistrict}</FieldLabel>
                    <TextInput
                      id="district"
                      value={form.district}
                      onChange={set('district')}
                      placeholder="Kadıköy"
                    />
                  </div>
                </div>

                {/* Adres */}
                <div className="mb-4">
                  <FieldLabel htmlFor="address">{t.fieldAddress}</FieldLabel>
                  <TextInput
                    id="address"
                    value={form.address}
                    onChange={set('address')}
                    placeholder="Moda Caddesi No:12"
                  />
                </div>

                {/* Telefon */}
                <div className="mb-4">
                  <FieldLabel htmlFor="phone">{t.fieldPhone}</FieldLabel>
                  <TextInput
                    id="phone"
                    value={form.phone}
                    onChange={set('phone')}
                    placeholder="+90 212 000 00 00"
                  />
                </div>

                {/* Website */}
                <div>
                  <FieldLabel htmlFor="website">{t.fieldWebsite}</FieldLabel>
                  <TextInput
                    id="website"
                    value={form.website}
                    onChange={set('website')}
                    placeholder="https://ornek.com"
                    type="url"
                  />
                  {errors.website && <p className="mt-1 text-xs text-[color:var(--yd-color-danger)]">{errors.website}</p>}
                </div>
              </PanelSectionCard>

              <PanelSectionCard title="Koordinat (opsiyonel)">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <FieldLabel htmlFor="lat">Enlem (lat)</FieldLabel>
                    <TextInput
                      id="lat"
                      value={form.lat}
                      onChange={set('lat')}
                      placeholder="41.0082"
                    />
                    {errors.lat && <p className="mt-1 text-xs text-[color:var(--yd-color-danger)]">{errors.lat}</p>}
                  </div>
                  <div>
                    <FieldLabel htmlFor="lng">Boylam (lng)</FieldLabel>
                    <TextInput
                      id="lng"
                      value={form.lng}
                      onChange={set('lng')}
                      placeholder="28.9784"
                    />
                    {errors.lng && <p className="mt-1 text-xs text-[color:var(--yd-color-danger)]">{errors.lng}</p>}
                  </div>
                </div>
              </PanelSectionCard>
            </div>
          </div>

          {/* Global hata */}
          {globalError && (
            <div className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-[color:var(--yd-color-danger)]">
              {globalError}
            </div>
          )}

          {/* Submit */}
          <div className="mt-6 flex items-center gap-3">
            <PanelActionButton
              type="submit"
              variant="primary"
              loading={isPending}
              icon={<CheckIcon />}
            >
              {isPending ? t.savingButton : t.saveButton}
            </PanelActionButton>
            <p className="text-xs text-muted">{t.requiredHint}</p>
          </div>
        </form>
      </PanelContentSurface>
    </div>
  );
}

function CheckIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function ListIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" />
      <line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" />
    </svg>
  );
}
