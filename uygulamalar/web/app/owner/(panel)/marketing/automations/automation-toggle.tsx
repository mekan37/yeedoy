'use client';

import { useOptimistic, useTransition } from 'react';
import { toggleAutomationAction } from './automation-actions';

interface Props {
  templateId: string;
  businessId: string;
  enabled: boolean;
  disabled?: boolean;
}

export function AutomationToggle({ templateId, businessId, enabled, disabled }: Props) {
  const [optimisticEnabled, setOptimistic] = useOptimistic(enabled);
  const [isPending, startTransition] = useTransition();

  function handleToggle() {
    if (disabled) return;
    const next = !optimisticEnabled;
    startTransition(async () => {
      setOptimistic(next);
      const fd = new FormData();
      fd.set('business_id', businessId);
      fd.set('template_id', templateId);
      fd.set('enable', String(next));
      await toggleAutomationAction(null, fd);
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
