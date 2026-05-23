import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';

const KDV = 0.18;

export async function GET(request: Request) {
  const url = new URL(request.url);
  const ay = url.searchParams.get('ay');
  const format = url.searchParams.get('format') ?? 'standard'; // standard | parasut | logo

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const simdi = new Date();
  let yil = simdi.getFullYear();
  let ayNum = simdi.getMonth() + 1;

  if (ay && /^\d{4}-\d{2}$/.test(ay)) {
    [yil, ayNum] = ay.split('-').map(Number);
  }

  const ayBaslangic = new Date(yil, ayNum - 1, 1).toISOString();
  const aySonu = new Date(yil, ayNum, 1).toISOString();

  const businesses = await getOwnerBusinesses<{ id: string; name: string }>(
    supabase as any,
    user.id,
    'id, name',
  );

  const businessIds = businesses.map((b: { id: string }) => b.id);
  const bizMap = Object.fromEntries(
    businesses.map((b: { id: string; name: string }) => [b.id, b.name]),
  );

  const { data: kalemler } = businessIds.length > 0
    ? await (supabase as any)
        .from('table_order_items')
        .select('business_id, price, quantity, created_at')
        .in('business_id', businessIds)
        .gte('created_at', ayBaslangic)
        .lt('created_at', aySonu)
        .order('created_at', { ascending: true })
    : { data: [] };

  const rows = (kalemler ?? []) as Array<{
    business_id: string;
    price: number;
    quantity: number;
    created_at: string;
  }>;

  let header: string;
  let lines: string[];
  let filename: string;

  if (format === 'parasut') {
    // Paraşüt muhasebe yazılımı import formatı
    header = 'Belge Tarihi,Belge No,Açıklama,Tutar,KDV Oranı,KDV Tutarı,Döviz,Hesap Kodu';
    lines = rows.map((r, i) => {
      const d = new Date(r.created_at).toLocaleDateString('tr-TR');
      const tutar = ((r.price ?? 0) / 100) * (r.quantity ?? 1);
      const kdv = tutar * KDV;
      return `${d},YDY-${String(i + 1).padStart(6,'0')},"${bizMap[r.business_id] ?? 'Satış'}",${(tutar - kdv).toFixed(2)},18,${kdv.toFixed(2)},TRY,600`;
    });
    filename = `parasut-${yil}-${String(ayNum).padStart(2,'0')}.csv`;
  } else if (format === 'logo') {
    // Logo Tiger / LUCA uyumlu format
    header = 'TARIH;FATURA_NO;ACIKLAMA;BRUT_TUTAR;KDV_ORANI;KDV_TUTARI;NET_TUTAR;PARA_BIRIMI';
    lines = rows.map((r, i) => {
      const d = new Date(r.created_at).toLocaleDateString('tr-TR').replace(/\./g, '/');
      const brut = ((r.price ?? 0) / 100) * (r.quantity ?? 1);
      const kdv = brut * KDV;
      const net = brut - kdv;
      return `${d};F${String(i + 1).padStart(8,'0')};${bizMap[r.business_id] ?? 'Yeedoy Sipariş'};${brut.toFixed(2)};18;${kdv.toFixed(2)};${net.toFixed(2)};TRY`;
    });
    filename = `logo-${yil}-${String(ayNum).padStart(2,'0')}.csv`;
  } else {
    // Standart format
    header = 'Tarih,İşletme,Tutar (₺),Miktar,Toplam (₺),KDV (%18),KDV Hariç (₺)';
    lines = rows.map(r => {
      const d = new Date(r.created_at).toLocaleDateString('tr-TR');
      const tutar = (r.price ?? 0) / 100;
      const miktar = r.quantity ?? 1;
      const toplam = tutar * miktar;
      const kdv = toplam * KDV;
      const net = toplam - kdv;
      return `${d},"${bizMap[r.business_id] ?? r.business_id}",${tutar.toFixed(2)},${miktar},${toplam.toFixed(2)},${kdv.toFixed(2)},${net.toFixed(2)}`;
    });
    filename = `finansal-rapor-${yil}-${String(ayNum).padStart(2,'0')}.csv`;
  }

  const csv = [header, ...lines].join('\n');

  return new Response('﻿' + csv, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  });
}
