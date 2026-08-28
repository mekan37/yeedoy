import { expect, test } from '@playwright/test';
import {
  createTinyPng,
  deleteBusinessMediaFixture,
  deleteStoragePaths,
  discoverLiveOwnerTarget,
  extractStoragePath,
  getPresentationSettingsRow,
  handoffQrSession,
  insertBusinessMediaFixture,
  issueSession,
  restorePresentationSettingsRow,
  savePresentationSettingsViaApi,
  uploadBrandingAsset,
} from './live-smoke.helpers';

const smoke = getSmokeConfig();

test.describe.serial('live public menu smoke', () => {
  test('public menu, qr page and redirect flow work with live route keys', async ({ page }) => {
    const pageViewTrack = page.waitForResponse(
      (response) =>
        response.url().includes('/sunucu/izleme') &&
        response.request().method() === 'POST' &&
        response.status() === 200,
    );

    const menuResponse = await page.goto(`/m/${smoke.businessId}?lang=${smoke.lang}`);
    expect(menuResponse?.ok()).toBeTruthy();
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
    const resolvedBusinessPath = getBusinessPathSegment(page.url());
    const expectedBusinessPath = smoke.businessPath ?? resolvedBusinessPath;

    expect(resolvedBusinessPath).toBe(expectedBusinessPath);
    await expect(page.getByRole('link', { name: /qr/i })).toHaveAttribute(
      'href',
      `/karekod/${smoke.businessId}?lang=${smoke.lang}&theme=bold`,
    );
    await pageViewTrack;

    if (expectedBusinessPath !== smoke.businessId) {
      await expect(page).toHaveURL(new RegExp(`/m/${expectedBusinessPath}\\?lang=${smoke.lang}`));
    }

    const qrResponse = await page.goto(`/karekod/${smoke.businessId}?lang=${smoke.lang}`);
    expect(qrResponse?.ok()).toBeTruthy();
    await expect(page).toHaveURL(/\/giris/);
    await expect(page.getByRole('heading', { name: /hoş geldin/i })).toBeVisible();

    const shortPath = `/kod/${encodeBusinessCode(smoke.businessId)}?lang=${smoke.lang}&theme=bold`;

    await page.goto(shortPath);
    await page.waitForURL(new RegExp(`/m/${expectedBusinessPath}\\?`));
    await expect(page).toHaveURL(new RegExp(`/m/${expectedBusinessPath}\\?(.+&)?src=qr(&|$)`));
    await expect(page).toHaveURL(new RegExp(`theme=bold`));

    if (smoke.categoryId) {
      const categoryResponse = await page.goto(`/m/${expectedBusinessPath}/c/${smoke.categoryId}?lang=${smoke.lang}`);
      expect(categoryResponse?.ok()).toBeTruthy();
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
    }

    if (smoke.itemId) {
      const itemResponse = await page.goto(`/m/${expectedBusinessPath}/i/${smoke.itemId}?lang=${smoke.lang}`);
      expect(itemResponse?.ok()).toBeTruthy();
      await expect(page.getByRole('button', { name: /^kapat$|^close$/i })).toBeVisible();
    }
  });

  test('owner can save template settings, upload branding and public menu applies them', async ({
    page,
    context,
  }) => {
    test.setTimeout(120_000);
    const target = await discoverLiveOwnerTarget();
    const ownerSession = await issueSession(target.ownerEmail);
    const previousPresentation = await getPresentationSettingsRow(target.businessId);
    const uploadedStoragePaths: string[] = [];
    let fixtureMediaId: string | null = null;

    try {
      const handoff = await handoffQrSession({
        request: context.request,
        businessId: target.businessId,
        session: ownerSession,
        lang: 'tr',
        theme: 'minimal',
      });

      expect(handoff.ok).toBeTruthy();
      expect(handoff.redirectTo).toBe(`/karekod/${target.businessId}?lang=tr&theme=minimal`);

      const fixtureCover = createTinyPng('cover-fixture.png');
      const fixtureUpload = await uploadBrandingAsset({
        request: context.request,
        businessId: target.businessId,
        type: 'cover',
        name: fixtureCover.name,
        mimeType: fixtureCover.mimeType,
        buffer: fixtureCover.buffer,
      });
      uploadedStoragePaths.push(fixtureUpload.path);

      const fixtureMedia = await insertBusinessMediaFixture({
        businessId: target.businessId,
        ownerUserId: target.ownerUserId,
        url: fixtureUpload.url,
      });
      fixtureMediaId = fixtureMedia.id;

      const seededLogo = await uploadBrandingAsset({
        request: context.request,
        businessId: target.businessId,
        type: 'logo',
        name: 'logo-owner.png',
        mimeType: 'image/png',
        buffer: createTinyPng('logo-owner.png').buffer,
      });
      const seededBackground = await uploadBrandingAsset({
        request: context.request,
        businessId: target.businessId,
        type: 'background',
        name: 'background-owner.png',
        mimeType: 'image/png',
        buffer: createTinyPng('background-owner.png').buffer,
      });
      uploadedStoragePaths.push(seededLogo.path, seededBackground.path);

      await savePresentationSettingsViaApi({
        request: context.request,
        payload: {
          businessId: target.businessId,
          defaultLang: 'tr',
          templateKey: 'minimal',
          settings: {
            backgroundMode: 'image',
            accentPreset: 'brand',
            accentHex: null,
            headerLayout: 'left',
            cardStyle: 'comfortable',
            showFeatured: true,
            showTags: true,
            showAllergens: true,
            showCurrencySymbol: true,
            showLastUpdated: true,
            fontScale: 'normal',
            layoutVariant: 'standard',
          },
          logoUrl: seededLogo.url,
          coverUrl: null,
          backgroundUrl: seededBackground.url,
        },
      });

      const qrResponse = await page.goto(`/karekod/${target.businessId}?lang=tr&theme=minimal`);
      expect(qrResponse?.ok()).toBeTruthy();
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();

      await page.getByRole('button', { name: /sablon ve marka/i }).click();
      await expect(page.getByTestId('media-field-logo').locator('img')).toBeVisible();
      await expect(page.getByTestId('media-field-background').locator('img')).toBeVisible();

      await savePresentationSettingsViaApi({
        request: context.request,
        payload: {
          businessId: target.businessId,
          defaultLang: 'en',
          templateKey: 'elegant',
          settings: {
            backgroundMode: 'image',
            accentPreset: 'brand',
            accentHex: null,
            headerLayout: 'centered',
            cardStyle: 'comfortable',
            showFeatured: true,
            showTags: true,
            showAllergens: true,
            showCurrencySymbol: true,
            showLastUpdated: true,
            fontScale: 'normal',
            layoutVariant: 'editorial',
          },
          logoUrl: seededLogo.url,
          coverUrl: fixtureUpload.url,
          backgroundUrl: seededBackground.url,
        },
      });

      const savedPresentation = await getPresentationSettingsRow(target.businessId);
      expect(savedPresentation?.template_key).toBe('elegant');
      expect(savedPresentation?.default_lang).toBe('en');
      expect(savedPresentation?.cover_url).toBe(fixtureUpload.url);
      expect(savedPresentation?.logo_url).toContain(
        `/storage/v1/object/public/menu-media/businesses/${target.businessId}/branding/logo/`,
      );
      expect(savedPresentation?.background_url).toContain(
        `/storage/v1/object/public/menu-media/businesses/${target.businessId}/branding/background/`,
      );
      expect(extractStoragePath(savedPresentation?.logo_url ?? '')).toMatch(
        new RegExp(`^businesses/${target.businessId}/branding/logo/`),
      );
      expect(extractStoragePath(savedPresentation?.background_url ?? '')).toMatch(
        new RegExp(`^businesses/${target.businessId}/branding/background/`),
      );

      uploadedStoragePaths.push(
        extractStoragePath(savedPresentation?.logo_url ?? ''),
        extractStoragePath(savedPresentation?.background_url ?? ''),
      );

      const publicResponse = await page.goto(`/m/${target.businessId}`);
      expect(publicResponse?.ok()).toBeTruthy();
      await expect(page.getByTestId('brand-mode-badge')).toHaveText(/elegant/i);
      await expect(page.getByRole('searchbox', { name: /menüde ara/i })).toBeVisible();
      await expect(
        page.locator(`img[src*="/businesses/${target.businessId}/branding/background/"]`).first(),
      ).toBeVisible();

      const overrideResponse = await page.goto(`/m/${target.businessId}?theme=bold`);
      expect(overrideResponse?.ok()).toBeTruthy();
      await expect(page.getByTestId('brand-mode-badge')).toHaveText(/bold/i);
    } finally {
      if (fixtureMediaId) {
        await deleteBusinessMediaFixture(fixtureMediaId);
      }
      await restorePresentationSettingsRow(target.businessId, previousPresentation);
      await deleteStoragePaths(Array.from(new Set(uploadedStoragePaths)));
    }
  });

  test('unauthorized user cannot upload or update presentation settings', async ({ context }) => {
    const target = await discoverLiveOwnerTarget();
    const nonOwnerSession = await issueSession(target.nonOwnerEmail);

    await handoffQrSession({
      request: context.request,
      businessId: target.businessId,
      session: nonOwnerSession,
      lang: 'tr',
      theme: 'bold',
    });

    const file = createTinyPng('unauthorized.png');
    const uploadResponse = await context.request.post('/sunucu/medya/yukleme', {
      multipart: {
        businessId: target.businessId,
        type: 'logo',
        file: {
          name: file.name,
          mimeType: file.mimeType,
          buffer: file.buffer,
        },
      },
    });
    expect(uploadResponse.status()).toBe(403);

    const settingsResponse = await context.request.post('/sunucu/sunum-ayarlari', {
      data: {
        businessId: target.businessId,
        defaultLang: 'tr',
        templateKey: 'bold',
        settings: {
          backgroundMode: 'gradient',
          accentPreset: 'brand',
          accentHex: null,
          headerLayout: 'left',
          cardStyle: 'comfortable',
          showFeatured: true,
          showTags: true,
          showAllergens: true,
          showCurrencySymbol: true,
          showLastUpdated: true,
          fontScale: 'normal',
          layoutVariant: 'standard',
        },
        logoUrl: null,
        coverUrl: null,
        backgroundUrl: null,
      },
    });
    expect(settingsResponse.status()).toBe(403);
  });
});

function getSmokeConfig() {
  const businessId = process.env.PLAYWRIGHT_SMOKE_BUSINESS_ID?.trim();
  if (!businessId) {
    throw new Error('PLAYWRIGHT_SMOKE_BUSINESS_ID is required for test:e2e:live');
  }

  return {
    businessId,
    businessPath: process.env.PLAYWRIGHT_SMOKE_BUSINESS_PATH?.trim() || null,
    categoryId: process.env.PLAYWRIGHT_SMOKE_CATEGORY_ID?.trim() || null,
    itemId: process.env.PLAYWRIGHT_SMOKE_ITEM_ID?.trim() || null,
    lang: process.env.PLAYWRIGHT_SMOKE_LANG?.trim() || 'tr',
  };
}

function encodeBusinessCode(uuid: string) {
  const normalized = uuid.replace(/-/g, '').toLowerCase();
  return Buffer.from(normalized, 'hex').toString('base64url');
}

function getBusinessPathSegment(url: string) {
  const pathname = new URL(url).pathname;
  const [, route, businessPath] = pathname.split('/');
  if (route !== 'm' || !businessPath) {
    throw new Error(`Unexpected public menu URL: ${url}`);
  }

  return businessPath;
}
