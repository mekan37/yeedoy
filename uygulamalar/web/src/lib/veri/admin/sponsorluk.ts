import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

// ─── Tipler ─────────────────────────────────────────────────────────────────

export type SponsorLead = {
  lead_id: string;
  status: string;
  created_at: string;
  business_id: string;
  business_name: string;
  city: string;
  district: string;
  owner_user_id: string;
  phone: string | null;
  message: string | null;
  preferred_surface: string;
  preferred_targeting: Record<string, unknown>;
};

export type SponsorshipRow = {
  sponsorship_id: string;
  status: string;
  surface: string;
  created_at: string;
  business_id: string;
  business_name: string;
  city: string;
  district: string;
  package_id: string;
  starts_at: string | null;
  ends_at: string | null;
  daily_cap: number | null;
  total_cap: number | null;
  source: string;
  created_by: string | null;
};

export type SponsorPackage = {
  id: string;
  name: string;
  surface: string;
  duration_days: number;
  price_display: string;
  price_cents: number;
  currency_code: string;
  inventory_limit: number;
  is_active: boolean;
  created_at: string;
};

export type SponsorshipSummary = {
  active_sponsorships: number;
  pending_sponsorships: number;
  open_leads: number;
  impressions_30d: number;
  unique_users_30d: number;
  estimated_active_revenue_cents: number;
};

export const LEAD_STATUS_LABELS: Record<string, string> = {
  new: 'Yeni',
  contacted: 'İletişim Kuruldu',
  closed: 'Kapatıldı',
};

export const LEAD_STATUS_STYLES: Record<string, string> = {
  new: 'bg-amber-50 text-amber-700',
  contacted: 'bg-green-50 text-green-700',
  closed: 'bg-zinc-100 text-zinc-500',
};

export const SPONSORSHIP_STATUS_LABELS: Record<string, string> = {
  active: 'Aktif',
  pending: 'Beklemede',
  paused: 'Duraklatıldı',
  ended: 'Sona Erdi',
};

export const SPONSORSHIP_STATUS_STYLES: Record<string, string> = {
  active: 'bg-green-50 text-green-700',
  pending: 'bg-amber-50 text-amber-700',
  paused: 'bg-blue-50 text-blue-700',
  ended: 'bg-zinc-100 text-zinc-500',
};

// ─── Veri Fonksiyonları ──────────────────────────────────────────────────────

/**
 * admin_get_sponsorship_summary_v1 RPC'yi çağırır.
 * is_admin() kontrolü SQL içinde yapılır — admin değilse boş satır döner.
 */
export async function getAdminSponsorshipSummary(): Promise<SponsorshipSummary> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string) => any };

  try {
    const { data, error } = await sb.rpc('admin_get_sponsorship_summary_v1');
    if (error) {
      logger.warn('getAdminSponsorshipSummary: RPC hatası', { error });
      return emptySummary();
    }
    const row = Array.isArray(data) ? data[0] : data;
    if (!row) return emptySummary();
    return {
      active_sponsorships: row.active_sponsorships ?? 0,
      pending_sponsorships: row.pending_sponsorships ?? 0,
      open_leads: row.open_leads ?? 0,
      impressions_30d: row.impressions_30d ?? 0,
      unique_users_30d: row.unique_users_30d ?? 0,
      estimated_active_revenue_cents: Number(row.estimated_active_revenue_cents ?? 0),
    };
  } catch (err) {
    logger.warn('getAdminSponsorshipSummary: istisna', { err });
    return emptySummary();
  }
}

function emptySummary(): SponsorshipSummary {
  return {
    active_sponsorships: 0,
    pending_sponsorships: 0,
    open_leads: 0,
    impressions_30d: 0,
    unique_users_30d: 0,
    estimated_active_revenue_cents: 0,
  };
}

/**
 * admin_list_sponsorship_leads_v1 RPC'yi çağırır.
 * is_admin() kontrolü SQL içinde yapılır.
 */
export async function listAdminSponsorLeads(
  status?: string,
  limit = 100,
  offset = 0,
): Promise<SponsorLead[]> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  try {
    const { data, error } = await sb.rpc('admin_list_sponsorship_leads_v1', {
      p_status: status && status !== 'all' ? status : null,
      p_limit: limit,
      p_offset: offset,
    });
    if (error) {
      logger.warn('listAdminSponsorLeads: RPC hatası', { error });
      return [];
    }
    return (data ?? []) as SponsorLead[];
  } catch (err) {
    logger.warn('listAdminSponsorLeads: istisna', { err });
    return [];
  }
}

/**
 * admin_list_sponsorships_v1 RPC'yi çağırır.
 * is_admin() kontrolü SQL içinde yapılır.
 */
export async function listAdminSponsorships(
  status?: string,
  surface?: string,
  limit = 100,
  offset = 0,
): Promise<SponsorshipRow[]> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  try {
    const { data, error } = await sb.rpc('admin_list_sponsorships_v1', {
      p_status: status && status !== 'all' ? status : null,
      p_surface: surface && surface !== 'all' ? surface : null,
      p_limit: limit,
      p_offset: offset,
    });
    if (error) {
      logger.warn('listAdminSponsorships: RPC hatası', { error });
      return [];
    }
    return (data ?? []) as SponsorshipRow[];
  } catch (err) {
    logger.warn('listAdminSponsorships: istisna', { err });
    return [];
  }
}

/**
 * sponsorship_packages tablosunu doğrudan sorgular (admin RLS politikası).
 */
export async function listAdminSponsorPackages(): Promise<SponsorPackage[]> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { from: (t: string) => any };

  try {
    const { data, error } = await sb
      .from('sponsorship_packages')
      .select('id, name, surface, duration_days, price_display, price_cents, currency_code, inventory_limit, is_active, created_at')
      .order('price_cents', { ascending: true });
    if (error) {
      logger.warn('listAdminSponsorPackages: sorgu hatası', { error });
      return [];
    }
    return (data ?? []) as SponsorPackage[];
  } catch (err) {
    logger.warn('listAdminSponsorPackages: istisna', { err });
    return [];
  }
}
