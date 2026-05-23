import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { MetricCard } from '@/src/ui/components/metric-card';

export const metadata: Metadata = {
  title: 'Analitik | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerAnalyticsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  // Fetch owner's business IDs
  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const businessIds = (businesses ?? []).map((b) => b.id);

  // Parallel event queries (last 30 days)
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const [menuViewsRes, qrScansRes, whatsappRes] = await Promise.all([
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', 'menu_view')
          .gte('created_at', since)
      : Promise.resolve({ count: 0 }),
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', 'qr_scan')
          .gte('created_at', since)
      : Promise.resolve({ count: 0 }),
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', 'whatsapp_click')
          .gte('created_at', since)
      : Promise.resolve({ count: 0 }),
  ]);

  const metrics = [
    {
      title: 'Menü Görüntüleme',
      value: menuViewsRes.count ?? 0,
      subtitle: 'Son 30 gün',
      icon: <EyeIcon />,
    },
    {
      title: 'QR Tarama',
      value: qrScansRes.count ?? 0,
      subtitle: 'Son 30 gün',
      icon: <QrIcon />,
    },
    {
      title: 'WhatsApp Tıklama',
      value: whatsappRes.count ?? 0,
      subtitle: 'Son 30 gün',
      icon: <PhoneIcon />,
    },
    {
      title: 'İşletme Sayısı',
      value: businesses?.length ?? 0,
      subtitle: 'Toplam',
      icon: <BuildingIcon />,
    },
  ];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Analitik"
        description="Son 30 gün performans özeti"
      />
      <PanelContentSurface className="pt-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {metrics.map((m) => (
            <MetricCard
              key={m.title}
              title={m.title}
              value={m.value.toLocaleString('tr-TR')}
              subtitle={m.subtitle}
              icon={m.icon}
            />
          ))}
        </div>

        {businesses && businesses.length > 0 && (
          <PanelSectionCard title="İşletmeler" className="mt-6">
            <p className="text-sm text-muted">
              Detaylı grafik görünümü yakında eklenecek.
            </p>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function EyeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}

function PhoneIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12.7a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.61 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.18 6.18l.98-.98a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" />
    </svg>
  );
}
