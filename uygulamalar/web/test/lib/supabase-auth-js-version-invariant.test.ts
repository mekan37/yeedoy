import { describe, expect, it } from 'vitest';
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import path from 'node:path';

/**
 * `src/lib/taban/hafif-auth-istemcisi.ts`, `@supabase/auth-js`'in `GoTrueClient`'ını doğrudan
 * kullanıyor ve bunun `@supabase/supabase-js`'in (tam istemcinin) transitive olarak bundle ettiği
 * auth-js ile AYNI sürüm olması gerekiyor — aksi halde aynı storageKey altında çalışan iki
 * GoTrueClient instance'ı (hafif istemci + tam istemcinin içindeki), farklı auth-js build'lerinden
 * gelmiş olur ve BroadcastChannel/commit-guard tabanlı çoklu-instance koordinasyonu (bkz.
 * `GoTrueClient.ts` içindeki storageKey bazlı instance sayacı ve broadcast mesajlaşması) sessizce
 * bozulabilir.
 *
 * Bu test, `web/package.json`'daki `@supabase/auth-js` pin'ini, `@supabase/supabase-js`'in KENDİ
 * `package.json`'ındaki `dependencies["@supabase/auth-js"]` alanıyla karşılaştırır. Bir
 * `pnpm update` veya `@supabase/supabase-js` sürüm bump'ı bu ikisini birbirinden ayırırsa, bu test
 * kırılır ve `hafif-auth-istemcisi.ts`'deki sürüm pin'inin güncellenmesi gerektiğini haber verir.
 */
describe('@supabase/auth-js sürüm pin invariant\'ı', () => {
  it('web/package.json\'daki @supabase/auth-js pin\'i, @supabase/supabase-js\'in bundle ettiği auth-js sürümüyle aynı', () => {
    const require = createRequire(import.meta.url);

    const webPackageJsonPath = path.resolve(__dirname, '../../package.json');
    const webPackageJson = JSON.parse(readFileSync(webPackageJsonPath, 'utf-8')) as {
      dependencies?: Record<string, string>;
    };
    const pinnedAuthJsVersion = webPackageJson.dependencies?.['@supabase/auth-js'];

    const supabaseJsPackageJsonPath = require.resolve('@supabase/supabase-js/package.json');
    const supabaseJsPackageJson = JSON.parse(readFileSync(supabaseJsPackageJsonPath, 'utf-8')) as {
      dependencies?: Record<string, string>;
    };
    const supabaseJsBundledAuthJsVersion = supabaseJsPackageJson.dependencies?.['@supabase/auth-js'];

    expect(
      pinnedAuthJsVersion,
      'web/package.json içinde "@supabase/auth-js" bağımlılığı bulunamadı — pin kaldırılmış olabilir.',
    ).toBeTruthy();
    expect(
      supabaseJsBundledAuthJsVersion,
      '@supabase/supabase-js/package.json içinde "@supabase/auth-js" bağımlılığı bulunamadı — supabase-js\'in kendi bağımlılık şekli değişmiş olabilir.',
    ).toBeTruthy();

    expect(
      pinnedAuthJsVersion,
      `web/package.json'daki @supabase/auth-js pin'i ("${pinnedAuthJsVersion}"), @supabase/supabase-js'in bundle ettiği auth-js sürümüyle ("${supabaseJsBundledAuthJsVersion}") eşleşmiyor. ` +
        `hafif-auth-istemcisi.ts'in GoTrueClient'ı ile tam istemcinin içindeki GoTrueClient'ın aynı auth-js build'inden gelmesi gerekiyor (bkz. hafif-auth-istemcisi.ts'in dosya başındaki "SÜRÜM PIN INVARIANT'I" notu). ` +
        `web/package.json'daki pin'i "${supabaseJsBundledAuthJsVersion}" olarak güncelle.`,
    ).toBe(supabaseJsBundledAuthJsVersion);
  });
});
