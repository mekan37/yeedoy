import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  menuIds: z.array(z.string().uuid()).min(1).max(20),
  targetLocales: z.array(z.enum(['en', 'de', 'ar', 'fr', 'ru', 'zh'])).min(1).max(6),
  engine: z.enum(['openai', 'deepl']).default('openai'),
});

async function translateWithOpenAI(text: string, targetLang: string): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error('OPENAI_API_KEY not configured');

  const langNames: Record<string, string> = { en: 'English', de: 'German', ar: 'Arabic', fr: 'French', ru: 'Russian', zh: 'Chinese' };

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: `Translate the following menu item name from Turkish to ${langNames[targetLang] ?? targetLang}. Return only the translation, nothing else. Keep it concise and suitable for a restaurant menu.` },
        { role: 'user', content: text },
      ],
      max_tokens: 100,
      temperature: 0.3,
    }),
  });

  if (!res.ok) throw new Error('OpenAI API error');
  const data = await res.json() as { choices: Array<{ message: { content: string } }> };
  return data.choices[0]?.message?.content?.trim() ?? text;
}

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { menuIds, targetLocales, engine } = parsed.data;

  // Fetch menu items + sections
  const { data: items } = await (supabase as any)
    .from('menu_items')
    .select('id, name')
    .in('menu_id', menuIds)
    .limit(200) as { data: Array<{ id: string; name: string }> | null };

  const { data: sections } = await (supabase as any)
    .from('menu_sections')
    .select('id, name')
    .in('menu_id', menuIds)
    .limit(50) as { data: Array<{ id: string; name: string }> | null };

  const toTranslate = [
    ...((items ?? []).map(i => ({ entity_type: 'menu_item', entity_id: i.id, name: i.name }))),
    ...((sections ?? []).map(s => ({ entity_type: 'section', entity_id: s.id, name: s.name }))),
  ];

  if (toTranslate.length === 0) return NextResponse.json({ ok: true, translated: 0 });

  // Check existing translations to avoid duplicates
  const { data: existing } = await (supabase as any)
    .from('menu_translations')
    .select('entity_id, locale')
    .in('entity_id', toTranslate.map(t => t.entity_id))
    .in('locale', targetLocales) as { data: Array<{ entity_id: string; locale: string }> | null };

  const existingSet = new Set((existing ?? []).map(e => `${e.entity_id}:${e.locale}`));

  let translated = 0;
  const inserts: Array<{ entity_type: string; entity_id: string; locale: string; name: string }> = [];

  for (const item of toTranslate) {
    for (const locale of targetLocales) {
      if (existingSet.has(`${item.entity_id}:${locale}`)) continue;
      try {
        const translatedName = engine === 'openai'
          ? await translateWithOpenAI(item.name, locale)
          : item.name; // DeepL integration placeholder

        inserts.push({ entity_type: item.entity_type, entity_id: item.entity_id, locale, name: translatedName });
        translated++;

        // Rate limit: avoid hitting API too fast
        if (translated % 10 === 0) await new Promise(r => setTimeout(r, 500));
      } catch {
        // Skip failed items, continue
      }
    }
  }

  if (inserts.length > 0) {
    await (supabase as any).from('menu_translations').insert(inserts);
  }

  return NextResponse.json({ ok: true, translated });
}
