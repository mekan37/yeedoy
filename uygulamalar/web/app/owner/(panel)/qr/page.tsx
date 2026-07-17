import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { QrPageClient, type QrCode, type QrStats } from './qr-client';

export const metadata: Metadata = {
  title: 'QR Menü & QR Kod | Owner Panel',
  robots: { index: false, follow: false },
};

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, '') ?? 'http://localhost:3000';

export default async function OwnerQrPage() {
  const supabase = await createSupabaseServerClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle() as { data: { business_id: string } | null };

  if (!claim) redirect('/owner/dashboard');

  const businessId = claim.business_id;

  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('slug')
    .eq('id', businessId)
    .maybeSingle() as { data: { slug: string | null } | null };

  const { data: result } = await (supabase as any).rpc('owner_list_qr_codes_v1', {
    p_business_id: businessId,
  }) as { data: { codes: QrCode[]; stats: QrStats } | null };

  const codes: QrCode[] = result?.codes ?? [];
  const stats: QrStats = result?.stats ?? {
    total_codes: 0,
    active_codes: 0,
    total_scans: 0,
    unique_visitors: 0,
  };

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="QR Menü & QR Kod"
        description="Dijital menünüzü yönetin ve QR kodlarınızı oluşturup indirin."
      />
      <PanelContentSurface className="pt-4">
        <QrPageClient
          businessId={businessId}
          businessSlug={biz?.slug ?? null}
          siteUrl={SITE_URL}
          initialCodes={codes}
          stats={stats}
        />
      </PanelContentSurface>
    </div>
  );
}
