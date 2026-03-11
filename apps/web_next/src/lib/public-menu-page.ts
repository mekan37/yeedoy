import { getMenuItemPhotos, getMenuItemVariants, getPublicMenuData } from '@/src/lib/db/menu-read';
import type { PublicMenuData } from '@/src/lib/db/menu-read';
export { getTranslationValue } from '@/src/lib/menu-text';

export type SelectedItemDetails = {
  variants: Awaited<ReturnType<typeof getMenuItemVariants>>;
  photos: Awaited<ReturnType<typeof getMenuItemPhotos>>;
};

export type PublicMenuPageData = PublicMenuData & {
  selectedItem: PublicMenuData['items'][number] | null;
  selectedItemDetails: SelectedItemDetails | null;
};

export async function getPublicMenuPageData(input: {
  businessSlugOrId: string;
  selectedItemId?: string | null;
}) {
  const data = await getPublicMenuData(input.businessSlugOrId);
  if (!data) return null;

  const selectedItem = input.selectedItemId
    ? data.items.find((item) => item.id === input.selectedItemId) ?? null
    : null;

  if (!selectedItem) {
    return {
      ...data,
      selectedItem: null,
      selectedItemDetails: null,
    } satisfies PublicMenuPageData;
  }

  const [variants, photos] = await Promise.all([
    getMenuItemVariants(selectedItem.id),
    getMenuItemPhotos(selectedItem.id),
  ]);

  return {
    ...data,
    selectedItem,
    selectedItemDetails: {
      variants,
      photos,
    },
  } satisfies PublicMenuPageData;
}
