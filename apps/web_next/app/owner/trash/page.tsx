import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { RestoreButton } from './restore-button';

export const metadata: Metadata = {
  title: 'Çöp Kutusu | Owner Panel',
  robots: { index: false, follow: false },
};

type TrashRow = {
  entity_type: 'menu' | 'item' | 'photo';
  entity_id: string;
  title: string;
  subtitle: string;
  occurred_at: string;
  menu_id: string | null;
  menu_item_id: string | null;
  photo_url: string | null;
};

const ENTITY_LABELS: Record<string, string> = {
  menu: 'Menü',
  item: 'Ürün',
  photo: 'Fotoğraf',
};

export default async function OwnerTrashPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const bizList = businesses ?? [];

  // Collect trash rows for all owned businesses
  const trashResults = await Promise.all(
    bizList.map((b) =>
      (supabase as any)
        .rpc('list_owner_menu_trash_v1', { p_business_id: b.id })
        .then((res: { data: TrashRow[] | null }) => ({
          bizName: b.name,
          rows: res.data ?? [],
        })),
    ),
  );

  const allRows = trashResults.flatMap((r) =>
    r.rows.map((row: TrashRow) => ({ ...row, bizName: r.bizName })),
  );

  // Sort by occurred_at desc
  allRows.sort((a, b) => new Date(b.occurred_at).getTime() - new Date(a.occurred_at).getTime());

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Çöp Kutusu"
        description="Silinen menü ve içerikleri bu alandan geri yükleyebilirsiniz. Silinen içerikler 30 gün boyunca saklanır."
      />
      <PanelContentSurface className="pt-6">
        {allRows.length === 0 ? (
          <PanelEmptyState
            icon={<TrashIcon />}
            title="Çöp kutusu boş"
            description="Silinen menüler ve ürünler burada listelenecek."
          />
        ) : (
          <PanelSectionCard
            title={`${allRows.length} silinen öğe`}
            description="Öğeyi geri yüklemek için 'Geri Yükle' düğmesine tıklayın."
            noPadding
          >
            <ul className="divide-y divide-border">
              {allRows.map((row) => (
                <li key={row.entity_id} className="flex items-center gap-4 px-5 py-4">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted">
                    <EntityIcon type={row.entity_type} />
                  </div>
                  <div className="flex min-w-0 flex-1 flex-col">
                    <span className="truncate font-[700] text-textStrong">{row.title}</span>
                    <span className="mt-0.5 text-xs text-muted">
                      {ENTITY_LABELS[row.entity_type] ?? row.entity_type}
                      {row.bizName ? ` · ${row.bizName}` : ''}
                      {' · '}
                      {new Date(row.occurred_at).toLocaleDateString('tr-TR')}
                    </span>
                  </div>
                  <RestoreButton entityType={row.entity_type} entityId={row.entity_id} />
                </li>
              ))}
            </ul>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function TrashIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6" /><path d="M14 11v6" />
      <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}

function EntityIcon({ type }: { type: string }) {
  if (type === 'menu') return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="12" x2="21" y2="12" /><line x1="3" y1="18" x2="15" y2="18" />
    </svg>
  );
  if (type === 'photo') return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" />
    </svg>
  );
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M12 2L2 7l10 5 10-5-10-5z" /><path d="M2 17l10 5 10-5" /><path d="M2 12l10 5 10-5" />
    </svg>
  );
}
