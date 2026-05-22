'use client';

import { useState, useTransition } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

type NotificationType = { key: string; label: string; description: string };

async function togglePref(userId: string, notificationKey: string, enabled: boolean) {
  const supabase = createSupabaseBrowserClient();
  await (supabase as any).from('notification_preferences').upsert(
    { user_id: userId, notification_type: notificationKey, enabled, updated_at: new Date().toISOString() },
    { onConflict: 'user_id,notification_type' },
  );
}

export function BildirimTercihleri({
  userId,
  types,
  initialPrefs,
}: {
  userId: string;
  types: NotificationType[];
  initialPrefs: Record<string, boolean>;
}) {
  const [prefs, setPrefs] = useState<Record<string, boolean>>(initialPrefs);
  const [pending, startTransition] = useTransition();
  const [saving, setSaving] = useState<string | null>(null);

  async function handleToggle(key: string, label: string) {
    const next = !(prefs[key] ?? true);
    setPrefs((p) => ({ ...p, [key]: next }));
    setSaving(key);
    startTransition(async () => {
      try {
        await togglePref(userId, key, next);
        toast(next ? `${label} bildirimleri açıldı` : `${label} bildirimleri kapatıldı`, next ? 'success' : 'default');
      } catch {
        setPrefs((p) => ({ ...p, [key]: !next }));
        toast('Tercih kaydedilemedi', 'danger');
      } finally {
        setSaving(null);
      }
    });
  }

  return (
    <div className="flex flex-col gap-3">
      {types.map(({ key, label, description }) => {
        const enabled = prefs[key] ?? true;
        const isSaving = saving === key && pending;
        return (
          <button
            key={key}
            type="button"
            onClick={() => handleToggle(key, label)}
            disabled={isSaving}
            className="flex items-center gap-4 rounded-2xl border border-border bg-bg px-4 py-4 min-h-[64px] text-left transition-colors hover:bg-cardAlt disabled:opacity-70"
          >
            <div className="min-w-0 flex-1">
              <p className="font-[900] text-textStrong leading-tight">{label}</p>
              <p className="mt-0.5 text-xs leading-snug text-muted">{description}</p>
            </div>
            <div
              className={[
                'relative h-6 w-11 shrink-0 rounded-full transition-colors duration-200',
                enabled ? 'bg-primary' : 'bg-border',
              ].join(' ')}
              aria-checked={enabled}
              role="switch"
              aria-label={label}
            >
              <span
                className={[
                  'absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform duration-200',
                  enabled ? 'translate-x-5' : 'translate-x-0.5',
                ].join(' ')}
              />
            </div>
          </button>
        );
      })}
      <p className="mt-2 text-xs leading-relaxed text-muted">
        Tercihler anında kaydedilir. Push bildirimleri izni verildikten sonra aktif olur.
      </p>
    </div>
  );
}
