'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { updateMealCardProviders } from './isletme-islemleri';

export interface MealCardProvider {
  id: string;
  key: string;
  name: string;
  assetName: string;
  sortOrder: number;
}

interface Props {
  businessId: string;
  allProviders: MealCardProvider[];
  selectedKeys: string[];
}

export function MealCardEditor({ businessId, allProviders, selectedKeys }: Props) {
  const [selected, setSelected] = useState<Set<string>>(new Set(selectedKeys));
  const [isPending, startTransition] = useTransition();
  const [feedback, setFeedback] = useState<'idle' | 'success' | 'error'>('idle');

  function toggle(key: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(key)) {
        next.delete(key);
      } else {
        next.add(key);
      }
      return next;
    });
    setFeedback('idle');
  }

  function handleSave() {
    startTransition(async () => {
      const result = await updateMealCardProviders(businessId, Array.from(selected));
      if (result?.error) {
        setFeedback('error');
      } else {
        setFeedback('success');
        setTimeout(() => setFeedback('idle'), 3000);
      }
    });
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        {allProviders.map((provider) => {
          const isSelected = selected.has(provider.key);
          return (
            <label
              key={provider.id}
              className={[
                'flex cursor-pointer items-center gap-3 rounded-xl border px-3 py-2.5 transition-colors',
                isSelected
                  ? 'border-primary bg-[#7F1D1D]/5'
                  : 'border-border bg-card hover:bg-bg',
              ].join(' ')}
            >
              <input
                type="checkbox"
                className="sr-only"
                checked={isSelected}
                onChange={() => toggle(provider.key)}
              />
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={`/meal-cards/meal_card_${provider.key}.png`}
                alt={provider.name}
                className="h-5 w-auto max-w-[56px] object-contain"
                onError={(e) => {
                  (e.currentTarget as HTMLImageElement).style.display = 'none';
                }}
              />
              <span
                className={[
                  'flex-1 text-sm font-[700]',
                  isSelected ? 'text-primary' : 'text-textStrong',
                ].join(' ')}
              >
                {provider.name}
              </span>
              <span
                className={[
                  'h-4 w-4 shrink-0 rounded-full border-2 transition-colors',
                  isSelected
                    ? 'border-primary bg-primary'
                    : 'border-border bg-transparent',
                ].join(' ')}
              />
            </label>
          );
        })}
      </div>

      <div className="flex items-center gap-3 pt-1">
        <PanelActionButton
          variant="primary"
          onClick={handleSave}
          disabled={isPending}
        >
          {isPending ? 'Kaydediliyor…' : 'Kaydet'}
        </PanelActionButton>
        {feedback === 'success' && (
          <span className="text-sm font-[700] text-green-700">Kaydedildi</span>
        )}
        {feedback === 'error' && (
          <span className="text-sm font-[700] text-danger">Kayıt başarısız</span>
        )}
      </div>
    </div>
  );
}
