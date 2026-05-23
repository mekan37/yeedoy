'use client';

import { useOptimistic, useTransition } from 'react';
import { toggleOtomasyon } from './otomasyon-eylemleri';

interface Props {
  templateId: string;
  businessId: string | null;
  enabled: boolean;
  disabled?: boolean;
}

export function OtomasyonToggle({ templateId, businessId, enabled, disabled }: Props) {
  const [optimisticEnabled, setOptimistic] = useOptimistic(enabled);
  const [isPending, startTransition] = useTransition();

  function handleToggle() {
    if (!businessId || disabled) return;
    const next = !optimisticEnabled;
    startTransition(async () => {
      setOptimistic(next);
      await toggleOtomasyon(businessId, templateId, next);
    });
  }

  return (
    <button
      role="switch"
      aria-checked={optimisticEnabled}
      disabled={disabled || isPending}
      onClick={handleToggle}
      className={`relative shrink-0 h-6 w-11 rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40 disabled:cursor-not-allowed disabled:opacity-40 ${
        optimisticEnabled ? 'bg-primary' : 'bg-border'
      }`}
    >
      <span
        className={`absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${
          optimisticEnabled ? 'translate-x-5' : 'translate-x-0'
        }`}
      />
    </button>
  );
}
