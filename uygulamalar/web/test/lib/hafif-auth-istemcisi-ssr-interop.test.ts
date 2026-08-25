import { describe, expect, it } from 'vitest';
import { createBrowserClient } from '@supabase/ssr';
import type { Session, User } from '@supabase/auth-js';
import { hafifAuthCookieStorage } from '@/src/lib/taban/hafif-auth-istemcisi';

/**
 * `hafif-auth-istemcisi.ts`'in cookie storage adaptörünün, `@supabase/ssr`'in GERÇEK
 * `createBrowserClient()`'ının kurduğu adaptörle byte-uyumlu (aynı storageKey, aynı chunklama,
 * aynı base64url kodlama) olduğunu doğrulayan entegrasyon testi. `hafif-auth-istemcisi.test.ts`
 * sadece `hafifAuthCookieStorage`'ın kendi içinde round-trip yapıyor — bu dosya, ~13 diğer
 * çağrı noktasının kullandığı GERÇEK adaptörle karşılıklı okunabilirliği test ediyor. Bu, aynı
 * sayfada iki istemcinin (hafif + tam) aynı cookie'yi bozmadan paylaşabildiğinin tek otomatik
 * garantisi — manuel kod okuması değil.
 *
 * Ağ çağrısı YAPILMAZ:
 * - `_saveSession` auth-js'in TS-only "private" (derlenmiş JS'te normal) bir metodu; gerçek bir
 *   giriş akışı olmadan storage'a yazma yolunu tetiklemek için kullanılıyor.
 * - `getSession()` public API'dir ve session storage'dan canlı okunduğu için (bkz.
 *   `GoTrueClient.ts` `__loadSession` -> `getItemAsync(this.storage, this.storageKey)`) gerçek bir
 *   ağ isteği tetiklemeden okuma yolunu test ediyor.
 * - `autoRefreshToken`/`detectSessionInUrl` kapalı, bu yüzden arka planda beklenmedik bir fetch
 *   denemesi olmaz.
 */

const TEST_URL = 'https://interop-test-project.supabase.co';
const TEST_ANON_KEY = 'test-anon-key';

function buildFakeSession(): Session {
  const user: User = {
    id: 'interop-test-user-id',
    app_metadata: {},
    user_metadata: {},
    aud: 'authenticated',
    created_at: new Date().toISOString(),
  };
  return {
    access_token: 'interop-fake-access-token',
    refresh_token: 'interop-fake-refresh-token',
    expires_in: 3600,
    expires_at: Math.floor(Date.now() / 1000) + 3600,
    token_type: 'bearer',
    user,
  };
}

function createTestFullClient() {
  // isSingleton:false -> testler arası @supabase/ssr'nin modül-seviyesi singleton cache'inden
  // etkilenmesin. autoRefreshToken/detectSessionInUrl:false -> arka planda ağ çağrısı riskini
  // tamamen ortadan kaldırır (storage adaptörü davranışını etkilemezler).
  return createBrowserClient(TEST_URL, TEST_ANON_KEY, {
    isSingleton: false,
    auth: {
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
}

describe('hafifAuthCookieStorage <-> @supabase/ssr createBrowserClient interop', () => {
  it('@supabase/ssr createBrowserClient ile yazılan bir session, hafifAuthCookieStorage ile okunabilir', async () => {
    const fullClient = createTestFullClient();
    const storageKey = (fullClient.auth as unknown as { storageKey: string }).storageKey;

    try {
      const session = buildFakeSession();
      await (
        fullClient.auth as unknown as { _saveSession: (s: Session) => Promise<void> }
      )._saveSession(session);

      const raw = await hafifAuthCookieStorage.getItem(storageKey);
      expect(raw).not.toBeNull();

      const parsed = JSON.parse(raw as string) as Session;
      expect(parsed.access_token).toBe(session.access_token);
      expect(parsed.refresh_token).toBe(session.refresh_token);
      expect(parsed.user.id).toBe(session.user.id);
    } finally {
      await hafifAuthCookieStorage.removeItem(storageKey);
    }
  });

  it('hafifAuthCookieStorage ile yazılan bir session, @supabase/ssr createBrowserClient (getSession) ile okunabilir', async () => {
    const fullClient = createTestFullClient();
    const storageKey = (fullClient.auth as unknown as { storageKey: string }).storageKey;

    try {
      const session = buildFakeSession();
      await hafifAuthCookieStorage.setItem(storageKey, JSON.stringify(session));

      const {
        data: { session: readBack },
      } = await fullClient.auth.getSession();

      expect(readBack?.access_token).toBe(session.access_token);
      expect(readBack?.refresh_token).toBe(session.refresh_token);
      expect(readBack?.user.id).toBe(session.user.id);
    } finally {
      await hafifAuthCookieStorage.removeItem(storageKey);
    }
  });

  it('hafifAuthCookieStorage ile yazılan büyük (chunklı) bir session, @supabase/ssr createBrowserClient ile de doğru birleştirilip okunur', async () => {
    const fullClient = createTestFullClient();
    const storageKey = (fullClient.auth as unknown as { storageKey: string }).storageKey;

    try {
      const session = {
        ...buildFakeSession(),
        // 4KB cookie sınırını aştırıp chunklamayı zorlamak için büyük bir alan ekliyoruz.
        provider_token: 'x'.repeat(6000),
      };
      await hafifAuthCookieStorage.setItem(storageKey, JSON.stringify(session));
      expect(document.cookie).toContain(`${storageKey}.0=`);

      const {
        data: { session: readBack },
      } = await fullClient.auth.getSession();

      expect(readBack?.access_token).toBe(session.access_token);
      expect(readBack?.provider_token).toBe(session.provider_token);
    } finally {
      await hafifAuthCookieStorage.removeItem(storageKey);
    }
  });
});
