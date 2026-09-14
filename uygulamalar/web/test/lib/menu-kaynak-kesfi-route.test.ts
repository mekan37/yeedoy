import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/src/lib/auth/admin-guard', () => ({ checkAdminAccess: vi.fn() }));
vi.mock('@/src/lib/oran-siniri', () => ({
  getClientIp: vi.fn(() => '127.0.0.1'),
  getRequestIdentity: vi.fn(() => 'test-admin'),
  rateLimit: vi.fn(() => ({ ok: true })),
}));
vi.mock('@/src/lib/taban/sunucu', () => ({ createSupabaseServerClient: vi.fn() }));
vi.mock('@/src/lib/menu-analiz/disari-cagri', () => ({ menuExtractorStartSourceDiscoveryJob: vi.fn() }));
// Gerçek DNS çözümlemesi yapan assertSsrfSafeUrl testte ağa bağımlı/kırılgan
// olmasın diye mock'lanıyor — SSRF mantığının kendisi ayrı bir test dosyasında.
vi.mock('@/src/lib/menu-analiz/url-guvenlik', () => ({ assertSsrfSafeUrl: vi.fn(async () => ({ ok: true })) }));

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
    // DB kaydı artık dış çağrıdan ÖNCE oluşturuluyor (orphan-job fix) — ilk
    // rpc çağrısı admin_create_menu_extract_job_v1 (external_job_id=null),
    // ikincisi admin_set_menu_extract_job_external_id_v1 (dış çağrı başarılı
    // olduktan sonra external id'yi dolduran çağrı).
    const rpc = vi.fn(async (fn: string) => {
      if (fn === 'admin_create_menu_extract_job_v1') return { data: 'internal-job-1', error: null };
      if (fn === 'admin_set_menu_extract_job_external_id_v1') return { data: null, error: null };
      throw new Error(`unexpected rpc: ${fn}`);
    });
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
      p_external_job_id: null,
    }));
    expect(rpc).toHaveBeenCalledWith('admin_set_menu_extract_job_external_id_v1', {
      p_job_id: 'internal-job-1',
      p_external_job_id: 'external-job-1',
    });
  });
});
