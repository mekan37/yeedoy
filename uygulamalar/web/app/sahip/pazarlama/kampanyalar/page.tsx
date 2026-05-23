import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { KampanyaFormu } from './kampanya-formu';

export const metadata: Metadata = {
  title: 'Push Kampanyaları | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerCampaignsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? (await getOwnerBusinesses<{ id: string; name: string; is_active: boolean | null }>(
      supabase as any,
      user.id,
      'id, name, is_active',
    )).filter((business) => business.is_active !== false)
    : [];

  // Her işletme için takipçi sayısı
  const businessIds = businesses.map((b: { id: string }) => b.id);
  const followerCounts: Record<string, number> = {};

  if (businessIds.length > 0) {
    for (const bid of businessIds) {
      const { count } = await (supabase as any)
        .from('favorites')
        .select('*', { count: 'exact', head: true })
        .eq('business_id', bid) as { count: number | null };
      followerCounts[bid] = count ?? 0;
    }
  }

  const bizList = businesses.map((b: { id: string; name: string }) => ({
    ...b,
    followerCount: followerCounts[b.id] ?? 0,
  }));

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Push Kampanyaları"
        description="Takipçilerinize anlık bildirim gönderin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          <PanelBolumKarti title="Bildirim Gönder">
            {bizList.length === 0 ? (
              <p className="text-sm text-muted">Aktif işletme bulunamadı.</p>
            ) : (
              <KampanyaFormu businesses={bizList} />
            )}
          </PanelBolumKarti>

          <div className="flex flex-col gap-4">
            {/* Takipçi özeti */}
            <PanelBolumKarti title="Takipçi Durumu">
              <ul className="flex flex-col gap-3">
                {bizList.map((b) => (
                  <li key={b.id} className="flex items-center justify-between">
                    <span className="text-sm font-[700] text-textStrong truncate mr-2">{b.name}</span>
                    <span className="shrink-0 rounded-full bg-primary/[0.08] border border-primary/20 px-2 py-0.5 text-xs font-[900] text-primary">
                      {b.followerCount} takipçi
                    </span>
                  </li>
                ))}
              </ul>
            </PanelBolumKarti>

            {/* Kurallar */}
            <div className="rounded-xl border border-border bg-cardAlt p-4">
              <p className="mb-2 text-xs font-[800] uppercase tracking-wide text-muted">Bildirim Kuralları</p>
              <ul className="space-y-1.5 text-xs text-muted">
                <li>• Günde maksimum 3 kampanya gönderilebilir</li>
                <li>• Başlık en fazla 60 karakter</li>
                <li>• Mesaj en fazla 160 karakter</li>
                <li>• Yalnızca işletmeyi favorileyen kullanıcılara gider</li>
              </ul>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
