'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export type ActionState = { error: string } | { success: true } | null;

type BusinessMutationResult = {
  data: { id: string; slug: string | null; public_slug: string | null } | null;
  error: { message: string } | null;
};

type ServerSupabaseClient = Awaited<ReturnType<typeof createSupabaseServerClient>>;
type AuthenticatedUser = NonNullable<
  Awaited<ReturnType<ServerSupabaseClient['auth']['getUser']>>['data']['user']
>;
type AuthenticatedContext = {
  businessId: string;
  supabase: ServerSupabaseClient;
  user: AuthenticatedUser;
};
type RpcResult = {
  data: unknown;
  error: { message?: string } | null;
};

const BusinessIdSchema = z.string().uuid();

const OptionalUrlSchema = z
  .string()
  .trim()
  .max(500)
  .refine((value) => {
    if (!value) return true;

    try {
      const url = new URL(value);
      return url.protocol === 'http:' || url.protocol === 'https:';
    } catch {
      return false;
    }
  });

const ProfileSchema = z.object({
  name: z.string().trim().min(1).max(120),
  category: z.string().trim().min(1).max(80),
  description: z.string().trim().max(1000),
  phone: z.string().trim().max(30),
  email: z.union([z.literal(''), z.string().trim().email().max(255)]),
  address: z.string().trim().max(300),
  city: z.string().trim().max(80),
  district: z.string().trim().max(80),
});

const BrandingSchema = z.object({
  type: z.enum(['logo', 'cover']),
  url: z.string().trim().url().max(2000),
});

const ContactSchema = z.object({
  website_url: OptionalUrlSchema,
  instagram_url: OptionalUrlSchema,
  facebook_url: OptionalUrlSchema,
  twitter_url: OptionalUrlSchema,
});

const ReservationSettingsSchema = z
  .object({
    accepts_reservations: z.boolean(),
    reservation_phone: z.string().trim().max(30),
    reservation_min_party: z.coerce.number().int().min(1).max(99).default(1),
    reservation_max_party: z.coerce.number().int().min(1).max(99).default(20),
    reservation_note: z.string().trim().max(500),
  })
  .refine((data) => data.reservation_min_party <= data.reservation_max_party, {
    message: 'Minimum kişi sayısı maksimum kişi sayısından büyük olamaz.',
    path: ['reservation_min_party'],
  });

const PasswordSchema = z
  .object({
    password: z.string().min(8).max(72),
    confirmPassword: z.string().min(1),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Şifreler eşleşmiyor.',
    path: ['confirmPassword'],
  });

function toNull(value: string) {
  return value || null;
}

function readFormValue(formData: FormData, key: string) {
  return formData.get(key);
}

async function getAuthenticatedUser() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return { supabase, user };
}

async function callAuthenticatedRpc(
  supabase: ServerSupabaseClient,
  functionName: string,
  args: Record<string, unknown>,
): Promise<RpcResult> {
  try {
    return await (supabase as unknown as {
      rpc: (name: string, params: Record<string, unknown>) => Promise<RpcResult>;
    }).rpc(functionName, args);
  } catch {
    return { data: null, error: { message: 'rpc_failed' } };
  }
}

async function prepareBusinessMutation(
  businessId: string,
  action: string,
  limit: number,
  windowMs: number,
): Promise<AuthenticatedContext | { error: string }> {
  const parsedBusinessId = BusinessIdSchema.safeParse(businessId);
  if (!parsedBusinessId.success) {
    return { error: 'Geçersiz işletme bilgisi.' };
  }

  const { supabase, user } = await getAuthenticatedUser();
  if (!user) {
    return { error: 'Oturum açmanız gerekiyor.' };
  }

  const limitResult = rateLimit(
    `owner-settings:${action}:${user.id}:${parsedBusinessId.data}`,
    limit,
    windowMs,
  );
  if (!limitResult.ok) {
    return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };
  }

  return { businessId: parsedBusinessId.data, supabase, user };
}

async function authorizeBusinessWrite(
  businessId: string,
  action: string,
): Promise<AuthenticatedContext | { error: string }> {
  const context = await prepareBusinessMutation(businessId, action, 10, 60_000);
  if ('error' in context) return context;

  const permission = await callAuthenticatedRpc(context.supabase, 'has_business_permission_v1', {
    p_business_id: context.businessId,
    p_permission: 'business_write',
  });
  if (permission.error || permission.data !== true) {
    return { error: 'Bu işletmeyi düzenleme yetkiniz yok.' };
  }

  const persistentLimit = await consumePersistentRateLimit(
    context.supabase,
    `owner_settings_business_${action}`,
    200,
  );
  if (persistentLimit === 'limited') {
    return { error: 'Günlük işlem sınırına ulaşıldı. Lütfen daha sonra tekrar deneyin.' };
  }
  if (persistentLimit === 'error') {
    return { error: 'İşlem güvenli şekilde doğrulanamadı. Lütfen tekrar deneyin.' };
  }

  return context;
}

async function consumePersistentRateLimit(
  supabase: ServerSupabaseClient,
  action: string,
  dailyLimit: number,
): Promise<'ok' | 'limited' | 'error'> {
  const result = await callAuthenticatedRpc(supabase, 'consume_rate_limit_v1', {
    p_action: action,
    p_daily_limit: dailyLimit,
  });

  if (result.error || typeof result.data !== 'object' || result.data === null) {
    return 'error';
  }

  const ok = (result.data as { ok?: unknown }).ok;
  if (ok === true) return 'ok';
  if (ok === false) return 'limited';
  return 'error';
}

function revalidateBusinessPaths(
  businessId: string,
  business: BusinessMutationResult['data'],
) {
  revalidatePath('/sahip/ayarlar');
  revalidatePath('/sahip/isletmeler');
  revalidatePath(`/sahip/isletmeler/${businessId}`);

  const publicSlugs = new Set(
    [business?.slug, business?.public_slug].filter(
      (slug): slug is string => typeof slug === 'string' && slug.length > 0,
    ),
  );
  for (const publicSlug of publicSlugs) {
    revalidatePath(`/b/${publicSlug}`);
  }
}

export async function updateBusinessProfile(
  businessId: string,
  _previousState: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const authorization = await authorizeBusinessWrite(businessId, 'profile');
  if ('error' in authorization) return { error: authorization.error };

  const parsed = ProfileSchema.safeParse({
    name: readFormValue(formData, 'name'),
    category: readFormValue(formData, 'category'),
    description: readFormValue(formData, 'description'),
    phone: readFormValue(formData, 'phone'),
    email: readFormValue(formData, 'email'),
    address: readFormValue(formData, 'address'),
    city: readFormValue(formData, 'city'),
    district: readFormValue(formData, 'district'),
  });
  if (!parsed.success) {
    return { error: 'Lütfen işletme bilgilerini kontrol edin.' };
  }

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı.' };

  const result = (await (service as any)
    .from('businesses')
    .update({
      name: parsed.data.name,
      category: parsed.data.category,
      description: toNull(parsed.data.description),
      phone: toNull(parsed.data.phone),
      email: toNull(parsed.data.email),
      address: toNull(parsed.data.address),
      city: toNull(parsed.data.city),
      district: toNull(parsed.data.district),
    })
    .eq('id', authorization.businessId)
    .select('id, slug, public_slug')
    .maybeSingle()) as BusinessMutationResult;

  if (result.error || !result.data) {
    return { error: 'İşletme bilgileri kaydedilemedi.' };
  }

  revalidateBusinessPaths(authorization.businessId, result.data);
  return { success: true };
}

export async function updateContactInfo(
  businessId: string,
  _previousState: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const authorization = await authorizeBusinessWrite(businessId, 'contact');
  if ('error' in authorization) return { error: authorization.error };

  const parsed = ContactSchema.safeParse({
    website_url: readFormValue(formData, 'website_url'),
    instagram_url: readFormValue(formData, 'instagram_url'),
    facebook_url: readFormValue(formData, 'facebook_url'),
    twitter_url: readFormValue(formData, 'twitter_url'),
  });
  if (!parsed.success) {
    return { error: 'URL alanlarına http:// veya https:// ile başlayan geçerli adresler girin.' };
  }

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı.' };

  const result = (await (service as any)
    .from('businesses')
    .update({
      website_url: toNull(parsed.data.website_url),
      instagram_url: toNull(parsed.data.instagram_url),
      facebook_url: toNull(parsed.data.facebook_url),
      twitter_url: toNull(parsed.data.twitter_url),
    })
    .eq('id', authorization.businessId)
    .select('id, slug, public_slug')
    .maybeSingle()) as BusinessMutationResult;

  if (result.error || !result.data) {
    return { error: 'İletişim bilgileri kaydedilemedi.' };
  }

  revalidateBusinessPaths(authorization.businessId, result.data);
  return { success: true };
}

export async function updateBusinessBranding(
  businessId: string,
  type: 'logo' | 'cover',
  url: string,
): Promise<{ error: string } | { success: true }> {
  const authorization = await authorizeBusinessWrite(businessId, 'branding');
  if ('error' in authorization) return { error: authorization.error };

  const parsed = BrandingSchema.safeParse({ type, url });
  if (!parsed.success) {
    return { error: 'Geçersiz görsel adresi.' };
  }

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı.' };

  const column = parsed.data.type === 'logo' ? 'logo_url' : 'cover_url';
  const result = (await (service as any)
    .from('businesses')
    .update({ [column]: parsed.data.url })
    .eq('id', authorization.businessId)
    .select('id, slug, public_slug')
    .maybeSingle()) as BusinessMutationResult;

  if (result.error || !result.data) {
    return { error: 'Görsel kaydedilemedi.' };
  }

  revalidateBusinessPaths(authorization.businessId, result.data);
  return { success: true };
}

export async function updateReservationSettings(
  businessId: string,
  _previousState: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const authorization = await authorizeBusinessWrite(businessId, 'reservation');
  if ('error' in authorization) return { error: authorization.error };

  const parsed = ReservationSettingsSchema.safeParse({
    accepts_reservations: readFormValue(formData, 'accepts_reservations') === 'on',
    reservation_phone: readFormValue(formData, 'reservation_phone'),
    reservation_min_party: readFormValue(formData, 'reservation_min_party') ?? undefined,
    reservation_max_party: readFormValue(formData, 'reservation_max_party') ?? undefined,
    reservation_note: readFormValue(formData, 'reservation_note'),
  });
  if (!parsed.success) {
    const partyRangeError = parsed.error.issues.some(
      (issue) => issue.path[0] === 'reservation_min_party' && issue.code === 'custom',
    );
    return {
      error: partyRangeError
        ? 'Minimum kişi sayısı maksimum kişi sayısından büyük olamaz.'
        : 'Lütfen rezervasyon ayarlarını kontrol edin.',
    };
  }

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı.' };

  const result = (await (service as any)
    .from('businesses')
    .update({
      accepts_reservations: parsed.data.accepts_reservations,
      reservation_phone: toNull(parsed.data.reservation_phone),
      reservation_min_party: parsed.data.reservation_min_party,
      reservation_max_party: parsed.data.reservation_max_party,
      reservation_note: toNull(parsed.data.reservation_note),
    })
    .eq('id', authorization.businessId)
    .select('id, slug, public_slug')
    .maybeSingle()) as BusinessMutationResult;

  if (result.error || !result.data) {
    return { error: 'Rezervasyon ayarları kaydedilemedi.' };
  }

  revalidateBusinessPaths(authorization.businessId, result.data);
  revalidatePath('/sahip/rezervasyonlar');
  return { success: true };
}

export async function updatePassword(
  _previousState: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const { supabase, user } = await getAuthenticatedUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const limitResult = rateLimit(`owner-settings:password:${user.id}`, 5, 5 * 60_000);
  if (!limitResult.ok) {
    return { error: 'Çok fazla deneme yapıldı. Lütfen beş dakika sonra tekrar deneyin.' };
  }

  const persistentLimit = await consumePersistentRateLimit(
    supabase,
    'owner_settings_password_update',
    20,
  );
  if (persistentLimit === 'limited') {
    return { error: 'Günlük şifre güncelleme sınırına ulaşıldı. Lütfen daha sonra tekrar deneyin.' };
  }
  if (persistentLimit === 'error') {
    return { error: 'Şifre güncelleme isteği doğrulanamadı. Lütfen tekrar deneyin.' };
  }

  const parsed = PasswordSchema.safeParse({
    password: readFormValue(formData, 'password'),
    confirmPassword: readFormValue(formData, 'confirm_password'),
  });
  if (!parsed.success) {
    const mismatch = parsed.error.issues.some(
      (issue) => issue.path[0] === 'confirmPassword' && issue.code === 'custom',
    );
    return {
      error: mismatch ? 'Şifreler eşleşmiyor.' : 'Şifre 8 ile 72 karakter arasında olmalıdır.',
    };
  }

  const { error } = await supabase.auth.updateUser({ password: parsed.data.password });
  if (error) return { error: 'Şifre güncellenemedi. Lütfen tekrar deneyin.' };

  return { success: true };
}

export async function deactivateBusiness(
  businessId: string,
): Promise<{ error: string } | null> {
  const authorization = await prepareBusinessMutation(businessId, 'deactivate', 3, 60 * 60_000);
  if ('error' in authorization) return { error: authorization.error };

  const role = await callAuthenticatedRpc(authorization.supabase, 'get_business_role_v1', {
    p_business_id: authorization.businessId,
  });
  if (role.error || role.data !== 'owner') {
    return { error: 'Bu işletmeyi yalnızca işletme sahibi devre dışı bırakabilir.' };
  }

  const persistentLimit = await consumePersistentRateLimit(
    authorization.supabase,
    'owner_settings_business_deactivate',
    5,
  );
  if (persistentLimit === 'limited') {
    return { error: 'Günlük işletme devre dışı bırakma sınırına ulaşıldı.' };
  }
  if (persistentLimit === 'error') {
    return { error: 'İşlem güvenli şekilde doğrulanamadı. Lütfen tekrar deneyin.' };
  }

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı.' };

  const result = (await (service as any)
    .from('businesses')
    .update({ is_active: false })
    .eq('id', authorization.businessId)
    .select('id, slug, public_slug')
    .maybeSingle()) as BusinessMutationResult;

  if (result.error || !result.data) {
    return { error: 'İşletme devre dışı bırakılamadı.' };
  }

  revalidateBusinessPaths(authorization.businessId, result.data);
  revalidatePath('/sahip/gosterge-panosu');
  return null;
}
