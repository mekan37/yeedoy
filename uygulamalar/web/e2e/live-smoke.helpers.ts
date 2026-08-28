import { createClient, type SupabaseClient, type User } from '@supabase/supabase-js';

type Json = string | number | boolean | null | Json[] | { [key: string]: Json };

type LiveOwnerTarget = {
  businessId: string;
  ownerEmail: string;
  ownerUserId: string;
  nonOwnerEmail: string;
};

type SessionBundle = {
  accessToken: string;
  refreshToken: string;
  user: User;
};

type PresentationRow = {
  business_id: string;
  default_lang: string;
  template_key: string;
  settings: Json;
  logo_url: string | null;
  cover_url: string | null;
  background_url: string | null;
};

type BusinessMediaRow = {
  id: string;
  business_id: string;
  kind: string;
  url: string;
  url_large: string | null;
  url_thumb: string | null;
  provider: string;
  created_by: string | null;
  is_shadow: boolean;
  status: string;
  is_hidden: boolean;
};

let liveTargetPromise: Promise<LiveOwnerTarget> | null = null;

export function getServiceClient() {
  return createClient(requireEnv('NEXT_PUBLIC_SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export function getAnonClient() {
  return createClient(requireEnv('NEXT_PUBLIC_SUPABASE_URL'), requireEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export async function discoverLiveOwnerTarget() {
  if (!liveTargetPromise) {
    liveTargetPromise = loadLiveOwnerTarget();
  }

  return liveTargetPromise;
}

async function loadLiveOwnerTarget(): Promise<LiveOwnerTarget> {
  const service = getServiceClient();
  const explicitBusinessId = process.env.PLAYWRIGHT_OWNER_SMOKE_BUSINESS_ID?.trim();
  const explicitOwnerEmail = process.env.PLAYWRIGHT_OWNER_SMOKE_EMAIL?.trim();
  const explicitNonOwnerEmail = process.env.PLAYWRIGHT_NON_OWNER_SMOKE_EMAIL?.trim();

  const { data: claims, error: claimsError } = await service
    .from('owner_claims')
    .select('business_id,user_id,status')
    .eq('status', 'approved');

  if (claimsError || !claims?.length) {
    throw new Error(`No approved owner_claims found: ${claimsError?.message ?? 'unknown error'}`);
  }

  const ownerClaims = explicitBusinessId
    ? claims.filter((claim) => claim.business_id === explicitBusinessId)
    : claims;

  if (!ownerClaims.length) {
    throw new Error(`No approved owner claim found for business ${explicitBusinessId}`);
  }

  const businessIds = Array.from(new Set(ownerClaims.map((claim) => claim.business_id)));
  const { data: menus, error: menusError } = await service
    .from('menus')
    .select('business_id,id,status')
    .in('business_id', businessIds)
    .eq('status', 'published');

  if (menusError || !menus?.length) {
    throw new Error(`No published menus found for owner claims: ${menusError?.message ?? 'unknown error'}`);
  }

  const publishedBusinessIds = Array.from(new Set(menus.map((menu) => menu.business_id)));
  const { data: items, error: itemsError } = await service
    .from('menu_items')
    .select('business_id,id')
    .in('business_id', publishedBusinessIds)
    .eq('is_available', true);

  if (itemsError || !items?.length) {
    throw new Error(`No available menu_items found for owner claims: ${itemsError?.message ?? 'unknown error'}`);
  }

  const itemCounts = new Map<string, number>();
  for (const item of items) {
    itemCounts.set(item.business_id, (itemCounts.get(item.business_id) ?? 0) + 1);
  }

  const eligibleClaims = ownerClaims
    .filter((claim) => publishedBusinessIds.includes(claim.business_id))
    .sort((a, b) => (itemCounts.get(b.business_id) ?? 0) - (itemCounts.get(a.business_id) ?? 0));

  if (!eligibleClaims.length) {
    throw new Error('No owner business with a published menu and available items found');
  }

  const ownerClaim = eligibleClaims[0];
  const { data: usersPage, error: usersError } = await service.auth.admin.listUsers({
    page: 1,
    perPage: 200,
  });

  if (usersError) {
    throw new Error(`Could not list auth users: ${usersError.message}`);
  }

  const users = usersPage.users;
  const ownerUser = users.find((user) => user.id === ownerClaim.user_id && user.email);
  if (!ownerUser?.email) {
    throw new Error(`Owner user email not found for user ${ownerClaim.user_id}`);
  }

  const ownerEmail = explicitOwnerEmail || ownerUser.email;
  const ownerUserId = ownerUser.id;
  const claimedUserIds = new Set(claims.map((claim) => claim.user_id));
  const nonOwnerUser = users.find(
    (user) => user.email && !claimedUserIds.has(user.id) && user.email !== ownerEmail,
  );
  const nonOwnerEmail = explicitNonOwnerEmail || nonOwnerUser?.email;

  if (!nonOwnerEmail) {
    throw new Error('Could not find a non-owner auth user for negative security smoke');
  }

  return {
    businessId: ownerClaim.business_id,
    ownerEmail,
    ownerUserId,
    nonOwnerEmail,
  };
}

export async function issueSession(email: string): Promise<SessionBundle> {
  const service = getServiceClient();
  const anon = getAnonClient();
  const { data: linkData, error: linkError } = await service.auth.admin.generateLink({
    type: 'magiclink',
    email,
  });

  if (linkError || !linkData.properties.email_otp) {
    throw new Error(`Could not generate magic link for ${email}: ${linkError?.message ?? 'missing otp'}`);
  }

  const { data, error } = await anon.auth.verifyOtp({
    email,
    token: linkData.properties.email_otp,
    type: 'magiclink',
  });

  if (error || !data.session || !data.user) {
    throw new Error(`Could not verify magic link for ${email}: ${error?.message ?? 'missing session'}`);
  }

  return {
    accessToken: data.session.access_token,
    refreshToken: data.session.refresh_token,
    user: data.user,
  };
}

export async function handoffQrSession(input: {
  request: {
    post: (url: string, options: Record<string, unknown>) => Promise<{
      ok: () => boolean;
      status: () => number;
      json: () => Promise<unknown>;
      text: () => Promise<string>;
    }>;
  };
  businessId: string;
  session: SessionBundle;
  lang?: string;
  theme?: string;
}) {
  const form = new FormData();
  form.set('access_token', input.session.accessToken);
  form.set('refresh_token', input.session.refreshToken);
  form.set('business_id', input.businessId);
  form.set('lang', input.lang ?? 'tr');
  form.set('theme', input.theme ?? 'bold');

  const response = await input.request.post('/auth/panel-handoff', {
    headers: {
      accept: 'application/json',
    },
    multipart: Object.fromEntries(form.entries()),
  });

  if (!response.ok()) {
    throw new Error(`Panel handoff failed: ${response.status()} ${await response.text()}`);
  }

  return (await response.json()) as { ok: boolean; redirectTo: string };
}

export async function uploadBrandingAsset(input: {
  request: {
    post: (url: string, options: Record<string, unknown>) => Promise<{
      ok: () => boolean;
      status: () => number;
      json: () => Promise<unknown>;
      text: () => Promise<string>;
    }>;
  };
  businessId: string;
  type: 'logo' | 'cover' | 'background';
  name: string;
  mimeType: 'image/png' | 'image/webp';
  buffer: Buffer;
}): Promise<{ url: string; path: string }> {
  const response = await input.request.post('/sunucu/medya/yukleme', {
    multipart: {
      businessId: input.businessId,
      type: input.type,
      file: {
        name: input.name,
        mimeType: input.mimeType,
        buffer: input.buffer,
      },
    },
  });

  const payload = (await response.json()) as {
    ok?: boolean;
    data?: { url?: string; path?: string };
    error?: string;
  };

  if (!response.ok() || !payload.data?.url || !payload.data.path) {
    throw new Error(`Upload failed: ${response.status()} ${JSON.stringify(payload)}`);
  }

  return {
    url: payload.data.url,
    path: payload.data.path,
  };
}

export async function savePresentationSettingsViaApi(input: {
  request: {
    post: (url: string, options: Record<string, unknown>) => Promise<{
      ok: () => boolean;
      status: () => number;
      json: () => Promise<unknown>;
      text: () => Promise<string>;
    }>;
  };
  payload: {
    businessId: string;
    defaultLang: 'tr' | 'en';
    templateKey: 'minimal' | 'bold' | 'elegant' | 'photo-heavy' | 'dark-modern';
    settings: {
      backgroundMode: 'solid' | 'gradient' | 'image';
      accentPreset: 'brand' | 'slate' | 'forest' | 'amber' | 'rose' | 'custom';
      accentHex: string | null;
      headerLayout: 'left' | 'centered';
      cardStyle: 'compact' | 'comfortable';
      showFeatured: boolean;
      showTags: boolean;
      showAllergens: boolean;
      showCurrencySymbol: boolean;
      showLastUpdated: boolean;
      fontScale: 'normal' | 'large';
      layoutVariant: 'standard' | 'editorial' | 'immersive';
    };
    logoUrl: string | null;
    coverUrl: string | null;
    backgroundUrl: string | null;
  };
}) {
  const response = await input.request.post('/sunucu/sunum-ayarlari', {
    data: input.payload,
  });

  if (!response.ok()) {
    throw new Error(`Presentation save failed: ${response.status()} ${await response.text()}`);
  }

  return (await response.json()) as { ok: boolean };
}

export async function getPresentationSettingsRow(businessId: string) {
  const service = getServiceClient();
  const { data, error } = await service
    .from('business_menu_presentation_settings')
    .select('business_id,default_lang,template_key,settings,logo_url,cover_url,background_url')
    .eq('business_id', businessId)
    .maybeSingle();

  if (error) {
    throw new Error(`Could not read presentation settings: ${error.message}`);
  }

  return (data as PresentationRow | null) ?? null;
}

export async function restorePresentationSettingsRow(
  businessId: string,
  snapshot: PresentationRow | null,
) {
  const service = getServiceClient();
  if (!snapshot) {
    const { error } = await service
      .from('business_menu_presentation_settings')
      .delete()
      .eq('business_id', businessId);
    if (error) {
      throw new Error(`Could not delete presentation settings restore row: ${error.message}`);
    }
    return;
  }

  const { error } = await service.from('business_menu_presentation_settings').upsert(snapshot, {
    onConflict: 'business_id',
  });
  if (error) {
    throw new Error(`Could not restore presentation settings row: ${error.message}`);
  }
}

export async function insertBusinessMediaFixture(input: {
  businessId: string;
  ownerUserId: string;
  url: string;
}) {
  const service = getServiceClient();
  const payload = {
    business_id: input.businessId,
    kind: 'cover',
    url: input.url,
    url_large: input.url,
    url_thumb: input.url,
    provider: 'branding-smoke',
    created_by: input.ownerUserId,
    is_shadow: false,
    status: 'approved',
    is_hidden: false,
  };

  const { data, error } = await service
    .from('business_media')
    .insert(payload)
    .select('id,business_id,kind,url,url_large,url_thumb,provider,created_by,is_shadow,status,is_hidden')
    .single();

  if (error) {
    throw new Error(`Could not insert business_media fixture: ${error.message}`);
  }

  return data as BusinessMediaRow;
}

export async function deleteBusinessMediaFixture(id: string) {
  const service = getServiceClient();
  const { error } = await service.from('business_media').delete().eq('id', id);
  if (error) {
    throw new Error(`Could not delete business_media fixture ${id}: ${error.message}`);
  }
}

export async function deleteStoragePaths(paths: string[]) {
  if (paths.length === 0) return;

  const service = getServiceClient();
  const { error } = await service.storage.from('menu-media').remove(paths);
  if (error) {
    throw new Error(`Could not delete uploaded branding assets: ${error.message}`);
  }
}

export function createTinyPng(name: string) {
  return {
    name,
    mimeType: 'image/png' as const,
    buffer: Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2NkYGD4DwABBAEAeM1Z4QAAAABJRU5ErkJggg==',
      'base64',
    ),
  };
}

export function extractStoragePath(publicUrl: string) {
  const marker = '/storage/v1/object/public/menu-media/';
  const index = publicUrl.indexOf(marker);
  if (index === -1) {
    throw new Error(`Unexpected storage public URL: ${publicUrl}`);
  }

  return publicUrl.slice(index + marker.length);
}

function requireEnv(name: string) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required env var: ${name}`);
  }
  return value;
}
