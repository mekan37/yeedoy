'use client';

import { AtSign, UserRound } from 'lucide-react';
import type { ReactNode } from 'react';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import type { UserData } from '../ayarlar-istemcisi';

export function HesapAyarlariTab({ user }: { user: UserData }) {
  return (
    <PanelBolumKarti
      title="Hesap Bilgileri"
      description="Yeedoy hesabınızla ilişkilendirilmiş kullanıcı bilgileri."
    >
      <dl className="divide-y divide-border">
        <AccountField
          icon={<UserRound aria-hidden="true" className="h-5 w-5" />}
          label="Ad Soyad"
          value={user.displayName || 'Belirtilmemiş'}
        />
        <AccountField
          icon={<AtSign aria-hidden="true" className="h-5 w-5" />}
          label="E-posta"
          value={user.email || 'Belirtilmemiş'}
          description="E-posta adresi bu ekrandan değiştirilemez."
        />
      </dl>
    </PanelBolumKarti>
  );
}

function AccountField({
  icon,
  label,
  value,
  description,
}: {
  icon: ReactNode;
  label: string;
  value: string;
  description?: string;
}) {
  return (
    <div className="grid gap-3 py-4 first:pt-0 last:pb-0 sm:grid-cols-[11rem_minmax(0,1fr)] sm:items-start">
      <dt className="flex min-h-11 items-center gap-3 text-sm font-[700] text-muted">
        <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-cardAlt text-muted">
          {icon}
        </span>
        {label}
      </dt>
      <dd className="min-w-0 sm:pt-2.5">
        <p className="break-words text-sm font-[700] text-textStrong">{value}</p>
        {description ? <p className="mt-1 text-xs text-muted">{description}</p> : null}
      </dd>
    </div>
  );
}
