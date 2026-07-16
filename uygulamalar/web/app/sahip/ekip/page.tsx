import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { addTeamMember } from './ekip-islemleri';
import { EkipListesi, type EkipUyesi } from './ekip-listesi';
import { ROLE_LABELS, ROLE_DESCRIPTIONS, permissionsForRole } from './ekip-sabitleri';

export const metadata: Metadata = {
  title: 'Ekip | Sahip Paneli',
  robots: { index: false, follow: false },
};

const STATUS_MESSAGES: Record<string, { text: string; className: string }> = {
  eklendi: { text: 'Ekip üyesi eklendi veya davet güncellendi.', className: 'border-success/25 bg-success/[0.08] text-success' },
  gecersiz: { text: 'E-posta, işletme veya rol bilgisi eksik.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  yetkisiz: { text: 'Bu işletme için ekip yönetimi yetkiniz yok.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  forbidden: { text: 'Bu işletme için ekip yönetimi yetkiniz yok.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  email_required: { text: 'Geçerli bir e-posta girin.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  invalid_role: { text: 'Geçerli bir rol seçin.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  hata: { text: 'Ekip üyesi eklenemedi. Tekrar deneyin.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
};

type Props = {
  searchParams?: Promise<{ durum?: string }>;
};

type TeamMemberRpcRow = {
  membership_id: string | null;
  user_id: string | null;
  email: string | null;
  role: string;
  scope: string;
  status: string;
  source: string;
  created_at: string;
  accepted_at: string | null;
};

export default async function OwnerTeamPage({ searchParams }: Props) {
  const params = await searchParams;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b) => b.id);

  const memberGroups = await Promise.all(
    businesses.map(async (business) => {
      let data: TeamMemberRpcRow[] = [];
      try {
        const result = await (supabase as any).rpc('list_team_members_v1', {
          p_business_id: business.id,
        });
        data = result.data ?? [];
      } catch {
        data = [];
      }

      return data.map((m): EkipUyesi => ({
        key: `${business.id}-${m.membership_id ?? m.user_id ?? m.email}`,
        membershipId: m.membership_id,
        userId: m.user_id,
        email: m.email,
        role: m.role,
        status: m.status === 'active' ? 'active' : 'pending',
        source: m.source,
        createdAt: m.created_at,
        businessId: business.id,
        businessName: business.name,
        permissionCount: permissionsForRole(m.role).length,
        manageable: m.source === 'team_membership' && !!m.membership_id,
      }));
    }),
  );
  const list = memberGroups.flat();
  const statusMessage = params?.durum ? STATUS_MESSAGES[params.durum] : null;

  const activeCount = list.filter((m) => m.status === 'active').length;
  const pendingCount = list.filter((m) => m.status === 'pending').length;
  const managerCount = list.filter((m) => m.role === 'owner' || m.role === 'manager').length;
  const staffCount = list.length - managerCount;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Ekip"
        description="İşletmenizdeki ekip üyelerini ve rollerini yönetin."
        actions={
          businesses.length > 0 ? (
            <a
              href="#davet-formu"
              className="btn-primary inline-flex min-h-[40px] items-center justify-center rounded-xl px-4 text-sm font-[800] text-white"
            >
              + Üye Davet Et
            </a>
          ) : undefined
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {statusMessage && (
          <div className={`mb-4 rounded-xl border px-4 py-3 text-sm font-[700] ${statusMessage.className}`}>
            {statusMessage.text}
          </div>
        )}

        {/* İstatistikler */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <StatCard icon={<UsersIcon />} iconBg="bg-blue-50 text-blue-600" label="Toplam Üye" value={String(list.length)} subtitle={list.length > 0 ? `Aktif ${activeCount}` : undefined} />
          <StatCard icon={<ShieldIcon />} iconBg="bg-purple-50 text-purple-600" label="Yönetici" value={String(managerCount)} subtitle="Sahip dahil" />
          <StatCard icon={<UserIcon />} iconBg="bg-green-50 text-green-600" label="Personel" value={String(staffCount)} />
          <StatCard icon={<ClockIcon />} iconBg="bg-orange-50 text-orange-600" label="Bekleyen Davet" value={String(pendingCount)} subtitle={pendingCount > 0 ? 'Davet gönderildi' : undefined} />
        </div>

        <div className="mt-6 grid gap-6 lg:grid-cols-[1fr_320px]">
          {/* Sol: ekip listesi */}
          <div className="min-w-0">
            {businesses.length === 0 ? (
              <PanelEmptyState
                icon={<UsersIcon />}
                title="İşletme bulunamadı"
                description="Ekip üyesi eklemek için önce işletme sahibi olmanız gerekiyor."
              />
            ) : list.length === 0 ? (
              <PanelEmptyState
                icon={<UsersIcon />}
                title="Ekip üyesi yok"
                description="Sağdaki formdan ekip üyesi davet edebilirsiniz."
              />
            ) : (
              <EkipListesi members={list} showBusinessColumn={businessIds.length > 1} />
            )}
          </div>

          {/* Sağ: davet formu + rol tanımları */}
          <div className="flex flex-col gap-4">
            <div id="davet-formu" className="scroll-mt-6 rounded-2xl border border-border bg-card p-4">
              <p className="mb-1 text-sm font-[800] text-textStrong">Davet Et</p>
              <p className="mb-3 text-[11px] text-muted">Ekip arkadaşlarınızı e-posta ile davet edin.</p>
              {businesses.length === 0 ? (
                <p className="text-xs text-muted">Davet göndermek için önce işletme sahibi olmanız gerekiyor.</p>
              ) : (
                <form action={addTeamMember} className="flex flex-col gap-3">
                  {businesses.length > 1 ? (
                    <select
                      name="businessId"
                      required
                      className="min-h-[40px] rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                    >
                      {businesses.map((business) => (
                        <option key={business.id} value={business.id}>{business.name}</option>
                      ))}
                    </select>
                  ) : (
                    <input type="hidden" name="businessId" value={businesses[0].id} />
                  )}
                  <input
                    name="email"
                    type="email"
                    required
                    placeholder="E-posta adresi girin…"
                    className="min-h-[40px] rounded-xl border border-border bg-bg px-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                  />
                  <select
                    name="role"
                    defaultValue="staff"
                    className="min-h-[40px] rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                  >
                    <option value="manager">Yönetici</option>
                    <option value="editor">Editör</option>
                    <option value="staff">Personel</option>
                    <option value="viewer">İzleyici</option>
                  </select>
                  <button
                    type="submit"
                    className="btn-primary inline-flex min-h-[40px] cursor-pointer items-center justify-center rounded-xl px-5 text-sm font-[900] text-white"
                  >
                    Davet Gönder
                  </button>
                </form>
              )}
            </div>

            <div className="rounded-2xl border border-border bg-card p-4">
              <p className="mb-3 text-sm font-[800] text-textStrong">Rol Tanımları</p>
              <div className="flex flex-col gap-3">
                {(['owner', 'manager', 'editor', 'staff', 'viewer'] as const).map((role) => (
                  <div key={role} className="flex items-start gap-2.5">
                    <span className={`mt-0.5 shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[800] ${ROLE_LABELS[role].className}`}>
                      {ROLE_LABELS[role].label}
                    </span>
                    <p className="flex-1 text-[12px] text-muted">{ROLE_DESCRIPTIONS[role]}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Shift Scheduler */}
        <PanelBolumKarti title="Vardiya Planı (Bu Hafta)" className="mt-6">
          <ShiftScheduler members={list} />
        </PanelBolumKarti>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function StatCard({
  icon,
  iconBg,
  label,
  value,
  subtitle,
}: {
  icon: React.ReactNode;
  iconBg: string;
  label: string;
  value: string;
  subtitle?: string;
}) {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-border bg-card p-4">
      <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${iconBg}`}>{icon}</span>
      <div className="min-w-0">
        <p className="text-[11px] font-[700] uppercase tracking-wide text-muted">{label}</p>
        <p className="mt-0.5 truncate text-lg font-[900] text-textStrong">{value}</p>
        {subtitle && <p className="text-[11px] text-muted">{subtitle}</p>}
      </div>
    </div>
  );
}

const DAYS = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const SHIFTS = ['Sabah (07-15)', 'Öğle (11-19)', 'Akşam (15-23)', 'Gece (23-07)'];

function ShiftScheduler({ members }: { members: EkipUyesi[] }) {
  if (members.length === 0) return (
    <p className="py-6 text-center text-sm text-muted">Ekip üyesi eklendikten sonra vardiya planlayabilirsiniz.</p>
  );

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full text-xs">
        <thead>
          <tr className="border-b border-border">
            <th className="px-3 py-2 text-left text-[11px] font-[800] uppercase tracking-wide text-muted w-32">Personel</th>
            {DAYS.map(d => (
              <th key={d} className="px-2 py-2 text-center text-[11px] font-[800] uppercase tracking-wide text-muted">{d}</th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {members.filter((member) => member.role !== 'owner').slice(0, 8).map((m) => (
            <tr key={m.key} className="hover:bg-black/[0.02]">
              <td className="px-3 py-2 font-[700] text-textStrong">
                <p className="truncate max-w-[120px]">{m.email ?? '—'}</p>
                <p className="text-[10px] text-muted">{ROLE_LABELS[m.role]?.label ?? m.role}</p>
              </td>
              {DAYS.map((d) => (
                <td key={d} className="px-1 py-1.5 text-center">
                  <select
                    className="w-full rounded border border-border bg-surface py-0.5 text-[10px] text-textStrong focus:border-primary focus:outline-none"
                    defaultValue=""
                    aria-label={`${m.email ?? ''} ${d} vardiyası`}
                  >
                    <option value="">—</option>
                    {SHIFTS.map(s => <option key={s} value={s}>{s.split(' ')[0]}</option>)}
                  </select>
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      <p className="mt-3 text-xs text-muted">Not: Vardiya kayıt entegrasyonu yakında aktif olacak.</p>
    </div>
  );
}

function UsersIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
function ShieldIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" /></svg>;
}
function UserIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>;
}
function ClockIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>;
}
