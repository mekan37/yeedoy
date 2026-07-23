import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getMenuWithSections } from '@/src/lib/veri/owner/sahip-menuler';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { KategorilerClient } from './kategoriler-istemcisi';

type Props = { params: Promise<{ menuId: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('menus').select('title').eq('id', menuId).single() as { data: { title: string } | null };
  return { title: data ? `${data.title} — Kategoriler | Sahip Paneli` : 'Kategoriler | Sahip Paneli', robots: { index: false, follow: false } };
}

export default async function MenuKategorilerPage({ params }: Props) {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent(`/sahip/menuler/${menuId}/kategoriler`)}`);
  }

  const detail = await getMenuWithSections(menuId, user.id);
  if (!detail) notFound();

  const { menu, business: biz, sections, items } = detail;

  const itemCounts: Record<string, number> = {};
  for (const item of items) {
    itemCounts[item.section_id] = (itemCounts[item.section_id] ?? 0) + 1;
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow={biz.name}
        title="Kategoriler"
        description={`${menu.title} menüsündeki bölümleri yönetin`}
        actions={
          <Link
            href={`/sahip/menuler/${menuId}/duzenle`}
            className="rounded-xl border border-border bg-card px-3 py-1.5 text-[12px] font-[700] text-textStrong transition-colors hover:bg-bg"
          >
            ← Menü Düzenleyiciye Dön
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <KategorilerClient
          menuId={menuId}
          sections={sections.map((section) => ({ id: section.id, title: section.title, sort_order: section.sort_order }))}
          itemCounts={itemCounts}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
