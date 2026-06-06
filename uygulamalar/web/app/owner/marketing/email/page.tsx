import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { EmailCampaignForm } from './email-campaign-form';

export const metadata: Metadata = {
  title: 'E-posta Kampanyaları | Owner Panel',
  robots: { index: false, follow: false },
};

interface PageProps {
  searchParams: Promise<{ business_id?: string }>;
}

type BusinessRow = { id: string; name: string };
type CampaignRow = {
  id: string;
  subject: string;
  sent_count: number | null;
  sent_at: string | null;
  created_at: string;
};

export default async function OwnerEmailCampaignsPage({ searchParams }: PageProps) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as {
    auth: { getUser: () => Promise<{ data: { user: { id: string } | null } }> };
    from: (table: string) => any;
    rpc: (fn: string, args?: Record<string, unknown>) => any;
  };

  const {
    data: { user },
  } = await supabaseAny.auth.getUser();

  if (!user) {
    redirect('/login?redirect=/owner/marketing/email');
  }

  const businesses = await getOwnerBusinesses<BusinessRow>(
    supabase as any,
    user.id,
    'id, name',
  );

  if (businesses.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader
          eyebrow="Pazarlama"
          title="E-posta Kampanyaları"
          description="Müşterilerinize e-posta ile ulaşın"
        />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<MailIcon />}
            title="Henüz bir işletmeniz yok"
            description="E-posta kampanyası oluşturabilmek için önce bir işletme sahiplenmeniz gerekiyor."
          />
        </PanelContentSurface>
      </div>
    );
  }

  const { business_id: qBusinessId } = await searchParams;
  const selectedId =
    qBusinessId && businesses.some((b) => b.id === qBusinessId)
      ? qBusinessId
      : businesses[0].id;

  // Fetch last 5 campaigns for selected business
  const { data: campaigns } = await supabaseAny
    .from('email_campaigns')
    .select('id, subject, sent_count, sent_at, created_at')
    .eq('business_id', selectedId)
    .order('created_at', { ascending: false })
    .limit(5);

  const recentCampaigns: CampaignRow[] = (campaigns ?? []) as CampaignRow[];
  const selectedBusiness = businesses.find((b) => b.id === selectedId)!;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Pazarlama"
        title="E-posta Kampanyaları"
        description="E-posta izni veren takipçilerinize kampanya gönderin"
      />

      <PanelContentSurface className="pt-6">
        {/* Business selector — shown only when owner has multiple businesses */}
        {businesses.length > 1 && (
          <div className="mb-6">
            <BusinessSelector businesses={businesses} selectedId={selectedId} />
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          {/* Main form column */}
          <div className="flex flex-col gap-6">
            <EmailCampaignForm
              businessId={selectedId}
              businessName={selectedBusiness.name}
            />
          </div>

          {/* Sidebar: recent campaigns */}
          <aside className="flex flex-col gap-4">
            <PanelSectionCard
              title="Son Kampanyalar"
              description="Son 5 gönderim"
            >
              {recentCampaigns.length === 0 ? (
                <p className="text-sm text-muted">Henüz kampanya gönderilmemiş.</p>
              ) : (
                <ul className="flex flex-col gap-3">
                  {recentCampaigns.map((c) => (
                    <li
                      key={c.id}
                      className="flex flex-col gap-0.5 rounded-lg border border-border bg-bg p-3 text-sm"
                    >
                      <span className="font-[700] text-textStrong line-clamp-1">{c.subject}</span>
                      <span className="text-xs text-muted">
                        {c.sent_at
                          ? `${c.sent_count ?? 0} kişiye gönderildi — ${formatDate(c.sent_at)}`
                          : `Oluşturuldu — ${formatDate(c.created_at)}`}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </PanelSectionCard>

            <PanelSectionCard title="Consent Notu" description="KVKK bilgisi">
              <p className="text-xs text-muted leading-relaxed">
                Yalnızca e-posta pazarlamayı kabul etmiş (
                <strong className="font-[700] text-textStrong">is_subscribed_email = true</strong>)
                takipçilere gönderim yapılır. Diğer kullanıcılar otomatik olarak dışarıda bırakılır.
              </p>
            </PanelSectionCard>
          </aside>
        </div>
      </PanelContentSurface>
    </div>
  );
}

// ---- sub-components ----

function BusinessSelector({
  businesses,
  selectedId,
}: {
  businesses: BusinessRow[];
  selectedId: string;
}) {
  return (
    <form method="GET" className="flex items-center gap-3">
      <label htmlFor="business_id" className="shrink-0 text-sm font-[700] text-textStrong">
        İşletme:
      </label>
      <select
        id="business_id"
        name="business_id"
        defaultValue={selectedId}
        className="h-10 rounded-lg border border-border bg-card px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      >
        {businesses.map((b) => (
          <option key={b.id} value={b.id}>
            {b.name}
          </option>
        ))}
      </select>
      <button
        type="submit"
        className="rounded-lg border border-border bg-card px-3 py-2 text-sm font-[700] text-textStrong hover:bg-black/[0.04]"
      >
        Seç
      </button>
    </form>
  );
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return iso;
  }
}

function MailIcon() {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22,6 12,13 2,6" />
    </svg>
  );
}
