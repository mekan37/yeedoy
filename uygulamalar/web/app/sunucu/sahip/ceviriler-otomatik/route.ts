import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { translateWithFallback, type TranslationEngine } from '@/src/lib/ceviri/motorlar';
import { z } from 'zod';

const schema = z.object({
  menuIds: z.array(z.string().uuid()).min(1).max(20),
  targetLocales: z.array(z.enum(['en', 'de', 'ar', 'fr', 'ru', 'zh'])).min(1).max(6),
});

type SupabaseAny = {
  from: (table: string) => any;
  rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const rl = rateLimit(`ceviri:${user.id}`, 2, 3_600_000); // 2/saat/kullanıcı
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { menuIds, targetLocales } = parsed.data;

  const { data: menuRows } = await sb.from('menus').select('id, business_id').in('id', menuIds) as
    { data: Array<{ id: string; business_id: string }> | null };

  const businessIds = Array.from(new Set((menuRows ?? []).map((m) => m.business_id)));
  if (businessIds.length !== 1) {
    return NextResponse.json({ error: 'menus_must_belong_to_one_business' }, { status: 400 });
  }
  const businessId = businessIds[0];

  const owned = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!owned) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  // Ön-kontrol: hangi diller plan limitine takılacak? (API çağrısı yapmadan önce öğren, kota harcama)
  const allowedLocales: string[] = [];
  const preSkippedLocales: string[] = [];
  for (const locale of targetLocales) {
    const { data: allowed } = await sb.rpc('check_translation_language_limit_v1', { p_business_id: businessId, p_locale: locale });
    if (allowed) allowedLocales.push(locale); else preSkippedLocales.push(locale);
  }

  if (allowedLocales.length === 0) {
    return NextResponse.json({ ok: true, translated: 0, byEngine: {}, skippedLocales: preSkippedLocales });
  }

  // menü → bölüm → ürün zinciri (menu_items'ta menu_id YOK, section_id üzerinden gidilir;
  // menu_sections'ta başlık kolonu 'title', 'name' değil)
  const { data: sections } = await sb.from('menu_sections').select('id, title, menu_id').in('menu_id', menuIds) as
    { data: Array<{ id: string; title: string; menu_id: string }> | null };

  const sectionIds = (sections ?? []).map((s) => s.id);

  const { data: items } = sectionIds.length === 0
    ? { data: [] as Array<{ id: string; name: string; description: string | null; section_id: string }> }
    : await sb.from('menu_items').select('id, name, description, section_id').in('section_id', sectionIds).limit(200) as
        { data: Array<{ id: string; name: string; description: string | null; section_id: string }> | null };

  const toTranslate = [
    ...((items ?? []).map((i) => ({ entity_type: 'item' as const, entity_id: i.id, name: i.name, description: i.description }))),
    ...((sections ?? []).map((s) => ({ entity_type: 'category' as const, entity_id: s.id, name: s.title, description: null as string | null }))),
  ];

  if (toTranslate.length === 0) {
    return NextResponse.json({ ok: true, translated: 0, byEngine: {}, skippedLocales: preSkippedLocales });
  }

  const { data: existing } = await sb.from('menu_translations').select('entity_id, locale')
    .in('entity_id', toTranslate.map((t) => t.entity_id)).in('locale', allowedLocales) as
    { data: Array<{ entity_id: string; locale: string }> | null };

  const existingSet = new Set((existing ?? []).map((e) => `${e.entity_id}:${e.locale}`));

  const byEngine: Partial<Record<TranslationEngine, number>> = {};
  const inserts: Array<{ entity_type: 'item' | 'category'; entity_id: string; locale: string; name: string; description: string | null }> = [];

  for (const entity of toTranslate) {
    for (const locale of allowedLocales) {
      if (existingSet.has(`${entity.entity_id}:${locale}`)) continue;

      const nameResult = await translateWithFallback(entity.name, locale);
      if (!nameResult) continue;

      let descriptionText: string | null = null;
      if (entity.description?.trim()) {
        const descResult = await translateWithFallback(entity.description, locale);
        descriptionText = descResult?.text ?? null;
      }

      inserts.push({ entity_type: entity.entity_type, entity_id: entity.entity_id, locale, name: nameResult.text, description: descriptionText });
      byEngine[nameResult.engine] = (byEngine[nameResult.engine] ?? 0) + 1;
    }
  }

  if (inserts.length === 0) {
    return NextResponse.json({ ok: true, translated: 0, byEngine, skippedLocales: preSkippedLocales });
  }

  const { data: bulkResult, error } = await sb.rpc('bulk_upsert_menu_translations_v1', {
    p_business_id: businessId,
    p_translations: inserts,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  const result = bulkResult as { inserted: number; skipped_locales: string[] };
  const skippedLocales = Array.from(new Set([...preSkippedLocales, ...(result.skipped_locales ?? [])]));

  return NextResponse.json({ ok: true, translated: result.inserted, byEngine, skippedLocales });
}
