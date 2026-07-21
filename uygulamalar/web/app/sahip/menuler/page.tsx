import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { createOwnerMenu, createExternalMenu } from './menu-islemleri';
import { MenuAktivasyonButonu } from './menu-aktivasyon-butonu';

export const metadata: Metadata = {
  title: 'Menüler | Sahip Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams?: Promise<{ hata?: string; basari?: string }>;
};

const createMenuErrors: Record<string, string> = {
  missing_fields: 'İşletme, menü adı ve URL zorunlu.',
  forbidden: 'Bu işletme için menü oluşturma yetkiniz yok.',
  create_failed: 'Menü oluşturulamadı. Lütfen tekrar deneyin.',
  invalid_url: 'Geçerli bir URL giriniz (https:// ile başlamalı).',
};

const successMessages: Record<string, string> = {
  external_menu_created: 'Dış menü bağlantısı başarıyla eklendi.',
  url_updated: 'Menü URL\'si güncellendi.',
};

export default async function OwnerMenusPage({ searchParams }: Props) {
  const resolvedSearchParams = await (searchParams ?? Promise.resolve({ hata: undefined, basari: undefined }));
  const hata   = resolvedSearchParams.hata;
  const basari = resolvedSearchParams.basari;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = await getOwnerBusinesses<{ id: string; name: string }>(
    supabase as any,
    user!.id,
    'id, name',
  );

  const businessIds = businesses.map((b) => b.id);
  const businessMap = Object.fromEntries(businesses.map((b) => [b.id, b.name]));

  type MenuRow = { id: string; business_id: string; title: string; status: string; kind: string | null; external_url: string | null; created_at: string };
  const { data: menus } = businessIds.length > 0
    ? await (supabase as any)
        .from('menus')
        .select('id, business_id, title, status, kind, external_url, created_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false }) as { data: MenuRow[] | null }
    : { data: [] as MenuRow[] };

  const list = menus ?? [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Menüler"
        description="İşletmelerinize ait tüm menüler"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <PanelBolumKarti
          title="Yeni menü oluştur"
          description="İşletme seçin, menü adını girin ve editöre geçin."
          className="mb-5"
        >
          <form action={createOwnerMenu} className="grid gap-3 md:grid-cols-[minmax(0,1fr)_minmax(220px,320px)_auto] md:items-end">
            <label className="flex flex-col gap-1">
              <span className="text-xs font-[800] text-muted">Menü adı</span>
              <input
                name="title"
                required
                maxLength={200}
                placeholder="Örn: Ana Menü"
                className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
              />
            </label>
            <label className="flex flex-col gap-1">
              <span className="text-xs font-[800] text-muted">İşletme</span>
              <select
                name="businessId"
                required
                className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
                defaultValue={businesses[0]?.id ?? ''}
              >
                {businesses.length === 0 ? (
                  <option value="" disabled>İşletme yok</option>
                ) : (
                  businesses.map((business) => (
                    <option key={business.id} value={business.id}>{business.name}</option>
                  ))
                )}
              </select>
            </label>
            <button
              type="submit"
              disabled={businesses.length === 0}
              className="min-h-11 rounded-xl bg-primary px-4 text-sm font-[900] text-white disabled:cursor-not-allowed disabled:opacity-50"
            >
              Oluştur
            </button>
          </form>
          {hata && createMenuErrors[hata] && (
            <p className="mt-3 rounded-xl bg-red-50 px-3 py-2 text-sm font-[700] text-red-700">
              {createMenuErrors[hata]}
            </p>
          )}
          {basari && successMessages[basari] && (
            <p className="mt-3 rounded-xl bg-green-50 px-3 py-2 text-sm font-[700] text-green-700">
              {successMessages[basari]}
            </p>
          )}
        </PanelBolumKarti>

        {/* Dış menü bağlantısı */}
        <PanelBolumKarti
          title="Dış menü bağlantısı ekle"
          description="QR kod linki, yemeksepeti veya başka bir platform URL'si ekleyin."
          className="mb-5"
        >
          <form action={createExternalMenu} className="grid gap-3">
            <div className="grid gap-3 md:grid-cols-[minmax(0,1fr)_minmax(180px,240px)_minmax(160px,200px)]">
              <label className="flex flex-col gap-1">
                <span className="text-xs font-[800] text-muted">Menü adı</span>
                <input
                  name="title"
                  required
                  maxLength={200}
                  placeholder="Örn: QR Menü"
                  className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
                />
              </label>
              <label className="flex flex-col gap-1">
                <span className="text-xs font-[800] text-muted">Tür</span>
                <select
                  name="kind"
                  className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
                >
                  <option value="external">Dış Link</option>
                  <option value="qr">QR Kod</option>
                </select>
              </label>
              <label className="flex flex-col gap-1">
                <span className="text-xs font-[800] text-muted">İşletme</span>
                <select
                  name="businessId"
                  required
                  className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
                  defaultValue={businesses[0]?.id ?? ''}
                >
                  {businesses.map((b) => (
                    <option key={b.id} value={b.id}>{b.name}</option>
                  ))}
                </select>
              </label>
            </div>
            <div className="flex gap-3">
              <label className="flex flex-1 flex-col gap-1">
                <span className="text-xs font-[800] text-muted">URL</span>
                <input
                  name="externalUrl"
                  type="url"
                  required
                  placeholder="https://view.qrall.co/tr?..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
                />
              </label>
              <div className="flex items-end">
                <button
                  type="submit"
                  disabled={businesses.length === 0}
                  className="min-h-11 rounded-xl bg-primary px-4 text-sm font-[900] text-white disabled:opacity-50"
                >
                  Ekle
                </button>
              </div>
            </div>
          </form>
        </PanelBolumKarti>
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<MenuIcon />}
            title="Henüz menü yok"
            description="İşletmenize menü eklemek için önce bir işletme seçin."
          />
        ) : (
          <PanelBolumKarti noPadding>
            <ul className="divide-y divide-border">
              {list.map((m) => (
                <li key={m.id} className="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-black/[0.02]">
                  <Link
                    href={`/sahip/menuler/${m.id}`}
                    className="flex min-w-0 flex-1 items-center gap-4"
                  >
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted">
                      {m.kind === 'qr' ? <QrIcon /> : m.kind === 'external' ? <LinkIcon /> : <MenuIcon />}
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-[800] text-textStrong">{m.title}</p>
                      <p className="mt-0.5 text-xs text-muted">
                        {businessMap[m.business_id] ?? m.business_id}
                        {m.external_url && (
                          <span className="ml-2 rounded bg-blue-50 px-1.5 py-0.5 text-[10px] font-[700] text-blue-600">
                            {m.kind === 'qr' ? 'QR' : 'Dış Link'}
                          </span>
                        )}
                      </p>
                    </div>
                  </Link>

                  <MenuAktivasyonButonu
                    menuId={m.id}
                    businessId={m.business_id}
                    isActive={m.status === 'published'}
                  />

                  <span
                    className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${
                      m.status === 'published'
                        ? 'bg-green-50 text-green-700'
                        : m.status === 'archived'
                          ? 'bg-zinc-100 text-zinc-500'
                          : 'bg-amber-50 text-amber-700'
                    }`}
                  >
                    {m.status === 'published' ? 'Yayında' : m.status === 'archived' ? 'Arşiv' : 'Taslak'}
                  </span>

                  <Link href={`/sahip/menuler/${m.id}`} aria-label="Menü detayına git">
                    <ChevronIcon />
                  </Link>
                </li>
              ))}
            </ul>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function MenuIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}

function ChevronIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" /><line x1="14" y1="14" x2="14" y2="14" />
      <line x1="17" y1="14" x2="20" y2="14" /><line x1="14" y1="17" x2="14" y2="20" />
      <line x1="17" y1="17" x2="17" y2="17" /><line x1="20" y1="17" x2="20" y2="20" />
    </svg>
  );
}

function LinkIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" />
      <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" />
    </svg>
  );
}

