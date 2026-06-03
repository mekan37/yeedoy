import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

export type YogunSaatSatiri = {
  hourOfDay: number;
  eventCount: number;
  avgEventCount: number;
  peakRank: number;
};

/**
 * Calls get_business_busy_hours_v1 RPC and returns 24 rows (hour 0–23).
 * Falls back to an empty 24-row array on error so callers always get
 * a predictable shape regardless of RPC availability.
 */
export async function getYogunSaatler(businessId: string): Promise<YogunSaatSatiri[]> {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as {
    rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
  };

  try {
    const { data, error } = await supabaseAny.rpc('get_business_busy_hours_v1', {
      p_business_id: businessId,
      p_days_back: 28,
    });

    if (error) {
      logger.warn('getYogunSaatler: RPC error', { businessId, error });
      return bosVeri();
    }

    if (!Array.isArray(data)) return bosVeri();

    return (data as Array<Record<string, unknown>>).map((row) => ({
      hourOfDay: Number(row.hour_of_day ?? 0),
      eventCount: Number(row.event_count ?? 0),
      avgEventCount: Number(row.avg_event_count ?? 0),
      peakRank: Number(row.peak_rank ?? 0),
    }));
  } catch (err) {
    logger.warn('getYogunSaatler: RPC threw', { businessId, err });
    return bosVeri();
  }
}

/** Returns 24 zero-filled rows (fallback when RPC is unavailable). */
function bosVeri(): YogunSaatSatiri[] {
  return Array.from({ length: 24 }, (_, i) => ({
    hourOfDay: i,
    eventCount: 0,
    avgEventCount: 0,
    peakRank: 0,
  }));
}
