import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Menüler | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerMenusPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  // Fetch owner's businesses first, then their menus
  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const businessIds = (businesses ?? []).map((b) => b.id);
  const businessMap = Object.fromEntries((businesses ?? []).map((b) => [b.id, b.name]));

  type MenuRow = { id: string; business_id: string; title: string; status: string; created_at: string };
  const { data: menus } = businessIds.length > 0
    ? await (supabase as any)
        .from('menus')
        .select('id, business_id, title, status, created_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false }) as { data: MenuRow[] | null }
    : { data: [] as MenuRow[] };

  const list = menus ?? [];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Menüler"
        description="İşletmelerinize ait tüm menüler"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<MenuIcon />}
            title="Henüz menü yok"
            description="İşletmenize menü eklemek için önce bir işletme seçin."
          />
        ) : (
          <PanelSectionCard noPadding>
            <ul className="divide-y divide-border">
              {list.map((m) => (
                <li key={m.id}>
                  <Link
                    href={`/owner/menus/${m.id}`}
                    className="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-black/[0.02]"
                  >
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted">
                      <MenuIcon />
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-[800] text-textStrong">{m.title}</p>
                      <p className="mt-0.5 text-xs text-muted">
                        {businessMap[m.business_id] ?? m.business_id}
                      </p>
                    </div>

                    <span
                      className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${
                        m.status === 'published'
                          ? 'bg-green-50 text-green-700'
                          : m.status === 'archived'
                            ? 'bg-zinc-100 text-zinc-500'
                            : 'bg-amber-50 text-amber-700'
                      }`}
                    >
                      {m.status === 'published' ? 'Yayında' : m.status === 'archived' ? 'Arşiv' : 'Taslak'}
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

function MenuIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
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
