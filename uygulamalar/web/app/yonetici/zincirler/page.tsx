import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';

export const metadata: Metadata = {
  title: 'Zincirler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; page?: string }> };

const PAGE_SIZE = 40;

type ChainRow = {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  logo_url: string | null;
  is_verified: boolean;
  branch_count: number;
  template_business_id: string | null;
  created_at: string;
};

export default async function YoneticiZincilerPage({ searchParams }: Props) {
  const { q = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));

  const supabase = await createSupabaseServerClient();

  const { data: rpcData, error } = await (supabase as any).rpc('admin_list_chains_v1', {
    p_q: q || null,
    p_limit: PAGE_SIZE,
    p_offset: (pageNum - 1) * PAGE_SIZE,
  });

  const rows: ChainRow[] = rpcData ?? [];
  // RPC does not return total — show current page count; pagination is by offset
  const hasMore = rows.length === PAGE_SIZE;
  const totalPages = hasMore ? pageNum + 1 : pageNum;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Zincirler"
        description={error ? 'Yüklenemedi' : rows.length === 0 && !q ? 'Henüz zincir yok' : `${rows.length} zincir${hasMore ? '+' : ''}`}
        actions={
          <Link href="/yonetici/zincirler/new">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni Zincir
            </PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <form method="get" className="mb-4">
          <input
            name="q"
            defaultValue={q}
            placeholder="Zincir ara..."
            className="w-full max-w-sm rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
        </form>

        {rows.length === 0 ? (
          <PanelEmptyState
            icon={<LayersIcon />}
            title={q ? 'Sonuç bulunamadı' : 'Zincir yok'}
            description={q ? `"${q}" ile eşleşen zincir yok` : 'Henüz zincir oluşturulmamış'}
          />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Zincir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şube</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şablon</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.map((chain) => (
                  <tr key={chain.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <ChainAvatar name={chain.name} logoUrl={chain.logo_url} />
                        <div>
                          <Link
                            href={`/yonetici/zincirler/${chain.id}`}
                            className="font-[700] text-textStrong hover:text-[color:var(--yd-color-primary)]"
                          >
                            {chain.name}
                          </Link>
                          <p className="text-xs text-muted">{chain.slug ?? '—'}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-muted">{chain.category ?? '—'}</td>
                    <td className="px-5 py-3">
                      <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[11px] font-[800] text-slate-700">
                        {chain.branch_count} şube
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      {chain.template_business_id ? (
                        <span className="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-[800] text-indigo-700">
                          Var
                        </span>
                      ) : (
                        <span className="text-xs text-muted">—</span>
                      )}
                    </td>
                    <td className="px-5 py-3">
                      {chain.is_verified ? (
                        <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-[800] text-blue-700">
                          Onaylı
                        </span>
                      ) : (
                        <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[11px] font-[800] text-zinc-500">
                          Onaysız
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-border px-5 py-3">
                <p className="text-xs text-muted">
                  Sayfa {pageNum} / {totalPages}
                </p>
                <div className="flex gap-2">
                  {pageNum > 1 && (
                    <Link
                      href={`?q=${q}&page=${pageNum - 1}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] hover:bg-black/[0.04]"
                    >
                      Önceki
                    </Link>
                  )}
                  {pageNum < totalPages && (
                    <Link
                      href={`?q=${q}&page=${pageNum + 1}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] hover:bg-black/[0.04]"
                    >
                      Sonraki
                    </Link>
                  )}
                </div>
              </div>
            )}
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ChainAvatar({ name, logoUrl }: { name: string; logoUrl: string | null }) {
  if (logoUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={logoUrl}
        alt={name}
        className="h-8 w-8 rounded-full object-cover border border-border"
      />
    );
  }
  return (
    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-[13px] font-[900] text-primary">
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

function LayersIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 2 7 12 12 22 7 12 2" />
      <polyline points="2 17 12 22 22 17" />
      <polyline points="2 12 12 17 22 12" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}
