'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

// ── Notification definitions ──────────────────────────────────────────────────

const CHANNELS = [
  {
    key: 'push_notifications',
    label: 'Push Bildirimleri',
    description: 'Tarayıcı ve cihaz push bildirimleri alın',
  },
  {
    key: 'email_notifications',
    label: 'E-posta Bildirimleri',
    description: 'Önemli güncellemeleri e-posta ile alın',
  },
] as const;

const CATEGORIES = [
  {
    key: 'announcements',
    label: 'Duyurular',
    description: 'Önemli duyuru ve güncellemeler',
  },
  {
    key: 'campaigns',
    label: 'Kampanyalar',
    description: 'Özel kampanya ve fırsat bildirimleri',
  },
  {
    key: 'achievements',
    label: 'Başarılar ve Rozetler',
    description: 'Rozet kazandığınızda ve başarılarınızda',
  },
  {
    key: 'events',
    label: 'Etkinlikler',
    description: 'Etkinlik hatırlatmaları ve takvim bildirimleri',
  },
  {
    key: 'social',
    label: 'Sosyal Bildirimler',
    description: 'Arkadaş aktiviteleri ve sosyal bildirimler',
  },
  {
    key: 'review_replies',
    label: 'Yorum Yanıtları',
    description: 'Yorumlarınıza gelen yanıtlardan haberdar olun',
  },
  {
    key: 'price_alerts',
    label: 'Fiyat Alarmları',
    description: 'Takip ettiğiniz fiyatlar değiştiğinde bildirim alın',
  },
] as const;

// ── Toggle row ────────────────────────────────────────────────────────────────

type ToggleItem = { readonly key: string; readonly label: string; readonly description: string };

function ToggleRow({
  item,
  enabled,
  saving,
  onToggle,
}: {
  item: ToggleItem;
  enabled: boolean;
  saving: boolean;
  onToggle: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      disabled={saving}
      className="flex min-h-[64px] w-full items-center gap-4 rounded-2xl border border-border bg-bg px-4 py-4 text-left transition-colors hover:bg-cardAlt disabled:opacity-70"
    >
      <div className="min-w-0 flex-1">
        <p className="font-[900] leading-tight text-textStrong">{item.label}</p>
        <p className="mt-0.5 text-xs leading-snug text-muted">{item.description}</p>
      </div>
      <div
        className={[
          'relative h-6 w-11 shrink-0 rounded-full transition-colors duration-200',
          enabled ? 'bg-primary' : 'bg-border',
        ].join(' ')}
        role="switch"
        aria-checked={enabled}
        aria-label={item.label}
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
}

// ── Page ──────────────────────────────────────────────────────────────────────

type PrefRow = { notification_type: string; enabled: boolean };

export default function BildirimTercihlerPage() {
  const [userId, setUserId] = useState<string | null>(null);
  const [prefs, setPrefs] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) return;
      setUserId(user.id);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (supabase as any)
        .from('notification_preferences')
        .select('notification_type, enabled')
        .eq('user_id', user.id)
        .then(({ data }: { data: PrefRow[] | null }) => {
          if (Array.isArray(data)) {
            const map: Record<string, boolean> = {};
            for (const row of data) {
              map[row.notification_type] = row.enabled;
            }
            setPrefs(map);
          }
          setLoading(false);
        });
    });
  }, []);

  async function handleToggle(key: string, label: string) {
    if (!userId) return;
    const next = !(prefs[key] ?? true);
    setPrefs((p) => ({ ...p, [key]: next }));
    setSaving(key);
    try {
      const supabase = createSupabaseBrowserClient();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (supabase as any).from('notification_preferences').upsert(
        {
          user_id: userId,
          notification_type: key,
          enabled: next,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,notification_type' },
      );
      toast(next ? `${label} açıldı` : `${label} kapatıldı`, next ? 'success' : 'default');
    } catch {
      setPrefs((p) => ({ ...p, [key]: !next }));
      toast('Tercih kaydedilemedi', 'danger');
    } finally {
      setSaving(null);
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            href="/profil"
            className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
          >
            ← Profilime Dön
          </Link>
          <h1 className="text-xl font-[900] text-textStrong">Bildirim Tercihleri</h1>
          <p className="mt-1 text-sm text-muted">Hangi bildirimleri almak istediğinizi seçin.</p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <span className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
          </div>
        ) : (
          <>
            <section className="flex flex-col gap-3">
              <h2 className="text-sm font-[900] uppercase tracking-wide text-muted">
                Bildirim Kanalları
              </h2>
              {(CHANNELS as readonly ToggleItem[]).map((item) => (
                <ToggleRow
                  key={item.key}
                  item={item}
                  enabled={prefs[item.key] ?? true}
                  saving={saving === item.key}
                  onToggle={() => handleToggle(item.key, item.label)}
                />
              ))}
            </section>

            <section className="flex flex-col gap-3">
              <h2 className="text-sm font-[900] uppercase tracking-wide text-muted">
                Bildirim Kategorileri
              </h2>
              {(CATEGORIES as readonly ToggleItem[]).map((item) => (
                <ToggleRow
                  key={item.key}
                  item={item}
                  enabled={prefs[item.key] ?? true}
                  saving={saving === item.key}
                  onToggle={() => handleToggle(item.key, item.label)}
                />
              ))}
            </section>
          </>
        )}

        <p className="text-xs leading-relaxed text-muted">
          Tercihler anında kaydedilir. Push bildirimleri için{' '}
          <Link
            href="/bildirim-ayarlari"
            className="font-[700] text-primary underline-offset-2 hover:underline"
          >
            tarayıcı izni
          </Link>{' '}
          gereklidir.
        </p>
      </div>
    </main>
  );
}
