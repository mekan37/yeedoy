import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { TopluIslemlerIstemci } from './toplu-islemler-istemci';

export const metadata: Metadata = {
  title: 'Toplu İşlemler | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function TopluIslemlerPage() {
  const supabase = await createSupabaseServerClient();

  // Pending businesses for bulk approval
  const { data: pendingBusinesses } = await (supabase as any)
    .from('businesses')
    .select('id, name, city, is_active, created_at')
    .eq('is_active', false)
    .order('created_at', { ascending: true })
    .limit(200) as { data: Array<{
      id: string; name: string; city: string; is_active: boolean; created_at: string;
    }> | null };

  // Flagged reviews for bulk moderation
  const { data: flaggedReviews } = await (supabase as any)
    .from('reviews')
    .select('id, content, rating, created_at')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(100) as { data: Array<{
      id: string; content: string; rating: number; created_at: string;
    }> | null };

  // Suspicious users (many flagged reviews)
  const { data: suspiciousUsers } = await (supabase as any)
    .from('user_profiles')
    .select('user_id, display_name, created_at, shadow_banned')
    .eq('shadow_banned', true)
    .limit(50) as { data: Array<{
      user_id: string; display_name: string; created_at: string; shadow_banned: boolean;
    }> | null };

  // Operation history
  const { data: opHistory } = await (supabase as any)
    .from('bulk_op_logs')
    .select('id, op_type, count, action, created_at, operator')
    .order('created_at', { ascending: false })
    .limit(50) as { data: Array<{
      id: string; op_type: string; count: number; action: string; created_at: string; operator: string;
    }> | null };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Toplu İşlemler"
        description="İşletme onayları, yorum moderasyonu ve kullanıcı işlemlerini toplu yönet"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Stats row */}
          <div className="grid grid-cols-3 gap-4">
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Bekleyen İşletme</p>
              <p className="mt-1 text-2xl font-[900] text-yellow-600">{(pendingBusinesses ?? []).length}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Şikayet Edilen Yorum</p>
              <p className="mt-1 text-2xl font-[900] text-red-600">{(flaggedReviews ?? []).length}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Şüpheli Kullanıcı</p>
              <p className="mt-1 text-2xl font-[900] text-orange-600">{(suspiciousUsers ?? []).length}</p>
            </div>
          </div>

          <TopluIslemlerIstemci
            pendingBusinesses={(pendingBusinesses ?? []).map((business) => ({
              ...business,
              status: business.is_active ? 'active' : 'pending',
              user_profiles: null,
            }))}
            flaggedReviews={(flaggedReviews ?? []).map((review) => ({
              ...review,
              businesses: null,
              user_profiles: null,
            }))}
            suspiciousUsers={(suspiciousUsers ?? []).map((user) => ({
              id: user.user_id,
              display_name: user.display_name,
              email: '',
              created_at: user.created_at,
            }))}
            opHistory={opHistory ?? []}
          />
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
