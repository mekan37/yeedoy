const { test, expect } = require('../../web_next/node_modules/@playwright/test');
const ownerBusinessId = '11111111-1111-4111-8111-111111111111';

async function fillStable(locator, value) {
  await locator.click();
  await locator.fill('');
  await locator.pressSequentially(value);
  await expect(locator).toHaveValue(value);
}

test('public landing smoke', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByText('İşletmemi Başlat')).toBeVisible();
  await expect(page.getByText('Panel Girişi')).toBeVisible();
  await expect(page.getByText('Legal Merkezi')).toBeVisible();
  await expect(page.getByText('Trust & Safety')).toBeVisible();
});

test('public legal center smoke', async ({ page }) => {
  await page.goto('/legal');
  await expect(page.getByRole('button', { name: 'Ana Sayfa' })).toBeVisible({
    timeout: 15000,
  });
  await expect(
    page.getByRole('button', {
      name: /Kullanım Şartları Platformun kullanım koşulları/i,
    }),
  ).toBeVisible();
  await expect(
    page.getByRole('button', {
      name: /Gizlilik Politikası Kişisel veri kategorileri/i,
    }),
  ).toBeVisible();

  await page.goto('/legal/terms');
  await expect(page).toHaveURL(/\/legal\/terms$/, {
    timeout: 15000,
  });
  await expect(
    page.getByRole('button', { name: 'İletişim ve Kurumsal Bilgiler' }),
  ).toBeVisible();
  await expect(
    page.getByRole('button', { name: 'Veri Hakları ve Başvuru Kanalları' }),
  ).toBeVisible();

  await page.goto('/legal/privacy');
  await expect(page).toHaveURL(/\/legal\/privacy$/, {
    timeout: 15000,
  });
  await expect(page.getByText('İşlenen Veri Kategorileri')).toBeVisible();
});

test('owner shell smoke', async ({ page }) => {
  await page.goto('/owner');
  await expect(page.getByText('Operasyon özeti')).toBeVisible({
    timeout: 15000,
  });
});

test('owner businesses smoke', async ({ page }) => {
  await page.goto('/owner/businesses');
  await expect(page.getByRole('heading', { name: 'İşletmelerim' })).toBeVisible({
    timeout: 15000,
  });
  await expect(
    page.getByRole('button', { name: 'Rezervasyon ve sipariş linkleri' }).first(),
  ).toBeVisible();
});

test('owner businesses commerce links save smoke', async ({ page }) => {
  await page.goto('/owner/businesses');
  await expect(page.getByRole('heading', { name: 'İşletmelerim' })).toBeVisible({
    timeout: 15000,
  });
  await page
    .getByRole('button', { name: 'Rezervasyon ve sipariş linkleri' })
    .first()
    .click();
  await expect(page.getByLabel('Rezervasyon URL')).toBeVisible();
  await page.getByLabel('Rezervasyon URL').fill('https://reserve.example/cafe-nova');
  await page.getByRole('button', { name: 'Kaydet' }).click();
  await expect(page.getByText('Linkler güncellendi.').first()).toBeVisible();
});

test('owner menus create smoke', async ({ page }) => {
  await page.goto('/owner/menus');
  await expect(page.getByText('Menü yönetimi')).toBeVisible({
    timeout: 15000,
  });
  await page.mouse.wheel(0, 700);
  await expect(page.getByRole('checkbox', { name: 'MultiNet' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Yeni menü oluştur' })).toBeVisible();
  await page.getByRole('button', { name: 'Yeni menü oluştur' }).click();
  await expect(page.getByText('Yeni menü')).toBeVisible();
  await page.getByLabel('Başlık').fill('Brunch Menüsü');
  await page.getByRole('button', { name: 'Oluştur' }).click();
  await expect(page.getByText('Menü oluşturuldu.').first()).toBeVisible();
});

test('owner menu editor open smoke', async ({ page }) => {
  await page.goto('/owner/menus');
  await expect(page.getByText('Menü yönetimi')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Düzenle' }).first().click();
  await expect(page.getByRole('heading', { name: 'Cafe Nova Ana Menü' })).toBeVisible();
  await expect(page.getByRole('group', { name: 'Bölümler' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Bölüm Ekle' })).toBeVisible();
});

test('owner trash smoke', async ({ page }) => {
  await page.goto(`/owner/trash?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Çöp kutusu')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByLabel('Çöp kutusunda ara')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Geri yükle' }).first()).toBeVisible();
});

test('owner trash restore smoke', async ({ page }) => {
  await page.goto(`/owner/trash?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Çöp kutusu')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Geri yükle' }).first().click();
  await page.getByRole('button', { name: 'Onayla' }).click();
  await expect(page.getByText('Kayıt geri yüklendi.').first()).toBeVisible();
});

test('owner business submissions smoke', async ({ page }) => {
  await page.goto('/owner/businesses/submissions');
  await expect(page.getByText('Başvurularım')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByText('Cafe Nova Kadikoy')).toBeVisible();
});

test('owner new business submit smoke', async ({ page }) => {
  await page.goto('/owner/businesses/new');
  await expect(page.getByText('Yeni işletme ekle')).toBeVisible({
    timeout: 15000,
  });
  await fillStable(page.getByLabel('İşletme adı'), 'Smoke Bistro');
  await fillStable(page.getByLabel('Şehir'), 'Istanbul');
  await fillStable(page.getByLabel('İlçe'), 'Besiktas');
  await fillStable(page.getByLabel('Kategori'), 'Cafe');
  await fillStable(page.getByLabel('Adres'), 'Barbaros Bulvari 10');
  const businessTermsCheckbox = page.getByRole('checkbox', {
    name: 'İşletme Kullanım Koşulları’nı kabul ediyorum.',
  });
  await businessTermsCheckbox.focus();
  await businessTermsCheckbox.press('Space');
  await expect(businessTermsCheckbox).toHaveAttribute('aria-checked', 'true');

  const accuracyCheckbox = page.getByRole('checkbox', {
    name: 'Menü ve işletme bilgilerinin doğruluğundan sorumlu olduğumu kabul ediyorum.',
  });
  await accuracyCheckbox.focus();
  await accuracyCheckbox.press('Space');
  await expect(accuracyCheckbox).toHaveAttribute('aria-checked', 'true');
  await page.getByRole('button', { name: 'Başvuruyu gönder' }).click();
  await expect(page.getByText('Başvurularım')).toBeVisible();
  await expect(page.getByText('Smoke Bistro')).toBeVisible();
});

test('owner onboarding smoke', async ({ page }) => {
  await page.goto(`/owner/onboarding?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Kurulum')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByLabel('Logo URL')).toBeVisible();
  await expect(page.getByLabel('Kapak URL')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Açılış saatini seç' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Kapanış saatini seç' })).toBeVisible();
});

test('owner requests offer sheet smoke', async ({ page }) => {
  await page.goto('/owner/requests');
  await expect(page.getByRole('heading', { name: 'Talepler' })).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Teklif ver' }).first().click();
  await expect(page.getByLabel('Toplam teklif (TL)')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Gönder' })).toBeVisible();
});

test('owner team invite smoke', async ({ page }) => {
  await page.goto(`/owner/team?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Ekip üyeleri')).toBeVisible({
    timeout: 15000,
  });
  await page.getByLabel('E-posta').fill('servis@cafenova.example');
  await page.getByRole('button', { name: 'Üyeyi kaydet' }).click();
  await expect(
    page.getByRole('group', { name: /servis@cafenova\.example/i }),
  ).toBeVisible();
});

test('owner growth smoke', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 3200 });
  await page.goto(`/owner/growth?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Büyüme merkezi')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByText('14 gün')).toBeVisible();
  await expect(page.getByText('3 boş / limit 8')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Pro talebi gönder' })).toBeVisible();
});

test('owner growth lead submit smoke', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 3200 });
  await page.goto(`/owner/growth?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Büyüme merkezi')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Pro talebi gönder' }).click();
  await expect(page.getByText('Talebini aldık.').first()).toBeVisible();
});

test('owner price suggestion approve smoke', async ({ page }) => {
  await page.goto(`/owner/price-suggestions?businessId=${ownerBusinessId}`);
  await expect(page.getByRole('heading', { name: 'Fiyat onayları' })).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByRole('button', { name: 'Onayla' }).first()).toBeVisible();
  await page.getByRole('button', { name: 'Onayla' }).first().click();
  await expect(page.getByText('Fiyat önerisi onaylansın mı?')).toBeVisible();
  await page.getByRole('button', { name: 'Onaylandı' }).first().click();
  await expect(page.getByText('Onaylandı.').first()).toBeVisible();
  await expect(page.getByText('Kayıt yok')).toBeVisible();
});

test('owner suspended smoke', async ({ page }) => {
  await page.goto(`/owner/suspended?businessId=${ownerBusinessId}`);
  await expect(page.getByText('Askıda Yönetimi')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByRole('button', { name: 'Onayla' }).first()).toBeVisible();
});

test('owner activity smoke', async ({ page }) => {
  await page.goto(`/owner/activity?businessId=${ownerBusinessId}`);
  await expect(page.getByText('İşletme aktivitesi')).toBeVisible({
    timeout: 15000,
  });
});

test('owner audit alias smoke', async ({ page }) => {
  await page.goto(`/owner/audit?businessId=${ownerBusinessId}`);
  await expect(page.getByText('İşletme aktivitesi')).toBeVisible({
    timeout: 15000,
  });
});

test('owner analytics smoke', async ({ page }) => {
  await page.goto(`/owner/analytics?businessId=${ownerBusinessId}`);
  await expect(page.getByText('İşletme analitiği')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByText('QR taramaları 42')).toBeVisible();
  await expect(
    page.getByRole('group', { name: /En çok ilgi gören ürünler/i }),
  ).toBeVisible();
});

test('admin dashboard smoke', async ({ page }) => {
  await page.goto('/admin');
  await expect(page.getByText('V3 Kalite ve Güven Kapısı (P0)')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByText('Canlı kapı: 8/8')).toBeVisible();
});

test('admin unauth redirect smoke', async ({ page }) => {
  await page.goto('/admin?auth=none');
  await expect(page.getByText('İşletme Girişi')).toBeVisible({
    timeout: 15000,
  });
});

test('admin search smoke', async ({ page }) => {
  await page.goto('/admin/search?q=cafe');
  await expect(
    page.getByRole('group', { name: /Yönetici araması/i }),
  ).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByRole('group', { name: /Cafe Nova/i })).toBeVisible();
});

test('admin queue smoke', async ({ page }) => {
  await page.goto('/admin/queue');
  await expect(page.getByText('Birleşik kuyruk')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Detayı aç' }).first().click();
  await expect(page.getByText('Karar desteği')).toBeVisible();
});

test('admin queue assign action smoke', async ({ page }) => {
  await page.goto('/admin/queue');
  await expect(page.getByText('Birleşik kuyruk')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Bana ata' }).first().click();
  await expect(page.getByText('Kayıt sana atandı.').first()).toBeVisible();
});

test('admin reports smoke', async ({ page }) => {
  await page.goto('/admin/reports');
  await expect(page.getByText('report-1')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Detay' }).first().click();
  await expect(page.getByText('Menu photo looks duplicated.')).toBeVisible();
});

test('admin reports assign action smoke', async ({ page }) => {
  await page.goto('/admin/reports');
  await expect(page.getByText('report-1')).toBeVisible({
    timeout: 15000,
  });
  await page.getByRole('button', { name: 'Detay' }).first().click();
  await expect(page.getByText('Rapor detayı')).toBeVisible();
  await page.getByRole('button', { name: 'Bana ata' }).click();
  await expect(page.getByText('Üzerine alındı.').first()).toBeVisible();
});

test('admin businesses smoke', async ({ page }) => {
  await page.goto('/admin/businesses');
  await expect(page.getByText('İşletmeler')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByText('Cafe Nova').first()).toBeVisible();
});

test('admin receipt submissions smoke', async ({ page }) => {
  await page.goto('/admin/receipt-submissions');
  await expect(page.getByText('Fiş doğrulamaları')).toBeVisible({
    timeout: 15000,
  });
  await page
    .getByRole('button', { name: /Cafe Nova Bekliyor/i })
    .first()
    .click();
  await expect(
    page.getByRole('button', { name: /Cafe Nova Bekliyor/i }).first(),
  ).toBeVisible();
});

test('admin observability smoke', async ({ page }) => {
  await page.goto('/admin/observability');
  await expect(page.getByText('Observability')).toBeVisible({
    timeout: 15000,
  });
  await expect(page.getByRole('button', { name: 'Save calibration' })).toBeVisible();
});

test('admin observability save calibration smoke', async ({ page }) => {
  await page.goto('/admin/observability');
  await expect(page.getByText('Observability')).toBeVisible({
    timeout: 15000,
  });
  await page.getByLabel('Min signal count').fill('4');
  await page.getByRole('button', { name: 'Save calibration' }).click();
  await expect(page.getByText('Offline alert thresholds saved.').first()).toBeVisible();
});
