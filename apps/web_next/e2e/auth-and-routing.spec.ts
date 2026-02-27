import { expect, test } from '@playwright/test';

test('login page renders auth form', async ({ page }) => {
  await page.goto('/login');
  await expect(page.getByRole('heading', { name: 'Yeedoy Isletme Girisi' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Giris Yap' })).toBeVisible();
});

test('admin route returns redirect to panel host', async ({ request }) => {
  const response = await request.get('/admin', {
    maxRedirects: 0,
    failOnStatusCode: false,
  });
  expect(response.status()).toBeGreaterThanOrEqual(300);
  expect(response.status()).toBeLessThan(400);
  const location = response.headers()['location'] ?? '';
  expect(location).toContain('/admin');
});
