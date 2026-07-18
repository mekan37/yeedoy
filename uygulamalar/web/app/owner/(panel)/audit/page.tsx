import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { AuditClient } from './audit-client';
import type { AuditLogRow, MemberOption } from './audit-client';

export const metadata: Metadata = {
  title: 'Denetim Kaydı | Owner Panel',
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 10;

type Props = {
  searchParams: Promise<{
    page?: string;
    actor?: string;
    action?: string;
    from?: string;
    to?: string;
  }>;
};

type BizJoinRow = { business_id: string; businesses: { id: string; name: string } | null };

export default async function OwnerAuditPage({ searchParams }: Props) {
  const { page: pageParam, actor, action, from, to } = await searchParams;
  const page = Math.max(1, Number(pageParam) || 1);

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: ownerBiz }, { data: teamBiz }, { data: ownProfile }] = await Promise.all([
    (supabase as any)
      .from('owner_claims')
      .select('business_id, businesses(id, name)')
      .eq('user_id', user.id)
      .eq('status', 'approved'),
    (supabase as any)
      .from('business_team_memberships')
      .select('business_id, businesses(id, name)')
      .eq('user_id', user.id)
      .not('accepted_at', 'is', null)
      .is('revoked_at', null),
    (supabase as any)
      .from('user_profiles')
      .select('user_id, display_name')
      .eq('user_id', user.id)
      .maybeSingle(),
  ]);

  const ownerRows = (ownerBiz ?? []) as BizJoinRow[];
  const teamRows = (teamBiz ?? []) as BizJoinRow[];

  const businessMap = new Map<string, string>();
  for (const r of [...ownerRows, ...teamRows]) {
    if (r.businesses) businessMap.set(r.businesses.id, r.businesses.name);
  }
  const businessIds = Array.from(businessMap.keys());

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Owner" title="Denetim Kaydı" description="Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve filtreleyebilirsiniz." />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="İşletme bulunamadı"
            description="Denetim kaydını görmek için önce bir işletmeye erişiminiz olmalı."
          />
        </PanelContentSurface>
      </div>
    );
  }

  // ── Ekip üyeleri (Üye filtre dropdown'u için) ─────────────────────────────
  const { data: memberRows } = await (supabase as any)
    .from('business_team_memberships')
    .select('user_id, role, user_profiles(user_id, display_name)')
    .in('business_id', businessIds)
    .not('accepted_at', 'is', null)
    .is('revoked_at', null);

  type MemberJoinRow = { user_id: string; role: string; user_profiles: { user_id: string; display_name: string } | null };
  const memberMap = new Map<string, MemberOption>();

  // Owner'ın kendisi de listede olmalı (kendi eylemleri actor_role='owner' ile loglanır)
  const ownDisplayName = (ownProfile as { display_name: string } | null)?.display_name ?? 'Ben';
  memberMap.set(user.id, { user_id: user.id, display_name: ownDisplayName, role: 'owner' });

  for (const m of (memberRows ?? []) as MemberJoinRow[]) {
    if (!memberMap.has(m.user_id)) {
      memberMap.set(m.user_id, {
        user_id: m.user_id,
        display_name: m.user_profiles?.display_name ?? 'Kullanıcı',
        role: m.role,
      });
    }
  }
  const members = Array.from(memberMap.values());

  // ── Denetim kayıtlarını çek ────────────────────────────────────────────────
  const offset = (page - 1) * PAGE_SIZE;
  const { data: result } = await (supabase as any).rpc('get_business_audit_log_v1', {
    p_business_ids: businessIds,
    p_actor_id: actor || null,
    p_action: action || null,
    p_date_from: from || null,
    p_date_to: to || null,
    p_limit: PAGE_SIZE,
    p_offset: offset,
  });

  const logRows = (result?.rows ?? []) as AuditLogRow[];
  const total = (result?.total ?? 0) as number;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Denetim Kaydı"
        description="Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve filtreleyebilirsiniz."
        actions={
          <>
            <PanelActionButton variant="secondary" disabled title="Yakında aktif olacak">Dışa Aktar</PanelActionButton>
            <PanelActionButton variant="primary" disabled title="Yakında aktif olacak">Denetim Raporu</PanelActionButton>
          </>
        }
      />
      <AuditClient
        logRows={logRows}
        total={total}
        page={page}
        pageSize={PAGE_SIZE}
        members={members}
        showBusinessColumn={businessIds.length > 1}
        filters={{ actor: actor ?? '', action: action ?? '', from: from ?? '', to: to ?? '' }}
      />
    </div>
  );
}

function ShieldIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
