import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { KullanicilarTablosu } from './kullanicilar-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { DavetEtModal } from './davet-et-modal';
import { ROLE_MAP, yuzdeDegisim, type KullaniciSatiri } from './kullanicilar-yardimcilari';

export const metadata: Metadata = {
  title: 'Kullanıcılar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; role?: string; city?: string; page?: string }> };
const PAGE_SIZE = 10;

export default async function AdminUsersPage({ searchParams }: Props) {
  const { q = '', role = '', city = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);

  const supabase = await createSupabaseServerClient();
  const serviceClient = createSupabaseServiceClient();
  const sb = supabase as any;

  if (!serviceClient) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Kullanıcılar" description="Servis anahtarı yapılandırılmamış." />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState icon={<UsersIcon />} title="Kullanıcı listesi yüklenemedi" description="SUPABASE_SERVICE_ROLE_KEY eksik." />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const { data: authData } = await (serviceClient as any).auth.admin.listUsers({ page: 1, perPage: 1000 });
  const authUsers = (authData?.users ?? []) as any[];
  const userIds = authUsers.map((u) => u.id);

  const [{ data: profiles }, { data: approvedClaims }] = await Promise.all([
    userIds.length > 0 ? sb.from('user_profiles').select('user_id, display_name, phone, city, shadow_banned, created_at').in('user_id', userIds) : Promise.resolve({ data: [] }),
    userIds.length > 0 ? sb.from('owner_claims').select('user_id').eq('status', 'approved').in('user_id', userIds) : Promise.resolve({ data: [] }),
  ]);

  const profileByUser = new Map<string, any>((profiles ?? []).map((p: any) => [p.user_id as string, p]));
  const ownerUserIds = new Set<string>((approvedClaims ?? []).map((c: any) => c.user_id as string));

  function getRole(user: any): string {
    const r = String(user?.app_metadata?.role ?? user?.user_metadata?.role ?? 'user').toLocaleLowerCase('tr-TR');
    return ROLE_MAP[r] ? r : 'user';
  }

  const allRows: KullaniciSatiri[] = authUsers.map((u) => {
    const profile = profileByUser.get(u.id);
    return {
      id: u.id,
      displayName: profile?.display_name ?? null,
      email: u.email ?? null,
      phone: profile?.phone ?? u.phone ?? null,
      role: getRole(u),
      city: profile?.city ?? null,
      createdAt: u.created_at ?? profile?.created_at ?? new Date(0).toISOString(),
      lastSignInAt: u.last_sign_in_at ?? null,
      isOwner: ownerUserIds.has(u.id),
      shadowBanned: profile?.shadow_banned ?? false,
    };
  });

  const now = Date.now();
  const otuzGunOnce = new Date(now - 30 * 86400000).toISOString();
  const altmisGunOnce = new Date(now - 60 * 86400000).toISOString();

  const toplam = allRows.length;
  const aktif = allRows.filter((r) => r.lastSignInAt && r.lastSignInAt >= otuzGunOnce).length;
  const yeniBuAy = allRows.filter((r) => r.createdAt >= otuzGunOnce).length;
  const yeniOncekiAy = allRows.filter((r) => r.createdAt >= altmisGunOnce && r.createdAt < otuzGunOnce).length;
  const engellenen = allRows.filter((r) => r.shadowBanned).length;

  const cities = Array.from(new Set(allRows.map((r) => r.city).filter((c): c is string => Boolean(c)))).sort((a, b) => a.localeCompare(b, 'tr-TR'));

  const filtered = allRows.filter((r) => {
    if (role && r.role !== role) return false;
    if (city && r.city !== city) return false;
    if (q) {
      const needle = q.toLocaleLowerCase('tr-TR');
      const haystack = [r.displayName, r.email, r.phone, r.city, r.id].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR');
      if (!haystack.includes(needle)) return false;
    }
    return true;
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageRows = filtered.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const roleCounts = new Map<string, number>();
  for (const r of allRows) roleCounts.set(r.role, (roleCounts.get(r.role) ?? 0) + 1);
  const isletmeSahibiSayisi = ownerUserIds.size;

  const donutHam: Array<[string, number, string]> = [
    ['Kullanıcı', Math.max(0, (roleCounts.get('user') ?? 0) - isletmeSahibiSayisi), '#2563eb'],
    ['İşletme Sahibi', isletmeSahibiSayisi, '#059669'],
    ['Admin', (roleCounts.get('admin') ?? 0) + (roleCounts.get('super_admin') ?? 0), '#7c3aed'],
    ['Moderatör', roleCounts.get('community_mod') ?? 0, '#d97706'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const gunlukKayit: Record<string, number> = {};
  for (const r of allRows) {
    const d = new Date(r.createdAt);
    const gun = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    gunlukKayit[gun] = (gunlukKayit[gun] ?? 0) + 1;
  }
  const trendVerisi: { label: string; value: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(now - i * 86400000);
    const label = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    trendVerisi.push({ label, value: gunlukKayit[label] ?? 0 });
  }

  const queryBase = buildQueryString({ q, role, city });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Kullanıcılar"
        description="Platformdaki tüm kullanıcıları görüntüleyin, arayın ve yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MetricCard title="Toplam Kullanıcı" value={toplam.toLocaleString('tr-TR')} tone="blue" icon={<UsersIcon />}
              trend={{ value: yuzdeDegisim(yeniBuAy, yeniOncekiAy), label: 'önceki 30 güne göre' }} />
            <MetricCard title="Aktif Kullanıcı" value={aktif.toLocaleString('tr-TR')} subtitle="son 30 günde giriş yapan" tone="green" icon={<ActivityIcon />} />
            <MetricCard title="Yeni Kullanıcı" value={yeniBuAy.toLocaleString('tr-TR')} subtitle="son 30 gün" tone="orange" icon={<UserPlusIcon />} />
            <MetricCard title="Engellenen" value={engellenen.toLocaleString('tr-TR')} subtitle="toplam engellenen" tone="pink" icon={<ShieldIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Kullanıcı ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="role" defaultValue={role} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Rol: Tümü</option>
                  {Object.entries(ROLE_MAP).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
                </select>
                <select name="city" defaultValue={city} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Şehir: Tümü</option>
                  {cities.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
                <div className="flex gap-2 lg:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/kullanicilar" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<UsersIcon />} title="Kullanıcı bulunamadı" />
              ) : (
                <PanelBolumKarti noPadding>
                  <KullanicilarTablosu rows={pageRows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {filtered.length.toLocaleString('tr-TR')} kullanıcı</p>
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
              <PanelBolumKarti title="Kullanıcı Dağılımı">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <RolDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Kayıt İstatistikleri (Son 30 Gün)">
                <KayitTrendGrafik veriler={trendVerisi} />
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="grid grid-cols-1 gap-2">
                  <DavetEtModal />
                  <Link href="#toplu-islemler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    <span>Toplu İşlemler<span className="block text-[10px] font-bold text-muted">Toplu engelle/uyar/temizle</span></span>
                    <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/roller" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    <span>Roller<span className="block text-[10px] font-bold text-muted">Rol dağılımı ve ayrıcalıklı hesaplar</span></span>
                    <ArrowIcon />
                  </Link>
                  <DisaAktarButonu rows={filtered} />
                </div>
              </PanelBolumKarti>

              <div className="rounded-2xl border border-blue-200 bg-blue-50 p-4">
                <p className="mb-2 text-sm font-black text-blue-900">Notlar</p>
                <ul className="flex flex-col gap-1.5 text-xs text-blue-800">
                  <li>Engellenen kullanıcılar giriş yapamaz ve işletmelere erişemez.</li>
                  <li>Rol değişiklikleri anında etkin olur.</li>
                </ul>
              </div>
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

function KayitTrendGrafik({ veriler }: { veriler: { label: string; value: number }[] }) {
  const W = 260, H = 90;
  const pad = { l: 4, r: 4, t: 8, b: 16 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;
  const maxVal = Math.max(...veriler.map((v) => v.value), 1);
  const stepX = innerW / Math.max(veriler.length - 1, 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;
  const linePath = veriler.map((v, i) => `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(v.value)}`).join(' ');
  const toplam = veriler.reduce((s, v) => s + v.value, 0);

  return (
    <div>
      <p className="mb-2 text-xs font-bold text-muted">{toplam} yeni kayıt</p>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full">
        <path d={linePath} fill="none" stroke="#dc2626" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
      </svg>
    </div>
  );
}

function RolDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
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

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function ActivityIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>; }
function UserPlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="20" y1="8" x2="20" y2="14" /><line x1="17" y1="11" x2="23" y2="11" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><line x1="9" y1="9" x2="15" y2="15" /><line x1="15" y1="9" x2="9" y2="15" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
