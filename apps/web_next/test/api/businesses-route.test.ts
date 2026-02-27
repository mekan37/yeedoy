// @vitest-environment node

import { POST } from '@/app/api/businesses/route';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { beforeEach, describe, expect, test, vi } from 'vitest';

vi.mock('@/src/lib/supabaseServer', () => ({
  createSupabaseServerClient: vi.fn(),
}));

const createSupabaseServerClientMock = vi.mocked(createSupabaseServerClient);

describe('POST /api/businesses', () => {
  beforeEach(() => {
    createSupabaseServerClientMock.mockReset();
  });

  test('gecersiz form verisinde 400 doner', async () => {
    const form = new FormData();
    form.set('name', 'A');
    form.set('city', '');
    form.set('district', '');
    form.set('address', '');

    const request = new Request('http://localhost/api/businesses', {
      method: 'POST',
      body: form,
    });
    const response = await POST(request);
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload.error).toBeTruthy();
    expect(createSupabaseServerClientMock).not.toHaveBeenCalled();
  });

  test('oturum yoksa 401 doner', async () => {
    createSupabaseServerClientMock.mockResolvedValue({
      auth: {
        getUser: vi.fn().mockResolvedValue({ data: { user: null } }),
      },
      rpc: vi.fn(),
    } as never);

    const form = new FormData();
    form.set('name', 'Yeedoy Bistro');
    form.set('city', 'Istanbul');
    form.set('district', 'Besiktas');
    form.set('category', 'Restoran');
    form.set('address', 'Barbaros Bulvari');

    const request = new Request('http://localhost/api/businesses', {
      method: 'POST',
      body: form,
    });
    const response = await POST(request);
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload.error).toContain('Oturum');
    expect(createSupabaseServerClientMock).toHaveBeenCalledTimes(1);
  });
});
