import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Başvurularım | Owner Panel',
  robots: { index: false, follow: false },
};

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  new: { label: 'İnceleniyor', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

export default async function OwnerBusinessSubmissionsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: submissions } = await (supabase as any)
    .from('business_submissions')
    .select('id, name, city, district, category, status, admin_note, created_at')
    .eq('submitted_by', user!.id)
    .order('created_at', { ascending: false });

  const list = (submissions ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="İşletmeler"
        title="Başvurularım"
        description="Gönderdiğiniz işletme başvurularının durumu"
        actions={
          <Link href="/owner/businesses/new">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni Başvuru
            </PanelActionButton>
          </Link>
        }
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<DocumentIcon />}
            title="Henüz başvuru yok"
            description="Yeni işletme başvurusu oluşturabilirsiniz."
            action={
              <Link href="/owner/businesses/new">
                <PanelActionButton variant="primary" icon={<PlusIcon />}>
                  Başvuru Oluştur
                </PanelActionButton>
              </Link>
            }
          />
        ) : (
          <PanelSectionCard noPadding>
            <ul className="divide-y divide-border">
              {list.map((s) => {
                const statusInfo = STATUS_MAP[s.status] ?? STATUS_MAP['new'];
                return (
                  <li key={s.id} className="px-5 py-4">
                    <div className="flex items-start justify-between gap-4">
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-[800] text-textStrong">{s.name}</p>
                        <p className="mt-0.5 text-xs text-muted">
                          {s.category} · {s.city}, {s.district}
                        </p>
                        {s.admin_note && (
                          <p className="mt-1.5 text-xs text-muted italic">
                            Admin notu: {s.admin_note}
                          </p>
                        )}
                      </div>
                      <div className="flex shrink-0 flex-col items-end gap-1.5">
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${statusInfo.className}`}>
                          {statusInfo.label}
                        </span>
                        <span className="text-[11px] text-muted">
                          {new Date(s.created_at).toLocaleDateString('tr-TR')}
                        </span>
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function DocumentIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}
