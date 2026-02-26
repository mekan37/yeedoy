import { z } from 'zod';

export const businessSchema = z.object({
  name: z.string().trim().min(2, 'İşletme adı zorunludur.'),
  city: z.string().trim().min(2, 'Şehir bilgisi zorunludur.'),
  district: z.string().trim().min(2, 'İlçe bilgisi zorunludur.'),
  category: z.string().trim().min(2).default('Restoran'),
  address: z.string().trim().min(3, 'Adres zorunludur.'),
  phone: z.string().trim().optional().or(z.literal('')),
  website: z.string().trim().optional().or(z.literal('')),
});

export type BusinessFormValues = z.output<typeof businessSchema>;
