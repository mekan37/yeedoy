import { describe, it, expect, vi, afterEach } from 'vitest';
import { sendEmailCampaign } from '@/src/lib/email/resend-client';

describe('sendEmailCampaign', () => {
  const originalKey = process.env.RESEND_API_KEY;

  afterEach(() => {
    process.env.RESEND_API_KEY = originalKey;
    vi.unstubAllGlobals();
  });

  it('provider_not_configured döner, RESEND_API_KEY yoksa', async () => {
    delete process.env.RESEND_API_KEY;
    const result = await sendEmailCampaign(
      [{ email: 'a@test.com', displayName: 'A', htmlBody: '<p>Test</p>' }],
      { subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com' },
    );
    expect(result).toEqual({ success_count: 0, failure_count: 0, provider_not_configured: true });
  });

  it('alıcı yoksa hiç fetch çağırmadan 0/0 döner', async () => {
    process.env.RESEND_API_KEY = 'test-key';
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await sendEmailCampaign([], {
      subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com',
    });
    expect(result).toEqual({ success_count: 0, failure_count: 0 });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı gönderimleri sayar', async () => {
    process.env.RESEND_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, status: 200 }));
    const result = await sendEmailCampaign(
      [
        { email: 'a@test.com', displayName: 'A', htmlBody: "<p>A'ya özel</p>" },
        { email: 'b@test.com', displayName: 'B', htmlBody: "<p>B'ye özel</p>" },
      ],
      { subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com' },
    );
    expect(result).toEqual({ success_count: 2, failure_count: 0 });
  });

  it('401 auth hatasını başarısız sayar, hiçbir e-posta adresini fırlatmaz', async () => {
    process.env.RESEND_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 401 }));
    const result = await sendEmailCampaign(
      [{ email: 'a@test.com', displayName: 'A', htmlBody: '<p>Test</p>' }],
      { subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com' },
    );
    expect(result).toEqual({ success_count: 0, failure_count: 1 });
  });
});
