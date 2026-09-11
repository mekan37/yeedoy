import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/src/lib/auth/admin-guard', () => ({
  checkAdminAccess: vi.fn(async () => ({ authorized: true, userId: 'admin-1' })),
}));
vi.mock('@/src/lib/oran-siniri', () => ({ rateLimit: vi.fn(() => ({ ok: true })) }));
vi.mock('@/src/lib/taban-sunucu', () => ({ createSupabaseServerClient: vi.fn() }));
vi.mock('@/src/lib/menu-analiz/disari-cagri', () => ({
  menuExtractorStartSourceDiscoveryJob: vi.fn(),
  menuExtractorPollJob: vi.fn(),
}));

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { menuExtractorPollJob, menuExtractorStartSourceDiscoveryJob } from '@/src/lib/menu-analiz/disari-cagri';
import { menuAnalizBaslatUrl, menuAnalizDurumSorgula } from '@/app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-islemleri';

const liveSchemaResult = {
  selected_source: 'https://menumgelsin.com/visalcafe/menuler',
  selected_source_provider: 'menumgelsin',
  extraction_started: true,
  extraction_finished: true,
  extracted_item_count: 2,
  complete_item_count: 2,
  partial_item_count: 0,
  outcome_status: 'SOURCE_FOUND_ITEMS_FOUND',
  extraction_result: {
    source_type: 'html',
    content_type: 'text/html',
    result: {
      category_count: 1,
      item_count: 2,
      categories: [{
        name: 'TOSTLAR',
        items: [
          { name: 'KARIŞIK TOST', price: 190, currency: 'TRY', completeness: 'complete', price_missing: false },
          { name: 'KAŞARLI TOST', price: 180, currency: 'TRY', completeness: 'complete', price_missing: false },
        ],
      }],
    },
  },
};

describe('menuAnalizBaslatUrl', () => {
  beforeEach(() => vi.clearAllMocks());

  it('Menü Linki URL değerini legacy URL endpoint yerine source-discovery motoruna gönderir', async () => {
    vi.mocked(menuExtractorStartSourceDiscoveryJob).mockResolvedValue({ ok: true, jobId: 'external-job-1' });
    const rpc = vi.fn(async () => ({ data: 'internal-job-1', error: null }));
    vi.mocked(createSupabaseServerClient).mockResolvedValue({ rpc } as never);

    await expect(menuAnalizBaslatUrl(
      '11111111-1111-4111-8111-111111111111',
      'https://menumgelsin.com/visalcafe/menulerim',
    )).resolves.toEqual({ ok: true, jobId: 'internal-job-1' });

    expect(menuExtractorStartSourceDiscoveryJob).toHaveBeenCalledWith('https://menumgelsin.com/visalcafe/menulerim');
    expect(rpc).toHaveBeenCalledWith('admin_create_menu_extract_job_v1', expect.objectContaining({
      p_source_type: 'url',
      p_source_url: 'https://menumgelsin.com/visalcafe/menulerim',
    }));
  });

  it('finished canlı şemayı normalize edip mevcut staging/review RPC hattına aktarır', async () => {
    vi.mocked(menuExtractorPollJob).mockResolvedValue({ status: 'finished', result: liveSchemaResult });
    const rpc = vi.fn(async (name: string, _args?: Record<string, unknown>) => {
      if (name === 'admin_get_menu_extract_job_v1') {
        return {
          data: [{
            status: 'queued', error_message: null, external_job_id: 'external-job-1',
            source_type: 'url', source_url: 'https://menumgelsin.com/visalcafe/menulerim', result: null,
          }],
          error: null,
        };
      }
      return { data: null, error: null };
    });
    vi.mocked(createSupabaseServerClient).mockResolvedValue({ rpc } as never);

    const response = await menuAnalizDurumSorgula('11111111-1111-4111-8111-111111111111');

    expect(response).toEqual(expect.objectContaining({
      ok: true,
      data: expect.objectContaining({ status: 'finished' }),
    }));
    const finishCall = rpc.mock.calls.find(([name]) => name === 'admin_finish_menu_extract_job_v1');
    expect(finishCall?.[1]).toEqual(expect.objectContaining({
      p_items: [
        expect.objectContaining({ category_name: 'TOSTLAR', name: 'KARIŞIK TOST', price_cents: 19000 }),
        expect.objectContaining({ category_name: 'TOSTLAR', name: 'KAŞARLI TOST', price_cents: 18000 }),
      ],
    }));
  });
});
