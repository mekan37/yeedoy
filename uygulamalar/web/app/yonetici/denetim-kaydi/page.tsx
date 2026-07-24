import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Denetim Kaydı | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ action?: string; page?: string }> };
const PAGE_SIZE = 50;

const ACTION_COLORS: Record<string, string> = {
  create: 'bg-green-50 text-green-700',
  update: 'bg-blue-50 text-blue-700',
  delete: 'bg-red-50 text-red-700',
  approve: 'bg-emerald-50 text-emerald-700',
  reject: 'bg-orange-50 text-orange-700',
  suspend: 'bg-amber-50 text-amber-700',
  restore: 'bg-teal-50 text-teal-700',
  ban: 'bg-red-100 text-red-800',
};

const KNOWN_ACTIONS = ['create', 'update', 'delete', 'approve', 'reject', 'suspend', 'restore', 'ban'];

export default async function AdminAuditPage({ searchParams }: Props) {
  const { action = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = null;
  let tableExists = true;

  try {
    let query = (supabase as any)
      .from('admin_audit_log')
      .select('id, action, target_table, target_id, meta, created_at', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1);

    if (action) {
      query = query.eq('action', action);
    }

    const { data, count: total, error } = await query;

    if (error && (error.code === '42P01' || error.message?.includes('does not exist'))) {
      tableExists = false;
    } else {
      list = (data ?? []) as any[];
      count = total ?? 0;
    }
  } catch {
    tableExists = false;
  }

  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Denetim Kaydı"
        description={
          tableExists && count != null
            ? `${count.toLocaleString('tr-TR')} kayıt`
            : 'Admin işlemlerinin denetim geçmişi'
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {!tableExists ? (
          <PanelBolumKarti>
            <PanelEmptyState
              icon={<ShieldIcon />}
              title="Denetim tablosu bulunamadı"
              description="admin_audit_log tablosu henüz oluşturulmamış. Denetim kaydı altyapısı yapılandırıldıktan sonra bu sayfa otomatik olarak aktif hale gelecek."
            />
          </PanelBolumKarti>
        ) : (
          <>
            {/* Action filter */}
            <form method="get" className="mb-4 flex flex-wrap gap-2">
              <button
                type="submit"
                name="action"
                value=""
                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
                  action === ''
                    ? 'bg-primary text-white'
                    : 'bg-card border border-border text-muted hover:text-textStrong'
                }`}
              >
                Tümü
              </button>
              {KNOWN_ACTIONS.map((a) => (
                <button
                  key={a}
                  type="submit"
                  name="action"
                  value={a}
                  className={`rounded-lg px-3 py-1.5 text-xs font-bold capitalize transition-colors ${
                    action === a
                      ? 'bg-primary text-white'
                      : 'bg-card border border-border text-muted hover:text-textStrong'
                  }`}
                >
                  {a}
                </button>
              ))}
            </form>

            {list.length === 0 ? (
              <PanelEmptyState
                icon={<ShieldIcon />}
                title="Kayıt bulunamadı"
                description="Seçilen filtre için denetim kaydı yok."
              />
            ) : (
              <PanelBolumKarti noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Eylem</th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Hedef Tablo</th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Hedef ID</th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Aktör</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((entry: any) => {
                      const colorClass = ACTION_COLORS[entry.action] ?? 'bg-zinc-100 text-zinc-600';
                      const actorId = entry.meta?.actor_id ?? entry.meta?.user_id ?? null;
                      return (
                        <tr key={entry.id} className="hover:bg-black/1">
                          <td className="px-5 py-3 text-xs text-muted whitespace-nowrap">
                            {entry.created_at
                              ? new Date(entry.created_at).toLocaleString('tr-TR', {
                                  day: '2-digit',
                                  month: '2-digit',
                                  year: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit',
                                })
                              : '—'}
                          </td>
                          <td className="px-5 py-3">
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold capitalize ${colorClass}`}>
                              {entry.action ?? '—'}
                            </span>
                          </td>
                          <td className="px-5 py-3 font-mono text-xs text-muted">
                            {entry.target_table ?? '—'}
                          </td>
                          <td className="px-5 py-3 font-mono text-xs text-muted">
                            {entry.target_id
                              ? String(entry.target_id).length > 16
                                ? String(entry.target_id).slice(0, 12) + '…'
                                : entry.target_id
                              : '—'}
                          </td>
                          <td className="px-5 py-3 font-mono text-xs text-muted">
                            {actorId
                              ? String(actorId).length > 16
                                ? String(actorId).slice(0, 12) + '…'
                                : actorId
                              : '—'}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
                {totalPages > 1 && (
                  <div className="flex items-center justify-between border-t border-border px-5 py-3">
                    <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                    <div className="flex gap-2">
                      {pageNum > 1 && (
                        <a
                          href={`?action=${action}&page=${pageNum - 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                        >
                          ← Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a
                          href={`?action=${action}&page=${pageNum + 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                        >
                          Sonraki →
                        </a>
                      )}
                    </div>
                  </div>
                )}
              </PanelBolumKarti>
            )}
          </>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ShieldIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}

