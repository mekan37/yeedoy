import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { TemizleDugmesi } from './temizle-dugmesi';

export const metadata: Metadata = {
  title: 'Geçici Yüklemeler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 50;

type Props = { searchParams: Promise<{ page?: string; expired?: string }> };

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default async function AdminTempUploadsPage({ searchParams }: Props) {
  const { page = '1', expired = '' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = null;
  let tableExists = true;

  try {
    let query = (supabase as any)
      .from('temp_uploads')
      .select('id, file_name:storage_path, file_size:bytes, user_id, created_at, expires_at, bucket:storage_bucket', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1);

    if (expired === '1') {
      query = query.lt('expires_at', new Date().toISOString());
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
  const expiredCount = list.filter((u) => u.expires_at && new Date(u.expires_at) < new Date()).length;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Geçici Yüklemeler"
        description={
          tableExists && count != null
            ? `${count.toLocaleString('tr-TR')} dosya — ${expiredCount} süresi dolmuş`
            : 'Geçici medya yükleme kayıtları'
        }
        actions={tableExists && count != null ? <TemizleDugmesi /> : undefined}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {!tableExists ? (
          <PanelBolumKarti>
            <PanelEmptyState
              icon={<UploadIcon />}
              title="Geçici yükleme tablosu bulunamadı"
              description="temp_uploads tablosu henüz oluşturulmamış. Depolama yönetimi altyapısı yapılandırıldıktan sonra bu sayfa aktif hale gelecek."
            />
          </PanelBolumKarti>
        ) : (
          <>
            {/* Filters */}
            <form method="get" className="mb-4 flex flex-wrap gap-2">
              <button
                type="submit"
                name="expired"
                value=""
                className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                  expired !== '1'
                    ? 'bg-primary text-white'
                    : 'bg-card border border-border text-muted hover:text-textStrong'
                }`}
              >
                Tümü
              </button>
              <button
                type="submit"
                name="expired"
                value="1"
                className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                  expired === '1'
                    ? 'bg-primary text-white'
                    : 'bg-card border border-border text-muted hover:text-textStrong'
                }`}
              >
                Süresi Dolmuş
              </button>
            </form>

            {list.length === 0 ? (
              <PanelEmptyState
                icon={<UploadIcon />}
                title="Yükleme bulunamadı"
                description="Seçilen filtre için kayıt yok."
              />
            ) : (
              <PanelBolumKarti noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Dosya Adı</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Boyut</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Yükleme</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Son Kullanma</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((u: any) => {
                      const isExpired = u.expires_at && new Date(u.expires_at) < new Date();
                      return (
                        <tr key={u.id} className="hover:bg-black/[0.01]">
                          <td className="px-5 py-3">
                            <p className="font-[700] text-textStrong max-w-[200px] truncate">{u.file_name ?? '—'}</p>
                            {u.bucket && <p className="text-[10px] text-muted">{u.bucket}</p>}
                          </td>
                          <td className="px-5 py-3 text-muted">
                            {u.file_size != null ? formatBytes(u.file_size) : '—'}
                          </td>
                          <td className="px-5 py-3 text-xs text-muted font-mono">
                            {u.user_id ? u.user_id.slice(0, 12) + '…' : '—'}
                          </td>
                          <td className="px-5 py-3 text-xs text-muted">
                            {u.created_at ? new Date(u.created_at).toLocaleDateString('tr-TR') : '—'}
                          </td>
                          <td className="px-5 py-3 text-xs text-muted">
                            {u.expires_at ? new Date(u.expires_at).toLocaleDateString('tr-TR') : '—'}
                          </td>
                          <td className="px-5 py-3">
                            {isExpired ? (
                              <span className="rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-[800] text-red-700">
                                Süresi Doldu
                              </span>
                            ) : (
                              <span className="rounded-full bg-green-50 px-2 py-0.5 text-[10px] font-[800] text-green-700">
                                Geçerli
                              </span>
                            )}
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
                          href={`?expired=${expired}&page=${pageNum - 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                        >
                          ← Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a
                          href={`?expired=${expired}&page=${pageNum + 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
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

function UploadIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="17 8 12 3 7 8" />
      <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
  );
}
