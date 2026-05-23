import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { MetricCard } from '@/src/ui/components/metric-card';

export const metadata: Metadata = {
  title: 'Büyüme | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerGrowthPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id);

  const businessIds = (businesses ?? []).map((b: any) => b.id);

  const now = Date.now();
  const since7d = new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString();
  const since30d = new Date(now - 30 * 24 * 60 * 60 * 1000).toISOString();
  const since90d = new Date(now - 90 * 24 * 60 * 60 * 1000).toISOString();

  const eventsQuery = (since: string, eventName: string) =>
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', eventName)
          .gte('created_at', since)
      : Promise.resolve({ count: 0 });

  const [
    views7d, views30d, views90d,
    qr7d, qr30d, qr90d,
    wa7d, wa30d,
    reviewsRes,
  ] = await Promise.all([
    eventsQuery(since7d, 'menu_view'),
    eventsQuery(since30d, 'menu_view'),
    eventsQuery(since90d, 'menu_view'),
    eventsQuery(since7d, 'qr_scan'),
    eventsQuery(since30d, 'qr_scan'),
    eventsQuery(since90d, 'qr_scan'),
    eventsQuery(since7d, 'whatsapp_click'),
    eventsQuery(since30d, 'whatsapp_click'),
    businessIds.length > 0
      ? (supabase as any)
          .from('business_reviews')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .gte('created_at', since30d)
      : Promise.resolve({ count: 0 }),
  ]);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Büyüme"
        description="İşletmelerinizin büyüme istatistikleri"
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          <PanelSectionCard title="Menü Görüntüleme">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Son 7 Gün" value={(views7d.count ?? 0).toLocaleString('tr-TR')} icon={<EyeIcon />} />
              <MetricCard title="Son 30 Gün" value={(views30d.count ?? 0).toLocaleString('tr-TR')} icon={<EyeIcon />} />
              <MetricCard title="Son 90 Gün" value={(views90d.count ?? 0).toLocaleString('tr-TR')} icon={<EyeIcon />} />
            </div>
          </PanelSectionCard>

          <PanelSectionCard title="QR Tarama">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Son 7 Gün" value={(qr7d.count ?? 0).toLocaleString('tr-TR')} icon={<QrIcon />} />
              <MetricCard title="Son 30 Gün" value={(qr30d.count ?? 0).toLocaleString('tr-TR')} icon={<QrIcon />} />
              <MetricCard title="Son 90 Gün" value={(qr90d.count ?? 0).toLocaleString('tr-TR')} icon={<QrIcon />} />
            </div>
          </PanelSectionCard>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <PanelSectionCard title="WhatsApp (Son 30 Gün)">
              <MetricCard
                title="Tıklama"
                value={(wa30d.count ?? 0).toLocaleString('tr-TR')}
                subtitle="Son 30 gün"
                icon={<PhoneIcon />}
              />
            </PanelSectionCard>
            <PanelSectionCard title="Yorumlar (Son 30 Gün)">
              <MetricCard
                title="Yeni Yorum"
                value={(reviewsRes.count ?? 0).toLocaleString('tr-TR')}
                subtitle="Son 30 gün"
                icon={<StarIcon />}
              />
            </PanelSectionCard>
          </div>

          {businessIds.length === 0 && (
            <p className="text-center text-sm text-muted">
              Büyüme verisi görüntülemek için önce işletme ekleyin.
            </p>
          )}
        </div>
      </PanelContentSurface>
    </div>
  );
}

function EyeIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
function QrIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /></svg>;
}
function PhoneIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12.7a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.61 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.18 6.18l.98-.98a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>;
}
function StarIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}
