import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('next/navigation', () => ({
  usePathname: () => '/yonetici/isletmeler/11111111-1111-4111-8111-111111111111/menu-analiz',
  useRouter: () => ({ replace: vi.fn() }),
}));

vi.mock('@/app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-islemleri', () => ({
  menuAnalizBaslatUrl: vi.fn(),
  menuAnalizDurumSorgula: vi.fn(),
  menuAnalizOgeleriListele: vi.fn(),
  menuAnalizOgeGuncelle: vi.fn(),
  menuAnalizOgeHaricTut: vi.fn(),
  isletmeMenuOgeleriListele: vi.fn(),
  menuAnalizUygula: vi.fn(),
}));

import {
  DiscoveryOutcomeCard,
  MenuAnalizIstemcisi,
} from '@/app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-istemcisi';
import * as menuActions from '@/app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-islemleri';

const defaultProps = {
  businessId: '11111111-1111-4111-8111-111111111111',
  businessName: 'Örnek',
  initialJobId: null,
  initialWebsiteUrl: 'https://www.ornek-restoran.com',
};

beforeEach(() => vi.clearAllMocks());
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe('MenuAnalizIstemcisi kaynak sekmeleri', () => {
  it('iki mevcut sekmeyi ve üçüncü Web Sitesinden Bul sekmesini gösterir', () => {
    render(<MenuAnalizIstemcisi {...defaultProps} />);

    expect(screen.getByRole('tab', { name: 'Menü Linki (URL)' })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: 'Dosya Yükle (PDF/Görsel)' })).toBeInTheDocument();
    fireEvent.click(screen.getByRole('tab', { name: 'Web Sitesinden Bul' }));
    expect(screen.getByLabelText('İşletme web sitesi')).toHaveValue('https://www.ornek-restoran.com');
    expect(screen.getByRole('button', { name: 'Menüyü Bul ve Analiz Et' })).toBeEnabled();
  });

  it('website discovery isteğini extractor yerine yalnızca Next.js route’una gönderir', async () => {
    const fetchSpy = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => (
      new Response(JSON.stringify({ data: { job_id: 'internal-job-1' } }), { status: 201 })
    ));
    vi.stubGlobal('fetch', fetchSpy);
    render(<MenuAnalizIstemcisi {...defaultProps} />);

    fireEvent.click(screen.getByRole('tab', { name: 'Web Sitesinden Bul' }));
    fireEvent.click(screen.getByRole('button', { name: 'Menüyü Bul ve Analiz Et' }));

    await waitFor(() => expect(fetchSpy).toHaveBeenCalledTimes(1));
    const [url, init] = fetchSpy.mock.calls[0];
    expect(url).toBe('/api/yonetici/menu-analiz/kaynak-kesfi');
    expect(JSON.parse(String(init?.body))).toEqual({
      business_id: defaultProps.businessId,
      website_url: defaultProps.initialWebsiteUrl,
    });
    expect(String(init?.body)).not.toContain('api_key');
    expect(String(init?.body)).not.toContain('auto_extract');
  });

  it('mevcut Menü Linki sekmesinin server action akışını korur', async () => {
    vi.mocked(menuActions.menuAnalizBaslatUrl).mockResolvedValue({ ok: true, jobId: 'url-job' });
    render(<MenuAnalizIstemcisi {...defaultProps} />);

    fireEvent.change(screen.getByLabelText("Menü URL'si"), { target: { value: 'https://site.com/menu.pdf' } });
    fireEvent.click(screen.getByRole('button', { name: 'Analizi Başlat' }));

    await waitFor(() => expect(menuActions.menuAnalizBaslatUrl).toHaveBeenCalledWith(defaultProps.businessId, 'https://site.com/menu.pdf'));
  });

  it('mevcut Dosya Yükle sekmesinin upload route akışını korur', async () => {
    const fetchSpy = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => (
      new Response(JSON.stringify({ data: { job_id: 'upload-job' } }), { status: 201 })
    ));
    vi.stubGlobal('fetch', fetchSpy);
    render(<MenuAnalizIstemcisi {...defaultProps} />);

    fireEvent.click(screen.getByRole('tab', { name: 'Dosya Yükle (PDF/Görsel)' }));
    const file = new File(['menu'], 'menu.pdf', { type: 'application/pdf' });
    fireEvent.change(screen.getByLabelText('Dosya (PDF veya görsel, maks. 30 MB)'), { target: { files: [file] } });
    fireEvent.click(screen.getByRole('button', { name: 'Analizi Başlat' }));

    await waitFor(() => expect(fetchSpy).toHaveBeenCalledTimes(1));
    expect(fetchSpy.mock.calls[0][0]).toBe('/sunucu/yonetici/menu-analiz/baslat');
    expect(fetchSpy.mock.calls[0][1]?.body).toBeInstanceOf(FormData);
  });

  it('discovery job sonucunu mevcut polling üzerinden aynı review alanına taşır', async () => {
    vi.mocked(menuActions.menuAnalizDurumSorgula).mockResolvedValue({
      ok: true,
      data: {
        status: 'finished',
        errorMessage: null,
        sourceType: 'website_discovery',
        discoveryOutcome: {
          status: 'SOURCE_FOUND_PARTIAL_ITEMS',
          message: 'Menü bulundu. Bazı ürünlerin fiyat bilgisi eksik.',
          totalItems: 1,
          pricedItems: 0,
          missingPriceItems: 1,
          categoryCount: 1,
          sourceUrl: 'https://site.com/menu',
          sourceProvider: 'MenumGelsin',
          selectedSource: null,
          discoveredVia: 'website_link',
        },
      },
    });
    vi.mocked(menuActions.menuAnalizOgeleriListele).mockResolvedValue([{
      id: 'item-1', category_name: 'Mezeler', name: 'Humus', description: null,
      price_cents: null, currency: 'TRY', confidence: 0.9, requires_review: true,
      review_reasons: ['Fiyat eksik'], warnings: [], excluded: false, imported: false,
      imported_menu_item_id: null,
    }]);

    render(<MenuAnalizIstemcisi {...defaultProps} initialJobId="internal-job-1" />);

    expect(await screen.findByText('Menü bulundu')).toBeInTheDocument();
    expect(await screen.findByDisplayValue('Humus')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('—')).toHaveValue('');
    expect(screen.getAllByText('Fiyat eksik').length).toBeGreaterThan(0);
  });
});

describe('DiscoveryOutcomeCard', () => {
  it('NO_SOURCE_FOUND durumunda mevcut giriş sekmelerine geçiş sunar', () => {
    const onModeChange = vi.fn();
    render(<DiscoveryOutcomeCard
      outcome={{
        status: 'NO_SOURCE_FOUND',
        message: 'İşletmenin web sitesinde otomatik olarak menü kaynağı bulunamadı.',
        totalItems: 0,
        pricedItems: 0,
        missingPriceItems: 0,
        categoryCount: 0,
        sourceUrl: null,
        sourceProvider: null,
        selectedSource: null,
        discoveredVia: null,
      }}
      onModeChange={onModeChange}
      onRetry={vi.fn()}
    />);

    fireEvent.click(screen.getByRole('button', { name: 'Menü Linki Gir' }));
    expect(onModeChange).toHaveBeenCalledWith('url');
    fireEvent.click(screen.getByRole('button', { name: 'PDF/Görsel Yükle' }));
    expect(onModeChange).toHaveBeenCalledWith('dosya');
  });

  it('FETCH_FAILED durumunda tekrar deneme ve iki alternatif sekmeyi sunar', () => {
    const onRetry = vi.fn();
    render(<DiscoveryOutcomeCard
      outcome={{
        status: 'FETCH_FAILED',
        message: 'İşletmenin web sitesine otomatik olarak erişilemedi.',
        totalItems: 0,
        pricedItems: 0,
        missingPriceItems: 0,
        categoryCount: 0,
        sourceUrl: null,
        sourceProvider: null,
        selectedSource: null,
        discoveredVia: null,
      }}
      onModeChange={vi.fn()}
      onRetry={onRetry}
    />);

    fireEvent.click(screen.getByRole('button', { name: 'Tekrar Dene' }));
    expect(onRetry).toHaveBeenCalledTimes(1);
    expect(screen.getByRole('button', { name: 'Menü Linki Gir' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'PDF/Görsel Yükle' })).toBeInTheDocument();
  });
});
