import { NextResponse } from 'next/server';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const runtime = 'edge';
export const revalidate = 3600;

// Herkese açık Fiyat Endeksi CSV — medya ve araştırmacılar için
// Atıf: "Yeedoy Restoran Fiyat Endeksi, yeedoy.com/fiyat-endeksi"
export async function GET() {
  try {
    const supabase = createSupabasePublicClient();
    const { data } = await (supabase as any).rpc('get_regional_price_index_v2', {
      p_city: null,
      p_district: null,
      p_limit: 50,
    }) as { data: Array<{
      category: string;
      median_price_cents: number;
      avg_price_cents: number;
      sample_count: number;
      updated_in_30d: number;
    }> | null };

    const rows = (data ?? []).filter((r) => r.sample_count >= 3);
    const now = new Date();
    const period = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    const header = 'kategori,medyan_fiyat_tl,ortalama_fiyat_tl,ornek_sayisi,guncellenen_30g,donem,kaynak\r\n';
    const lines = rows.map((r) => [
      `"${r.category}"`,
      (r.median_price_cents / 100).toFixed(2),
      (r.avg_price_cents / 100).toFixed(2),
      r.sample_count,
      r.updated_in_30d,
      period,
      '"Yeedoy Restoran Fiyat Endeksi — yeedoy.com/fiyat-endeksi"',
    ].join(','));

    const csv = header + lines.join('\r\n');
    const filename = `yeedoy-fiyat-endeksi-${period}.csv`;

    return new NextResponse(csv, {
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'public, max-age=3600, s-maxage=3600',
        'X-Data-Source': 'Yeedoy Topluluk Fiyat Verisi',
        'X-Period': period,
      },
    });
  } catch {
    return NextResponse.json({ error: 'Veri yüklenemedi' }, { status: 500 });
  }
}
