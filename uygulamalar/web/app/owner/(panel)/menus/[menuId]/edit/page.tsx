import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { MenuEditorClient } from './menu-editor-client';

type Props = { params: Promise<{ menuId: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('menus').select('title').eq('id', menuId).single() as { data: { title: string } | null };
  return { title: data ? `${data.title} Düzenle | Owner Panel` : 'Menü Editörü | Owner Panel', robots: { index: false, follow: false } };
}

export default async function MenuEditorPage({ params }: Props) {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type Menu = { id: string; title: string; status: string; business_id: string };
  const { data: menu } = await (supabase as any).from('menus').select('id, title, status, business_id').eq('id', menuId).single() as { data: Menu | null };
  if (!menu) notFound();

  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('businesses(id, name)')
    .eq('user_id', user!.id)
    .eq('business_id', menu.business_id)
    .eq('status', 'approved')
    .maybeSingle() as { data: { businesses: { id: string; name: string } } | null };
  const biz = claim?.businesses ?? null;
  if (!biz) notFound();

  type Section = { id: string; title: string; sort_order: number };
  type Item = {
    id: string; name: string; description: string | null;
    price_cents: number; currency: string; is_available: boolean;
    section_id: string; sort_order: number;
    image_url: string | null; tags: string[] | null;
    calories_min: number | null; calories_max: number | null;
    portion_size: string | null; portion_unit: string | null;
  };

  const { data: sectionsRaw } = await (supabase as any).from('menu_sections').select('id, title, sort_order').eq('menu_id', menuId).order('sort_order') as { data: Section[] | null };
  const sections = sectionsRaw ?? [];

  const sectionIds = sections.map((s) => s.id);
  let items: Item[] = [];
  if (sectionIds.length > 0) {
    const { data: itemsRaw } = await (supabase as any)
      .from('menu_items')
      .select('id, name, description, price_cents, currency, is_available, section_id, sort_order, image_url, tags, calories_min, calories_max, portion_size, portion_unit')
      .in('section_id', sectionIds)
      .order('sort_order') as { data: Item[] | null };
    items = itemsRaw ?? [];
  }

  const STATUS_MAP: Record<string, { label: string; className: string }> = {
    draft:     { label: 'Taslak',   className: 'bg-amber-50 text-amber-700' },
    published: { label: 'Yayında',  className: 'bg-green-50 text-green-700' },
    archived:  { label: 'Arşiv',    className: 'bg-zinc-100 text-zinc-500'  },
  };
  const statusInfo = STATUS_MAP[menu.status] ?? STATUS_MAP.draft;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow={biz.name}
        title={menu.title}
        description={`Menü editörü — ${sections.length} bölüm, ${items.length} ürün`}
        actions={
          <div className="flex items-center gap-2">
            <span className={`rounded-full px-2.5 py-1 text-[11px] font-[700] ${statusInfo.className}`}>{statusInfo.label}</span>
            <Link href={`/owner/menus/${menuId}`} className="rounded-xl border border-border bg-card px-3 py-1.5 text-[12px] font-[700] text-textStrong hover:bg-bg transition-colors cursor-pointer">← Önizleme</Link>
          </div>
        }
      />
      <PanelContentSurface className="pt-6">
        <MenuEditorClient
          menuId={menuId}
          businessId={biz.id}
          initialTitle={menu.title}
          initialStatus={menu.status as 'draft' | 'published' | 'archived'}
          sections={sections}
          items={items}
        />
      </PanelContentSurface>
    </div>
  );
}
