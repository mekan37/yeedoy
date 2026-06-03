import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

// Admin ve moderator rolleri
const ADMIN_ROLES = ['super_admin', 'admin', 'community_mod'] as const;

// Desteklenen export tipleri
// PII notu: tüm RPC'ler aggregate/anonymized veri döndürür;
// bireysel kullanıcıya ait satır bu exportlara dahil değildir.
type ExportType = 'inflation' | 'trends' | 'regional';

const EXPORT_CONFIG: Record<
  ExportType,
  { rpc: string; params: (days: number, city: string | null) => Record<string, unknown>; filename: (days: number) => string }
> = {
  inflation: {
    rpc: 'admin_export_menu_inflation_csv_v1',
    params: (days) => ({ p_days: days }),
    filename: (days) => `yeedoy-fiyat-enflasyonu-${days}gun.csv`,
  },
  trends: {
    rpc: 'admin_export_anonymous_trends_csv_v1',
    params: (days) => ({ p_days: days }),
    filename: (days) => `yeedoy-anonim-trendler-${days}gun.csv`,
  },
  regional: {
    rpc: 'admin_export_regional_price_index_csv_v1',
    params: (days) => ({ p_days: days }),
    filename: (days) => `yeedoy-bolgesel-fiyat-endeksi-${days}gun.csv`,
  },
};

export async function GET(request: NextRequest) {
  // Rate limit: admin export başına 10 istek/dakika
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`admin-b2b-export:${identity}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  // Auth kontrolü
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  // Admin rol kontrolü
  const { data: profile, error: profileError } = await (supabase as any)
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError || !profile || !ADMIN_ROLES.includes(profile.role)) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  // Query parametrelerini parse et
  const { searchParams } = request.nextUrl;
  const rawType = searchParams.get('type') ?? 'inflation';
  const rawDays = parseInt(searchParams.get('days') ?? '90', 10);

  if (!Object.keys(EXPORT_CONFIG).includes(rawType)) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: { type: [`Geçersiz tip: ${rawType}. Kabul edilenler: inflation, trends, regional`] } },
      { status: 400 },
    );
  }

  const exportType = rawType as ExportType;
  const days = Math.min(Math.max(Number.isNaN(rawDays) ? 90 : rawDays, 7), 365);
  const config = EXPORT_CONFIG[exportType];

  // RPC çağrısı — is_admin() SECURITY DEFINER içinde kontrol edilir
  const { data: csvData, error: rpcError } = await (supabase as any).rpc(
    config.rpc,
    config.params(days, searchParams.get('city')),
  );

  if (rpcError) {
    logger.warn('Admin b2b export RPC failed', { rpc: config.rpc, error: rpcError.message });
    // is_admin() hatası → 403
    if (rpcError.message?.includes('not authorized') || rpcError.message?.includes('not_admin')) {
      return NextResponse.json({ error: 'forbidden' }, { status: 403 });
    }
    return NextResponse.json({ error: 'rpc_error' }, { status: 500 });
  }

  if (!csvData || (typeof csvData === 'string' && csvData.trim().length === 0)) {
    return NextResponse.json({ error: 'no_data' }, { status: 404 });
  }

  const csv = typeof csvData === 'string' ? csvData : rowsToCsv(csvData as Record<string, unknown>[]);

  // UTF-8 BOM — Excel'in Türkçe karakterleri doğru okuması için
  const BOM = '﻿';
  const filename = config.filename(days);

  return new NextResponse(BOM + csv, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}

/**
 * JSON satır dizisini CSV'ye çevirir.
 * RPC'ler zaten text döndürüyor; bu helper yalnızca fallback olarak kullanılır.
 */
function rowsToCsv(rows: Record<string, unknown>[]): string {
  if (!rows?.length) return '';
  const headers = Object.keys(rows[0]);
  const escape = (val: unknown): string => {
    const str = val == null ? '' : String(val);
    if (str.includes(',') || str.includes('"') || str.includes('\n')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  };
  return [headers.join(','), ...rows.map((row) => headers.map((h) => escape(row[h])).join(','))].join('\n');
}
