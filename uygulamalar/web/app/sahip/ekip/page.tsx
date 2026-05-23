import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { addTeamMember } from './ekip-islemleri';

export const metadata: Metadata = {
  title: 'Ekip | Sahip Paneli',
  robots: { index: false, follow: false },
};

const ROLE_LABELS: Record<string, { label: string; className: string }> = {
  owner: { label: 'Sahip', className: 'bg-primary/10 text-primary' },
  manager: { label: 'Yönetici', className: 'bg-purple-50 text-purple-700' },
  editor: { label: 'Editör', className: 'bg-blue-50 text-blue-700' },
  staff: { label: 'Personel', className: 'bg-zinc-100 text-zinc-600' },
  viewer: { label: 'İzleyici', className: 'bg-zinc-50 text-zinc-500' },
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

type TeamMember = {
  membership_id: string | null;
  user_id: string | null;
  email: string | null;
  role: string;
  scope: string;
  status: string;
  source: string;
  created_at: string;
  accepted_at: string | null;
  business_id: string;
  business_name: string;
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
      let data: Omit<TeamMember, 'business_id' | 'business_name'>[] = [];
      try {
        const result = await (supabase as any).rpc('list_team_members_v1', {
          p_business_id: business.id,
        });
        data = result.data ?? [];
      } catch {
        data = [];
      }

      return data
        .map((member) => ({
          ...member,
          business_id: business.id,
          business_name: business.name,
        }));
    }),
  );
  const list = memberGroups.flat();
  const statusMessage = params?.durum ? STATUS_MESSAGES[params.durum] : null;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Ekip"
        description="İşletme erişim üyeleri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {statusMessage && (
          <div className={`mb-4 rounded-xl border px-4 py-3 text-sm font-[700] ${statusMessage.className}`}>
            {statusMessage.text}
          </div>
        )}

        <PanelBolumKarti title="Ekip Üyesi Ekle" description="Kayıtlı kullanıcı e-postası girerseniz üyelik aktif olur; değilse davet beklemede kalır.">
          {businesses.length === 0 ? (
            <PanelEmptyState
              icon={<UsersIcon />}
              title="İşletme bulunamadı"
              description="Ekip üyesi eklemek için önce işletme sahibi olmanız gerekiyor."
            />
          ) : (
            <form action={addTeamMember} className="grid gap-3 md:grid-cols-[1fr_1.2fr_180px_auto] md:items-end">
              <label className="flex flex-col gap-1.5">
                <span className="text-xs font-[800] uppercase tracking-wide text-muted">İşletme</span>
                <select
                  name="businessId"
                  className="min-h-[44px] rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                  required
                >
                  {businesses.map((business) => (
                    <option key={business.id} value={business.id}>{business.name}</option>
                  ))}
                </select>
              </label>
              <label className="flex flex-col gap-1.5">
                <span className="text-xs font-[800] uppercase tracking-wide text-muted">E-posta</span>
                <input
                  name="email"
                  type="email"
                  required
                  placeholder="personel@ornek.com"
                  className="min-h-[44px] rounded-xl border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </label>
              <label className="flex flex-col gap-1.5">
                <span className="text-xs font-[800] uppercase tracking-wide text-muted">Rol</span>
                <select
                  name="role"
                  defaultValue="staff"
                  className="min-h-[44px] rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                >
                  <option value="manager">Yönetici</option>
                  <option value="editor">Editör</option>
                  <option value="staff">Personel</option>
                  <option value="viewer">İzleyici</option>
                </select>
              </label>
              <button
                type="submit"
                className="btn-primary inline-flex min-h-[44px] items-center justify-center rounded-xl px-5 text-sm font-[900] text-white"
              >
                Ekle
              </button>
            </form>
          )}
        </PanelBolumKarti>

        {list.length === 0 ? (
          <div className="mt-6">
            <PanelEmptyState
              icon={<UsersIcon />}
              title="Ekip üyesi yok"
              description="Yukarıdaki formdan ekip üyesi ekleyebilirsiniz."
            />
          </div>
        ) : (
          <PanelBolumKarti title="Ekip Üyeleri" noPadding className="mt-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  {businessIds.length > 1 && (
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  )}
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Rol</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Eklenme</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((m) => {
                  const roleConfig = ROLE_LABELS[m.role] ?? ROLE_LABELS.viewer;
                  return (
                    <tr key={`${m.business_id}-${m.membership_id ?? m.user_id ?? m.email}`} className="hover:bg-black/[0.02]">
                      <td className="px-5 py-3">
                        <p className="font-[700] text-textStrong">
                          {m.email ?? '—'}
                        </p>
                        <p className="text-xs text-muted">{m.source === 'owner_claim' ? 'İşletme sahibi' : m.source === 'team_membership' ? 'Ekip üyeliği' : 'Zincir üyeliği'}</p>
                      </td>
                      {businessIds.length > 1 && (
                        <td className="px-5 py-3 text-muted">{m.business_name}</td>
                      )}
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${roleConfig.className}`}>
                          {roleConfig.label}
                        </span>
                      </td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${
                          m.status === 'active' ? 'bg-success/[0.10] text-success' : 'bg-warning/[0.10] text-warning'
                        }`}>
                          {m.status === 'active' ? 'Aktif' : 'Davet bekliyor'}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(m.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </PanelBolumKarti>
        )}

        {/* Shift Scheduler */}
        <PanelBolumKarti title="Vardiya Planı (Bu Hafta)" className="mt-6">
          <ShiftScheduler members={list} />
        </PanelBolumKarti>
      </PanelIcerikYuzeyi>
    </div>
  );
}

const DAYS = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const SHIFTS = ['Sabah (07-15)', 'Öğle (11-19)', 'Akşam (15-23)', 'Gece (23-07)'];

function ShiftScheduler({ members }: { members: TeamMember[] }) {
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
            <tr key={`${m.business_id}-${m.membership_id ?? m.user_id ?? m.email}`} className="hover:bg-black/[0.02]">
              <td className="px-3 py-2 font-[700] text-textStrong">
                <p className="truncate max-w-[120px]">{m.email ?? '—'}</p>
                <p className="text-[10px] text-muted">{ROLE_LABELS[m.role]?.label ?? m.role}</p>
              </td>
              {DAYS.map((d, di) => (
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
