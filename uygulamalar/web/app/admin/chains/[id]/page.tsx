import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Zincir Detayı | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { params: Promise<{ id: string }> };

type DetailRow = {
  chain_id: string;
  chain_name: string;
  chain_slug: string | null;
  chain_category: string | null;
  chain_description: string | null;
  chain_logo_url: string | null;
  chain_cover_url: string | null;
  chain_website: string | null;
  chain_is_verified: boolean;
  template_business_id: string | null;
  business_id: string;
  business_name: string;
  branch_label: string | null;
  city: string | null;
  district: string | null;
  is_template: boolean;
  is_active: boolean;
};

export default async function AdminChainDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();

  const { data, error } = await (supabase as any).rpc('admin_get_chain_detail_v1', { p_chain_id: id });

  if (error || !data || (data as DetailRow[]).length === 0) notFound();

  const rows = data as DetailRow[];
  const first = rows[0];

  const chain = {
    id: first.chain_id,
    name: first.chain_name,
    slug: first.chain_slug,
    category: first.chain_category,
    description: first.chain_description,
    logo_url: first.chain_logo_url,
    website: first.chain_website,
    is_verified: first.chain_is_verified,
    template_business_id: first.template_business_id,
  };

  const branches = rows.map((r) => ({
    id: r.business_id,
    name: r.business_name,
    branch_label: r.branch_label,
    city: r.city,
    district: r.district,
    is_template: r.is_template,
    is_active: r.is_active,
  }));

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Zincirler"
        title={chain.name}
        description={`${branches.length} şube${chain.category ? ` · ${chain.category}` : ''}`}
        actions={
          <div className="flex items-center gap-2">
            {chain.is_verified ? (
              <span className="rounded-full bg-blue-50 px-3 py-1 text-[12px] font-[800] text-blue-700">Onaylı</span>
            ) : (
              <span className="rounded-full bg-zinc-100 px-3 py-1 text-[12px] font-[800] text-zinc-500">Onaysız</span>
            )}
            <Link
              href="/admin/chains"
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:bg-black/[0.04]"
            >
              ← Zincirler
            </Link>
          </div>
        }
      />
      <PanelContentSurface className="pt-6 space-y-6">
        {/* Chain info */}
        <PanelSectionCard title="Zincir Bilgileri">
          <dl className="grid grid-cols-2 gap-x-8 gap-y-4 sm:grid-cols-3">
            <InfoRow label="Kategori" value={chain.category ?? '—'} />
            <InfoRow label="Slug" value={chain.slug ?? '—'} />
            <InfoRow label="Website" value={chain.website ?? '—'} />
            <InfoRow
              label="Şablon Şube"
              value={
                chain.template_business_id
                  ? (branches.find((b) => b.id === chain.template_business_id)?.name ?? 'Var')
                  : '—'
              }
            />
            <InfoRow label="Şube Sayısı" value={String(branches.length)} />
            <InfoRow label="Doğrulama" value={chain.is_verified ? 'Onaylı' : 'Onaysız'} />
          </dl>
          {chain.description && (
            <p className="mt-4 text-sm text-muted border-t border-border pt-4">{chain.description}</p>
          )}
        </PanelSectionCard>

        {/* Branches */}
        <PanelSectionCard title="Şubeler" noPadding>
          {branches.length === 0 ? (
            <div className="p-6">
              <PanelEmptyState
                icon={<BuildingIcon />}
                title="Şube yok"
                description="Bu zincire henüz şube atanmamış"
              />
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şube Etiketi</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Rol</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {branches.map((b) => (
                  <tr key={b.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3">
                      <Link
                        href={`/admin/businesses/${b.id}`}
                        className="font-[700] text-textStrong hover:text-[color:var(--yd-color-primary)]"
                      >
                        {b.name}
                      </Link>
                    </td>
                    <td className="px-5 py-3 text-muted text-xs">{b.branch_label ?? '—'}</td>
                    <td className="px-5 py-3 text-muted">
                      {[b.city, b.district].filter(Boolean).join(', ') || '—'}
                    </td>
                    <td className="px-5 py-3">
                      {b.is_template ? (
                        <span className="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-[800] text-indigo-700">
                          Şablon
                        </span>
                      ) : (
                        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-[800] text-slate-500">
                          Şube
                        </span>
                      )}
                    </td>
                    <td className="px-5 py-3">
                      <span
                        className={`rounded-full px-2 py-0.5 text-[11px] font-[800] ${
                          b.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                        }`}
                      >
                        {b.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <Link
                        href={`/admin/businesses/${b.id}`}
                        className="text-xs font-[700] text-primary hover:underline"
                      >
                        Detay →
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </PanelSectionCard>

        {/* Template menu note */}
        {chain.template_business_id && (
          <PanelSectionCard title="Zincir Menüsü">
            <p className="text-sm text-muted mb-4">
              Şablon şubenin menüsü tüm şubelere uygulanır. Şube override fiyatları şube detay sayfasından yönetilebilir.
            </p>
            <Link
              href={`/admin/businesses/${chain.template_business_id}`}
              className="inline-flex items-center gap-2 rounded-lg border border-border px-4 py-2 text-sm font-[700] text-textStrong hover:bg-black/[0.03] transition-colors"
            >
              <MenuIcon />
              Şablon Şube: {branches.find((b) => b.id === chain.template_business_id)?.name ?? 'Şube'}
            </Link>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-[11px] font-[800] uppercase tracking-wide text-muted">{label}</dt>
      <dd className="mt-1 text-sm font-[600] text-textStrong">{value}</dd>
    </div>
  );
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="8" y1="6" x2="21" y2="6" />
      <line x1="8" y1="12" x2="21" y2="12" />
      <line x1="8" y1="18" x2="21" y2="18" />
      <line x1="3" y1="6" x2="3.01" y2="6" />
      <line x1="3" y1="12" x2="3.01" y2="12" />
      <line x1="3" y1="18" x2="3.01" y2="18" />
    </svg>
  );
}
