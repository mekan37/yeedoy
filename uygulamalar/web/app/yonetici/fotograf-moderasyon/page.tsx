import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { FotografModerasyon } from './fotograf-moderasyon-istemci';

export const metadata: Metadata = {
  title: 'Fotoğraf Moderasyon | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function FotografModerasyon_Page() {
  const supabase = await createSupabaseServerClient();

  // Fetch hidden / pending business media items for admin review.
  const { data: photos } = await (supabase as any)
    .from('business_media')
    .select('id, business_id, created_by, url, status, is_hidden, created_at, businesses(name)')
    .or('status.eq.pending,is_hidden.eq.true')
    .order('created_at', { ascending: true })
    .limit(100) as { data: Array<{
      id: string; business_id: string; created_by: string | null; url: string;
      status: string; is_hidden: boolean; created_at: string;
      businesses: { name: string } | null;
    }> | null };

  const { count: totalPending } = await (supabase as any)
    .from('business_media')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'pending');

  const { count: totalFlagged } = await (supabase as any)
    .from('business_media')
    .select('id', { count: 'exact', head: true })
    .eq('is_hidden', true);

  const { count: totalApproved } = await (supabase as any)
    .from('business_media')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'approved');

  const photoList = (photos ?? []).map((photo) => ({
    id: photo.id,
    business_id: photo.business_id,
    user_id: photo.created_by ?? '',
    url: photo.url,
    status: photo.is_hidden ? 'flagged' : photo.status,
    created_at: photo.created_at,
    businesses: photo.businesses,
    user_profiles: null,
  }));

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Fotoğraf Moderasyon"
        description="Kullanıcı yüklü fotoğrafları incele ve onayla veya reddet"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Stats Row */}
          <div className="grid grid-cols-3 gap-4">
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Bekleyen</p>
              <p className="mt-1 text-2xl font-[900] text-yellow-600">{totalPending ?? 0}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Şikayet Edilen</p>
              <p className="mt-1 text-2xl font-[900] text-red-600">{totalFlagged ?? 0}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Onaylanan (toplam)</p>
              <p className="mt-1 text-2xl font-[900] text-green-600">{totalApproved ?? 0}</p>
            </div>
          </div>

          {/* Photo grid */}
          <PanelBolumKarti title="İnceleme Kuyruğu">
            <FotografModerasyon photos={photoList} />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
