import { z } from 'zod';
import { menuItemSchema } from '@/src/shared/schemas/menuItemSchema';

export const loginSchema = z.object({
  email: z.string().email('Gecerli bir e-posta girin.'),
  password: z.string().min(6, 'Sifre en az 6 karakter olmali.'),
});

export const categorySchema = z.object({
  business_id: z.string().uuid(),
  name: z.string().min(1, 'Kategori adi zorunlu'),
  sort_order: z.number().int().nonnegative().default(0),
  is_active: z.boolean().default(true),
});

export const itemSchema = z.object({
  business_id: z.string().uuid(),
  category_id: z.string().uuid(),
}).merge(menuItemSchema.pick({
  name: true,
  description: true,
  price_cents: true,
  currency: true,
  tags: true,
  image_url: true,
  is_available: true,
}));

export const menuImportSchema = z.object({
  categories: z.array(
    z.object({
      name: z.string(),
      sort_order: z.number().int().optional(),
      items: z.array(
        z.object({
          name: menuItemSchema.shape.name,
          description: menuItemSchema.shape.description,
          price_cents: menuItemSchema.shape.price_cents,
          currency: menuItemSchema.shape.currency.optional(),
          is_available: menuItemSchema.shape.is_available.optional(),
          sort_order: z.number().int().optional(),
          tags: menuItemSchema.shape.tags.optional(),
          image_url: menuItemSchema.shape.image_url,
        }),
      ),
    }),
  ),
});
