'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useMemo, useRef, useState } from 'react';
import { clsx } from 'clsx';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { addTeamMember } from './ekip-islemleri';
import { EkipUyeSatiriAksiyonlari } from './ekip-uye-satiri-aksiyonlari';
import { ROL_TANIMI, ROL_OZET_ETIKETI, rolYetkiSayisi, type EkipRolu } from './ekip-yetkiler';

export interface EkipUyesi {
  membershipId: string | null;
  userId: string | null;
  email: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  phone: string | null;
  role: EkipRolu;
  status: 'active' | 'pending';
  source: string;
  createdAt: string;
  acceptedAt: string | null;
}

const ROLE_BADGE: Record<EkipRolu, string> = {
  owner: 'bg-primary/10 text-primary',
  manager: 'bg-purple-50 text-purple-700',
  editor: 'bg-blue-50 text-blue-700',
  staff: 'bg-blue-50 text-blue-700',
  viewer: 'bg-zinc-100 text-zinc-600',
};

const ROLE_LABEL: Record<EkipRolu, string> = {
  owner: 'Sahip',
  manager: 'Yönetici',
  editor: 'Editör',
  staff: 'Personel',
  viewer: 'Kısıtlı',
};

const PAGE_SIZE = 8;
type Sekme = 'tumu' | 'aktif' | 'bekleyen';

export function EkipIstemcisi({
  businessId,
  businessName,
  initialUyeler,
  statusMessage,
}: {
  businessId: string;
  businessName: string;
  initialUyeler: EkipUyesi[];
  statusMessage: { text: string; className: string } | null;
}) {
  const [uyeler, setUyeler] = useState(initialUyeler);
  const [sekme, setSekme] = useState<Sekme>('tumu');
  const [arama, setArama] = useState('');
  const [rolFiltre, setRolFiltre] = useState<'tumu' | EkipRolu>('tumu');
  const [sayfa, setSayfa] = useState(1);
  const davetEmailRef = useRef<HTMLInputElement>(null);

  const toplam = uyeler.length;
  const yoneticiSayisi = uyeler.filter((u) => u.role === 'manager').length;
  const personelSayisi = uyeler.filter((u) => u.role === 'editor' || u.role === 'staff').length;
  const bekleyenSayisi = uyeler.filter((u) => u.status === 'pending').length;
  const aktifSayisi = uyeler.filter((u) => u.status === 'active').length;

  const sekmeSecenekleri: { key: Sekme; label: string; count: number }[] = [
    { key: 'tumu', label: 'Tüm Üyeler', count: toplam },
    { key: 'aktif', label: 'Aktif', count: aktifSayisi },
    { key: 'bekleyen', label: 'Bekleyen', count: bekleyenSayisi },
  ];

  const filtreliListe = useMemo(() => {
    let list = uyeler;
    if (sekme === 'aktif') list = list.filter((u) => u.status === 'active');
    if (sekme === 'bekleyen') list = list.filter((u) => u.status === 'pending');
    if (rolFiltre !== 'tumu') list = list.filter((u) => u.role === rolFiltre);
    const q = arama.trim().toLocaleLowerCase('tr-TR');
    if (q) {
      list = list.filter(
        (u) =>
          (u.displayName ?? '').toLocaleLowerCase('tr-TR').includes(q) ||
          (u.email ?? '').toLocaleLowerCase('tr-TR').includes(q) ||
          (u.phone ?? '').includes(q),
      );
    }
    return list;
  }, [uyeler, sekme, rolFiltre, arama]);

  const sayfaSayisi = Math.max(1, Math.ceil(filtreliListe.length / PAGE_SIZE));
  const guvenliSayfa = Math.min(sayfa, sayfaSayisi);
  const sayfadakiListe = filtreliListe.slice((guvenliSayfa - 1) * PAGE_SIZE, guvenliSayfa * PAGE_SIZE);

  function odakDavetForm() {
    davetEmailRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    davetEmailRef.current?.focus();
  }

  return (
    <div className="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_320px]">
      <div className="flex min-w-0 flex-col gap-5">
        <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-2xl font-black tracking-tight text-textStrong">Ekip</h1>
            <p className="mt-1 text-sm text-muted">{businessName} işletmenizdeki ekip üyelerinizi ve rollerini yönetin.</p>
          </div>
          <button
            type="button"
            onClick={odakDavetForm}
            className="inline-flex items-center gap-2 self-start rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
            style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
          >
            <PlusIcon /> Üye Davet Et
          </button>
        </div>

        {statusMessage && (
          <div className={`rounded-xl border px-4 py-3 text-sm font-bold ${statusMessage.className}`}>
            {statusMessage.text}
          </div>
        )}

        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <MetricCard title="Toplam Üye" value={toplam} subtitle={`Aktif ${aktifSayisi}`} tone="primary" icon={<UsersIcon />} />
          <MetricCard title="Yönetici" value={yoneticiSayisi} subtitle="Sahip dahil" tone="purple" icon={<ShieldIcon />} />
          <MetricCard title="Personel" value={personelSayisi} subtitle="Aktif" tone="blue" icon={<UserIcon />} />
          <MetricCard title="Bekleyen Davet" value={bekleyenSayisi} subtitle="Davet gönderildi" tone="orange" icon={<ClockIcon />} />
        </div>

        <div className="flex flex-wrap gap-1 border-b border-border">
          {sekmeSecenekleri.map((s) => (
            <button
              key={s.key}
              type="button"
              onClick={() => { setSekme(s.key); setSayfa(1); }}
              className={clsx(
                'flex items-center gap-1.5 border-b-2 px-3 py-2.5 text-sm font-extrabold transition-colors',
                sekme === s.key ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong',
              )}
            >
              {s.label} <span className="text-xs font-semibold text-muted">({s.count})</span>
            </button>
          ))}
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <div className="relative min-w-[220px] flex-1">
            <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
            <input
              value={arama}
              onChange={(e) => { setArama(e.target.value); setSayfa(1); }}
              placeholder="Üye adı, e-posta veya telefon ara..."
              className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
            />
          </div>
          <select
            value={rolFiltre}
            onChange={(e) => { setRolFiltre(e.target.value as typeof rolFiltre); setSayfa(1); }}
            className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-primary"
          >
            <option value="tumu">Tüm Roller</option>
            {(Object.keys(ROLE_LABEL) as EkipRolu[]).map((r) => (
              <option key={r} value={r}>{ROLE_LABEL[r]}</option>
            ))}
          </select>
        </div>

        <div className="overflow-x-auto rounded-2xl border border-border bg-card shadow-xs">
          <table className="w-full min-w-[820px] border-collapse text-sm">
            <thead>
              <tr className="border-b border-border bg-black/2 text-left text-xs font-extrabold uppercase tracking-wide text-muted">
                <th className="px-4 py-3">Üye</th>
                <th className="px-4 py-3">Rol</th>
                <th className="px-4 py-3">Yetkiler</th>
                <th className="px-4 py-3">Durum</th>
                <th className="px-4 py-3">Katılım Tarihi</th>
                <th className="px-4 py-3 text-right">İşlemler</th>
              </tr>
            </thead>
            <tbody>
              {sayfadakiListe.map((u, index) => {
                const key = u.membershipId ?? u.userId ?? u.email ?? `row-${index}`;
                const ad = u.displayName ?? u.email ?? '—';
                const baslangicHarfleri = ad
                  .split(' ')
                  .map((p) => p.charAt(0))
                  .join('')
                  .slice(0, 2)
                  .toUpperCase();
                return (
                  <tr key={key} className="border-b border-border last:border-0 hover:bg-black/2">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10">
                          {u.avatarUrl ? (
                            <Image src={u.avatarUrl} alt={ad} fill className="object-cover" sizes="40px" />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center text-xs font-black text-primary">
                              {baslangicHarfleri || '—'}
                            </div>
                          )}
                        </div>
                        <div className="min-w-0">
                          <div className="flex items-center gap-1.5">
                            <p className="truncate font-bold text-textStrong">{ad}</p>
                            <span className={clsx('shrink-0 rounded-full px-1.5 py-0.5 text-[10px] font-extrabold', ROLE_BADGE[u.role])}>
                              {ROLE_LABEL[u.role]}
                            </span>
                          </div>
                          {u.displayName && u.email && <p className="truncate text-xs text-muted">{u.email}</p>}
                          {u.phone && <p className="truncate text-xs text-muted">{u.phone}</p>}
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-0.5">
                        <span className={clsx('w-fit rounded-full px-2.5 py-1 text-[11px] font-extrabold', ROLE_BADGE[u.role])}>
                          {ROLE_LABEL[u.role]}
                        </span>
                        <span className="text-[11px] text-muted">{ROL_OZET_ETIKETI[u.role]}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 font-bold text-textStrong">{rolYetkiSayisi(u.role)} yetki</td>
                    <td className="px-4 py-3">
                      <span
                        className={clsx(
                          'inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-extrabold',
                          u.status === 'active' ? 'bg-emerald-50 text-emerald-600' : 'bg-amber-50 text-amber-600',
                        )}
                      >
                        <span className={clsx('h-1.5 w-1.5 rounded-full', u.status === 'active' ? 'bg-emerald-500' : 'bg-amber-500')} />
                        {u.status === 'active' ? 'Aktif' : 'Bekliyor'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted">
                      {u.status === 'pending' ? (
                        <>Davet gönderildi<br />{formatTarih(u.createdAt)}</>
                      ) : (
                        <>Katıldı<br />{formatTarih(u.acceptedAt ?? u.createdAt)}</>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {u.source === 'team_membership' ? (
                        <EkipUyeSatiriAksiyonlari
                          businessId={businessId}
                          email={u.email ?? ''}
                          role={u.role}
                          membershipId={u.membershipId}
                          onRemoved={() => setUyeler((prev) => prev.filter((x) => x.membershipId !== u.membershipId))}
                          onRoleChanged={(newRole) =>
                            setUyeler((prev) => prev.map((x) => (x.membershipId === u.membershipId ? { ...x, role: newRole } : x)))
                          }
                        />
                      ) : (
                        <span className="text-[11px] text-muted">—</span>
                      )}
                    </td>
                  </tr>
                );
              })}

              {sayfadakiListe.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-sm text-muted">
                    {toplam === 0 ? 'Henüz ekip üyeniz yok.' : 'Aramanızla eşleşen üye bulunamadı.'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {sayfaSayisi > 1 && (
          <div className="flex items-center justify-between text-sm">
            <p className="text-muted">Toplam {filtreliListe.length} üye</p>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                disabled={guvenliSayfa === 1}
                onClick={() => setSayfa((p) => Math.max(1, p - 1))}
                className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4"
              >
                Önceki
              </button>
              {Array.from({ length: sayfaSayisi }, (_, i) => i + 1).map((n) => (
                <button
                  key={n}
                  type="button"
                  onClick={() => setSayfa(n)}
                  className={clsx(
                    'h-8 w-8 rounded-lg font-bold',
                    n === guvenliSayfa ? 'text-white' : 'border border-border text-textStrong hover:bg-black/4',
                  )}
                  style={n === guvenliSayfa ? { background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' } : undefined}
                >
                  {n}
                </button>
              ))}
              <button
                type="button"
                disabled={guvenliSayfa === sayfaSayisi}
                onClick={() => setSayfa((p) => Math.min(sayfaSayisi, p + 1))}
                className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4"
              >
                Sonraki
              </button>
            </div>
          </div>
        )}

        <div className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left" style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}>
          <div>
            <p className="font-black text-textStrong">Doğru yetki, güçlü işletme</p>
            <p className="text-sm text-muted">Ekip üyelerinize sadece ihtiyaç duydukları yetkileri vererek hem güvenliği artırın hem de iş akışınızı hızlandırın.</p>
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-4">
        <div className="rounded-2xl border border-border bg-card p-5">
          <h3 className="mb-1 text-sm font-black text-textStrong">Davet Et</h3>
          <p className="mb-4 text-xs text-muted">Ekip arkadaşlarınızı e-posta ile davet edin.</p>
          <form action={addTeamMember} className="flex flex-col gap-3">
            <input type="hidden" name="businessId" value={businessId} />
            <input
              ref={davetEmailRef}
              name="email"
              type="email"
              required
              placeholder="E-posta adresi girin..."
              className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
            />
            <label className="flex flex-col gap-1.5">
              <span className="text-xs font-extrabold text-muted">Rol seçin</span>
              <select
                name="role"
                defaultValue="staff"
                className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-bold text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
              >
                <option value="manager">Yönetici</option>
                <option value="editor">Editör</option>
                <option value="staff">Personel</option>
                <option value="viewer">Kısıtlı</option>
              </select>
            </label>
            <button
              type="submit"
              className="mt-1 inline-flex min-h-11 items-center justify-center gap-2 rounded-xl px-4 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
            >
              <SendIcon /> Davet Gönder
            </button>
          </form>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5">
          <h3 className="mb-3 text-sm font-black text-textStrong">Rol Tanımları</h3>
          <div className="flex flex-col gap-3">
            {(Object.keys(ROLE_LABEL) as EkipRolu[]).map((r) => (
              <div key={r} className="flex items-start gap-2.5">
                <span className={clsx('mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-lg text-[10px] font-black', ROLE_BADGE[r])}>
                  {ROLE_LABEL[r].charAt(0)}
                </span>
                <div className="min-w-0">
                  <p className="text-xs font-extrabold text-textStrong">{ROLE_LABEL[r]}</p>
                  <p className="text-[11px] text-muted">{ROL_TANIMI[r]}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5">
          <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
          <Link
            href="/sahip/denetim-kaydi"
            className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-sm font-bold text-textStrong transition-colors hover:bg-black/4"
          >
            Ekip Aktivite Logu
            <ChevronRightIcon />
          </Link>
        </div>
      </div>
    </div>
  );
}

function formatTarih(iso: string): string {
  return new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });
}

function PlusIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M12 5v14M5 12h14" />
    </svg>
  );
}
function SendIcon() {
  return (
    <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m22 2-7 20-4-9-9-4Z" /><path d="M22 2 11 13" />
    </svg>
  );
}
function SearchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}>
      <circle cx="11" cy="11" r="7" />
      <path d="m21 21-4.35-4.35" />
    </svg>
  );
}
function UsersIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
function ShieldIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
    </svg>
  );
}
function UserIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}
function ClockIcon() {
  return (
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 3" />
    </svg>
  );
}
function ChevronRightIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}
