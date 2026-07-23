import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'İnceleme Kuyruğu | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminQueuePage() {
  const supabase = await createSupabaseServerClient();

  const [reportsRes, submissionsRes, suggestionsRes, countsRpc] = await Promise.all([
    (supabase as any)
      .from('reports')
      .select('id, target_type, reason, status, created_at, assigned_to')
      .in('status', ['open', 'reviewing'])
      .order('created_at', { ascending: true })
      .limit(50),
    (supabase as any)
      .from('business_submissions')
      .select('id, name, city, category, status, created_at')
      .eq('status', 'new')
      .order('created_at', { ascending: true })
      .limit(30),
    (supabase as any)
      .from('business_suggestions')
      .select('id, name, city, category, status, created_at')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(30),
    supabase.rpc('admin_get_queues_counts_v1' as never),
  ]);

  const counts = (countsRpc.data as any) ?? {};
  const reports = (reportsRes.data ?? []) as any[];
  const submissions = (submissionsRes.data ?? []) as any[];
  const suggestions = (suggestionsRes.data ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="İnceleme Kuyruğu"
        description="Bekleyen raporlar, başvurular ve öneriler"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Summary */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <MetricCard title="Açık Rapor" value={counts.reports_open ?? reports.length} icon={<FlagIcon />} />
            <MetricCard title="Bekleyen Talep" value={counts.claims_pending ?? 0} icon={<InboxIcon />} />
            <MetricCard title="Bekleyen Öneri" value={counts.suggestions_pending ?? suggestions.length} icon={<LightbulbIcon />} />
          </div>

          {/* Reports */}
          {reports.length > 0 && (
            <PanelBolumKarti title={`Açık Raporlar (${reports.length})`} noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Hedef</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Neden</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {reports.map((r: any) => (
                    <tr key={r.id}>
                      <td className="px-5 py-3 font-[700] text-textStrong capitalize">{r.target_type}</td>
                      <td className="px-5 py-3 text-muted">{r.reason}</td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                          r.status === 'reviewing' ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'
                        }`}>
                          {r.status === 'reviewing' ? 'İnceleniyor' : 'Açık'}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(r.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}

          {/* Business submissions */}
          {submissions.length > 0 && (
            <PanelBolumKarti title={`İşletme Başvuruları (${submissions.length})`} noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {submissions.map((s: any) => (
                    <tr key={s.id}>
                      <td className="px-5 py-3 font-[700] text-textStrong">{s.name}</td>
                      <td className="px-5 py-3 text-muted">{s.city}</td>
                      <td className="px-5 py-3 text-muted">{s.category}</td>
                      <td className="px-5 py-3 text-xs text-muted">{new Date(s.created_at).toLocaleDateString('tr-TR')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}

          {reports.length === 0 && submissions.length === 0 && suggestions.length === 0 && (
            <PanelEmptyState
              icon={<CheckIcon />}
              title="Kuyruk boş"
              description="Bekleyen inceleme yok."
            />
          )}

          {/* Suggestions */}
          {suggestions.length > 0 && (
            <PanelBolumKarti title={`Kullanıcı Önerileri (${suggestions.length})`} noPadding>
              <ul className="divide-y divide-border">
                {suggestions.map((s: any) => (
                  <li key={s.id} className="flex items-center justify-between px-5 py-3">
                    <div>
                      <p className="font-[700] text-textStrong">{s.name}</p>
                      <p className="text-xs text-muted">{s.category} · {s.city}</p>
                    </div>
                    <span className="text-xs text-muted">{new Date(s.created_at).toLocaleDateString('tr-TR')}</span>
                  </li>
                ))}
              </ul>
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function FlagIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>;
}
function InboxIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12" /><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></svg>;
}
function LightbulbIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="9" y1="18" x2="15" y2="18" /><line x1="10" y1="22" x2="14" y2="22" /><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14" /></svg>;
}
function CheckIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>;
}

