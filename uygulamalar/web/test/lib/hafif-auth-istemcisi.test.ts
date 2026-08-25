import { afterEach, describe, expect, it } from 'vitest';
import { hafifAuthCookieStorage } from '@/src/lib/taban/hafif-auth-istemcisi';

const { getItem, setItem, removeItem } = hafifAuthCookieStorage;

// `@supabase/ssr`'in `createBrowserClient()`'ının varsayılan storageKey formülüyle aynı şekle
// benzeyen bir test key'i (gerçek proje ref'i önemli değil, sadece chunk isimlendirme davranışı test ediliyor).
const TEST_KEY = 'sb-test-project-auth-token';

afterEach(async () => {
  await removeItem(TEST_KEY);
});

describe('hafifAuthCookieStorage', () => {
  it('bilinmeyen bir key için null döner', async () => {
    expect(await getItem(TEST_KEY)).toBeNull();
  });

  it('küçük bir JSON değerini tek cookie olarak yazar ve aynen geri okur', async () => {
    const value = JSON.stringify({ access_token: 'abc', expires_at: 123 });
    await setItem(TEST_KEY, value);

    expect(await getItem(TEST_KEY)).toBe(value);
    expect(document.cookie).toContain(`${TEST_KEY}=`);
    expect(document.cookie).not.toContain(`${TEST_KEY}.0=`);
  });

  it('removeItem sonrası değer bir daha okunamaz', async () => {
    const value = JSON.stringify({ a: 1 });
    await setItem(TEST_KEY, value);
    expect(await getItem(TEST_KEY)).toBe(value);

    await removeItem(TEST_KEY);
    expect(await getItem(TEST_KEY)).toBeNull();
  });

  it('4KB cookie sınırını aşan büyük bir değeri chunklayıp doğru şekilde geri birleştirir', async () => {
    const value = JSON.stringify({ big: 'x'.repeat(6000) });
    await setItem(TEST_KEY, value);

    // Tek cookie'ye sığmadığını (en az .0/.1 chunk'ları oluştuğunu) doğrula.
    expect(document.cookie).toContain(`${TEST_KEY}.0=`);
    expect(document.cookie).toContain(`${TEST_KEY}.1=`);

    expect(await getItem(TEST_KEY)).toBe(value);
  });

  it('chunklı büyük bir değerin üzerine küçük bir değer yazınca eski chunkları temizler', async () => {
    const bigValue = JSON.stringify({ big: 'x'.repeat(6000) });
    await setItem(TEST_KEY, bigValue);
    expect(document.cookie).toContain(`${TEST_KEY}.0=`);

    const smallValue = JSON.stringify({ small: true });
    await setItem(TEST_KEY, smallValue);

    expect(await getItem(TEST_KEY)).toBe(smallValue);
    expect(document.cookie).not.toContain(`${TEST_KEY}.0=`);
    expect(document.cookie).not.toContain(`${TEST_KEY}.1=`);
  });

  it('geçersiz/bozuk (JSON olmayan) bir cookie değerini yok sayar', async () => {
    document.cookie = `${TEST_KEY}=base64-%25invalid%25; Path=/`;
    expect(await getItem(TEST_KEY)).toBeNull();
  });

  it('UTF-8 karakter içeren değerleri kayıpsız kodlar/çözer', async () => {
    const value = JSON.stringify({ name: 'İşletme Sahibi 🎉 çğşöü' });
    await setItem(TEST_KEY, value);

    expect(await getItem(TEST_KEY)).toBe(value);
  });
});
