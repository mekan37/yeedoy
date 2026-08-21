const TIMEOUT_MS = 8_000;

async function fetchWithTimeout(url: string, init: RequestInit): Promise<Response | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, { ...init, signal: controller.signal });
    return res;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

const LANG_NAMES: Record<string, string> = {
  en: 'English', de: 'German', ar: 'Arabic', fr: 'French', ru: 'Russian', zh: 'Chinese',
};

function buildPrompt(text: string, targetLocale: string): string {
  const langName = LANG_NAMES[targetLocale] ?? targetLocale;
  return `Translate the following restaurant menu text from Turkish to ${langName}. Return only the translation, nothing else, no quotes, no explanation.\n\n${text}`;
}

export async function translateWithGemini(text: string, targetLocale: string): Promise<string | null> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || !text.trim()) return null;

  const res = await fetchWithTimeout(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: buildPrompt(text, targetLocale) }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 200 },
      }),
    },
  );
  if (!res || !res.ok) return null;

  try {
    const data = await res.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
    const translated = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    return translated || null;
  } catch {
    return null;
  }
}

export async function translateWithGroq(text: string, targetLocale: string): Promise<string | null> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey || !text.trim()) return null;

  const langName = LANG_NAMES[targetLocale] ?? targetLocale;
  const res = await fetchWithTimeout('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages: [
        { role: 'system', content: `Translate the following restaurant menu text from Turkish to ${langName}. Return only the translation, nothing else, no quotes, no explanation.` },
        { role: 'user', content: text },
      ],
      max_tokens: 200,
      temperature: 0.2,
    }),
  });
  if (!res || !res.ok) return null;

  try {
    const data = await res.json() as { choices?: Array<{ message?: { content?: string } }> };
    const translated = data.choices?.[0]?.message?.content?.trim();
    return translated || null;
  } catch {
    return null;
  }
}

export async function translateWithCloudflare(text: string, targetLocale: string): Promise<string | null> {
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  const apiToken = process.env.CLOUDFLARE_API_TOKEN;
  if (!accountId || !apiToken || !text.trim()) return null;

  const res = await fetchWithTimeout(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/@cf/meta/m2m100-1.2b`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiToken}` },
      body: JSON.stringify({ text, source_lang: 'tr', target_lang: targetLocale }),
    },
  );
  if (!res || !res.ok) return null;

  try {
    const data = await res.json() as { result?: { translated_text?: string } };
    const translated = data.result?.translated_text?.trim();
    return translated || null;
  } catch {
    return null;
  }
}

export type TranslationEngine = 'gemini' | 'groq' | 'cloudflare';
export interface TranslationOutcome { text: string; engine: TranslationEngine; }

const ENGINE_CHAIN: ReadonlyArray<{ name: TranslationEngine; run: (text: string, targetLocale: string) => Promise<string | null> }> = [
  { name: 'gemini', run: translateWithGemini },
  { name: 'groq', run: translateWithGroq },
  { name: 'cloudflare', run: translateWithCloudflare },
];

export async function translateWithFallback(text: string, targetLocale: string): Promise<TranslationOutcome | null> {
  if (!text.trim()) return null;
  for (const engine of ENGINE_CHAIN) {
    const result = await engine.run(text, targetLocale);
    if (result) return { text: result, engine: engine.name };
  }
  return null;
}
