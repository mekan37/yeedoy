import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Öneriler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  pending:  { label: 'Beklemede', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

export default async function AdminSuggestionsPage({ searchParams }: Props) {
  const { status = 'pending' } = await searchParams;
  const supabase = await createSupabaseServerClient();

  const [pendingRes, approvedRes, rejectedRes] = await Promise.all([
    (supabase as any).from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    (supabase as any).from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    (supabase as any).from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
  ]);

  let list: any[] = [];
  try {
    let query = (supabase as any)
      .from('business_suggestions')
      .select('id, name, city, category, status, note, created_at')
      .order('created_at', { ascending: false })
      .limit(100);

    if (status !== 'all') query = query.eq('status', status);

    const { data } = await query;
    list = data ?? [];
  } catch { list = []; }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Platform Önerileri"
        description="Kullanıcıların gönderdiği işletme önerileri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <MetricCard title="Beklemede" value={(pendingRes.count  ?? 0).toLocaleString('tr-TR')} icon={<ClockIcon />} />
            <MetricCard title="Onaylandı"  value={(approvedRes.count ?? 0).toLocaleString('tr-TR')} icon={<CheckIcon />} />
            <MetricCard title="Reddedildi" value={(rejectedRes.count ?? 0).toLocaleString('tr-TR')} icon={<XIcon />} />
          </div>

          <form method="get" className="flex flex-wrap gap-2">
            {[
              { value: 'pending',  label: 'Beklemede' },
              { value: 'approved', label: 'Onaylandı' },
              { value: 'rejected', label: 'Reddedildi' },
              { value: 'all',      label: 'Tümü' },
            ].map(({ value, label }) => (
              <button
                key={value}
                type="submit"
                name="status"
                value={value}
                className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                  status === value
                    ? 'bg-primary text-white'
                    : 'bg-card border border-border text-muted hover:text-textStrong'
                }`}
              >
                {label}
              </button>
            ))}
          </form>

          {list.length === 0 ? (
            <PanelEmptyState
              icon={<LightbulbIcon />}
              title="Öneri bulunamadı"
              description="Seçilen filtre için kayıt yok."
            />
          ) : (
            <PanelBolumKarti noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Not</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((s: any) => {
                    const statusInfo = STATUS_MAP[s.status] ?? STATUS_MAP['pending'];
                    return (
                      <tr key={s.id} className="hover:bg-black/[0.01]">
                        <td className="px-5 py-3 font-[700] text-textStrong">{s.name}</td>
                        <td className="px-5 py-3 text-muted">{s.city ?? '—'}</td>
                        <td className="px-5 py-3 text-muted">{s.category ?? '—'}</td>
                        <td className="px-5 py-3 text-muted max-w-[200px] truncate">{s.note ?? '—'}</td>
                        <td className="px-5 py-3">
                          <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${statusInfo.className}`}>
                            {statusInfo.label}
                          </span>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(s.created_at).toLocaleDateString('tr-TR')}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>; }
function XIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>; }
function LightbulbIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="9" y1="18" x2="15" y2="18" /><line x1="10" y1="22" x2="14" y2="22" /><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14" /></svg>; }

