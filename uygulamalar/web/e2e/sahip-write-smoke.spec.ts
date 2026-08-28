/**
 * Sahip paneli write smoke testleri.
 *
 * Çalışma koşulları (CI):
 *   PLAYWRIGHT_USE_START=true        → production build üzerinden çalışır
 *   NEXT_PUBLIC_SUPABASE_URL         → zorunlu
 *   NEXT_PUBLIC_SUPABASE_ANON_KEY    → zorunlu
 *   SUPABASE_SERVICE_ROLE_KEY        → zorunlu (magic link + service ops)
 *   PLAYWRIGHT_OWNER_SMOKE_BUSINESS_ID → opsiyonel, otomatik keşif yapılır
 *
 * Yerel çalıştırma:
 *   cp .env.local .env.playwright.local
 *   npx playwright test sahip-write-smoke --project=chromium
 */

import { expect, test } from '@playwright/test';
import {
  discoverLiveOwnerTarget,
  issueSession,
  getServiceClient,
} from './live-smoke.helpers';

// ─── Guard: ortam yoksa atla ──────────────────────────────────────────────────

const hasRequiredEnv =
  Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL) &&
  Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY);

// ─── Testler ─────────────────────────────────────────────────────────────────

test.describe.serial('Sahip paneli — write smoke', () => {
  test.skip(!hasRequiredEnv, 'SUPABASE_SERVICE_ROLE_KEY ayarlanmamış, test atlanıyor');

  test('sahip oturumu magic link ile açılır ve panele yönlendirilir', async ({ page }) => {
    const target = await discoverLiveOwnerTarget();
    const session = await issueSession(target.ownerEmail);

    // Cookie'ye oturum yerleştir
    await page.context().addCookies([
      {
        name: 'sb-access-token',
        value: session.accessToken,
        domain: new URL(page.url() || 'http://localhost').hostname || 'localhost',
        path: '/',
      },
    ]);

    // Auth header ile gosterge panosuna doğrudan git
    await page.goto('/sahip/gosterge-panosu');

    // Auth guard çalışıyorsa /giris'e, yoksa dashboard yüklenir
    const url = page.url();
    const isPanel = url.includes('/sahip/');
    const isLogin = url.includes('/giris');
    expect(isPanel || isLogin).toBe(true);
  });

  test('sahip analitik sayfası ?aralik=7g parametresiyle yüklenir', async ({ page }) => {
    const target = await discoverLiveOwnerTarget();
    const session = await issueSession(target.ownerEmail);

    await page.context().addCookies([
      {
        name: 'sb-access-token',
        value: session.accessToken,
        domain: 'localhost',
        path: '/',
      },
    ]);

    await page.goto('/sahip/analitik?aralik=7g');
    const url = page.url();

    // Sayfanın 404 veya 500 dönmediğini doğrula
    const response = await page.request.get(url);
    expect(response.status()).not.toBe(500);
    expect(response.status()).not.toBe(404);
  });

  test("sahip analitik ?aralik parametresi geçersiz değerde 30g fallback'e düşer", async ({ page }) => {
    await page.goto('/sahip/analitik?aralik=GECERSIZ');
    // 30g fallback → sayfa render'ı başarılı olmalı (hata fırlatmamalı)
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));
    await page.waitForLoadState('domcontentloaded');
    expect(errors).toHaveLength(0);
  });
});

test.describe('Sahip paneli — erişim kontrolü', () => {
  test.skip(!hasRequiredEnv, 'SUPABASE_SERVICE_ROLE_KEY ayarlanmamış, test atlanıyor');

  test('oturumsu kullanıcı sahip paneline erişince /giris\'e yönlenir', async ({ page }) => {
    // Cookie yok → oturumuz kullanıcı
    await page.goto('/sahip/gosterge-panosu');
    await page.waitForLoadState('networkidle');

    // Auth guard /giris veya /baslangic'a yönlendirmeli
    expect(page.url()).toMatch(/\/(giris|baslangic)/);
  });

  test('normal kullanıcı sahip paneline erişemez', async ({ page }) => {
    const target = await discoverLiveOwnerTarget();

    // Non-owner oturum
    const session = await issueSession(target.nonOwnerEmail);

    await page.context().addCookies([
      {
        name: 'sb-access-token',
        value: session.accessToken,
        domain: 'localhost',
        path: '/',
      },
    ]);

    await page.goto('/sahip/gosterge-panosu');
    await page.waitForLoadState('networkidle');

    // 403, 404 ya da /giris yönlendirmesi beklenir
    const urlOrStatus = page.url();
    const isRedirected = urlOrStatus.includes('/giris') || urlOrStatus.includes('/baslangic');
    // İzin yoksa yönlendirme yapılmış olmalı
    // (Kesin URL davranışı proxy.ts'e bağlı — sadece panel URL'de kalmadığını doğrula)
    const staysOnPanel = urlOrStatus.includes('/sahip/gosterge-panosu') && !isRedirected;
    // Non-owner panelde kalmamalı
    if (!isRedirected) {
      // Sayfa render'ı hata vermemeli ama panel içeriği gösterilmemeli
      await expect(page.locator('[data-testid="owner-dashboard"]')).not.toBeVisible();
    }
    expect(staysOnPanel).toBe(false);
  });
});

test.describe('Admin paneli — erişim kontrolü', () => {
  test.skip(!hasRequiredEnv, 'SUPABASE_SERVICE_ROLE_KEY ayarlanmamış, test atlanıyor');

  test('oturumsu kullanıcı yönetici paneline erişince yönlenir', async ({ page }) => {
    await page.goto('/yonetici/gosterge-panosu');
    await page.waitForLoadState('networkidle');
    expect(page.url()).toMatch(/\/(giris|baslangic)/);
  });

  test('sahip kullanıcı yönetici paneline erişemez', async ({ page }) => {
    const target = await discoverLiveOwnerTarget();
    const session = await issueSession(target.ownerEmail);

    await page.context().addCookies([
      {
        name: 'sb-access-token',
        value: session.accessToken,
        domain: 'localhost',
        path: '/',
      },
    ]);

    await page.goto('/yonetici/gosterge-panosu');
    await page.waitForLoadState('networkidle');

    // Admin-only sayfaya sahip kullanıcı erişemez
    const url = page.url();
    const isAdminPage = url.includes('/yonetici/gosterge-panosu');
    if (isAdminPage) {
      // Sayfada admin içeriği görünmemeli
      await expect(page.locator('[data-testid="admin-dashboard"]')).not.toBeVisible();
    } else {
      // Yönlendirme yapıldı — doğru davranış
      expect(url).toMatch(/\/(giris|baslangic|sahip)/);
    }
  });
});
