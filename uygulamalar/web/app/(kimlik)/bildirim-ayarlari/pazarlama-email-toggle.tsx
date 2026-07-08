'use client';

import { useState, useTransition } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

type Props = {
  initialEnabled: boolean;
};

/**
 * Global pazarlama e-postası izni toggle bileşeni.
 *
 * user_profiles.marketing_email_opt_in alanını günceller.
 * business_follows.is_subscribed_email'e dokunmaz — kavramlar birbirinden bağımsız.
 *
 * UYARI: Bu bileşen, user_profiles tablosuna doğrudan Supabase browser client ile
 * upsert yapar. RPC tablosundan önce migration (20260620000001) uygulanmış olmalıdır.
 * Migration uygulanmadan önce bu toggle'ın UI'da görünür olmaması önerilir.
 */
export function PazarlamaEmailToggle({ initialEnabled }: Props) {
  const [enabled, setEnabled] = useState(initialEnabled);
  const [pending, startTransition] = useTransition();

  async function handleToggle() {
    const next = !enabled;
    setEnabled(next);

    startTransition(async () => {
      try {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
          setEnabled(!next);
          toast('Oturum bulunamadı', 'danger');
          return;
        }

        // marketing_email_opt_in güncellemesi
        // opted_in_at: true ise now(), false ise null
        const { error } = await (supabase as unknown as {
          from: (t: string) => {
            update: (v: unknown) => { eq: (c: string, v: string) => Promise<{ error: unknown }> };
          };
        })
          .from('user_profiles')
          .update({
            marketing_email_opt_in: next,
            marketing_email_opted_in_at: next ? new Date().toISOString() : null,
            updated_at: new Date().toISOString(),
          })
          .eq('user_id', user.id);

        if (error) {
          setEnabled(!next);
          toast('Tercih kaydedilemedi', 'danger');
          return;
        }

        toast(
          next ? 'Pazarlama e-postaları açıldı' : 'Pazarlama e-postaları kapatıldı',
          next ? 'success' : 'default',
        );
      } catch {
        setEnabled(!next);
        toast('Tercih kaydedilemedi', 'danger');
      }
    });
  }

  const isSaving = pending;

  return (
    <button
      type="button"
      onClick={handleToggle}
      disabled={isSaving}
      className="flex items-center gap-4 rounded-2xl border border-border bg-bg px-4 py-4 min-h-[64px] w-full text-left transition-colors hover:bg-cardAlt disabled:opacity-70"
      aria-pressed={enabled}
    >
      <div className="min-w-0 flex-1">
        <p className="font-[900] text-textStrong leading-tight">Pazarlama E-postaları</p>
        <p className="mt-0.5 text-xs leading-snug text-muted">
          Yeedoy kampanya ve duyurularını e-posta ile alın
        </p>
      </div>
      <div
        className={[
          'relative h-6 w-11 shrink-0 rounded-full transition-colors duration-200',
          enabled ? 'bg-primary' : 'bg-border',
        ].join(' ')}
        aria-checked={enabled}
        role="switch"
        aria-label="Pazarlama E-postaları"
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
