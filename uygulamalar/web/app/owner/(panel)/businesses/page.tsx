import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { buildMenuImageUrl } from '@/src/lib/media-url';

export const metadata: Metadata = {
  title: 'İşletmeler | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerBusinessesPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type BizRow = { id: string; name: string; slug: string | null; logo_url: string | null; logo_path: string | null; category: string; is_active: boolean; created_at: string };
  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug, logo_url, logo_path, category, is_active, created_at')
    .eq('owner_id', user!.id)
    .order('created_at', { ascending: false }) as { data: BizRow[] | null };

  const list = businesses ?? [];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="İşletmeler"
        description="Sahip olduğunuz işletmeleri yönetin"
        actions={
          <Link href="/owner/businesses/new">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni İşletme
            </PanelActionButton>
          </Link>
        }
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<BuildingIcon />}
            title="Henüz işletme yok"
            description="İlk işletmenizi ekleyerek başlayın."
            action={
              <Link href="/owner/businesses/new">
                <PanelActionButton variant="primary" icon={<PlusIcon />}>
                  İşletme Ekle
                </PanelActionButton>
              </Link>
            }
          />
        ) : (
          <PanelSectionCard noPadding>
            <ul className="divide-y divide-border">
              {list.map((b) => (
                <li key={b.id}>
                  <Link
                    href={`/owner/businesses/${b.id}`}
                    className="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-black/[0.02]"
                  >
                    {/* Logo */}
                    <div className="h-11 w-11 shrink-0 overflow-hidden rounded-xl border border-border bg-bg">
                      {b.logo_path ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={buildMenuImageUrl(b.logo_url, { width: 88, quality: 80 }) ?? ''}
                          alt={b.name}
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center text-xl font-[900] text-muted">
                          {b.name.charAt(0).toUpperCase()}
                        </div>
                      )}
                    </div>

                    {/* Info */}
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-[800] text-textStrong">{b.name}</p>
                      {b.category && (
                        <p className="mt-0.5 text-xs text-muted">{b.category}</p>
                      )}
                    </div>

                    {/* Status badge */}
                    <span
                      className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${
                        b.is_active
                          ? 'bg-green-50 text-green-700'
                          : 'bg-zinc-100 text-zinc-500'
                      }`}
                    >
                      {b.is_active ? 'Aktif' : 'Pasif'}
                    </span>

                    <ChevronIcon />
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

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function ChevronIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}
