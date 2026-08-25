import { GoTrueClient } from '@supabase/auth-js';
import { appConfig } from '@/src/lib/ayarlar';

/**
 * Sadece oturum yönetimi (getSession/refreshSession/signOut vb.) yapan, realtime/postgrest'e
 * hiç dokunmayan bileşenler için hafif bir Auth istemcisi.
 *
 * `createSupabaseBrowserClient()` (`src/lib/taban/istemci.ts`), `@supabase/ssr`'in
 * `createBrowserClient()`'ı üzerinden `@supabase/supabase-js`'in `createClient()`'ını çağırır.
 * `SupabaseClient` constructor'ı `RealtimeClient`'ı KOŞULSUZ olarak oluşturur — `.channel()` hiç
 * çağrılmasa bile realtime-js kodu bundle'a girer. Bu dosya, `@supabase/auth-js`'in
 * `GoTrueClient`'ını doğrudan kullanarak o sarmalayıcıyı (ve realtime-js'i) tamamen devre dışı
 * bırakır. (`GoTrueClient`'ın kendi JSDoc'u da tam olarak bu senaryo için "Standalone import for
 * bundle-sensitive environments" örneğini veriyor.)
 *
 * KRİTİK: Bu istemcinin cookie storage adaptörü, `@supabase/ssr`'in `createBrowserClient()` için
 * kurduğu adaptörle (bkz. `node_modules/@supabase/ssr/dist/module/cookies.js` ->
 * `createStorageFromOptions`, browser/document.cookie şubesi) BİREBİR aynı davranmalıdır:
 * aynı cookie adı (storageKey), aynı chunklama (`key`, `key.0`, `key.1`, ...), aynı
 * `base64-` önekli base64url kodlama. Aksi halde bu istemci ile tam istemci (`istemci.ts`)
 * aynı sayfada farklı cookie formatları yazıp birbirinin oturumunu bozabilir.
 *
 * KRİTİK #2 — SÜRÜM PIN INVARIANT'I: `package.json`'da `@supabase/auth-js` `2.110.8` olarak TAM
 * (caret'siz) sabitlenmiş durumda — bu, bugün `@supabase/supabase-js@^2.57.4`'ün transitive olarak
 * bundle ettiği auth-js sürümüyle (`node_modules/@supabase/supabase-js/package.json` ->
 * `dependencies["@supabase/auth-js"]`) aynı olacak şekilde seçildi. Bu eşleşme sadece kozmetik
 * değil: aynı `storageKey` altında iki ayrı `GoTrueClient` instance'ının (bu dosyanınki + tam
 * istemcinin içindeki) `BroadcastChannel` + commit-guard/single-flight refresh mekanizmasını
 * (bkz. `GoTrueClient.ts` `_callRefreshToken`/`_notifyAllSubscribers` civarı) güvenle
 * paylaşabilmesinin ÖN KOŞULU — iki farklı auth-js build'i, mesaj/state şeklini uyumsuz şekilde
 * değiştirmiş olabilir. `supabase-js` caret range'de (`^2.57.4`) olduğu için ileride bir
 * `pnpm update`, bu pin'i BURADA hareket ettirmeden supabase-js'in içindeki auth-js'i farklı bir
 * sürüme taşıyabilir. Bu sessiz sürüklenmeyi yakalamak için
 * `test/lib/supabase-auth-js-version-invariant.test.ts` dosyası, buradaki pin ile
 * `@supabase/supabase-js`'in kendi `package.json`'ındaki auth-js bağımlılığını karşılaştırıyor —
 * o test kırılırsa, bu dosyadaki `"@supabase/auth-js"` pin'ini supabase-js'in yeni auth-js
 * sürümüyle eşleşecek şekilde güncelle.
 */

// ── Cookie chunk/encoding yardımcıları ─────────────────────────────────────────
// Aşağıdaki chunklama ve base64url mantığı, @supabase/ssr'nin `utils/chunker.ts` ve
// `cookies.ts` (browser şubesi) davranışının birebir eşdeğeridir — büyük session
// JSON'larının 4KB cookie sınırını aşabilmesi için gereklidir.

const BASE64_PREFIX = 'base64-';
const MAX_CHUNK_SIZE = 3180;
const CHUNK_LIKE_REGEX = /^(.*)[.](0|[1-9][0-9]*)$/;

function isChunkLike(cookieName: string, key: string): boolean {
  if (cookieName === key) return true;
  const match = cookieName.match(CHUNK_LIKE_REGEX);
  return !!match && match[1] === key;
}

function createChunks(key: string, value: string): Array<{ name: string; value: string }> {
  const encodedValue = encodeURIComponent(value);
  if (encodedValue.length <= MAX_CHUNK_SIZE) {
    return [{ name: key, value }];
  }

  const chunkValues: string[] = [];
  let remaining = encodedValue;

  while (remaining.length > 0) {
    let encodedChunkHead = remaining.slice(0, MAX_CHUNK_SIZE);
    const lastEscapePos = encodedChunkHead.lastIndexOf('%');
    if (lastEscapePos > MAX_CHUNK_SIZE - 3) {
      encodedChunkHead = encodedChunkHead.slice(0, lastEscapePos);
    }

    let valueHead = '';
    while (encodedChunkHead.length > 0) {
      try {
        valueHead = decodeURIComponent(encodedChunkHead);
        break;
      } catch (error) {
        if (
          error instanceof URIError &&
          encodedChunkHead.at(-3) === '%' &&
          encodedChunkHead.length > 3
        ) {
          encodedChunkHead = encodedChunkHead.slice(0, encodedChunkHead.length - 3);
        } else {
          throw error;
        }
      }
    }

    chunkValues.push(valueHead);
    remaining = remaining.slice(encodedChunkHead.length);
  }

  return chunkValues.map((chunkValue, index) => ({ name: `${key}.${index}`, value: chunkValue }));
}

async function combineChunks(
  key: string,
  retrieveChunk: (chunkName: string) => Promise<string | null>,
): Promise<string | null> {
  const value = await retrieveChunk(key);
  if (value) return value;

  const values: string[] = [];
  for (let i = 0; ; i += 1) {
    const chunk = await retrieveChunk(`${key}.${i}`);
    if (!chunk) break;
    values.push(chunk);
  }
  return values.length > 0 ? values.join('') : null;
}

function utf8ToBase64Url(value: string): string {
  const bytes = new TextEncoder().encode(value);
  let binary = '';
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlToUtf8(value: string): string {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

// ── document.cookie erişimi ─────────────────────────────────────────────────

interface RawCookie {
  name: string;
  value: string;
}

function readAllCookies(): RawCookie[] {
  if (typeof document === 'undefined' || !document.cookie) return [];
  return document.cookie
    .split(';')
    .map((pair) => pair.trim())
    .filter(Boolean)
    .map((pair) => {
      const eq = pair.indexOf('=');
      const name = eq === -1 ? pair : pair.slice(0, eq);
      const rawValue = eq === -1 ? '' : pair.slice(eq + 1);
      let value = rawValue;
      try {
        value = decodeURIComponent(rawValue);
      } catch {
        // Bozuk encoding — `cookie` paketinin güvenli-decode davranışıyla aynı: ham değeri koru.
      }
      return { name, value };
    });
}

interface CookieWriteOptions {
  path: string;
  sameSite: 'Lax';
  maxAge: number;
}

// @supabase/ssr'nin DEFAULT_COOKIE_OPTIONS'ı ile aynı (path/sameSite/maxAge).
// `httpOnly` burada yok çünkü tarayıcı JS'i zaten HttpOnly cookie yazamaz (no-op olurdu).
const DEFAULT_COOKIE_OPTIONS: CookieWriteOptions = {
  path: '/',
  sameSite: 'Lax',
  maxAge: 400 * 24 * 60 * 60, // 400 gün — tarayıcıların izin verdiği maksimum ömür
};

function writeCookie(name: string, value: string, options: CookieWriteOptions): void {
  if (typeof document === 'undefined') return;
  const segments = [
    `${name}=${encodeURIComponent(value)}`,
    `Max-Age=${Math.floor(options.maxAge)}`,
    `Path=${options.path}`,
    `SameSite=${options.sameSite}`,
  ];
  document.cookie = segments.join('; ');
}

// ── GoTrueClient storage adaptörü ────────────────────────────────────────────

async function getItem(key: string): Promise<string | null> {
  const allCookies = readAllCookies();
  const combined = await combineChunks(key, async (chunkName) => {
    const found = allCookies.find((cookie) => cookie.name === chunkName);
    return found ? found.value : null;
  });
  if (!combined) return null;
  if (!combined.startsWith(BASE64_PREFIX)) return combined;

  // Aşağıdaki iki hata kolu ve mesajları, @supabase/ssr'nin `cookies.ts` ->
  // `decodeChunkedCookieValue`'suyla kasıtlı olarak birebir eşleşiyor (teşhis sinyali kaybolmasın
  // diye): teşhis edilebilir bir prod bug'ı ("sürekli çıkışa atılıyorum" gibi) rapor edildiğinde,
  // konsolda hangi kolun tetiklendiği görünür olmalı.
  let decoded: string;
  try {
    decoded = base64UrlToUtf8(combined.slice(BASE64_PREFIX.length));
  } catch (error) {
    console.warn(
      'hafif-auth-istemcisi: could not base64url-decode chunked cookie value, treating as absent. Cookie chunks may have been written partially across responses.',
      error,
    );
    return null;
  }

  try {
    JSON.parse(decoded);
  } catch {
    console.warn(
      'hafif-auth-istemcisi: chunked cookie decoded to invalid JSON, treating as absent. This usually indicates that cookie chunks from different writes were combined (e.g. response committed before all Set-Cookie headers were sent).',
    );
    return null;
  }
  return decoded;
}

async function setItem(key: string, value: string): Promise<void> {
  const allCookies = readAllCookies();
  const staleChunkNames = new Set(
    allCookies.map((cookie) => cookie.name).filter((name) => isChunkLike(name, key)),
  );

  const encodedValue = BASE64_PREFIX + utf8ToBase64Url(value);
  const chunksToSet = createChunks(key, encodedValue);
  chunksToSet.forEach(({ name }) => staleChunkNames.delete(name));

  staleChunkNames.forEach((name) => {
    writeCookie(name, '', { ...DEFAULT_COOKIE_OPTIONS, maxAge: 0 });
  });
  chunksToSet.forEach(({ name, value: chunkValue }) => {
    writeCookie(name, chunkValue, DEFAULT_COOKIE_OPTIONS);
  });
}

async function removeItem(key: string): Promise<void> {
  const allCookies = readAllCookies();
  const staleChunkNames = allCookies
    .map((cookie) => cookie.name)
    .filter((name) => isChunkLike(name, key));

  staleChunkNames.forEach((name) => {
    writeCookie(name, '', { ...DEFAULT_COOKIE_OPTIONS, maxAge: 0 });
  });
}

/**
 * Cookie storage adaptörü — birim testleri için dışa açık (bkz. `test/lib/hafif-auth-istemcisi.test.ts`).
 * Gerçek kullanım her zaman `createHafifAuthClient()` üzerinden olmalı.
 */
export const hafifAuthCookieStorage = { getItem, setItem, removeItem };

// ── Factory ──────────────────────────────────────────────────────────────────

let cachedClient: GoTrueClient | undefined;

/**
 * Sadece auth (getSession/refreshSession/signOut) ihtiyacı olan client component'ler için
 * `GoTrueClient`'ı doğrudan döndürür — `SupabaseClient`/`RealtimeClient` bundle'a girmez.
 *
 * `createSupabaseBrowserClient()` ile AYNI cookie'yi (storageKey) okur/yazar, bu yüzden ikisi
 * aynı sayfada birlikte kullanılabilir; oturum durumu tutarlı kalır.
 *
 * NOT: `detectSessionInUrl` bilinçli olarak `false` — bu istemcinin kullanıldığı bileşenler
 * (`oturum-suresi-uyarisi.tsx`, `kullanici-dropdown.tsx`) hiçbir zaman OAuth/magic-link
 * yönlendirmesi işlemez; `false` bırakmak, tam istemci ile aynı anda aynı URL grant'ini iki kez
 * işleme riskini ortadan kaldırır.
 */
export function createHafifAuthClient(): GoTrueClient {
  if (typeof window === 'undefined') {
    throw new Error('createHafifAuthClient yalnızca tarayıcıda çağrılabilir.');
  }
  if (cachedClient) return cachedClient;

  const supabaseUrl = appConfig.supabaseUrl();
  const supabaseAnonKey = appConfig.supabaseAnonKey();
  const baseUrl = new URL(supabaseUrl);

  // supabase-js ile aynı varsayılan storageKey formülü (bkz. SupabaseClient.ts):
  // `sb-${projectRef}-auth-token`. Aynı formül olmazsa iki istemci farklı cookie okur/yazar.
  const storageKey = `sb-${baseUrl.hostname.split('.')[0]}-auth-token`;

  cachedClient = new GoTrueClient({
    url: new URL('auth/v1', baseUrl).href,
    headers: {
      apikey: supabaseAnonKey,
      Authorization: `Bearer ${supabaseAnonKey}`,
    },
    storageKey,
    storage: { getItem, setItem, removeItem },
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
    flowType: 'pkce',
  });

  return cachedClient;
}
