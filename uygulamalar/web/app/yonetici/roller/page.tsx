import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { trend, goreliZaman, type AdminRole } from './roller-yardimcilari';
import { RolTablosu } from './rol-tablosu';
import { YeniRolButonu } from './rol-modal';
import { DisaAktarButonu } from './disa-aktar-butonu';

export const metadata: Metadata = {
  title: 'Roller | Yönetici Paneli',
  robots: { index: false, follow: false },
};

const DAY = 86_400_000;

type Props = { searchParams: Promise<{ q?: string; durum?: string }> };

export default async function RollerPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:roller');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Roller" description="Kullanıcı rollerini yönetin ve her rol için izinleri tanımlayın." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Roller" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', durum = '' } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const [{ data: rawRoles }, { data: rawMembers }] = await Promise.all([
    sb.from('admin_roles').select('id, name, description, is_system, is_active, permissions, created_at, updated_at, updated_by').order('created_at', { ascending: true }),
    sb.from('admin_users').select('user_id, role_id, created_at'),
  ]);

  const roles = (rawRoles ?? []) as Array<Omit<AdminRole, 'userCount' | 'updated_by_name'>>;
  const members = (rawMembers ?? []) as Array<{ user_id: string; role_id: string; created_at: string }>;

  const countByRole = new Map<string, number>();
  for (const m of members) countByRole.set(m.role_id, (countByRole.get(m.role_id) ?? 0) + 1);

  const updaterIds = Array.from(new Set(roles.map((r) => r.updated_by).filter((v): v is string => !!v)));
  const memberIds = Array.from(new Set(members.map((m) => m.user_id)));
  const profileIds = Array.from(new Set([...updaterIds, ...memberIds]));
  const nameByUserId = new Map<string, string>();
  if (profileIds.length > 0) {
    const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', profileIds);
    for (const p of (profiles ?? []) as Array<{ user_id: string; display_name: string | null }>) {
      if (p.display_name) nameByUserId.set(p.user_id, p.display_name);
    }
  }

  const withCounts: AdminRole[] = roles.map((r) => ({
    ...r,
    userCount: countByRole.get(r.id) ?? 0,
    updated_by_name: r.updated_by ? nameByUserId.get(r.updated_by) ?? null : null,
  }));

  const qNorm = q.trim().toLocaleLowerCase('tr-TR');
  const filtered = withCounts.filter((r) => {
    if (durum === 'aktif' && !r.is_active) return false;
    if (durum === 'pasif' && r.is_active) return false;
    if (qNorm) {
      const hay = `${r.name} ${r.description ?? ''}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });

  const total = withCounts.length;
  const activeCount = withCounts.filter((r) => r.is_active).length;
  const systemCount = withCounts.filter((r) => r.is_system).length;
  const customCount = total - systemCount;
  const assignedUserCount = members.length;

  const now = Date.now();
  const thisWeek = withCounts.filter((r) => new Date(r.updated_at).getTime() >= now - 7 * DAY).length;
  const lastWeek = withCounts.filter((r) => {
    const ts = new Date(r.updated_at).getTime();
    return ts >= now - 14 * DAY && ts < now - 7 * DAY;
  }).length;

  const sonGuncellenen = [...withCounts].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())[0];

  const turDagilimi: Array<[string, number, string]> = ([
    ['Sistem', systemCount, '#7c3aed'],
    ['Özel', customCount, '#2563eb'],
  ] as Array<[string, number, string]>).filter(([, n]) => n > 0);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Roller"
        description="Kullanıcı rollerini yönetin ve her rol için izinleri tanımlayın."
        actions={<YeniRolButonu />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Rol" value={total.toLocaleString('tr-TR')} icon={<UsersIcon />} />
            <MetricCard title="Aktif Rol" value={activeCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((activeCount / total) * 100)}` : undefined} icon={<CheckIcon />} trend={trend(thisWeek, lastWeek)} />
            <MetricCard title="Sistem Rolü" value={systemCount.toLocaleString('tr-TR')} subtitle="Sistem tarafından tanımlı" icon={<LockIcon />} />
            <MetricCard title="Özel Rol" value={customCount.toLocaleString('tr-TR')} subtitle="Özel olarak oluşturulmuş" icon={<PlusIcon />} />
            <MetricCard title="Kullanıcı Atanan" value={assignedUserCount.toLocaleString('tr-TR')} subtitle="Toplam admin kullanıcı" icon={<ShieldIcon />} />
            <MetricCard title="Son Güncelleme" value={sonGuncellenen ? goreliZaman(sonGuncellenen.updated_at) : '—'} subtitle={sonGuncellenen?.updated_by_name ?? undefined} icon={<ClockIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-3">
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Rol adı, açıklama ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="durum" defaultValue={durum} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Durum: Tümü</option>
                  <option value="aktif">Aktif</option>
                  <option value="pasif">Pasif</option>
                </select>
                <div className="flex gap-2 md:col-span-3">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/roller" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  <div className="ml-auto"><DisaAktarButonu rows={filtered} /></div>
                </div>
              </form>

              {filtered.length === 0 ? (
                <PanelEmptyState
                  icon={<UsersIcon />}
                  title={total === 0 ? 'Henüz rol yok' : 'Sonuç bulunamadı'}
                  description={total === 0 ? 'Sistem kurulumunda Süper Admin rolü otomatik oluşturulur.' : 'Seçili filtrelere uygun rol yok.'}
                />
              ) : (
                <RolTablosu roles={filtered} members={members} nameByUserId={Object.fromEntries(nameByUserId)} />
              )}
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Rol Türlerine Göre Dağılım">
                {turDagilimi.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <Donut veriler={turDagilimi} toplam={total} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Rol Durumuna Göre Dağılım">
                <div className="flex flex-col gap-3">
                  {([['Aktif', activeCount, '#059669'], ['Pasif', total - activeCount, '#94a3b8']] as Array<[string, number, string]>).map(([label, n, renk]) => (
                    <div key={label} className="flex flex-col gap-1">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold text-textStrong">{label}</span>
                        <span className="font-extrabold text-muted">{n} {total ? `(%${Math.round((n / total) * 100)})` : ''}</span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-black/8">
                        <div className="h-full rounded-full" style={{ width: `${total ? (n / total) * 100 : 0}%`, background: renk }} />
                      </div>
                    </div>
                  ))}
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <YeniRolButonu variant="list" />
                  <p className="rounded-xl border border-border px-3 py-2.5 text-[10px] text-muted">
                    Bir rolün kullanıcı sayısına tıklayarak o role atanmış kullanıcıları görüp başka role taşıyabilirsiniz.
                  </p>
                </div>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function Donut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE} strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n, renk]) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: renk }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>; }
function LockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>; }
function PlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
