import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';

type Props = { params: Promise<{ menuId: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('menus').select('title').eq('id', menuId).single() as { data: { title: string } | null };
  return {
    title: data ? `${data.title} | Owner Panel` : 'Menü | Owner Panel',
    robots: { index: false, follow: false },
  };
}

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: currency || 'TRY',
    minimumFractionDigits: 2,
  }).format(cents / 100);
}

export default async function OwnerMenuDetailPage({ params }: Props) {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  // Verify ownership via businesses
  type MenuDetail = { id: string; title: string; status: string; business_id: string; created_at: string };
  const { data: menu } = await (supabase as any)
    .from('menus')
    .select('id, title, status, business_id, created_at')
    .eq('id', menuId)
    .single() as { data: MenuDetail | null };

  if (!menu) notFound();

  // Verify owner owns this business
  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('id', menu.business_id)
    .eq('owner_id', user!.id)
    .single();

  if (!biz) notFound();

  // Load sections
  type SectionRow = { id: string; title: string; sort_order: number };
  const { data: sections } = await (supabase as any)
    .from('menu_sections')
    .select('id, title, sort_order')
    .eq('menu_id', menuId)
    .order('sort_order', { ascending: true }) as { data: SectionRow[] | null };

  const sectionIds = (sections ?? []).map((s) => s.id);

  // Load all items for these sections
  const { data: items } = sectionIds.length > 0
    ? await (supabase as any)
        .from('menu_items')
        .select('id, section_id, name, description, price_cents, currency, is_available, sort_order, image_url')
        .in('section_id', sectionIds)
        .order('sort_order', { ascending: true })
    : { data: [] };

  const itemsBySection = ((items ?? []) as any[]).reduce<Record<string, any[]>>((acc, item) => {
    if (!acc[item.section_id]) acc[item.section_id] = [];
    acc[item.section_id].push(item);
    return acc;
  }, {});

  const statusInfo = menu.status === 'published'
    ? { label: 'Yayında', className: 'bg-green-50 text-green-700' }
    : menu.status === 'archived'
      ? { label: 'Arşiv', className: 'bg-zinc-100 text-zinc-500' }
      : { label: 'Taslak', className: 'bg-amber-50 text-amber-700' };

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow={biz.name}
        title={menu.title}
        description={`${(sections ?? []).length} bölüm · ${(items ?? []).length} ürün`}
        actions={
          <div className="flex items-center gap-2">
            <span className={`rounded-full px-3 py-1 text-xs font-[800] ${statusInfo.className}`}>
              {statusInfo.label}
            </span>
            <Link href="/owner/menus">
              <PanelActionButton variant="ghost">← Menüler</PanelActionButton>
            </Link>
          </div>
        }
      />
      <PanelContentSurface className="pt-6">
        {(sections ?? []).length === 0 ? (
          <PanelEmptyState
            icon={<SectionIcon />}
            title="Henüz bölüm eklenmedi"
            description="Bu menüde henüz bir bölüm bulunmuyor."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {(sections ?? []).map((section) => {
              const sectionItems = itemsBySection[section.id] ?? [];
              return (
                <PanelSectionCard key={section.id} title={section.title} noPadding>
                  {sectionItems.length === 0 ? (
                    <p className="px-5 py-4 text-sm text-muted">Bu bölümde ürün yok.</p>
                  ) : (
                    <ul className="divide-y divide-border">
                      {sectionItems.map((item: any) => (
                        <li key={item.id} className="flex items-center gap-4 px-5 py-3">
                          {item.image_url && (
                            <Image
                              src={item.image_url}
                              alt={item.name}
                              width={40}
                              height={40}
                              className="h-10 w-10 shrink-0 rounded-lg object-cover"
                              unoptimized
                            />
                          )}
                          <div className="min-w-0 flex-1">
                            <div className="flex items-center gap-2">
                              <p className="truncate text-sm font-[800] text-textStrong">{item.name}</p>
                              {!item.is_available && (
                                <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-[700] text-zinc-500">
                                  Mevcut Değil
                                </span>
                              )}
                            </div>
                            {item.description && (
                              <p className="mt-0.5 line-clamp-1 text-xs text-muted">{item.description}</p>
                            )}
                          </div>
                          <span className="shrink-0 text-sm font-[900] text-textStrong">
                            {formatPrice(item.price_cents, item.currency)}
                          </span>
                        </li>
                      ))}
                    </ul>
                  )}
                </PanelSectionCard>
              );
            })}
          </div>
        )}
      </PanelContentSurface>
    </div>
  );
}

function SectionIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" />
      <line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" />
    </svg>
  );
}
