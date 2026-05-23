import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getMarketplaceBusinessBySlug } from '@/src/lib/veri/pazar-okuma';
import { getPublicMenuPageData, getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import { SiparisClient } from './SiparisClient';

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const business = await getMarketplaceBusinessBySlug(slug);
  if (!business) return { title: 'Sipariş | Yeedoy' };
  return {
    title: `${business.name} — Sipariş Ver | Yeedoy`,
    description: `${business.name} menüsünden sipariş verin.`,
  };
}

export default async function SiparisPage({ params }: Props) {
  const { slug } = await params;

  const business = await getMarketplaceBusinessBySlug(slug);
  if (!business) notFound();

  const menuData = await getPublicMenuPageData({ businessSlugOrId: slug }).catch(() => null);

  type SiparisCategory = { id: string; name: string };
  type SiparisItem = {
    id: string;
    name: string;
    price_cents: number;
    currency: string;
    is_available: boolean;
    category_id: string;
    description?: string | null;
  };

  const translations = menuData?.translations ?? [];

  const categories: SiparisCategory[] = (menuData?.categories ?? []).map((c) => ({
    id: c.id,
    name:
      getTranslationValue({ translations, entityType: 'category', entityId: c.id, locale: 'tr', field: 'name' }) ??
      getTranslationValue({ translations, entityType: 'category', entityId: c.id, locale: 'en', field: 'name' }) ??
      `Kategori ${c.sort_order ?? ''}`,
  }));

  const items: SiparisItem[] = (menuData?.items ?? []).map((item) => ({
    id: item.id,
    name: item.name,
    price_cents: item.price_cents ?? 0,
    currency: item.currency ?? 'TRY',
    is_available: item.is_available ?? true,
    category_id: item.category_id ?? '',
    description: item.description ?? null,
  }));

  return (
    <SiparisClient
      business={{ id: business.id, name: business.name, slug: business.slug }}
      menuCategories={categories}
      menuItems={items}
    />
  );
}
