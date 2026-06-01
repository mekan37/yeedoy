/**
 * Yeedoy API Kontrat Tipleri
 * Oluşturulma: 2026-05-26
 *
 * Bu dosya tüm Next.js route handler ve Supabase RPC kontratları için
 * TypeScript tip tanımlarını içerir. Yeni bir endpoint yazıldığında
 * burada karşılık gelen tipler de güncellenmeli veya eklenmelidir.
 */

// ─── Standart Response Wrapper ───────────────────────────────────────────────

export interface ApiMeta {
  page?: number;
  page_size?: number;
  total?: number;
  has_more?: boolean;
}

export type ApiSuccess<T> = { data: T; meta?: ApiMeta };
export type ApiError = { error: string; code?: string; issues?: Record<string, string[]> };
export type ApiResponse<T> = ApiSuccess<T> | ApiError;

export function isApiError(r: ApiResponse<unknown>): r is ApiError {
  return 'error' in r;
}

// ─── Auth / Session ──────────────────────────────────────────────────────────

export type UserRole = 'super_admin' | 'admin' | 'community_mod' | 'user' | 'owner' | 'staff';

// ─── Business ────────────────────────────────────────────────────────────────

/** GET /api/owner/businesses */
export interface BusinessSummary {
  id: string;
  name: string;
  slug: string | null;
  public_slug: string | null;
  category: string | null;
  description: string | null;
  phone: string | null;
  city: string | null;
  district: string | null;
  address: string | null;
  is_active: boolean;
  is_verified: boolean;
  logo_url: string | null;
  cover_url: string | null;
  created_at: string;
}

/** PATCH /api/owner/businesses/[id] */
export interface BusinessUpdatePayload {
  name?: string;
  description?: string;
  city?: string;
  category?: string;
  phone?: string;
  website?: string;
}

export interface BusinessUpdateResult {
  id: string;
  name: string;
  description: string | null;
  city: string | null;
  category: string | null;
  phone: string | null;
  is_active: boolean;
}

// ─── Menu ─────────────────────────────────────────────────────────────────────

/** POST /api/owner/menus */
export interface CreateMenuPayload {
  business_id: string;
  title: string;
}

export interface MenuSummary {
  id: string;
  business_id: string;
  title: string;
  status: 'draft' | 'published' | 'archived';
  kind: string | null;
  created_at: string;
  updated_at: string | null;
}

// ─── Media Upload ─────────────────────────────────────────────────────────────

/** POST /api/media/upload */
export interface MediaUploadPayload {
  businessId: string;
  type: 'logo' | 'cover' | 'background';
  file: File;
}

export interface MediaUploadResult {
  bucket: string;
  path: string;
  url: string;
  mimeType: string;
  size: number;
}

// ─── Feedback ────────────────────────────────────────────────────────────────

/** POST /api/feedback */
export interface FeedbackPayload {
  businessId: string;
  rating: 1 | 2 | 3 | 4 | 5;
  category: 'menu' | 'price' | 'service' | 'app' | 'other';
  message?: string;
}

// ─── Admin — Claims ───────────────────────────────────────────────────────────

/** GET /api/admin/claims */
export interface AdminClaimsListResult {
  data: BusinessClaim[];
  meta: { total: number; page: number; page_size: number };
}

export interface BusinessClaim {
  id: string;
  created_at: string;
  status: string;
  user_id: string;
  business_id: string;
  full_name: string;
  phone: string;
  evidence_url: string | null;
  note: string | null;
}

// ─── Admin — Moderation ───────────────────────────────────────────────────────

/** POST /api/admin/moderation */
export interface ModerationPayload {
  action: 'approve' | 'reject' | 'suspend';
  target_type: string;
  target_id: string;
  reason?: string;
}

export interface ModerationResult {
  action: string;
  target_type: string;
  target_id: string;
  status: unknown;
}

// ─── Analytics / Track ───────────────────────────────────────────────────────

/** POST /api/track */
export type TrackEventName = 'page_view' | 'category_view' | 'item_view' | 'item_click' | 'qr_scanned';

export interface TrackEventPayload {
  eventName: TrackEventName;
  businessId: string;
  menuId?: string | null;
  source?: string;
  clientId?: string | null;
  meta?: Record<string, unknown>;
}

/** Standart analytics event şeması (RPC log_event_v1 ile hizalı) */
export interface AnalyticsEvent {
  /** snake_case: 'menu_view', 'qr_scanned', 'business_page_view' */
  event: string;
  properties: Record<string, unknown>;
  /** ISO 8601 */
  timestamp?: string;
  session_id?: string;
  /** Hash'lenmiş — PII içermez */
  user_id?: string;
}

// ─── Cache Invalidation ───────────────────────────────────────────────────────

/** POST /api/revalidate */
export interface RevalidatePayload {
  secret: string;
  slug?: string;
  businessId?: string;
}

export interface RevalidateResult {
  ok: true;
  invalidated: string[];
}

// ─── Supabase RPC Response Types ──────────────────────────────────────────────

/** get_dashboard_stats_today_v1 */
export interface DashboardStatsTodayResult {
  bugun_bekleyen: number;
  bugun_hazirlaniyor: number;
  bugun_tamamlanan: number;
  toplam_bugun: number;
  personel_performans: Array<{
    staff_id: string;
    siparis_sayisi: number;
    tamamlanan: number;
  }>;
}

/** search_nearby_businesses_v3 / nearby_businesses_v2 */
export interface NearbyBusinessResult {
  id: string;
  name: string;
  slug: string | null;
  public_slug: string | null;
  category: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  lat: number;
  lng: number;
  /** Metre cinsinden mesafe */
  distance_m?: number;
  avg_rating: number;
  review_count: number;
  is_active: boolean;
  is_verified: boolean;
  logo_url: string | null;
  cover_url: string | null;
}

/** get_business_detail_v1 */
export interface BusinessDetailResult {
  id: string;
  name: string;
  slug: string | null;
  public_slug: string | null;
  category: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  lat: number | null;
  lng: number | null;
  avg_rating: number;
  review_count: number;
  is_active: boolean;
  is_verified: boolean;
  logo_url: string | null;
  cover_url: string | null;
  latest_reviews: ReviewSummary[];
}

export interface ReviewSummary {
  id: string;
  user_id: string;
  rating: number;
  body: string | null;
  created_at: string;
  verified_visit: boolean;
}

/** get_business_reviews_v3 */
export interface BusinessReviewItem {
  id: string;
  user_id: string;
  rating: number;
  body: string | null;
  created_at: string;
  helpful_count: number;
  verified_visit: boolean;
  has_owner_reply: boolean;
}

/** get_weekly_contributor_leaderboard_v1 */
export interface WeeklyLeaderboardEntry {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  score: number;
  rank: number;
}

/** get_business_rating_summary_v2 */
export interface BusinessRatingSummary {
  avg_rating: number;
  review_count: number;
  distribution: Record<'1' | '2' | '3' | '4' | '5', number>;
}

/** get_pending_table_orders_v1 */
export interface TableOrderItem {
  id: string;
  business_id: string;
  table_no: string | null;
  status: 'pending' | 'seen' | 'waiting' | 'done';
  items_json: Array<{
    id: string;
    name: string;
    price: number;
    quantity: number;
    note?: string | null;
  }>;
  staff_note: string | null;
  processed_by: string | null;
  created_at: string;
  updated_at: string;
}

/** get_my_favorites_v1 */
export interface FavoriteBusinessItem {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  city: string | null;
  logo_url: string | null;
  avg_rating: number;
  review_count: number;
}

/** get_taste_matches_hybrid_v1 */
export interface TasteMatchResult {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  overlap_count: number;
  match_score: number;
}

/** get_collab_list_detail_v1 */
export interface CollabListDetail {
  id: string;
  title: string;
  description: string | null;
  owner_id: string;
  members: Array<{ user_id: string; display_name: string | null; role: string }>;
  items: Array<{
    id: string;
    business_id: string;
    business_name: string | null;
    vote_score: number;
    my_vote: -1 | 0 | 1;
  }>;
}

/** Exchange rates (get-exchange-rates edge function) */
export interface ExchangeRatesResult {
  ok: boolean;
  source: 'cache' | 'cache_stale' | 'tcmb';
  fetched_at: string;
  rates: { USD: number; EUR: number };
}
