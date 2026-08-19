import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { AKTIF_ISLETME_COOKIE_NAME } from '@/src/ui/kabuk/aktif-isletme-cerezi';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { EkipIstemcisi, type EkipUyesi } from './ekip-istemcisi';
import type { EkipRolu } from './ekip-yetkiler';

export const metadata: Metadata = {
  title: 'Ekip | Sahip Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams?: Promise<{ durum?: string }>;
};

type RawTeamMember = {
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
  if (!user) redirect('/giris?redirect=/sahip/ekip');

  const [businesses, cookieStore] = await Promise.all([
    getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name'),
    cookies(),
  ]);

  if (businesses.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<UsersIcon />}
            title="İşletme bulunamadı"
            description="Ekip üyelerinizi yönetmek için önce işletme sahibi olmanız gerekiyor."
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const cookieId = cookieStore.get(AKTIF_ISLETME_COOKIE_NAME)?.value;
  const activeBusiness = businesses.find((b) => b.id === cookieId) ?? businesses[0];

  const { data: rawMembers } = await (supabase as any).rpc('list_team_members_v1', {
    p_business_id: activeBusiness.id,
  }) as { data: RawTeamMember[] | null };
  const members = rawMembers ?? [];

  const userIds = members.map((m) => m.user_id).filter((id): id is string => Boolean(id));
  const profileMap = new Map<string, { display_name: string | null; avatar_url: string | null; phone: string | null }>();
  if (userIds.length > 0) {
    const { data: profiles } = await (supabase as any)
      .from('user_profiles')
      .select('user_id, display_name, avatar_url, phone')
      .in('user_id', userIds) as {
        data: Array<{ user_id: string; display_name: string | null; avatar_url: string | null; phone: string | null }> | null;
      };
    for (const p of profiles ?? []) profileMap.set(p.user_id, p);
  }

  const uyeler: EkipUyesi[] = members.map((m) => {
    const profile = m.user_id ? profileMap.get(m.user_id) : undefined;
    return {
      membershipId: m.membership_id,
      userId: m.user_id,
      email: m.email,
      displayName: profile?.display_name ?? null,
      avatarUrl: profile?.avatar_url ?? null,
      phone: profile?.phone ?? null,
      role: VALID_ROLES.has(m.role as EkipRolu) ? (m.role as EkipRolu) : 'viewer',
      status: m.status === 'pending' ? 'pending' : 'active',
      source: m.source,
      createdAt: m.created_at,
      acceptedAt: m.accepted_at,
    };
  });

  const statusMessage = params?.durum ? STATUS_MESSAGES[params.durum] : null;

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <EkipIstemcisi
          businessId={activeBusiness.id}
          businessName={activeBusiness.name}
          initialUyeler={uyeler}
          statusMessage={statusMessage}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}

const VALID_ROLES = new Set<EkipRolu>(['owner', 'manager', 'editor', 'staff', 'viewer']);

const STATUS_MESSAGES: Record<string, { text: string; className: string }> = {
  eklendi: { text: 'Ekip üyesi eklendi veya davet güncellendi.', className: 'border-success/25 bg-success/8 text-success' },
  gecersiz: { text: 'E-posta, işletme veya rol bilgisi eksik.', className: 'border-danger/25 bg-danger/8 text-danger' },
  yetkisiz: { text: 'Bu işletme için ekip yönetimi yetkiniz yok.', className: 'border-danger/25 bg-danger/8 text-danger' },
  forbidden: { text: 'Bu işletme için ekip yönetimi yetkiniz yok.', className: 'border-danger/25 bg-danger/8 text-danger' },
  email_required: { text: 'Geçerli bir e-posta girin.', className: 'border-danger/25 bg-danger/8 text-danger' },
  invalid_role: { text: 'Geçerli bir rol seçin.', className: 'border-danger/25 bg-danger/8 text-danger' },
  hata: { text: 'Ekip üyesi eklenemedi. Tekrar deneyin.', className: 'border-danger/25 bg-danger/8 text-danger' },
  sifre_kisa: { text: 'Şifre en az 8 karakter olmalı.', className: 'border-danger/25 bg-danger/8 text-danger' },
  servis_yok: { text: 'Sunucu yapılandırması eksik (SUPABASE_SERVICE_ROLE_KEY tanımlı değil) — şifresiz davet gönderebilirsiniz.', className: 'border-danger/25 bg-danger/8 text-danger' },
  hesap_hata: { text: 'Hesap oluşturulamadı. Tekrar deneyin.', className: 'border-danger/25 bg-danger/8 text-danger' },
};

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
