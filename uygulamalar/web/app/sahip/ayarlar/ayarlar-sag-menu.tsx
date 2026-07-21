'use client';

import Link from 'next/link';
import { useState, useTransition } from 'react';
import {
  Building2,
  ChevronRight,
  ExternalLink,
  Globe2,
  LayoutGrid,
  QrCode,
  Share2,
  TriangleAlert,
  UserRound,
  type LucideIcon,
} from 'lucide-react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { deactivateBusiness } from './ayarlar-islemleri';
import type { BusinessData, UserData } from './ayarlar-istemcisi';

interface SettingsRightSidebarProps {
  user: UserData;
  business: BusinessData;
}

export function SettingsRightSidebar({ user, business }: SettingsRightSidebarProps) {
  const [isConfirming, setIsConfirming] = useState(false);
  const [confirmation, setConfirmation] = useState('');
  const [error, setError] = useState('');
  const [isPending, startTransition] = useTransition();
  const confirmationMatches = confirmation.trim() === business.name.trim();
  const initials = getInitials(user.displayName || user.email);

  const integrations = [
    { label: 'Web sitesi', url: getSafeHttpUrl(business.website_url), icon: Globe2 },
    { label: 'Instagram', url: getSafeHttpUrl(business.instagram_url), icon: Share2 },
    { label: 'Facebook', url: getSafeHttpUrl(business.facebook_url), icon: Share2 },
    { label: 'Twitter / X', url: getSafeHttpUrl(business.twitter_url), icon: Share2 },
  ];

  function handleDeactivate() {
    if (!confirmationMatches || isPending) return;

    setError('');
    startTransition(async () => {
      try {
        const result = await deactivateBusiness(business.id);
        if (result?.error) {
          setError(result.error);
          return;
        }

        window.location.assign('/sahip/isletmeler');
      } catch {
        setError('İşletme devre dışı bırakılamadı. Lütfen tekrar deneyin.');
      }
    });
  }

  return (
    <div className="flex flex-col gap-4">
      <PanelBolumKarti title="Kullanıcı Bilgisi">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-[900] text-primary">
            {initials || <UserRound aria-hidden="true" className="h-5 w-5" />}
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-[800] text-textStrong">
              {user.displayName || 'Kullanıcı'}
            </p>
            <p className="truncate text-xs text-muted">{user.email}</p>
            <p className="mt-1 text-xs font-[700] text-primary">İşletme sahibi</p>
          </div>
        </div>
      </PanelBolumKarti>

      <PanelBolumKarti title="Hızlı İşlemler" noPadding>
        <nav aria-label="Ayarlar hızlı işlemleri" className="divide-y divide-border">
          {business.slug ? (
            <QuickActionLink
              href={`/b/${business.slug}`}
              label="İşletme profilini önizle"
              icon={ExternalLink}
              external
            />
          ) : null}
          <QuickActionLink href="/sahip/karekod" label="QR menüyü görüntüle" icon={QrCode} />
          <QuickActionLink href="/sahip/isletmeler" label="İşletme bilgilerine git" icon={Building2} />
          <QuickActionLink href="/sahip/menuler" label="Menüleri yönet" icon={LayoutGrid} />
        </nav>
      </PanelBolumKarti>

      <PanelBolumKarti title="Entegrasyonlar" noPadding>
        <ul className="divide-y divide-border">
          {integrations.map((integration) => {
            const Icon = integration.icon;
            return (
              <li key={integration.label} className="flex min-h-11 items-center gap-3 px-5 py-2.5">
                <Icon aria-hidden="true" className="h-4 w-4 shrink-0 text-muted" />
                <span className="min-w-0 flex-1 truncate text-xs font-[700] text-textStrong">
                  {integration.label}
                </span>
                {integration.url ? (
                  <a
                    href={integration.url}
                    target="_blank"
                    rel="noreferrer"
                    aria-label={`${integration.label} bağlantısını yeni sekmede aç`}
                    className="inline-flex min-h-11 items-center gap-1.5 rounded-lg px-2 text-xs font-[800] text-success transition-colors hover:bg-success/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-success/30"
                  >
                    Bağlı
                    <ExternalLink aria-hidden="true" className="h-3.5 w-3.5" />
                  </a>
                ) : (
                  <span className="text-xs font-[700] text-muted">Eklenmedi</span>
                )}
              </li>
            );
          })}
        </ul>
      </PanelBolumKarti>

      <PanelBolumKarti title="Tehlikeli Bölge" className="border-danger/30">
        <div className="flex gap-3">
          <TriangleAlert aria-hidden="true" className="mt-0.5 h-5 w-5 shrink-0 text-danger" />
          <div>
            <p className="text-sm font-[800] text-textStrong">İşletmeyi devre dışı bırak</p>
            <p className="mt-1 text-xs text-muted">
              İşletme pasif duruma alınır. Bu işlem işletme kaydını veya hesabınızı silmez.
            </p>
          </div>
        </div>

        {!business.is_active ? (
          <p className="mt-4 rounded-lg bg-cardAlt px-3 py-2 text-xs font-[700] text-muted">
            Bu işletme zaten devre dışı.
          </p>
        ) : !isConfirming ? (
          <PanelActionButton
            type="button"
            variant="danger"
            onClick={() => setIsConfirming(true)}
            className="mt-4 min-h-11 w-full justify-center"
          >
            İşletmeyi Devre Dışı Bırak
          </PanelActionButton>
        ) : (
          <div className="mt-4 border-t border-danger/20 pt-4">
            <label htmlFor="deactivate-confirmation" className="text-xs font-[700] text-textStrong">
              Onaylamak için <span className="font-[900]">{business.name}</span> yazın
            </label>
            <input
              id="deactivate-confirmation"
              value={confirmation}
              onChange={(event) => setConfirmation(event.target.value)}
              disabled={isPending}
              autoComplete="off"
              className="mt-2 min-h-11 w-full rounded-xl border border-border bg-bg px-3 text-sm text-textStrong outline-none transition-colors focus:border-danger focus:ring-2 focus:ring-danger/20 disabled:opacity-60"
            />
            {error ? (
              <p role="alert" className="mt-2 text-xs font-[700] text-danger">
                {error}
              </p>
            ) : null}
            <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2 xl:grid-cols-1 2xl:grid-cols-2">
              <PanelActionButton
                type="button"
                variant="secondary"
                disabled={isPending}
                onClick={() => {
                  setIsConfirming(false);
                  setConfirmation('');
                  setError('');
                }}
                className="min-h-11 justify-center"
              >
                Vazgeç
              </PanelActionButton>
              <PanelActionButton
                type="button"
                variant="danger"
                disabled={!confirmationMatches}
                loading={isPending}
                onClick={handleDeactivate}
                className="min-h-11 justify-center"
              >
                {isPending ? 'Devre Dışı Bırakılıyor' : 'Onayla'}
              </PanelActionButton>
            </div>
          </div>
        )}
      </PanelBolumKarti>
    </div>
  );
}

function QuickActionLink({
  href,
  label,
  icon: Icon,
  external = false,
}: {
  href: string;
  label: string;
  icon: LucideIcon;
  external?: boolean;
}) {
  return (
    <Link
      href={href}
      target={external ? '_blank' : undefined}
      rel={external ? 'noreferrer' : undefined}
      className="flex min-h-11 items-center gap-3 px-5 py-2.5 text-xs font-[700] text-textStrong transition-colors hover:bg-cardAlt focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary/30"
    >
      <Icon aria-hidden="true" className="h-4 w-4 shrink-0 text-muted" />
      <span className="min-w-0 flex-1">{label}</span>
      {external ? (
        <ExternalLink aria-hidden="true" className="h-3.5 w-3.5 shrink-0 text-muted" />
      ) : (
        <ChevronRight aria-hidden="true" className="h-4 w-4 shrink-0 text-muted" />
      )}
    </Link>
  );
}

function getInitials(value: string) {
  return value
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part.charAt(0).toLocaleUpperCase('tr-TR'))
    .join('');
}

function getSafeHttpUrl(value: string | null) {
  if (!value) return null;

  try {
    const url = new URL(value);
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.toString() : null;
  } catch {
    return null;
  }
}
