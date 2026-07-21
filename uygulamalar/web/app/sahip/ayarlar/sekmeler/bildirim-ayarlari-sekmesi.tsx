'use client';

import { Bell, CalendarCheck, MessageSquareText, Tag, TrendingUp } from 'lucide-react';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';

const NOTIFICATION_ITEMS = [
  {
    id: 'review',
    label: 'Yeni yorumlar',
    description: 'İşletmenize yeni bir yorum geldiğinde bildirim alın.',
    icon: MessageSquareText,
  },
  {
    id: 'reservation',
    label: 'Rezervasyon talepleri',
    description: 'Yeni rezervasyon taleplerinden haberdar olun.',
    icon: CalendarCheck,
  },
  {
    id: 'price',
    label: 'Fiyat önerileri',
    description: 'Müşterilerin gönderdiği fiyat önerilerini takip edin.',
    icon: Tag,
  },
  {
    id: 'weekly',
    label: 'Haftalık performans özeti',
    description: 'İşletme performansınızın haftalık özetini alın.',
    icon: TrendingUp,
  },
] as const;

export function BildirimAyarlariTab() {
  return (
    <PanelBolumKarti
      title="Bildirim Tercihleri"
      description="Hesabınızla ilgili bildirim kanallarının mevcut durumu."
    >
      <div
        id="notification-readonly-note"
        className="mb-5 flex gap-3 border-b border-border pb-5 text-sm text-muted"
      >
        <Bell aria-hidden="true" className="mt-0.5 h-5 w-5 shrink-0 text-primary" />
        <p>
          Bildirim tercihleri henüz bu ekrandan kaydedilemiyor. Aşağıdaki kontroller
          yalnızca sunulacak tercihleri gösterir.
        </p>
      </div>

      <div className="divide-y divide-border">
        {NOTIFICATION_ITEMS.map((item) => {
          const Icon = item.icon;
          return (
            <div key={item.id} className="flex min-h-[4.75rem] items-center gap-3 py-3 first:pt-0 last:pb-0">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-cardAlt text-muted">
                <Icon aria-hidden="true" className="h-5 w-5" />
              </span>
              <div className="min-w-0 flex-1">
                <label
                  htmlFor={`notification-${item.id}`}
                  className="text-sm font-[700] text-textStrong"
                >
                  {item.label}
                </label>
                <p className="mt-0.5 text-xs text-muted">{item.description}</p>
              </div>
              <input
                id={`notification-${item.id}`}
                type="checkbox"
                disabled
                aria-describedby="notification-readonly-note"
                className="h-5 w-5 shrink-0 cursor-not-allowed rounded border-border text-primary opacity-50 accent-primary"
              />
            </div>
          );
        })}
      </div>
    </PanelBolumKarti>
  );
}
