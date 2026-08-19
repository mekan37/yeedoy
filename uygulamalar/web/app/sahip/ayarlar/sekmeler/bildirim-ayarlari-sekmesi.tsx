'use client';

import { useState, useTransition } from 'react';
import { CalendarCheck, MessageSquareText, Tag, TrendingUp } from 'lucide-react';
import { clsx } from 'clsx';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

const NOTIFICATION_ITEMS = [
  {
    id: 'owner_new_review',
    label: 'Yeni yorumlar',
    description: 'İşletmenize yeni bir yorum geldiğinde bildirim alın.',
    icon: MessageSquareText,
  },
  {
    id: 'owner_reservation_request',
    label: 'Rezervasyon talepleri',
    description: 'Yeni rezervasyon taleplerinden haberdar olun.',
    icon: CalendarCheck,
  },
  {
    id: 'owner_price_suggestion',
    label: 'Fiyat önerileri',
    description: 'Müşterilerin gönderdiği fiyat önerilerini takip edin.',
    icon: Tag,
  },
  {
    id: 'owner_weekly_summary',
    label: 'Haftalık performans özeti',
    description: 'İşletme performansınızın haftalık özetini alın.',
    icon: TrendingUp,
  },
] as const;

async function togglePref(userId: string, notificationType: string, enabled: boolean) {
  const supabase = createSupabaseBrowserClient();
  const { error } = await (supabase as any).from('notification_preferences').upsert(
    { user_id: userId, notification_type: notificationType, enabled, updated_at: new Date().toISOString() },
    { onConflict: 'user_id,notification_type' },
  );
  if (error) throw error;
}

export function BildirimAyarlariTab({
  userId,
  initialPrefs,
}: {
  userId: string;
  initialPrefs: Record<string, boolean>;
}) {
  const [prefs, setPrefs] = useState<Record<string, boolean>>(initialPrefs);
  const [pending, startTransition] = useTransition();
  const [saving, setSaving] = useState<string | null>(null);

  function handleToggle(id: string, label: string) {
    const next = !(prefs[id] ?? true);
    setPrefs((p) => ({ ...p, [id]: next }));
    setSaving(id);
    startTransition(async () => {
      try {
        await togglePref(userId, id, next);
        toast(next ? `${label} bildirimleri açıldı` : `${label} bildirimleri kapatıldı`, next ? 'success' : 'default');
      } catch {
        setPrefs((p) => ({ ...p, [id]: !next }));
        toast('Tercih kaydedilemedi', 'danger');
      } finally {
        setSaving(null);
      }
    });
  }

  return (
    <PanelBolumKarti
      title="Bildirim Tercihleri"
      description="Hangi olaylardan e-posta ve uygulama içi bildirim almak istediğinizi seçin."
    >
      <div className="divide-y divide-border">
        {NOTIFICATION_ITEMS.map((item) => {
          const Icon = item.icon;
          const enabled = prefs[item.id] ?? true;
          const isSaving = saving === item.id && pending;
          return (
            <div key={item.id} className="flex min-h-19 items-center gap-3 py-3 first:pt-0 last:pb-0">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-cardAlt text-muted">
                <Icon aria-hidden="true" className="h-5 w-5" />
              </span>
              <div className="min-w-0 flex-1">
                <label htmlFor={`notification-${item.id}`} className="text-sm font-bold text-textStrong">
                  {item.label}
                </label>
                <p className="mt-0.5 text-xs text-muted">{item.description}</p>
              </div>
              <button
                id={`notification-${item.id}`}
                type="button"
                role="switch"
                aria-checked={enabled}
                aria-label={item.label}
                disabled={isSaving}
                onClick={() => handleToggle(item.id, item.label)}
                className={clsx(
                  "relative h-6 w-11 shrink-0 rounded-full transition-colors after:absolute after:left-0.5 after:top-0.5 after:h-5 after:w-5 after:rounded-full after:bg-card after:shadow-xs after:transition-transform after:content-[''] disabled:cursor-not-allowed disabled:opacity-70 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30 focus-visible:ring-offset-2 focus-visible:ring-offset-card",
                  enabled ? 'bg-primary after:translate-x-5' : 'bg-borderStrong',
                )}
              />
            </div>
          );
        })}
      </div>
      <p className="mt-4 text-xs leading-relaxed text-muted">Tercihler anında kaydedilir.</p>
    </PanelBolumKarti>
  );
}
