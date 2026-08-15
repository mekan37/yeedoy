import { z } from 'zod';

export const epostaKampanyaGovdesi = z.object({
  businessId: z.string().uuid(),
  subject: z.string().min(1).max(200),
  body: z.string().min(1).max(5000),
  targetSegment: z.string().min(1).max(80),
});

export type EpostaKampanyaGovdesi = z.infer<typeof epostaKampanyaGovdesi>;
