import { NextResponse } from 'next/server';
import Replicate from 'replicate';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';

const MAX_SIZE_BYTES = 8 * 1024 * 1024; // 8 MB

const DEEPSEEK_OCR_MODEL =
  'lucataco/deepseek-ocr:cb3b474fbfc56b1664c8c7841550bccecbe7b74c30e45ce938ffca1180b4dff5' as const;

const OCR_PROMPT =
  'Bu bir restoran fişi veya makbuzudur. Lütfen görseldeki tüm metni, fiyatları, ürün adlarını, tarih ve toplam tutarı çıkar. Her satırı ayrı ayrı listele.';

const VISION_SYSTEM_PROMPT = `Sen bir restoran fişi OCR asistanısın. Sana verilen görüntüdeki fişi analiz et ve şu JSON formatında yanıt ver:
{
  "isletme": "işletme adı veya null",
  "tarih": "GG.AA.YYYY formatında tarih veya null",
  "toplam": "XX.XX formatında toplam tutar veya null",
  "kdv": "XX.XX formatında KDV tutarı veya null",
  "kalemler": [
    {"ad": "ürün adı", "adet": 1, "fiyat": "X.XX", "kategori": "yiyecek|icecek|diger"}
  ],
  "guven": 0.0-1.0 arası güven skoru,
  "restoran_fisi": true/false
}
Fiyatları sayısal değer olarak yaz, ₺ işareti olmadan. Sadece JSON döndür.`;

interface ReceiptItem {
  ad: string;
  adet?: number;
  fiyat: string;
  kategori?: string;
}

interface ParsedReceipt {
  isletme: string | null;
  tarih: string | null;
  toplam: string | null;
  kdv: string | null;
  kalemler: ReceiptItem[];
  guven: number;
  restoranFisi: boolean;
  rawOcr?: string;
  model?: string;
}

// ─── OpenAI Vision (GPT-4o-mini) ─────────────────────────────────────────────

async function openaiVision(
  base64: string,
  mime: string,
  apiKey: string,
): Promise<ParsedReceipt> {
  const body = {
    model: 'gpt-4o-mini',
    max_tokens: 1024,
    messages: [
      { role: 'system', content: VISION_SYSTEM_PROMPT },
      {
        role: 'user',
        content: [
          {
            type: 'image_url',
            image_url: { url: `data:${mime};base64,${base64}`, detail: 'high' },
          },
          { type: 'text', text: 'Bu fişteki bilgileri çıkar.' },
        ],
      },
    ],
    response_format: { type: 'json_object' },
  };

  const resp = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errBody = await resp.json().catch(() => ({})) as { error?: { message?: string } };
    throw new Error(errBody.error?.message ?? `OpenAI API hatası: ${resp.status}`);
  }

  const data = await resp.json() as {
    choices: Array<{ message: { content: string } }>;
  };
  const content = data.choices[0]?.message?.content ?? '{}';
  const p = JSON.parse(content) as {
    isletme?: string | null;
    tarih?: string | null;
    toplam?: string | null;
    kdv?: string | null;
    kalemler?: ReceiptItem[];
    guven?: number;
    restoran_fisi?: boolean;
  };

  const fmt = (v: string | null | undefined) =>
    v && v !== 'null' ? (v.includes('₺') ? v : `₺${v}`) : null;

  return {
    isletme: p.isletme ?? null,
    tarih: p.tarih ?? null,
    toplam: fmt(p.toplam),
    kdv: fmt(p.kdv),
    kalemler: (p.kalemler ?? []).map((k) => ({
      ...k,
      fiyat: fmt(k.fiyat) ?? k.fiyat,
    })),
    guven: p.guven ?? 0.85,
    restoranFisi: p.restoran_fisi ?? true,
    model: 'gpt-4o-mini',
  };
}

// ─── DeepSeek OCR via Replicate ───────────────────────────────────────────────

function parseReceiptText(rawText: string) {
  const lines = rawText.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  let isletme: string | null = null;
  let tarih: string | null = null;
  let toplam: string | null = null;
  const kalemler: ReceiptItem[] = [];

  const dateRe = /\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b/;
  const priceRe = /(\d[\d.,]*)\s*(?:₺|TL|lira)?/i;
  const totalKw = /toplam|total|genel|tutar|ödenecek|öde/i;
  const itemRe = /^(.+?)\s{2,}(\d[\d.,]*)\s*(?:₺|TL)?$/;

  for (const line of lines) {
    const dateMatch = line.match(dateRe);
    if (dateMatch && !tarih) {
      const [, d, m, y] = dateMatch;
      const year = y.length === 2 ? `20${y}` : y;
      tarih = `${d.padStart(2, '0')}.${m.padStart(2, '0')}.${year}`;
    }
    if (totalKw.test(line)) {
      const pm = line.match(priceRe);
      if (pm && !toplam) toplam = `₺${pm[1]}`;
    }
    const im = line.match(itemRe);
    if (im && !totalKw.test(line)) {
      const [, ad, fiyat] = im;
      if (ad.length > 1) kalemler.push({ ad: ad.trim(), fiyat: `₺${fiyat}` });
    }
    if (!isletme && line.length > 3 && line.length < 60 && !dateRe.test(line) && !/^\d/.test(line)) {
      isletme = line;
    }
  }
  return { isletme, tarih, toplam, kalemler };
}

async function deepseekOcr(dataUri: string, apiToken: string): Promise<ParsedReceipt> {
  const replicate = new Replicate({ auth: apiToken });
  const output = await replicate.run(DEEPSEEK_OCR_MODEL, {
    input: { image: dataUri, prompt: OCR_PROMPT, max_new_tokens: 1024 },
  });
  const rawText = Array.isArray(output)
    ? (output as string[]).join('')
    : String(output ?? '');
  const parsed = parseReceiptText(rawText);
  return {
    ...parsed,
    kdv: null,
    guven: 0.65,
    restoranFisi: true,
    rawOcr: rawText.slice(0, 600),
    model: 'deepseek-ocr',
  };
}

// ─── Handler ──────────────────────────────────────────────────────────────────

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const limit = rateLimit(`makbuz_ocr:${user.id}`, 5, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'Çok fazla istek. Lütfen bekleyin.' }, { status: 429 });
  }

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json({ error: 'Form verisi okunamadı' }, { status: 400 });
  }

  const file = formData.get('makbuz');
  if (!(file instanceof Blob)) {
    return NextResponse.json({ error: 'Dosya bulunamadı. "makbuz" alanını gönderin.' }, { status: 400 });
  }
  if (file.size > MAX_SIZE_BYTES) {
    return NextResponse.json({ error: 'Dosya çok büyük. Maks 8 MB.' }, { status: 413 });
  }
  const mime = file.type;
  if (!mime.startsWith('image/')) {
    return NextResponse.json({ error: 'Sadece görsel dosyalar kabul edilir.' }, { status: 415 });
  }

  const buffer = Buffer.from(await file.arrayBuffer());
  const base64 = buffer.toString('base64');
  const dataUri = `data:${mime};base64,${base64}`;

  const openaiKey = process.env.OPENAI_API_KEY;
  const replicateKey = process.env.REPLICATE_API_TOKEN;

  if (!openaiKey && !replicateKey) {
    const now = new Date();
    const d = now.getDate().toString().padStart(2, '0');
    const m = (now.getMonth() + 1).toString().padStart(2, '0');
    return NextResponse.json({
      tarih: `${d}.${m}.${now.getFullYear()}`,
      isletme: null,
      toplam: null,
      kdv: null,
      kalemler: [],
      guven: 0,
      restoranFisi: true,
      model: 'mock',
      mesaj: 'Fotoğraf okuma şu an kullanılamıyor. Bilgileri kendiniz girebilirsiniz.',
    });
  }

  try {
    let result: ParsedReceipt;

    if (openaiKey) {
      result = await openaiVision(base64, mime, openaiKey);
    } else {
      result = await deepseekOcr(dataUri, replicateKey!);
    }

    if (!result.toplam && !result.isletme && result.kalemler.length === 0) {
      return NextResponse.json({
        ...result,
        mesaj: 'Fiş okunamadı. Daha aydınlık ve net bir fotoğraf deneyin.',
      });
    }

    return NextResponse.json(result);
  } catch (err) {
    if (openaiKey && replicateKey) {
      try {
        const fallback = await deepseekOcr(dataUri, replicateKey);
        return NextResponse.json({ ...fallback, mesaj: 'Yedek OCR motoru kullanıldı.' });
      } catch (_) { /* ignore */ }
    }
    return NextResponse.json({ error: 'ocr_failed' }, { status: 502 });
  }
}
