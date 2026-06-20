import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/rate-limit';
import { z } from 'zod';

const schema = z.object({
  businessId: z.string().uuid(),
  fullName: z.string().min(1).max(200).transform((s) => s.trim()),
  phone: z.string().min(1).max(30).transform((s) => s.trim()),
  note: z.string().max(1000).nullish().transform((s) => s?.trim() || null),
  evidenceUrl: z.string().url().nullish().transform((s) => s?.trim() || null),
});

function ownerClaimErrorMessage(code: unknown): { message: string; status: number } {
  switch (String(code ?? '')) {
    case 'not_authenticated':
      return { message: 'Giriş yapmanız gerekiyor.', status: 401 };
    case 'missing_business_id':
      return { message: 'İşletme bilgisi eksik.', status: 400 };
    case 'rate_limited_7d':
      return {
        message: 'Bu işletme için yakın zamanda başvuru yaptınız. Yeni başvuru için lütfen 7 gün bekleyin.',
        status: 429,
      };
    case 'already_submitted':
      return {
        message: 'Bu işletme için zaten bir sahiplik başvurunuz var.',
        status: 409,
      };
    default:
      return { message: 'Talep kaydedilemedi. Lütfen tekrar deneyin.', status: 500 };
  }
}

export async function POST(request: NextRequest) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Giriş yapmanız gerekiyor.' }, { status: 401 });
  }

  const rl = rateLimit(`claim:submit:${user.id}`, 5, 15 * 60 * 1000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'Çok fazla istek gönderdiniz. Lütfen bekleyin.' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = schema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Geçersiz veri.' }, { status: 400 });
  }

  const { businessId, fullName, phone, note, evidenceUrl } = parsed.data;

  const supabaseAny = supabase as unknown as {
    rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
  };

  // İşletme var mı?
  const { data: biz } = await supabase
    .from('businesses')
    .select('id')
    .eq('id', businessId)
    .eq('is_active', true)
    .maybeSingle();

  if (!biz) {
    return NextResponse.json({ error: 'İşletme bulunamadı.' }, { status: 404 });
  }

  const { data, error } = await supabaseAny.rpc('submit_owner_claim_v1', {
    p_business_id: businessId,
    p_full_name: fullName,
    p_phone: phone,
    p_evidence_url: evidenceUrl,
    p_note: note,
  });

  if (error) {
    return NextResponse.json(
      { error: 'Talep kaydedilemedi. Lütfen tekrar deneyin.' },
      { status: 500 },
    );
  }

  const result = data as { ok?: boolean; error?: string; claim_id?: string } | null;
  if (!result?.ok) {
    const mapped = ownerClaimErrorMessage(result?.error);
    return NextResponse.json({ error: mapped.message }, { status: mapped.status });
  }

  return NextResponse.json({ ok: true, claimId: result.claim_id });
}
