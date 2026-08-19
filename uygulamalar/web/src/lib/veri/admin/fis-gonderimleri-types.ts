// Fiş Başvuruları için client-safe tipler ve sabitler.
// Sunucu-özel veri çekme fonksiyonları (next/headers'a bağımlı) fis-gonderimleri.ts içinde kalır —
// bu dosya bilinçli olarak hiçbir sunucu-özel modül import etmez, client component'ler
// (fis-satiri.tsx vb.) doğrudan buradan import eder.

export type FisGonderimDurumu = 'pending' | 'reviewed' | 'needs_followup' | 'all';

export type FisGonderim = {
  receipt_id: string;
  created_at: string;
  /** Maskelenmiş kullanıcı gösterimi — ham user_id asla UI'a verilmez */
  submitter_display: string;
  business_id: string | null;
  business_name: string | null;
  city: string | null;
  district: string | null;
  chain_name: string | null;
  /** Supabase Storage tam URL veya dış URL olabilir */
  image_url: string | null;
  matches_count: number;
  review_status: string;
  review_note: string | null;
};

export type FisGonderimOzeti = {
  total_count: number;
  pending_count: number;
  reviewed_count: number;
  needs_followup_count: number;
  zero_match_count: number;
  business_count: number;
  recent_24h_count: number;
};

export type FisGonderimSonucu = {
  list: FisGonderim[];
  count: number | null;
  hasNextPage: boolean;
  fetchError: boolean;
};

export const REVIEW_STATUS_LABELS: Record<string, string> = {
  pending: 'Bekliyor',
  reviewed: 'İncelendi',
  needs_followup: 'Takip Gerekli',
};

export const REVIEW_STATUS_STYLES: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  reviewed: 'bg-green-50 text-green-700',
  needs_followup: 'bg-blue-50 text-blue-700',
};
