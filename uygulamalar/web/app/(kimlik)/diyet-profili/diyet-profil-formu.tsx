'use client';

import { useState } from 'react';

type DietProfile = {
  is_vegan: boolean;
  is_vegetarian: boolean;
  is_gluten_free: boolean;
  is_dairy_free: boolean;
  detected_by: string | null;
} | null;

type ToggleItem = {
  key: 'is_vegan' | 'is_vegetarian' | 'is_gluten_free' | 'is_dairy_free';
  emoji: string;
  label: string;
  description: string;
};

const TOGGLE_ITEMS: ToggleItem[] = [
  {
    key: 'is_vegan',
    emoji: '🌱',
    label: 'Vegan',
    description: 'Hayvansal hiçbir ürün içermeyen menüler',
  },
  {
    key: 'is_vegetarian',
    emoji: '🥗',
    label: 'Vejetaryen',
    description: 'Et içermeyen, bitkisel ağırlıklı seçenekler',
  },
  {
    key: 'is_gluten_free',
    emoji: '🌾',
    label: 'Glütensiz',
    description: 'Buğday, arpa ve çavdar içermeyen ürünler',
  },
  {
    key: 'is_dairy_free',
    emoji: '🥛',
    label: 'Sütsüz',
    description: 'Süt ve süt türevleri içermeyen seçenekler',
  },
];

export function DiyetProfilFormu({ dietProfile }: { dietProfile: DietProfile }) {
  const [values, setValues] = useState({
    is_vegan: dietProfile?.is_vegan ?? false,
    is_vegetarian: dietProfile?.is_vegetarian ?? false,
    is_gluten_free: dietProfile?.is_gluten_free ?? false,
    is_dairy_free: dietProfile?.is_dairy_free ?? false,
  });
  const [status, setStatus] = useState<'idle' | 'loading' | 'saved' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  function toggle(key: keyof typeof values) {
    setValues((prev) => ({ ...prev, [key]: !prev[key] }));
    if (status === 'saved') setStatus('idle');
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setStatus('loading');
    setErrorMsg(null);
    try {
      const res = await fetch('/sunucu/diyet-profili', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(values),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(json.error ?? 'Bir hata oluştu');
      }
      setStatus('saved');
      window.setTimeout(() => setStatus('idle'), 3500);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Bir hata oluştu');
      setStatus('error');
    }
  }

  return (
    <form onSubmit={handleSave} className="flex flex-col gap-4">
      {TOGGLE_ITEMS.map(({ key, emoji, label, description }) => {
        const active = values[key];
        return (
          <button
            key={key}
            type="button"
            role="switch"
            aria-checked={active}
            onClick={() => toggle(key)}
            className={[
              'flex min-h-[64px] w-full items-center gap-4 rounded-2xl border px-5 py-4 text-left transition-all',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
              active
                ? 'border-primary/35 bg-[var(--yd-color-primary-soft)] shadow-yd1'
                : 'border-border bg-card hover:border-primary/20',
            ].join(' ')}
          >
            <span className="text-2xl leading-none" aria-hidden="true">{emoji}</span>
            <div className="min-w-0 flex-1">
              <p className={`font-[900] leading-tight ${active ? 'text-primary' : 'text-textStrong'}`}>
                {label}
              </p>
              <p className="mt-0.5 text-xs leading-snug text-muted">{description}</p>
            </div>
            {/* Toggle visual */}
            <div
              className={[
                'relative h-6 w-11 shrink-0 rounded-full transition-colors duration-200',
                active ? 'bg-primary' : 'bg-border',
              ].join(' ')}
              aria-hidden="true"
            >
              <span
                className={[
                  'absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform duration-200',
                  active ? 'translate-x-5' : 'translate-x-0.5',
                ].join(' ')}
              />
            </div>
          </button>
        );
      })}

      {/* Status messages */}
      {status === 'error' && errorMsg && (
        <p className="text-sm font-[800] text-danger">{errorMsg}</p>
      )}
      {status === 'saved' && (
        <p className="text-sm font-[800] text-success">Tercihleriniz kaydedildi</p>
      )}

      <button
        type="submit"
        disabled={status === 'loading'}
        className="mt-2 inline-flex min-h-[52px] w-full items-center justify-center rounded-2xl px-5 text-sm font-[900] text-white disabled:opacity-60 disabled:cursor-not-allowed"
        style={{ background: 'var(--yd-gradient-primary)' }}
      >
        {status === 'loading' ? 'Kaydediliyor…' : 'Kaydet'}
      </button>
    </form>
  );
}
