import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { MenulerTablosu } from './menuler-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import type { SilinmisMenuSatiri } from './cop-kutusu-yardimcilari';

export const metadata: Metadata = {
  title: 'Silinmiş Menüler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; kategori?: string; date_from?: string; date_to?: string; page?: string }> };
const PAGE_SIZE = 20;

const AKSIYON_ETIKETLERI: Record<string, string> = { restore: 'Geri yüklendi', delete: 'Kalıcı silindi' };

export default async function AdminTrashPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:cop-kutusu');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Silinmiş Menüler" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Silinmiş Menüler" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', kategori = '', date_from = '', date_to = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const otuzGunOnce = new Date(Date.now() - 30 * 86400000).toISOString();
  const simdi = new Date().toISOString();

  const [{ data: allRaw }, toplamRes, sonOtuzGunRes, sonAktiviteRes] = await Promise.all([
    sb.from('menus')
      .select('id, title, business_id, active_to, updated_at, businesses(name, city, district, category)')
      .eq('status', 'archived')
      .order('updated_at', { ascending: false })
      .limit(1000),
    sb.from('menus').select('id', { count: 'exact', head: true }).eq('status', 'archived'),
    sb.from('menus').select('id', { count: 'exact', head: true }).eq('status', 'archived').gte('updated_at', otuzGunOnce),
    sb.from('admin_audit_log').select('id, action, target_id, created_at').eq('target_table', 'menus').order('created_at', { ascending: false }).limit(8)
      .then((r: any) => r).catch(() => ({ data: [] })),
  ]);

  const allRows = (allRaw ?? []) as Array<{
    id: string; title: string; business_id: string; active_to: string | null; updated_at: string;
    businesses: { name: string; city: string | null; district: string | null; category: string | null } | null;
  }>;

  // Menü sahibi — owner_claims (approved) + user_profiles birleştirme (isletmeler sayfasıyla aynı desen)
  const businessIds = Array.from(new Set(allRows.map((r) => r.business_id)));
  const ownerNameByBusiness = new Map<string, string>();
  if (businessIds.length > 0) {
    const { data: claims } = await sb.from('owner_claims').select('business_id, user_id').eq('status', 'approved').in('business_id', businessIds);
    const userIds = Array.from(new Set((claims ?? []).map((c: any) => c.user_id)));
    if (userIds.length > 0) {
      const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', userIds);
      const nameByUser = new Map<string, string>((profiles ?? []).map((p: any) => [p.user_id as string, (p.display_name as string) ?? '—']));
      for (const c of (claims ?? []) as Array<{ business_id: string; user_id: string }>) {
        if (!ownerNameByBusiness.has(c.business_id)) ownerNameByBusiness.set(c.business_id, nameByUser.get(c.user_id) ?? '—');
      }
    }
  }

  let mapped: SilinmisMenuSatiri[] = allRows.map((r) => ({
    id: r.id,
    title: r.title ?? '—',
    businessId: r.business_id,
    businessName: r.businesses?.name ?? null,
    businessCity: r.businesses?.city ?? null,
    businessDistrict: r.businesses?.district ?? null,
    businessCategory: r.businesses?.category ?? null,
    ownerName: ownerNameByBusiness.get(r.business_id) ?? null,
    updatedAt: r.updated_at,
    activeTo: r.active_to,
  }));

  if (kategori) mapped = mapped.filter((r) => r.businessCategory === kategori);
  if (date_from) mapped = mapped.filter((r) => r.updatedAt >= date_from);
  if (date_to) mapped = mapped.filter((r) => r.updatedAt <= `${date_to}T23:59:59`);
  if (q.trim()) {
    const needle = q.trim().toLocaleLowerCase('tr-TR');
    mapped = mapped.filter((r) => [r.title, r.businessName, r.ownerName].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR').includes(needle));
  }

  const totalPages = Math.max(1, Math.ceil(mapped.length / PAGE_SIZE));
  const pageRows = mapped.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const toplam = toplamRes.count ?? 0;
  const sonOtuzGun = sonOtuzGunRes.count ?? 0;
  const suresiGecmis = allRows.filter((r) => r.active_to && new Date(r.active_to).getTime() < Date.now()).length;
  const etkilenenIsletme = businessIds.length;

  const kategoriSayilari = new Map<string, number>();
  for (const r of allRows) {
    const k = r.businesses?.category ?? 'Diğer';
    kategoriSayilari.set(k, (kategoriSayilari.get(k) ?? 0) + 1);
  }
  const RENKLER = ['#dc2626', '#2563eb', '#059669', '#d97706', '#7c3aed', '#0891b2', '#db2777'];
  const donutHam: Array<[string, number, string]> = Array.from(kategoriSayilari.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([label, n], i) => [label, n, RENKLER[i % RENKLER.length]]);
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const kategoriler = Array.from(kategoriSayilari.keys()).sort((a, b) => a.localeCompare(b, 'tr-TR'));
  const sonAktiviteler = (sonAktiviteRes?.data ?? []) as Array<{ id: string; action: string; target_id: string; created_at: string }>;
  const menuBaslikById = new Map<string, string>(allRows.map((r) => [r.id, r.title]));

  const queryBase = buildQueryString({ q, kategori, date_from, date_to });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Silinmiş Menüler"
        description="Arşivlenmiş menüleri geri yükleyin veya kalıcı olarak silin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MetricCard title="Toplam Arşivlenmiş" value={toplam.toLocaleString('tr-TR')} subtitle="menü" tone="blue" icon={<ArchiveIcon />} />
            <MetricCard title="Son 30 Gün" value={sonOtuzGun.toLocaleString('tr-TR')} subtitle="arşivlenen" tone="purple" icon={<ClockIcon />} />
            <MetricCard title="Süresi Geçmiş" value={suresiGecmis.toLocaleString('tr-TR')} subtitle="active_to geçti" tone="orange" icon={<AlertIcon />} />
            <MetricCard title="Etkilenen İşletme" value={etkilenenIsletme.toLocaleString('tr-TR')} subtitle="benzersiz işletme" tone="green" icon={<StoreIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Menü, işletme veya sahip ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="kategori" defaultValue={kategori} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Kategori: Tümü</option>
                  {kategoriler.map((k) => <option key={k} value={k}>{k}</option>)}
                </select>
                <div className="grid grid-cols-2 gap-2">
                  <input type="date" name="date_from" defaultValue={date_from} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
                  <input type="date" name="date_to" defaultValue={date_to} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
                </div>
                <div className="flex gap-2 lg:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/cop-kutusu" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<ArchiveIcon />} title="Arşivlenmiş menü yok" description={q || kategori || date_from || date_to ? 'Bu filtrelerle eşleşen menü yok.' : 'Henüz arşivlenmiş menü bulunmuyor.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <MenulerTablosu rows={pageRows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {mapped.length.toLocaleString('tr-TR')} menü</p>
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

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="İşletme Kategorisine Göre">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <KategoriDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Son İşlemler">
                {sonAktiviteler.length === 0 ? (
                  <p className="text-xs text-muted">Henüz kayıtlı işlem yok.</p>
                ) : (
                  <div className="flex flex-col gap-2.5">
                    {sonAktiviteler.map((a) => (
                      <div key={a.id} className="flex flex-col gap-0.5 text-xs">
                        <span className="font-bold text-textStrong">
                          {AKSIYON_ETIKETLERI[a.action] ?? a.action} — {menuBaslikById.get(a.target_id) ?? `#${a.target_id.slice(0, 6)}`}
                        </span>
                        <span className="text-[11px] text-muted">{new Date(a.created_at).toLocaleString('tr-TR')}</span>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Bilgilendirme">
                <ul className="flex flex-col gap-2 text-xs text-muted">
                  <li>• Arşivlenen menüler otomatik silinmez — kalıcı olarak silinene kadar burada kalır.</li>
                  <li>• &quot;Süresi Geçmiş&quot; işaretli menülerin <code>active_to</code> tarihi geride kalmıştır, ayrıca arşivlenmeleri gerekmez.</li>
                  <li>• Kalıcı silme işlemi geri alınamaz.</li>
                </ul>
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <Link href="/yonetici/isletmeler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    İşletmeler <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/olaylar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Olaylar <ArrowIcon />
                  </Link>
                  <DisaAktarButonu rows={mapped} />
                </div>
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

function KategoriDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE}
              strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n, renk]) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: renk }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ArchiveIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="21 8 21 21 3 21 3 8" /><rect x="1" y="3" width="22" height="5" /><line x1="10" y1="12" x2="14" y2="12" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
function AlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>; }
function StoreIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l1-5h16l1 5" /><path d="M3 9a2 2 0 0 0 4 0 2 2 0 0 0 4 0 2 2 0 0 0 4 0 2 2 0 0 0 4 0" /><path d="M4 9v10h16V9" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
