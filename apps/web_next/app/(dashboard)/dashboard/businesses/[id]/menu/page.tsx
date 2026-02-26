import Link from 'next/link';
import { requireBusinessOwner } from '@/src/lib/auth';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { getOwnedBusinessByIdOrSlug } from '@/src/lib/owned-business';
import { Card } from '@/src/ui/components/card';
import { MenuEditorSection } from '@/src/ui/sections/menu-editor';

type Props = { params: Promise<{ id: string }> };

export default async function BusinessMenuEditorPage({
  params,
  searchParams,
}: Props & { searchParams?: Promise<{ menu?: string }> }) {
  const { id } = await params;
  const qp = (await searchParams) ?? {};
  await requireBusinessOwner(id);
  const supabase = await createSupabaseServerClient();

  const business = await getOwnedBusinessByIdOrSlug(id);
  if (!business) {
    return (
      <Card className="rounded-3xl">
        <h1 className="text-xl font-bold text-slate-900">Menu acilamadi</h1>
        <p className="mt-2 text-sm text-slate-600">Bu isletme bulunamadi. Gelen ID/Slug: {id}</p>
        <div className="mt-4">
          <Link href="/dashboard/businesses" className="rounded-xl bg-slate-900 px-4 py-2 text-white">
            Isletmelere Don
          </Link>
        </div>
      </Card>
    );
  }

  const { data: menus } = await supabase
    .from('menus')
    .select('id,title,status,updated_at,created_at')
    .eq('business_id', business.business_id)
    .neq('status', 'archived')
    .order('updated_at', { ascending: false })
    .order('created_at', { ascending: false });

  const selectableMenus = (menus ?? []) as Array<{ id: string; title: string; status: string }>;
  const selectedMenuId =
    selectableMenus.find((m) => m.id === qp.menu)?.id ??
    selectableMenus.find((m) => m.status === 'published')?.id ??
    selectableMenus[0]?.id ??
    null;

  const { data: categories } = await (selectedMenuId
    ? supabase
        .from('menu_categories')
        .select('*')
        .eq('business_id', business.business_id)
        .eq('menu_id', selectedMenuId)
        .order('sort_order')
    : supabase.from('menu_categories').select('*').eq('business_id', business.business_id).order('sort_order'));

  const categoryIds = (categories ?? []).map((c: { id: string }) => c.id).filter(Boolean);
  const { data: items } =
    categoryIds.length > 0
      ? await supabase
          .from('menu_items')
          .select('id,business_id,category_id,name,description,price_cents,currency,tags,image_url,is_available,sort_order,created_at,updated_at')
          .eq('business_id', business.business_id)
          .in('category_id', categoryIds)
          .order('sort_order')
      : { data: [] as any[] };

  const { data: translations } = await supabase
    .from('menu_translations')
    .select('*')
    .in('entity_type', ['business', 'category', 'item']);

  const itemIds = (items ?? []).map((x: { id: string }) => x.id).filter(Boolean);
  const { data: variants } =
    itemIds.length > 0
      ? await supabase
          .from('menu_item_variants')
          .select('id,menu_item_id,label,price_cents,currency,is_default,is_available,sort_order')
          .in('menu_item_id', itemIds)
          .order('sort_order')
      : { data: [] as any[] };

  return (
    <div className="grid gap-6">
      <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <h1 className="text-2xl font-extrabold">Dijital Menu Olustur - {business.business_name}</h1>
        <p className="mt-2 text-sm text-slate-600">
          1) Kategori ekle, 2) Urunleri fiyatla gir, 3) QR varliklarini indir, 4) Public linki paylas.
        </p>
      </div>

      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold">Menu Editoru</h2>
        </div>
        <Link href={`/dashboard/businesses/${business.business_id}/qr`} className="rounded-xl border border-slate-300 bg-white px-4 py-2">
          QR Varliklari
        </Link>
      </div>

      <MenuEditorSection
        businessId={business.business_id}
        menuId={selectedMenuId}
        menus={(selectableMenus ?? []) as any}
        categories={(categories ?? []) as any}
        items={(items ?? []) as any}
        variants={(variants ?? []) as any}
        translations={(translations ?? []) as any}
      />
    </div>
  );
}
