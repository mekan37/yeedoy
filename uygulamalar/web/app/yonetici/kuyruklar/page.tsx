import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { attachEvidenceSignedUrls } from '@/src/lib/storage/claim-evidence-signed-urls';
import { IncelemeSatiri, type IncelemeSatiriVerisi } from './inceleme-satiri';
import { SahiplenmeSatiri, type SahiplenmeSatiriVerisi } from './sahiplenme-satiri';

export const metadata: Metadata = {
  title: 'Kuyruklar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Tab = 'inceleme' | 'sahiplenme';
type Props = { searchParams: Promise<{ tab?: string; q?: string; status?: string; sort?: string; page?: string; bugun?: string }> };

const PAGE_SIZE = 20;

export default async function AdminKuyruklarPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:kuyruklar');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Kuyruklar" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Kuyruklar" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { tab: rawTab, q = '', status = '', sort = 'newest', page = '1', bugun } = await searchParams;
  const tab: Tab = rawTab === 'sahiplenme' ? 'sahiplenme' : 'inceleme';
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const bugunFiltresi = bugun === '1';

  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;
  const bugunBasi = new Date(new Date().setHours(0, 0, 0, 0)).toISOString();

  const [incelemeBekleyenRes, sahiplenmeBekleyenRes] = await Promise.all([
    sb.from('business_submissions').select('id', { count: 'exact', head: true }).eq('status', 'new'),
    sb.from('owner_claims').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
  ]);
  const incelemeBekleyenSayisi = incelemeBekleyenRes.count ?? 0;
  const sahiplenmeBekleyenSayisi = sahiplenmeBekleyenRes.count ?? 0;

  let incelemeRows: IncelemeSatiriVerisi[] = [];
  let incelemeToplam = 0;
  let sahiplenmeRows: SahiplenmeSatiriVerisi[] = [];
  let sahiplenmeToplam = 0;

  if (tab === 'inceleme') {
    const result = await sb.rpc('admin_list_business_submissions_v2', {
      p_status: status || null,
      p_limit: PAGE_SIZE,
      p_offset: (pageNum - 1) * PAGE_SIZE,
      p_q: q.trim() || null,
      p_date_from: bugunFiltresi ? bugunBasi : null,
      p_date_to: null,
      p_sort_key: 'created_at',
      p_sort_ascending: sort === 'oldest',
    });
    const list = (result.data ?? []) as Array<{
      total_count: number; id: string; submitted_by: string; name: string; city: string; district: string;
      category: string; status: string; created_at: string;
    }>;
    incelemeToplam = list[0]?.total_count ?? 0;

    const userIds = Array.from(new Set(list.map((r) => r.submitted_by)));
    let nameByUser = new Map<string, string>();
    if (userIds.length > 0) {
      const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', userIds);
      nameByUser = new Map((profiles ?? []).map((p: any) => [p.user_id as string, (p.display_name as string) ?? '—']));
    }

    incelemeRows = list.map((r) => ({
      id: r.id, name: r.name, category: r.category, city: r.city, district: r.district,
      status: r.status, createdAt: r.created_at, submittedByName: nameByUser.get(r.submitted_by) ?? null,
    }));
  } else {
    let query = sb
      .from('owner_claims')
      .select('id, status, created_at, evidence_storage_path, phone, businesses(id, name, slug), user_profiles(user_id, display_name, email)', { count: 'exact' })
      .order('created_at', { ascending: sort === 'oldest' });
    if (status) query = query.eq('status', status);
    if (bugunFiltresi) query = query.gte('created_at', bugunBasi);
    if (q.trim()) query = query.ilike('businesses.name', `%${q.trim()}%`);
    query = query.range((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE - 1);

    const { data: claims, count } = await query;
    sahiplenmeToplam = count ?? 0;
    const enriched = await attachEvidenceSignedUrls(sb, (claims ?? []) as any[]);

    const businessIds = Array.from(new Set((claims ?? []).map((c: any) => c.businesses?.id).filter(Boolean)));
    const currentOwnerByBusiness = new Map<string, string>();
    if (businessIds.length > 0) {
      const { data: approvedClaims } = await sb
        .from('owner_claims')
        .select('business_id, user_profiles(display_name)')
        .eq('status', 'approved')
        .in('business_id', businessIds);
      for (const ac of (approvedClaims ?? []) as any[]) {
        if (!currentOwnerByBusiness.has(ac.business_id)) {
          currentOwnerByBusiness.set(ac.business_id, ac.user_profiles?.display_name ?? '—');
        }
      }
    }

    sahiplenmeRows = enriched.map((c: any) => ({
      id: c.id,
      businessName: c.businesses?.name ?? '—',
      businessSlug: c.businesses?.slug ?? null,
      currentOwnerName: c.businesses?.id ? currentOwnerByBusiness.get(c.businesses.id) ?? null : null,
      claimantName: c.user_profiles?.display_name ?? null,
      claimantEmail: c.user_profiles?.email ?? null,
      claimantPhone: c.phone ?? null,
      status: c.status,
      createdAt: c.created_at,
      evidenceUrl: c.evidence_signed_url ?? null,
    }));
  }

  const toplam = tab === 'inceleme' ? incelemeToplam : sahiplenmeToplam;
  const totalPages = Math.max(1, Math.ceil(toplam / PAGE_SIZE));
  const queryBase = buildQueryString({ tab, q, status, sort, bugun: bugunFiltresi ? '1' : '' });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Kuyruklar"
        description="İnceleme ve sahiplenme taleplerini buradan yönetebilirsiniz."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Sekmeler */}
          <div className="flex gap-2 border-b border-border">
            <TabButon href={`/yonetici/kuyruklar?tab=inceleme`} active={tab === 'inceleme'} label="İnceleme Kuyruğu" count={incelemeBekleyenSayisi} />
            <TabButon href={`/yonetici/kuyruklar?tab=sahiplenme`} active={tab === 'sahiplenme'} label="Sahiplenme Kuyruğu" count={sahiplenmeBekleyenSayisi} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <div>
                <h2 className="text-base font-black text-textStrong">{tab === 'inceleme' ? 'İnceleme Kuyruğu' : 'Sahiplenme Kuyruğu'}</h2>
                <p className="text-xs text-muted">
                  {tab === 'inceleme'
                    ? 'Listelenen işletmeler yayınlanmadan önce admin onayına ihtiyaç duyar.'
                    : 'İşletme sahipliği talepleri değerlendirme bekliyor.'}
                </p>
              </div>

              {/* Filtreler */}
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-[minmax(180px,1.6fr)_repeat(2,minmax(140px,1fr))_auto]">
                <input name="tab" value={tab} type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder={tab === 'inceleme' ? 'İşletme ara...' : 'İşletme veya kullanıcı ara...'}
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                <select name="status" defaultValue={status} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Durum: Tümü</option>
                  {tab === 'inceleme' ? (
                    <>
                      <option value="new">Beklemede</option>
                      <option value="approved">Onaylandı</option>
                      <option value="rejected">Reddedildi</option>
                    </>
                  ) : (
                    <>
                      <option value="pending">Beklemede</option>
                      <option value="approved">Onaylandı</option>
                      <option value="rejected">Reddedildi</option>
                    </>
                  )}
                </select>
                <select name="sort" defaultValue={sort} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="newest">Sırala: Yeni → Eski</option>
                  <option value="oldest">Sırala: Eski → Yeni</option>
                </select>
                <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">
                  Filtrele
                </button>
              </form>

              {(tab === 'inceleme' ? incelemeRows.length : sahiplenmeRows.length) === 0 ? (
                <PanelEmptyState icon={<CheckIcon />} title="Kayıt bulunamadı" description="Bu filtrelerle eşleşen bekleyen talep yok." />
              ) : (
                <PanelBolumKarti noPadding>
                  <div className="overflow-x-auto">
                    {tab === 'inceleme' ? (
                      <table className="w-full text-sm">
                        <thead>
                          <tr className="border-b border-border text-left">
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kategori</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Şehir / İlçe</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Başvuru Tarihi</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                            <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border">
                          {incelemeRows.map((row) => <IncelemeSatiri key={row.id} row={row} />)}
                        </tbody>
                      </table>
                    ) : (
                      <table className="w-full text-sm">
                        <thead>
                          <tr className="border-b border-border text-left">
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Mevcut Sahip</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Talep Eden</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Başvuru Tarihi</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kanıt</th>
                            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                            <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border">
                          {sahiplenmeRows.map((row) => <SahiplenmeSatiri key={row.id} row={row} />)}
                        </tbody>
                      </table>
                    )}
                  </div>

                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {toplam.toLocaleString('tr-TR')} kayıt</p>
                    {totalPages > 1 && (
                      <div className="flex items-center gap-1">
                        {pageNum > 1 && <Link href={`?${queryBase}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</Link>}
                        <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                        {pageNum < totalPages && <Link href={`?${queryBase}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</Link>}
                      </div>
                    )}
                  </div>
                </PanelBolumKarti>
              )}
            </div>

            {/* Sağ sidebar */}
            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Kuyruk Özeti">
                <div className="flex flex-col gap-3">
                  <OzetKarti label="İnceleme Kuyruğu" value={incelemeBekleyenSayisi} subtitle="bekleyen işletme" tone="pink" href="/yonetici/kuyruklar?tab=inceleme" />
                  <OzetKarti label="Sahiplenme Kuyruğu" value={sahiplenmeBekleyenSayisi} subtitle="bekleyen talep" tone="blue" href="/yonetici/kuyruklar?tab=sahiplenme" />
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Filtre Hızlı Erişim">
                <Link
                  href={`/yonetici/kuyruklar?tab=${tab}&bugun=1`}
                  className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
                >
                  Bugün Eklenenler <ArrowIcon />
                </Link>
              </PanelBolumKarti>

              <PanelBolumKarti title="Notlar">
                <ul className="flex flex-col gap-2 text-xs text-muted">
                  <li>İşletme başvurularını incelerken lütfen kapsül politikasına uygun davranın.</li>
                  <li>Şüpheli gördüğünüz durumları rapor olarak bildirebilirsiniz.</li>
                </ul>
                <Link href="/yonetici/olaylar" className="mt-3 block text-xs font-extrabold text-primary hover:underline">
                  Şüpheli durum bildir →
                </Link>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString();
}

function TabButon({ href, active, label, count }: { href: string; active: boolean; label: string; count: number }) {
  return (
    <Link
      href={href}
      className={`flex items-center gap-2 border-b-2 px-1 pb-3 text-sm font-extrabold transition-colors ${
        active ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong'
      }`}
    >
      {label}
      <span className={`rounded-full px-2 py-0.5 text-[11px] font-black ${active ? 'bg-primary text-white' : 'bg-zinc-100 text-zinc-600'}`}>{count}</span>
    </Link>
  );
}

function OzetKarti({ label, value, subtitle, tone, href }: { label: string; value: number; subtitle: string; tone: 'pink' | 'blue'; href: string }) {
  const TONE = { pink: 'border-rose-200 bg-rose-50', blue: 'border-blue-200 bg-blue-50' };
  return (
    <Link href={href} className={`block rounded-xl border p-3.5 transition-opacity hover:opacity-90 ${TONE[tone]}`}>
      <p className="text-xs font-bold text-textStrong">{label}</p>
      <p className="mt-1 text-2xl font-black text-textStrong">{value.toLocaleString('tr-TR')}</p>
      <p className="text-[11px] text-muted">{subtitle}</p>
    </Link>
  );
}

function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
