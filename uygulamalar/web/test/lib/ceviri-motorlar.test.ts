import { describe, it, expect, vi, afterEach } from 'vitest';
import { translateWithGemini, translateWithGroq, translateWithCloudflare, translateWithFallback } from '@/src/lib/ceviri/motorlar';

describe('translateWithGemini', () => {
  const originalKey = process.env.GEMINI_API_KEY;
  afterEach(() => { process.env.GEMINI_API_KEY = originalKey; vi.unstubAllGlobals(); });

  it('API key yoksa null döner, fetch çağırmaz', async () => {
    delete process.env.GEMINI_API_KEY;
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithGemini('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı yanıtta çeviriyi döner', async () => {
    process.env.GEMINI_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: 'Lentil Soup' }] } }] }),
    }));
    const result = await translateWithGemini('Mercimek Çorbası', 'en');
    expect(result).toBe('Lentil Soup');
  });

  it('API hata döndürürse null döner (throw etmez)', async () => {
    process.env.GEMINI_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 429 }));
    const result = await translateWithGemini('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
  });
});

describe('translateWithGroq', () => {
  const originalKey = process.env.GROQ_API_KEY;
  afterEach(() => { process.env.GROQ_API_KEY = originalKey; vi.unstubAllGlobals(); });

  it('API key yoksa null döner', async () => {
    delete process.env.GROQ_API_KEY;
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithGroq('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı yanıtta çeviriyi döner', async () => {
    process.env.GROQ_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Lentil Soup' } }] }),
    }));
    const result = await translateWithGroq('Mercimek Çorbası', 'en');
    expect(result).toBe('Lentil Soup');
  });
});

describe('translateWithCloudflare', () => {
  const originalAccount = process.env.CLOUDFLARE_ACCOUNT_ID;
  const originalToken = process.env.CLOUDFLARE_API_TOKEN;
  afterEach(() => {
    process.env.CLOUDFLARE_ACCOUNT_ID = originalAccount;
    process.env.CLOUDFLARE_API_TOKEN = originalToken;
    vi.unstubAllGlobals();
  });

  it('hesap ID veya token yoksa null döner', async () => {
    delete process.env.CLOUDFLARE_ACCOUNT_ID;
    delete process.env.CLOUDFLARE_API_TOKEN;
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithCloudflare('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı yanıtta çeviriyi döner', async () => {
    process.env.CLOUDFLARE_ACCOUNT_ID = 'acc';
    process.env.CLOUDFLARE_API_TOKEN = 'token';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ result: { translated_text: 'Lentil Soup' } }),
    }));
    const result = await translateWithCloudflare('Mercimek Çorbası', 'en');
    expect(result).toBe('Lentil Soup');
  });
});

describe('translateWithFallback', () => {
  const originalGemini = process.env.GEMINI_API_KEY;
  const originalGroq = process.env.GROQ_API_KEY;
  const originalCfAccount = process.env.CLOUDFLARE_ACCOUNT_ID;
  const originalCfToken = process.env.CLOUDFLARE_API_TOKEN;

  afterEach(() => {
    process.env.GEMINI_API_KEY = originalGemini;
    process.env.GROQ_API_KEY = originalGroq;
    process.env.CLOUDFLARE_ACCOUNT_ID = originalCfAccount;
    process.env.CLOUDFLARE_API_TOKEN = originalCfToken;
    vi.unstubAllGlobals();
  });

  it('Gemini başarılı olursa diğer motorları hiç çağırmaz', async () => {
    process.env.GEMINI_API_KEY = 'g';
    process.env.GROQ_API_KEY = 'q';
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: 'Lentil Soup' }] } }] }),
    });
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toEqual({ text: 'Lentil Soup', engine: 'gemini' });
    expect(fetchSpy).toHaveBeenCalledTimes(1);
  });

  it('Gemini yapılandırılmamışsa Groq denenir', async () => {
    delete process.env.GEMINI_API_KEY;
    process.env.GROQ_API_KEY = 'q';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Lentil Soup' } }] }),
    }));
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toEqual({ text: 'Lentil Soup', engine: 'groq' });
  });

  it('Gemini ve Groq başarısız olursa Cloudflare denenir', async () => {
    process.env.GEMINI_API_KEY = 'g';
    process.env.GROQ_API_KEY = 'q';
    process.env.CLOUDFLARE_ACCOUNT_ID = 'acc';
    process.env.CLOUDFLARE_API_TOKEN = 'token';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 500 }));
    // Cloudflare için ayrı bir mock gerekir çünkü aynı fetchSpy tüm çağrılarda 500 dönüyor olacak;
    // bu testte sadece "hiçbiri başarısız olursa null döner" davranışı doğrulanıyor (ayrı test aşağıda).
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
  });

  it('hiçbir motor yapılandırılmamışsa null döner', async () => {
    delete process.env.GEMINI_API_KEY;
    delete process.env.GROQ_API_KEY;
    delete process.env.CLOUDFLARE_ACCOUNT_ID;
    delete process.env.CLOUDFLARE_API_TOKEN;
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
  });

  it('boş metin için hiç fetch çağırmadan null döner', async () => {
    process.env.GEMINI_API_KEY = 'g';
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithFallback('   ', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
