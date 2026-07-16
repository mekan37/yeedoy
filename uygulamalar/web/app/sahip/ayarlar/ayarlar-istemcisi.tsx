'use client';

import { useRef, useState, type KeyboardEvent } from 'react';
import { BildirimAyarlariSekmesi } from './sekmeler/bildirim-ayarlari-sekmesi';
import { GizlilikGuvenlikSekmesi } from './sekmeler/gizlilik-guvenlik-sekmesi';
import { HesapAyarlariSekmesi } from './sekmeler/hesap-ayarlari-sekmesi';
import { IsletmeProfiliSekmesi } from './sekmeler/isletme-profili-sekmesi';
import { RezervasyonAyarlariSekmesi } from './sekmeler/rezervasyon-ayarlari-sekmesi';
import { AyarlarSagMenu } from './ayarlar-sag-menu';
import type { WeeklyHourRow } from './saatler/saatler-formu';

export type SettingsTab =
  | 'profile'
  | 'account'
  | 'notifications'
  | 'reservations'
  | 'privacy';

export interface BusinessData {
  id: string;
  name: string;
  category: string;
  description: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  logo_url: string | null;
  cover_url: string | null;
  is_active: boolean;
  slug: string | null;
  website_url: string | null;
  instagram_url: string | null;
  facebook_url: string | null;
  twitter_url: string | null;
  accepts_reservations: boolean;
  reservation_phone: string | null;
  reservation_min_party: number | null;
  reservation_max_party: number | null;
  reservation_note: string | null;
}

export interface UserData {
  id: string;
  email: string;
  displayName: string;
}

const TABS: ReadonlyArray<{ id: SettingsTab; label: string }> = [
  { id: 'profile', label: 'İşletme Profili' },
  { id: 'account', label: 'Hesap Ayarları' },
  { id: 'notifications', label: 'Bildirim Ayarları' },
  { id: 'reservations', label: 'Rezervasyon Ayarları' },
  { id: 'privacy', label: 'Gizlilik & Güvenlik' },
];

interface AyarlarIstemcisiProps {
  user: UserData;
  business: BusinessData;
  hours: WeeklyHourRow[];
}

export function AyarlarIstemcisi({ user, business, hours }: AyarlarIstemcisiProps) {
  const [activeTab, setActiveTab] = useState<SettingsTab>('profile');
  const tabRefs = useRef<Array<HTMLButtonElement | null>>([]);

  function selectTab(index: number) {
    const nextIndex = (index + TABS.length) % TABS.length;
    setActiveTab(TABS[nextIndex].id);
    tabRefs.current[nextIndex]?.focus();
  }

  function handleTabKeyDown(event: KeyboardEvent<HTMLButtonElement>, index: number) {
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      selectTab(index + 1);
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault();
      selectTab(index - 1);
    } else if (event.key === 'Home') {
      event.preventDefault();
      selectTab(0);
    } else if (event.key === 'End') {
      event.preventDefault();
      selectTab(TABS.length - 1);
    }
  }

  return (
    <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_18rem] xl:gap-7">
      <div className="min-w-0">
        <div
          role="tablist"
          aria-label="Ayar bölümleri"
          className="flex overflow-x-auto border-b border-border"
        >
          {TABS.map((tab, index) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                ref={(node) => { tabRefs.current[index] = node; }}
                id={`settings-tab-${tab.id}`}
                type="button"
                role="tab"
                aria-selected={isActive}
                aria-controls={`settings-panel-${tab.id}`}
                tabIndex={isActive ? 0 : -1}
                onClick={() => setActiveTab(tab.id)}
                onKeyDown={(event) => handleTabKeyDown(event, index)}
                className={`-mb-px min-h-11 shrink-0 border-b-2 px-4 text-sm font-[700] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 focus-visible:ring-inset ${
                  isActive
                    ? 'border-primary text-primary'
                    : 'border-transparent text-muted hover:text-textStrong'
                }`}
              >
                {tab.label}
              </button>
            );
          })}
        </div>

        <div
          id={`settings-panel-${activeTab}`}
          role="tabpanel"
          aria-labelledby={`settings-tab-${activeTab}`}
          tabIndex={0}
          className="pt-5 outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
        >
          {activeTab === 'profile' && (
            <IsletmeProfiliSekmesi business={business} hours={hours} />
          )}
          {activeTab === 'account' && <HesapAyarlariSekmesi user={user} />}
          {activeTab === 'notifications' && <BildirimAyarlariSekmesi />}
          {activeTab === 'reservations' && (
            <RezervasyonAyarlariSekmesi business={business} />
          )}
          {activeTab === 'privacy' && <GizlilikGuvenlikSekmesi />}
        </div>
      </div>

      <aside aria-label="Ayarlar yan bilgileri" className="min-w-0 xl:sticky xl:top-6">
        <AyarlarSagMenu user={user} business={business} />
      </aside>
    </div>
  );
}
