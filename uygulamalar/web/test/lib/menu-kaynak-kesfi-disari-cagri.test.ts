import { afterEach, describe, expect, it, vi } from 'vitest';

describe('menuExtractorStartSourceDiscoveryJob', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.resetModules();
    delete process.env.MENU_EXTRACTOR_BASE_URL;
    delete process.env.MENU_EXTRACTOR_API_KEY;
  });

  it('server tarafında doğru endpoint, payload ve gizli API anahtarını kullanır', async () => {
    process.env.MENU_EXTRACTOR_BASE_URL = 'https://extractor.internal';
    process.env.MENU_EXTRACTOR_API_KEY = 'server-secret';
    const fetchSpy = vi.fn(async () => new Response(JSON.stringify({ job_id: 'external-job-1' }), { status: 201 }));
    vi.stubGlobal('fetch', fetchSpy);

    const { menuExtractorStartSourceDiscoveryJob } = await import('@/src/lib/menu-analiz/disari-cagri');
    const result = await menuExtractorStartSourceDiscoveryJob('https://ornek-restoran.com');

    expect(result).toEqual({ ok: true, jobId: 'external-job-1' });
    expect(fetchSpy).toHaveBeenCalledWith(
      'https://extractor.internal/v1/jobs/source-discovery',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'Content-Type': 'application/json',
          'X-API-Key': 'server-secret',
        }),
        body: JSON.stringify({ website_url: 'https://ornek-restoran.com', auto_extract: true }),
      }),
    );
  });

  it('401 cevabını kaynak bulunamadı yerine AUTH_ERROR olarak döndürür', async () => {
    process.env.MENU_EXTRACTOR_BASE_URL = 'https://extractor.internal';
    process.env.MENU_EXTRACTOR_API_KEY = 'wrong-secret';
    vi.stubGlobal('fetch', vi.fn(async () => new Response(JSON.stringify({ detail: 'Geçersiz API anahtarı' }), { status: 401 })));

    const { menuExtractorStartSourceDiscoveryJob } = await import('@/src/lib/menu-analiz/disari-cagri');

    await expect(menuExtractorStartSourceDiscoveryJob('https://ornek-restoran.com')).resolves.toEqual({
      ok: false,
      code: 'AUTH_ERROR',
      error: 'Menü analiz servisi kimlik doğrulaması başarısız oldu.',
    });
  });
});

describe('menuExtractorPollJob', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.resetModules();
    delete process.env.MENU_EXTRACTOR_BASE_URL;
    delete process.env.MENU_EXTRACTOR_API_KEY;
  });

  it('discovery extraction_started iken extraction_finished olmadan işi finished saymaz', async () => {
    process.env.MENU_EXTRACTOR_BASE_URL = 'https://extractor.internal';
    vi.stubGlobal('fetch', vi.fn(async () => new Response(JSON.stringify({
      status: 'finished',
      result: {
        outcome_status: 'SOURCE_FOUND_ITEMS_FOUND',
        extraction_started: true,
        extraction_finished: false,
        extracted_item_count: 0,
      },
    }), { status: 200 })));

    const { menuExtractorPollJob } = await import('@/src/lib/menu-analiz/disari-cagri');

    await expect(menuExtractorPollJob('job-1')).resolves.toEqual({ status: 'started' });
  });
});
