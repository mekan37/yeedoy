import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { SmsGonderimFormu } from './sms-istemci';

export const metadata: Metadata = {
  title: 'SMS Pazarlama | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SmsPazarlamaPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const bizIds = businesses.map(b => b.id);

  const { count: followerCount } = await (supabase as any)
    .from('business_follows')
    .select('id', { count: 'exact', head: true })
    .in('business_id', bizIds);

  const { count: loyaltyCount } = await (supabase as any)
    .from('loyalty_cards')
    .select('id', { count: 'exact', head: true })
    .in('business_id', bizIds);

  // Opt-out list
  const { count: optOutCount } = await (supabase as any)
    .from('sms_optouts')
    .select('id', { count: 'exact', head: true })
    .in('business_id', bizIds);

  // Past campaigns with delivery stats
  const { data: campaigns } = await (supabase as any)
    .from('sms_campaigns')
    .select('id, message, segment, sent_count, delivered_count, failed_count, created_at, status, scheduled_at')
    .in('business_id', bizIds)
    .order('created_at', { ascending: false })
    .limit(20) as { data: Array<{
      id: string; message: string; segment: string;
      sent_count: number; delivered_count: number | null; failed_count: number | null;
      created_at: string; status: string; scheduled_at: string | null;
    }> | null };

  // Delivery analytics aggregation
  const allCampaigns = campaigns ?? [];
  const totalSent = allCampaigns.reduce((s, c) => s + (c.sent_count ?? 0), 0);
  const totalDelivered = allCampaigns.reduce((s, c) => s + (c.delivered_count ?? 0), 0);
  const totalFailed = allCampaigns.reduce((s, c) => s + (c.failed_count ?? 0), 0);
  const deliveryRate = totalSent > 0 ? Math.round((totalDelivered / totalSent) * 100) : 0;
  const totalCostEst = totalSent * 0.08;

  const reachable = Math.max(followerCount ?? 0, loyaltyCount ?? 0) - (optOutCount ?? 0);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner — Pazarlama"
        title="SMS Pazarlama"
        description="Takipçi ve sadakat kartlı müşterilere kısa mesaj gönder. Teslimat analitiği ve opt-out yönetimi."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Analytics KPIs */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Ulaşılabilir Kişi</p>
              <p className="mt-1 text-2xl font-[900] text-primary">{reachable.toLocaleString('tr-TR')}</p>
              <p className="text-[10px] text-muted mt-0.5">opt-out düşüldü</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Teslimat Oranı</p>
              <p className={`mt-1 text-2xl font-[900] ${deliveryRate >= 90 ? 'text-green-600' : deliveryRate >= 70 ? 'text-yellow-600' : 'text-red-600'}`}>
                %{deliveryRate}
              </p>
              <p className="text-[10px] text-muted mt-0.5">{totalDelivered.toLocaleString('tr-TR')} / {totalSent.toLocaleString('tr-TR')}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Toplam Maliyet</p>
              <p className="mt-1 text-2xl font-[900] text-textStrong">₺{totalCostEst.toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
              <p className="text-[10px] text-muted mt-0.5">₺0.08 / SMS tahmini</p>
            </div>
            <div className="rounded-xl border border-red-200 bg-red-50 p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-red-700">Opt-Out</p>
              <p className="mt-1 text-2xl font-[900] text-red-700">{(optOutCount ?? 0).toLocaleString('tr-TR')}</p>
              <p className="text-[10px] text-red-600 mt-0.5">vazgeçen abone</p>
            </div>
          </div>

          {/* Delivery trend bar */}
          {totalSent > 0 && (
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="mb-3 text-xs font-[800] uppercase tracking-wide text-muted">Gönderim Durumu Özeti</p>
              <div className="flex h-4 w-full overflow-hidden rounded-full">
                <div className="bg-green-500 transition-all" style={{ width: `${deliveryRate}%` }} title={`Teslim: ${totalDelivered}`} />
                {totalFailed > 0 && <div className="bg-red-400" style={{ width: `${Math.round((totalFailed / totalSent) * 100)}%` }} title={`Başarısız: ${totalFailed}`} />}
                <div className="flex-1 bg-zinc-200" />
              </div>
              <div className="mt-2 flex gap-4 text-[10px] text-muted">
                <span className="flex items-center gap-1"><span className="inline-block h-2 w-2 rounded-full bg-green-500" />Teslim edildi {totalDelivered.toLocaleString('tr-TR')}</span>
                {totalFailed > 0 && <span className="flex items-center gap-1"><span className="inline-block h-2 w-2 rounded-full bg-red-400" />Başarısız {totalFailed.toLocaleString('tr-TR')}</span>}
                <span className="flex items-center gap-1"><span className="inline-block h-2 w-2 rounded-full bg-zinc-200" />Beklemede {Math.max(0, totalSent - totalDelivered - totalFailed).toLocaleString('tr-TR')}</span>
              </div>
            </div>
          )}

          {/* Send form */}
          <PanelBolumKarti title="SMS Gönder">
            <SmsGonderimFormu
              bizIds={bizIds}
              followerCount={followerCount ?? 0}
              loyaltyCount={loyaltyCount ?? 0}
              optOutCount={optOutCount ?? 0}
            />
          </PanelBolumKarti>

          {/* Campaign history */}
          {allCampaigns.length > 0 && (
            <PanelBolumKarti title="Geçmiş SMS Kampanyaları" noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Mesaj</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Segment</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Gönderildi</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Teslim %</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Maliyet</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {allCampaigns.map(c => {
                    const rate = c.sent_count > 0 && c.delivered_count != null
                      ? Math.round((c.delivered_count / c.sent_count) * 100) : null;
                    const cost = (c.sent_count ?? 0) * 0.08;
                    return (
                      <tr key={c.id} className="hover:bg-black/[0.02]">
                        <td className="max-w-xs px-5 py-3">
                          <p className="line-clamp-1 text-xs text-textStrong">{c.message}</p>
                        </td>
                        <td className="px-5 py-3">
                          <span className="inline-flex rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-[700] text-blue-700">
                            {c.segment === 'followers' ? 'Takipçiler' : c.segment === 'loyalty' ? 'Sadakat' : 'Tümü'}
                          </span>
                        </td>
                        <td className="px-5 py-3 text-muted">{(c.sent_count ?? 0).toLocaleString('tr-TR')}</td>
                        <td className="px-5 py-3">
                          {rate != null ? (
                            <span className={`font-[700] text-xs ${rate >= 90 ? 'text-green-600' : rate >= 70 ? 'text-yellow-600' : 'text-red-600'}`}>
                              %{rate}
                            </span>
                          ) : <span className="text-xs text-muted">—</span>}
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">₺{cost.toFixed(2)}</td>
                        <td className="px-5 py-3">
                          <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${c.status === 'sent' ? 'bg-green-50 text-green-700' : c.status === 'scheduled' ? 'bg-blue-50 text-blue-700' : 'bg-yellow-50 text-yellow-700'}`}>
                            {c.status === 'sent' ? 'Gönderildi' : c.status === 'scheduled' ? `Zamanlandı: ${new Date(c.scheduled_at!).toLocaleDateString('tr-TR')}` : 'Bekliyor'}
                          </span>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(c.created_at).toLocaleDateString('tr-TR')}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}

          {/* Opt-out management */}
          <PanelBolumKarti title="Opt-Out Yönetimi">
            <div className="flex items-center gap-4">
              <div className="flex-1">
                <p className="text-sm text-muted">
                  <strong className="text-textStrong">{(optOutCount ?? 0).toLocaleString('tr-TR')} kişi</strong> SMS&apos;lerinizi almak istemediğini bildirdi.
                  Bu kişilere otomatik olarak SMS gönderilmez.
                </p>
              </div>
              {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
              <a
                href="/sunucu/sahip/sms-optout?export=csv"
                className="shrink-0 rounded-xl border border-border px-4 py-2 text-xs font-[700] text-muted hover:text-textStrong"
              >
                Listeyi İndir
              </a>
            </div>
            {(optOutCount ?? 0) > 0 && (
              <div className="mt-3 rounded-lg bg-yellow-50 p-3">
                <p className="text-xs text-yellow-700">
                  ⚠️ Opt-out listesi KVKK kapsamında korunmaktadır. Bu kişilere SMS göndermek yasal sorumluluk doğurabilir.
                </p>
              </div>
            )}
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
