import { z } from 'zod';

export const menuCategoryCreateSchema = z.object({
  business_id: z.string().uuid(),
  menu_id: z.string().uuid(),
  name_tr: z.string().trim().min(2, 'Kategori adı en az 2 karakter olmalıdır.'),
  name_en: z.string().trim().optional().or(z.literal('')),
});

export const menuCategoryReorderSchema = z.object({
  business_id: z.string().uuid(),
  menu_id: z.string().uuid(),
  category_id: z.string().uuid(),
  direction: z.enum(['up', 'down']),
});

export const menuCategoryDeleteSchema = z.object({
  business_id: z.string().uuid(),
  menu_id: z.string().uuid(),
  category_id: z.string().uuid(),
});
