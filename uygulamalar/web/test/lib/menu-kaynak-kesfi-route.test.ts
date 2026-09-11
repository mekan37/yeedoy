import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/src/lib/auth/admin-guard', () => ({ checkAdminAccess: vi.fn() }));
vi.mock('@/src/lib/oran-siniri', () => ({
  getClientIp: vi.fn(() => '127.0.0.1'),
  getRequestIdentity: vi.fn(() => 'test-admin'),
  rateLimit: vi.fn(() => ({ ok: true })),
}));
vi.mock('@/src/lib/taban/sunucu', () => ({ createSupabaseServerClient: vi.fn() }));
vi.mock('@/src/lib/menu-analiz/disari-cagri', () => ({ menuExtractorStartSourceDiscoveryJob: vi.fn() }));

import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { menuExtractorStartSourceDiscoveryJob } from '@/src/lib/menu-analiz/disari-cagri';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { POST, sourceDiscoveryRequestSchema } from '@/app/api/yonetici/menu-analiz/kaynak-kesfi/route';

beforeEach(() => vi.clearAllMocks());

describe('sourceDiscoveryRequestSchema', () => {
  it('geçerli işletme kimliği ve website URL değerini kabul eder', () => {
    expect(sourceDiscoveryRequestSchema.safeParse({
      business_id: '11111111-1111-4111-8111-111111111111',
      website_url: 'https://ornek-restoran.com',
    }).success).toBe(true);
  });

  it('extractor seçeneklerinin browser payload ile değiştirilmesini reddeder', () => {
    expect(sourceDiscoveryRequestSchema.safeParse({
      business_id: '11111111-1111-4111-8111-111111111111',
      website_url: 'https://ornek-restoran.com',
      auto_extract: false,
      api_key: 'client-secret',
    }).success).toBe(false);
  });

  it('yetkili isteği staging job olarak kaydeder ve secret bilgisini response içine koymaz', async () => {
    vi.mocked(checkAdminAccess).mockResolvedValue({ authorized: true, userId: 'admin-1' });
    vi.mocked(menuExtractorStartSourceDiscoveryJob).mockResolvedValue({ ok: true, jobId: 'external-job-1' });
    const rpc = vi.fn(async () => ({ data: 'internal-job-1', error: null }));
    vi.mocked(createSupabaseServerClient).mockResolvedValue({ rpc } as never);

    const response = await POST(new Request('http://localhost/api/yonetici/menu-analiz/kaynak-kesfi', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        business_id: '11111111-1111-4111-8111-111111111111',
        website_url: 'https://ornek-restoran.com',
      }),
    }));
    const body = await response.json();

    expect(response.status).toBe(201);
    expect(body).toEqual({ data: { job_id: 'internal-job-1' } });
    expect(JSON.stringify(body)).not.toContain('secret');
    expect(menuExtractorStartSourceDiscoveryJob).toHaveBeenCalledWith('https://ornek-restoran.com');
    expect(rpc).toHaveBeenCalledWith('admin_create_menu_extract_job_v1', expect.objectContaining({
      p_source_type: 'website_discovery',
      p_source_url: 'https://ornek-restoran.com',
      p_external_job_id: 'external-job-1',
    }));
  });
});
