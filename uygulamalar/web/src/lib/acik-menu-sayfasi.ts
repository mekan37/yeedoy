import { getMenuItemPhotos, getMenuItemVariants, getMenuItemPriceHistory, getPublicMenuData, getStockDishImagesCached } from '@/src/lib/veri/menu-okuma';
import type { PublicMenuData, PriceHistoryEntry, StockDishImage } from '@/src/lib/veri/menu-okuma';
export { getTranslationValue } from '@/src/lib/menu-metinleri';

export type SelectedItemDetails = {
  variants: Awaited<ReturnType<typeof getMenuItemVariants>>;
  photos: Awaited<ReturnType<typeof getMenuItemPhotos>>;
  priceHistory: PriceHistoryEntry[];
};

export type PublicMenuPageData = PublicMenuData & {
  selectedItem: PublicMenuData['items'][number] | null;
  selectedItemDetails: SelectedItemDetails | null;
  stockDishImages: StockDishImage[];
};

export async function getPublicMenuPageData(input: {
  businessSlugOrId: string;
  selectedItemId?: string | null;
}) {
  const [data, stockDishImages] = await Promise.all([
    getPublicMenuData(input.businessSlugOrId),
    getStockDishImagesCached(),
  ]);
  if (!data) return null;

  const selectedItem = input.selectedItemId
    ? data.items.find((item) => item.id === input.selectedItemId) ?? null
    : null;

  if (!selectedItem) {
    return {
      ...data,
      selectedItem: null,
      selectedItemDetails: null,
      stockDishImages,
    } satisfies PublicMenuPageData;
  }

  const [variants, photos, priceHistory] = await Promise.all([
    getMenuItemVariants(selectedItem.id),
    getMenuItemPhotos(selectedItem.id),
    getMenuItemPriceHistory(selectedItem.id),
  ]);

  return {
    ...data,
    selectedItem,
    selectedItemDetails: {
      variants,
      photos,
      priceHistory,
    },
    stockDishImages,
  } satisfies PublicMenuPageData;
}
