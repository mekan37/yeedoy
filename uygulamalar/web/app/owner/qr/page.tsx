import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'QR Design Kit | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerQrPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const list = await getOwnerBusinesses<{ id: string; name: string; slug: string | null }>(
    supabase as any,
    user!.id,
    'id, name, slug',
  );

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="QR Design Kit"
        description="Generate, download and place QR codes for your businesses"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<QrIcon />}
            title="No businesses found"
            description="Add a business first to generate QR codes."
          />
        ) : (
          <PanelSectionCard
            title="Your businesses"
            description="Select a business to open its QR Studio — generate PNG/SVG, copy links and customise branding"
          >
            <ul className="divide-y divide-border -mx-5 -mb-5">
              {list.map((b) => (
                <li key={b.id} className="flex items-center justify-between gap-4 px-5 py-4">
                  <div>
                    <p className="text-sm font-[800] text-textStrong">{b.name}</p>
                    {b.slug && (
                      <p className="text-xs text-muted">yeedoy.com/m/{b.slug}</p>
                    )}
                  </div>
                  <Link
                    href={`/karekod/${b.id}`}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-xs font-[800] text-white transition-opacity hover:opacity-90"
                  >
                    <QrIcon />
                    QR Studio
                  </Link>
                </li>
              ))}
            </ul>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function QrIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <path d="M14 14h.01M14 17h.01M17 14h.01M17 17h.01M20 14h.01M20 17h.01M20 20h.01" />
    </svg>
  );
}
