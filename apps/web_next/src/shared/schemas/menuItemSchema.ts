import { z } from 'zod';

const tagsSchema = z
  .array(z.string().trim().min(1).max(32))
  .max(10, 'En fazla 10 etiket girebilirsiniz.')
  .default([]);

export const menuItemSchema = z.object({
  name: z.string().trim().min(2, 'Ürün adı en az 2 karakter olmalıdır.'),
  description: z
    .string()
    .trim()
    .max(500, 'Açıklama en fazla 500 karakter olabilir.')
    .optional()
    .or(z.literal(''))
    .transform((value) => {
      if (!value) return undefined;
      return value;
    }),
  price_cents: z
    .number({ invalid_type_error: 'Fiyat sayısal olmalıdır.' })
    .int('Fiyat tam sayı olmalıdır.')
    .min(0, 'Fiyat 0 veya daha büyük olmalıdır.'),
  currency: z.literal('TRY').default('TRY'),
  tags: tagsSchema,
  image_url: z
    .string()
    .trim()
    .url('Geçerli bir görsel URL girin.')
    .optional()
    .or(z.literal(''))
    .transform((value) => {
      if (!value) return undefined;
      return value;
    }),
  is_available: z.boolean().default(true),
});

export const menuItemCreateSchema = menuItemSchema.extend({
  business_id: z.string().uuid(),
  category_id: z.string().uuid(),
});

export type MenuItemFormInput = z.input<typeof menuItemSchema>;
export type MenuItemFormValues = z.output<typeof menuItemSchema>;
