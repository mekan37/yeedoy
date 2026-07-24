'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { adminBusinessCopy } from '@/src/lib/i18n';

const t = adminBusinessCopy.tr;

type CreatedMenu = { id: string; name: string; business_id: string };

type FormState = {
  name: string;
  description: string;
  is_active: boolean;
};

const EMPTY_FORM: FormState = {
  name: '',
  description: '',
  is_active: true,
};

function FieldLabel({ htmlFor, children, required }: { htmlFor: string; children: React.ReactNode; required?: boolean }) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-[13px] font-bold text-textStrong">
      {children}
      {required && <span className="ml-0.5 text-(--yd-color-danger)">*</span>}
    </label>
  );
}

export function YeniMenuIstemcisi({ businessId }: { businessId: string }) {
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [globalError, setGlobalError] = useState<string | null>(null);
  const [created, setCreated] = useState<CreatedMenu | null>(null);
  const [isPending, startTransition] = useTransition();

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!form.name.trim()) errs.name = 'Menü adı zorunlu';
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
          is_active: form.is_active,
        };
        if (form.description.trim()) body.description = form.description.trim();

        const res = await fetch(`/sunucu/yonetici/isletmeler/${businessId}/menuler`, {
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

  // ── Başarı ekranı ─────────────────────────────────────────────────────────────
  if (created) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title={t.newMenuSaved} />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelBolumKarti>
            <div className="flex flex-col items-start gap-6">
              <div className="flex items-center gap-3">
                <span className="flex h-10 w-10 items-center justify-center rounded-full bg-green-50 text-green-600">
                  <CheckIcon />
                </span>
                <div>
                  <p className="text-[15px] font-extrabold text-textStrong">
                    &ldquo;{created.name}&rdquo; {t.newMenuSaved.toLowerCase()}
                  </p>
                  <p className="text-xs text-muted">ID: {created.id}</p>
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                <Link href={`/yonetici/isletmeler/${businessId}`}>
                  <PanelActionButton variant="secondary" icon={<BuildingIcon />}>
                    {t.newMenuGoToBusiness}
                  </PanelActionButton>
                </Link>
                <Link href="/yonetici/isletmeler">
                  <PanelActionButton variant="ghost" icon={<ListIcon />}>
                    {t.newBusinessGoToList}
                  </PanelActionButton>
                </Link>
              </div>
            </div>
          </PanelBolumKarti>
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────────
  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title={t.newMenuTitle}
        actions={
          <Link href={`/yonetici/isletmeler/${businessId}`}>
            <PanelActionButton variant="ghost" icon={<BuildingIcon />}>
              {t.newMenuGoToBusiness}
            </PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <form onSubmit={handleSubmit} noValidate className="max-w-xl">
          <PanelBolumKarti title="Menü Bilgileri">
            {/* Menü adı */}
            <div className="mb-4">
              <FieldLabel htmlFor="menu-name" required>{t.fieldMenuName}</FieldLabel>
              <input
                id="menu-name"
                type="text"
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="Örn. Yemek Menüsü"
                className="w-full rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
              />
              {errors.name && <p className="mt-1 text-xs text-(--yd-color-danger)">{errors.name}</p>}
            </div>

            {/* Açıklama */}
            <div className="mb-4">
              <FieldLabel htmlFor="menu-description">{t.fieldMenuDescription}</FieldLabel>
              <textarea
                id="menu-description"
                value={form.description}
                onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                placeholder="Menü hakkında kısa açıklama..."
                rows={3}
                className="w-full rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 resize-none"
              />
            </div>

            {/* Aktif toggle */}
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[13px] font-bold text-textStrong">{t.fieldMenuIsActive}</p>
                <p className="text-xs text-muted">Menü hemen yayınlansın mı?</p>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={form.is_active}
                onClick={() => setForm((f) => ({ ...f, is_active: !f.is_active }))}
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
          </PanelBolumKarti>

          {globalError && (
            <div className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-(--yd-color-danger)">
              {globalError}
            </div>
          )}

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
      </PanelIcerikYuzeyi>
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

function BuildingIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" />
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
