import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PushKampanyaFormu } from './push-kampanya-istemci';

export const metadata: Metadata = {
  title: 'Push Kampanyaları | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function PushKampanyalariPage() {
  const supabase = await createSupabaseServerClient();

  const { count: totalUsers } = await (supabase as any)
    .from('user_profiles')
    .select('user_id', { count: 'exact', head: true });

  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const { count: activeUsers } = await (supabase as any)
    .from('analytics_events')
    .select('user_id', { count: 'exact', head: true })
    .gte('created_at', since30d);

  const since7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const { count: newUsers } = await (supabase as any)
    .from('user_profiles')
    .select('user_id', { count: 'exact', head: true })
    .gte('created_at', since7d);

  // Fetch past campaigns
  const { data: campaigns } = await (supabase as any)
    .from('push_campaigns')
    .select('id, title, body, target_segment, sent_count, created_at, scheduled_at, sent_at, businesses(name)')
    .order('created_at', { ascending: false })
    .limit(20) as { data: Array<{
      id: string; title: string; body: string; target_segment: string;
      sent_count: number; created_at: string; scheduled_at: string | null; sent_at: string | null;
      businesses: { name: string } | null;
    }> | null };

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('is_active', true)
    .order('name', { ascending: true })
    .limit(100) as { data: Array<{ id: string; name: string }> | null };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Push Kampanyaları"
        description="Hedefli segment push bildirimleri gönder"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Audience stats */}
          <div className="grid grid-cols-3 gap-4">
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Toplam Kullanıcı</p>
              <p className="mt-1 text-2xl font-[900] text-textStrong">{(totalUsers ?? 0).toLocaleString('tr-TR')}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Son 30 Gün Aktif</p>
              <p className="mt-1 text-2xl font-[900] text-blue-600">{(activeUsers ?? 0).toLocaleString('tr-TR')}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Son 7 Gün Yeni</p>
              <p className="mt-1 text-2xl font-[900] text-green-600">{(newUsers ?? 0).toLocaleString('tr-TR')}</p>
            </div>
          </div>

          {/* Campaign form */}
          <PanelBolumKarti title="Yeni Kampanya Gönder">
            <PushKampanyaFormu
              totalUsers={totalUsers ?? 0}
              activeUsers={activeUsers ?? 0}
              newUsers={newUsers ?? 0}
              businesses={businesses ?? []}
            />
          </PanelBolumKarti>

          {/* Past campaigns */}
          {(campaigns ?? []).length > 0 && (
            <PanelBolumKarti title="Geçmiş Kampanyalar" noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Başlık</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Segment</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Gönderildi</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {(campaigns ?? []).map((c) => (
                    <tr key={c.id} className="hover:bg-black/[0.02]">
                      <td className="px-5 py-3 font-[600] text-textStrong">{c.title}</td>
                      <td className="px-5 py-3">
                        <span className="inline-flex items-center rounded-full bg-blue-50 px-2 py-0.5 text-xs font-[700] text-blue-700">
                          {c.businesses?.name ?? 'İşletme'} · {segmentLabel(c.target_segment)}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-muted">{(c.sent_count ?? 0).toLocaleString('tr-TR')}</td>
                      <td className="px-5 py-3">
                        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-[700] ${c.sent_at ? 'bg-green-50 text-green-700' : 'bg-yellow-50 text-yellow-700'}`}>
                          {c.sent_at ? 'Gönderildi' : c.scheduled_at ? 'Zamanlandı' : 'Taslak'}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(c.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function segmentLabel(segment: string) {
  if (segment === 'all_followers') return 'Tüm takipçiler';
  if (segment === 'loyal_top20') return 'Sadık ilk %20';
  if (segment === 'inactive_30d') return '30 gün pasif';
  if (segment === 'new_30d') return 'Son 30 gün yeni';
  return segment;
}
