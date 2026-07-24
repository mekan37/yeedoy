import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import {
  listAdminFisGonderimleri,
  getAdminFisGonderimOzeti,
  REVIEW_STATUS_LABELS,
  REVIEW_STATUS_STYLES,
  type FisGonderimDurumu,
} from '@/src/lib/veri/admin/fis-gonderimleri';
import { fisDurumGuncelle } from './fis-moderasyon-islemi';

export const metadata: Metadata = {
  title: 'Fiş Başvuruları | Yönetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };

const PAGE_SIZE = 40;

const STATUS_FILTRELER: Array<{ value: FisGonderimDurumu; label: string }> = [
  { value: 'pending', label: 'Bekliyor' },
  { value: 'needs_followup', label: 'Takip Gerekli' },
  { value: 'reviewed', label: 'İncelendi' },
  { value: 'all', label: 'Tümü' },
];

function normalizeStatus(value: string): FisGonderimDurumu {
  return STATUS_FILTRELER.some((f) => f.value === value)
    ? (value as FisGonderimDurumu)
    : 'pending';
}

export default async function FisBasvurulariSayfasi({ searchParams }: Props) {
  const { status: rawStatus = 'pending', page = '1' } = await searchParams;
  const status = normalizeStatus(rawStatus);
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const [{ list, count, hasNextPage, fetchError }, ozet] = await Promise.all([
    listAdminFisGonderimleri({
      reviewStatus: status,
      limit: PAGE_SIZE + 1,
      offset,
    }),
    getAdminFisGonderimOzeti(),
  ]);

  const totalPages =
    count != null
      ? Math.ceil(count / PAGE_SIZE)
      : pageNum + (hasNextPage ? 1 : 0);

  const sayfaAciklamasi = fetchError
    ? 'Fiş başvuruları okunamadı'
    : count != null
      ? `${count} başvuru`
      : `${list.length} başvuru`;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Fiş Başvuruları"
        description={sayfaAciklamasi}
      />

      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-5">

          {/* Özet kartları */}
          {!fetchError && (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              <OzetKarti label="Bekliyor" deger={ozet.pending_count} renk="text-amber-600" />
              <OzetKarti label="Takip Gerekli" deger={ozet.needs_followup_count} renk="text-blue-600" />
              <OzetKarti label="İncelendi" deger={ozet.reviewed_count} renk="text-green-600" />
              <OzetKarti label="Son 24 Saat" deger={ozet.recent_24h_count} renk="text-textStrong" />
            </div>
          )}

          {/* Durum filtreleri */}
          <form method="get" className="flex flex-wrap gap-2">
            {STATUS_FILTRELER.map(({ value, label }) => (
              <button
                key={value}
                type="submit"
                name="status"
                value={value}
                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
                  status === value
                    ? 'bg-primary text-white'
                    : 'border border-border bg-card text-muted hover:text-textStrong'
                }`}
              >
                {label}
                {value === 'pending' && ozet.pending_count > 0 && (
                  <span className="ml-1.5 inline-flex h-4 w-4 items-center justify-center rounded-full bg-amber-500 text-[9px] font-black text-white">
                    {ozet.pending_count > 99 ? '99+' : ozet.pending_count}
                  </span>
                )}
                {value === 'needs_followup' && ozet.needs_followup_count > 0 && (
                  <span className="ml-1.5 inline-flex h-4 w-4 items-center justify-center rounded-full bg-blue-500 text-[9px] font-black text-white">
                    {ozet.needs_followup_count > 99 ? '99+' : ozet.needs_followup_count}
                  </span>
                )}
              </button>
            ))}
          </form>

          {/* İçerik */}
          {fetchError ? (
            <PanelEmptyState
              icon={<FisIkonu />}
              title="Fiş başvuruları okunamadı"
              description="receipt_submissions yapısı mevcut ancak RPC erişimi veya yetki kontrolü başarısız oldu."
            />
          ) : list.length === 0 ? (
            <PanelEmptyState
              icon={<FisIkonu />}
              title="Başvuru yok"
              description={
                status === 'all'
                  ? 'Henüz fiş başvurusu alınmamış.'
                  : `"${REVIEW_STATUS_LABELS[status] ?? status}" durumunda başvuru yok.`
              }
            />
          ) : (
            <PanelBolumKarti noPadding>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        Kullanıcı
                      </th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        İşletme
                      </th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        Eşleşme
                      </th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        Durum
                      </th>
                      <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        Tarih
                      </th>
                      <th className="px-5 py-3 text-center text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        Fiş
                      </th>
                      <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">
                        İşlem
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((row) => (
                      <tr key={row.receipt_id} className="hover:bg-black/2">
                        {/* Kullanıcı — maskelenmiş */}
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {row.submitter_display}
                        </td>

                        {/* İşletme */}
                        <td className="px-5 py-3">
                          <p className="font-bold text-textStrong">
                            {row.business_name ?? '—'}
                          </p>
                          <p className="text-xs text-muted">
                            {[row.district, row.city, row.chain_name]
                              .filter(Boolean)
                              .join(' · ')}
                          </p>
                        </td>

                        {/* Eşleşme sayısı */}
                        <td className="px-5 py-3">
                          <span
                            className={`text-sm font-extrabold ${
                              row.matches_count === 0
                                ? 'text-red-500'
                                : 'text-textStrong'
                            }`}
                          >
                            {row.matches_count} ürün
                          </span>
                        </td>

                        {/* Durum badge */}
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                              REVIEW_STATUS_STYLES[row.review_status] ??
                              'bg-zinc-100 text-zinc-500'
                            }`}
                          >
                            {REVIEW_STATUS_LABELS[row.review_status] ?? row.review_status}
                          </span>
                          {row.review_note && (
                            <p className="mt-1 max-w-[180px] truncate text-xs text-muted">
                              {row.review_note}
                            </p>
                          )}
                        </td>

                        {/* Tarih */}
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(row.created_at).toLocaleDateString('tr-TR')}
                        </td>

                        {/* Fiş görseli */}
                        <td className="px-5 py-3 text-center">
                          {row.image_url ? (
                            <a
                              href={row.image_url}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex min-h-8 items-center gap-1 rounded-lg border border-border px-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
                            >
                              <FisIkonu boyut={14} />
                              Gör
                            </a>
                          ) : (
                            <span className="text-xs text-muted">—</span>
                          )}
                        </td>

                        {/* Moderasyon işlemleri */}
                        <td className="px-5 py-3">
                          <div className="flex items-center justify-end gap-1.5">
                            {row.review_status !== 'reviewed' && (
                              <form action={fisDurumGuncelle}>
                                <input type="hidden" name="receipt_id" value={row.receipt_id} />
                                <input type="hidden" name="review_status" value="reviewed" />
                                <button
                                  type="submit"
                                  className="rounded-lg bg-green-50 px-2.5 py-1.5 text-[11px] font-extrabold text-green-700 transition-colors hover:bg-green-100"
                                >
                                  İncele
                                </button>
                              </form>
                            )}
                            {row.review_status !== 'needs_followup' && (
                              <form action={fisDurumGuncelle}>
                                <input type="hidden" name="receipt_id" value={row.receipt_id} />
                                <input type="hidden" name="review_status" value="needs_followup" />
                                <button
                                  type="submit"
                                  className="rounded-lg bg-blue-50 px-2.5 py-1.5 text-[11px] font-extrabold text-blue-700 transition-colors hover:bg-blue-100"
                                >
                                  Takip
                                </button>
                              </form>
                            )}
                            {row.review_status !== 'pending' && (
                              <form action={fisDurumGuncelle}>
                                <input type="hidden" name="receipt_id" value={row.receipt_id} />
                                <input type="hidden" name="review_status" value="pending" />
                                <button
                                  type="submit"
                                  className="rounded-lg bg-zinc-50 px-2.5 py-1.5 text-[11px] font-extrabold text-zinc-500 transition-colors hover:bg-zinc-100"
                                >
                                  Sıfırla
                                </button>
                              </form>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Sayfalama */}
              {totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">
                    Sayfa {pageNum} / {totalPages}
                  </span>
                  <div className="flex gap-2">
                    {pageNum > 1 && (
                      <Link
                        href={`?status=${status}&page=${pageNum - 1}`}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                      >
                        Önceki
                      </Link>
                    )}
                    {pageNum < totalPages && (
                      <Link
                        href={`?status=${status}&page=${pageNum + 1}`}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                      >
                        Sonraki
                      </Link>
                    )}
                  </div>
                </div>
              )}
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Alt Bileşenler ──────────────────────────────────────────────────────────

function OzetKarti({
  label,
  deger,
  renk,
}: {
  label: string;
  deger: number;
  renk: string;
}) {
  return (
    <div className="rounded-xl border border-border bg-card px-4 py-3 shadow-xs">
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      <p className={`mt-1 text-2xl font-black ${renk}`}>{deger}</p>
    </div>
  );
}

function FisIkonu({ boyut = 20 }: { boyut?: number }) {
  return (
    <svg
      width={boyut}
      height={boyut}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  );
}
