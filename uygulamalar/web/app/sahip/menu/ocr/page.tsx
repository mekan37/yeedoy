import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { OcrIstemcisi } from './ocr-istemcisi';

export default async function OcrSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/menu/ocr');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const { data: menus } = await (supabase as any)
    .from('menus')
    .select('id, title, menu_sections(id, title)')
    .eq('business_id', businessId) as {
    data: Array<{ id: string; title: string; menu_sections: Array<{ id: string; title: string }> }> | null;
  };

  const sections = (menus ?? []).flatMap((menu) =>
    menu.menu_sections.map((section) => ({
      id: section.id,
      menuId: menu.id,
      label: `${menu.title} / ${section.title}`,
    })),
  );

  return <OcrIstemcisi businessId={businessId} sections={sections} />;
}
