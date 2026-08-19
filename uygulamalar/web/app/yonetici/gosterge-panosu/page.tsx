import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Genel Bakış | Yonetici Paneli',
  robots: { index: false, follow: false },
};

const GUN_SECENEKLERI = [7, 30, 90] as const;

type Props = { searchParams: Promise<{ gun?: string }> };

function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}

export default async function AdminDashboardPage({ searchParams }: Props) {
  const { gun } = await searchParams;
  const gunSayisi = GUN_SECENEKLERI.includes(Number(gun) as (typeof GUN_SECENEKLERI)[number])
    ? Number(gun)
    : 30;

  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const now = Date.now();
  const buHaftaBasi = new Date(now - 7 * 86400000).toISOString();
  const oncekiHaftaBasi = new Date(now - 14 * 86400000).toISOString();
  const trendBasi = new Date(now - gunSayisi * 86400000).toISOString();

  const [
    businessesRes,
    usersRes,
    yeniIsletmeBuHafta,
    yeniIsletmeOncekiHafta,
    yeniKullaniciBuHafta,
    yeniKullaniciOncekiHafta,
    aktiviteBuHafta,
    aktiviteOncekiHafta,
    premiumRes,
    itirazRes,
    trendIsletmeler,
    trendKullanicilar,
    trendAktivite,
    kategoriOrneklem,
    bekleyenBasvurular,
    bekleyenTalepler,
    events1h,
    events24h,
    rateLimit24h,
  ] = await Promise.all([
    supabase.from('businesses').select('id', { count: 'exact', head: true }),
    supabase.from('user_profiles').select('user_id', { count: 'exact', head: true }),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', buHaftaBasi),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', oncekiHaftaBasi).lt('created_at', buHaftaBasi),
    supabase.from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', buHaftaBasi),
    supabase.from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', oncekiHaftaBasi).lt('created_at', buHaftaBasi),
    sb.from('analytics_events').select('id', { count: 'exact', head: true }).in('event_name', ['qr_scanned', 'menu_view']).gte('created_at', buHaftaBasi),
    sb.from('analytics_events').select('id', { count: 'exact', head: true }).in('event_name', ['qr_scanned', 'menu_view']).gte('created_at', oncekiHaftaBasi).lt('created_at', buHaftaBasi),
    sb.from('business_premium').select('id', { count: 'exact', head: true }).eq('status', 'active').in('tier', ['starter', 'standard', 'pro']),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    sb.from('businesses').select('created_at').gte('created_at', trendBasi).limit(3000),
    sb.from('user_profiles').select('created_at').gte('created_at', trendBasi).limit(3000),
    sb.from('analytics_events').select('created_at').in('event_name', ['qr_scanned', 'menu_view']).gte('created_at', trendBasi).limit(3000),
    sb.from('businesses').select('category').not('category', 'is', null).limit(5000),
    sb.from('business_submissions').select('id, name, category, city, district, created_at').eq('status', 'new').order('created_at', { ascending: false }).limit(5),
    sb.from('owner_claims').select('id, business_id, created_at, businesses(name, city, district)').eq('status', 'pending').order('created_at', { ascending: false }).limit(5),
    sb.from('analytics_events').select('id', { count: 'exact', head: true }).gte('created_at', new Date(now - 3600000).toISOString()),
    sb.from('analytics_events').select('id', { count: 'exact', head: true }).gte('created_at', new Date(now - 86400000).toISOString()),
    sb.from('edge_rate_limit_events').select('id', { count: 'exact', head: true }).gte('created_at', new Date(now - 86400000).toISOString()),
  ]);

  let sonAktiviteler: Array<{ id: string; action: string; target_table: string; created_at: string }> = [];
  try {
    const { data, error } = await sb
      .from('admin_audit_log')
      .select('id, action, target_table, target_id, created_at')
      .order('created_at', { ascending: false })
      .limit(5);
    if (!error) sonAktiviteler = data ?? [];
  } catch {
    // admin_audit_log henüz mevcut değilse sessizce boş bırak
  }

  // ── Günlük trend (3 seri) ────────────────────────────────────────────
  function gunlukSayimYap(rows: Array<{ created_at: string }>): Record<string, number> {
    const acc: Record<string, number> = {};
    for (const r of rows ?? []) {
      const d = new Date(r.created_at);
      const gun = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
      acc[gun] = (acc[gun] ?? 0) + 1;
    }
    return acc;
  }
  const isletmeGunluk = gunlukSayimYap(trendIsletmeler.data ?? []);
  const kullaniciGunluk = gunlukSayimYap(trendKullanicilar.data ?? []);
  const aktiviteGunluk = gunlukSayimYap(trendAktivite.data ?? []);

  const trendVerisi: { label: string; kullanici: number; isletme: number; aktivite: number }[] = [];
  for (let i = gunSayisi - 1; i >= 0; i--) {
    const d = new Date(now - i * 86400000);
    const label = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    trendVerisi.push({
      label,
      kullanici: kullaniciGunluk[label] ?? 0,
      isletme: isletmeGunluk[label] ?? 0,
      aktivite: aktiviteGunluk[label] ?? 0,
    });
  }

  // ── Kategori dağılımı (örneklem) ─────────────────────────────────────
  const kategoriSayaci = new Map<string, number>();
  for (const row of (kategoriOrneklem.data ?? []) as Array<{ category: string }>) {
    kategoriSayaci.set(row.category, (kategoriSayaci.get(row.category) ?? 0) + 1);
  }
  const kategoriSirali = Array.from(kategoriSayaci.entries()).sort((a, b) => b[1] - a[1]);
  const ilkBes = kategoriSirali.slice(0, 5);
  const digerToplam = kategoriSirali.slice(5).reduce((s, [, c]) => s + c, 0);
  const donutVerisi = digerToplam > 0 ? [...ilkBes, ['Diğer', digerToplam] as [string, number]] : ilkBes;
  const donutToplam = donutVerisi.reduce((s, [, c]) => s + c, 0);

  // ── Bekleyen onaylar (birleşik) ──────────────────────────────────────
  type OnayItem = { id: string; baslik: string; konum: string; tur: 'Yeni İşletme' | 'Sahiplenme Talebi'; href: string; createdAt: string };
  const onaylar: OnayItem[] = [
    ...((bekleyenBasvurular.data ?? []) as Array<{ id: string; name: string; category: string; city: string | null; district: string | null; created_at: string }>).map((b) => ({
      id: b.id,
      baslik: b.name,
      konum: [b.district, b.city].filter(Boolean).join(', ') || '—',
      tur: 'Yeni İşletme' as const,
      href: '/yonetici/kuyruklar?tab=inceleme',
      createdAt: b.created_at,
    })),
    ...((bekleyenTalepler.data ?? []) as Array<{ id: string; created_at: string; businesses: { name: string; city: string | null; district: string | null } | null }>).map((c) => ({
      id: c.id,
      baslik: c.businesses?.name ?? 'İşletme',
      konum: [c.businesses?.district, c.businesses?.city].filter(Boolean).join(', ') || '—',
      tur: 'Sahiplenme Talebi' as const,
      href: '/yonetici/kuyruklar?tab=sahiplenme',
      createdAt: c.created_at,
    })),
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 6);

  // ── Sistem durumu (yalnızca gerçekten ölçülen sinyaller) ─────────────
  const olayHizi = events1h.count ?? 0;
  const ortalamaSaatlikOlay = (events24h.count ?? 0) / 24;
  const olaySicramasi = ortalamaSaatlikOlay > 0 && olayHizi > ortalamaSaatlikOlay * 3;
  const rateLimitSayisi = rateLimit24h.count ?? 0;
  const sistemSinyalleri = [
    { label: 'Olay Hızı', durum: olaySicramasi ? 'warning' : 'ok', detay: `${olayHizi} olay/saat (ort: ${Math.round(ortalamaSaatlikOlay)})` },
    { label: 'Rate Limiting', durum: rateLimitSayisi > 100 ? 'critical' : rateLimitSayisi > 20 ? 'warning' : 'ok', detay: `${rateLimitSayisi} vaka (24s)` },
  ];

  const ACTION_LABELS: Record<string, string> = {
    create: 'oluşturuldu', update: 'güncellendi', delete: 'silindi',
    approve: 'onaylandı', reject: 'reddedildi', suspend: 'askıya alındı',
    restore: 'geri yüklendi', ban: 'yasaklandı',
  };
  const TABLE_LABELS: Record<string, string> = {
    businesses: 'İşletme', user_profiles: 'Kullanıcı', reviews: 'Yorum',
    owner_claims: 'Sahiplenme talebi', business_suggestions: 'İşletme başvurusu',
    moderation_appeals: 'İtiraz', menu_items: 'Menü öğesi',
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Genel Bakış"
        description="Platform geneli özet istatistikler"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Ana metrikler */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <MetricCard
              title="Toplam İşletme"
              value={(businessesRes.count ?? 0).toLocaleString('tr-TR')}
              tone="pink"
              icon={<BuildingIcon />}
              trend={{ value: yuzdeDegisim(yeniIsletmeBuHafta.count ?? 0, yeniIsletmeOncekiHafta.count ?? 0), label: 'yeni kayıt, önceki haftaya göre' }}
            />
            <MetricCard
              title="Toplam Kullanıcı"
              value={(usersRes.count ?? 0).toLocaleString('tr-TR')}
              tone="blue"
              icon={<UsersIcon />}
              trend={{ value: yuzdeDegisim(yeniKullaniciBuHafta.count ?? 0, yeniKullaniciOncekiHafta.count ?? 0), label: 'yeni kayıt, önceki haftaya göre' }}
            />
            <MetricCard
              title="Platform Aktivitesi (7g)"
              value={(aktiviteBuHafta.count ?? 0).toLocaleString('tr-TR')}
              subtitle="QR tarama + menü görüntülenme"
              tone="green"
              icon={<ActivityIcon />}
              trend={{ value: yuzdeDegisim(aktiviteBuHafta.count ?? 0, aktiviteOncekiHafta.count ?? 0), label: 'önceki haftaya göre' }}
            />
            <MetricCard
              title="Ücretli Abonelik"
              value={(premiumRes.count ?? 0).toLocaleString('tr-TR')}
              subtitle="aktif Premium işletme"
              tone="orange"
              icon={<CrownIcon />}
            />
            <MetricCard
              title="Bekleyen İtiraz"
              value={(itirazRes.count ?? 0).toLocaleString('tr-TR')}
              subtitle="inceleme bekliyor"
              tone="purple"
              icon={<ScaleIcon />}
            />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_320px_260px]">
            {/* Trend grafiği */}
            <PanelBolumKarti
              title="Genel Bakış"
              actions={
                <div className="flex items-center gap-1 rounded-lg border border-border p-0.5">
                  {GUN_SECENEKLERI.map((g) => (
                    <Link
                      key={g}
                      href={`/yonetici/gosterge-panosu?gun=${g}`}
                      className={`rounded-md px-2.5 py-1 text-[11px] font-extrabold transition-colors ${g === gunSayisi ? 'bg-primary text-white' : 'text-muted hover:text-textStrong'}`}
                    >
                      {g} gün
                    </Link>
                  ))}
                </div>
              }
            >
              <div className="mb-3 flex items-center gap-4 text-[11px] font-bold">
                <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-blue-500" />Kullanıcı</span>
                <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-emerald-500" />İşletme</span>
                <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-orange-500" />Aktivite</span>
              </div>
              <PlatformTrendGrafik veriler={trendVerisi} />
            </PanelBolumKarti>

            {/* Kategori dağılımı */}
            <PanelBolumKarti title="İşletme Dağılımı" description="Örneklem bazlı kategori kırılımı">
              {donutToplam === 0 ? (
                <p className="text-xs text-muted">Veri yok.</p>
              ) : (
                <KategoriDonut veriler={donutVerisi} toplam={donutToplam} />
              )}
            </PanelBolumKarti>

            {/* Sistem durumu */}
            <PanelBolumKarti title="Sistem Sinyalleri">
              <div className="flex flex-col gap-2">
                {sistemSinyalleri.map((s) => (
                  <div key={s.label} className="flex items-start gap-2 rounded-xl border border-border p-2.5">
                    <span className="mt-0.5 text-sm">{s.durum === 'ok' ? '✅' : s.durum === 'warning' ? '⚠️' : '🔴'}</span>
                    <div className="min-w-0">
                      <p className="text-xs font-extrabold text-textStrong">{s.label}</p>
                      <p className="truncate text-[11px] text-muted">{s.detay}</p>
                    </div>
                  </div>
                ))}
              </div>
              <Link href="/yonetici/gozlemlenebilirlik" className="mt-3 block text-center text-xs font-extrabold text-primary hover:underline">
                Tüm sistem durumu →
              </Link>
            </PanelBolumKarti>
          </div>

          <div className="grid gap-6 lg:grid-cols-3">
            {/* Son aktiviteler */}
            <PanelBolumKarti title="Son Aktiviteler" actions={<Link href="/yonetici/olaylar" className="text-xs font-extrabold text-primary hover:underline">Tümünü Gör</Link>}>
              {sonAktiviteler.length === 0 ? (
                <PanelEmptyState icon={<ClipboardIcon />} title="Henüz aktivite yok" description="Yönetici işlemleri burada listelenir." />
              ) : (
                <div className="flex flex-col gap-3">
                  {sonAktiviteler.map((a) => (
                    <div key={a.id} className="flex items-start justify-between gap-3">
                      <p className="text-xs font-bold text-textStrong">
                        {TABLE_LABELS[a.target_table] ?? a.target_table} {ACTION_LABELS[a.action] ?? a.action}
                      </p>
                      <span className="shrink-0 text-[11px] text-muted">{zamanFarki(a.created_at)}</span>
                    </div>
                  ))}
                </div>
              )}
            </PanelBolumKarti>

            {/* Bekleyen onaylar */}
            <PanelBolumKarti title="Bekleyen Onaylar" actions={<Link href="/yonetici/kuyruklar" className="text-xs font-extrabold text-primary hover:underline">Tümünü Gör</Link>}>
              {onaylar.length === 0 ? (
                <PanelEmptyState icon={<InboxIcon />} title="Bekleyen onay yok" description="Yeni başvuru ve talep geldiğinde burada görünür." />
              ) : (
                <div className="flex flex-col gap-3">
                  {onaylar.map((o) => (
                    <div key={`${o.tur}-${o.id}`} className="flex items-center justify-between gap-3">
                      <div className="flex min-w-0 items-center gap-2.5">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-xs font-black text-primary">
                          {o.baslik.charAt(0).toUpperCase()}
                        </span>
                        <div className="min-w-0">
                          <p className="truncate text-xs font-extrabold text-textStrong">{o.baslik}</p>
                          <p className="truncate text-[11px] text-muted">{o.tur} · {o.konum}</p>
                        </div>
                      </div>
                      <Link href={o.href} className="shrink-0 rounded-lg border border-border px-2.5 py-1 text-[11px] font-extrabold text-primary hover:border-primary/30">
                        İncele
                      </Link>
                    </div>
                  ))}
                </div>
              )}
            </PanelBolumKarti>

            {/* Hızlı işlemler */}
            <PanelBolumKarti title="Hızlı İşlemler">
              <div className="grid grid-cols-2 gap-2">
                <HizliIslemButonu href="/yonetici/isletmeler/yeni" label="Yeni İşletme Ekle" icon={<BuildingIcon />} tone="pink" />
                <HizliIslemButonu href="/yonetici/kullanicilar" label="Kullanıcı Yönetimi" icon={<UsersIcon />} tone="blue" />
                <HizliIslemButonu href="/yonetici/isletmeler#toplu-islemler" label="Toplu İşlemler" icon={<ListChecksIcon />} tone="green" />
                <HizliIslemButonu href="/yonetici/raporlar" label="Rapor Oluştur" icon={<FileTextIcon />} tone="purple" />
                <HizliIslemButonu href="/yonetici/kuyruklar" label="Kuyruklar" icon={<FlagIcon />} tone="orange" />
                <HizliIslemButonu href="/yonetici/feature-flags" label="Feature Flags" icon={<FlagFeatureIcon />} tone="primary" />
              </div>
            </PanelBolumKarti>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function zamanFarki(iso: string): string {
  const dakika = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  if (dakika < 1) return 'az önce';
  if (dakika < 60) return `${dakika} dk önce`;
  const saat = Math.floor(dakika / 60);
  if (saat < 24) return `${saat} sa önce`;
  return `${Math.floor(saat / 24)} gün önce`;
}

// ─── Hızlı işlem butonu ────────────────────────────────────────────────────

const TONE_CLASSES: Record<string, string> = {
  primary: 'bg-primary/10 text-(--yd-color-primary)',
  blue: 'bg-blue-50 text-blue-600',
  pink: 'bg-rose-50 text-rose-600',
  purple: 'bg-violet-50 text-violet-600',
  green: 'bg-emerald-50 text-emerald-600',
  orange: 'bg-amber-50 text-amber-600',
};

function HizliIslemButonu({ href, label, icon, tone }: { href: string; label: string; icon: React.ReactNode; tone: string }) {
  return (
    <Link
      href={href}
      className="flex flex-col items-start gap-2 rounded-xl border border-border p-3 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-sm"
    >
      <span className={`flex h-8 w-8 items-center justify-center rounded-lg ${TONE_CLASSES[tone]}`}>{icon}</span>
      <span className="text-xs font-extrabold text-textStrong">{label}</span>
    </Link>
  );
}

// ─── Kategori Donut (SVG) ───────────────────────────────────────────────────

const DONUT_RENKLERI = ['#dc2626', '#2563eb', '#059669', '#d97706', '#7c3aed', '#64748b'];

function KategoriDonut({ veriler, toplam }: { veriler: Array<[string, number]>; toplam: number }) {
  const R = 60;
  const CX = 70;
  const CY = 70;
  const STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, count]) => (count / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, uzunluk, i) => {
    acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]);
    return acc;
  }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label], i) => {
            const uzunluk = uzunluklar[i];
            const dash = `${uzunluk} ${CIRCUM - uzunluk}`;
            const dashoffset = -offsetler[i];
            return (
              <circle
                key={label}
                cx={CX}
                cy={CY}
                r={R}
                fill="none"
                stroke={DONUT_RENKLERI[i % DONUT_RENKLERI.length]}
                strokeWidth={STROKE}
                strokeDasharray={dash}
                strokeDashoffset={dashoffset}
              />
            );
          })}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">
          {toplam.toLocaleString('tr-TR')}
        </text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">
          Örneklem
        </text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, count], i) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: DONUT_RENKLERI[i % DONUT_RENKLERI.length] }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{Math.round((count / toplam) * 100)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Platform Trend Grafik (SVG, 3 seri) ───────────────────────────────────

function PlatformTrendGrafik({ veriler }: { veriler: { label: string; kullanici: number; isletme: number; aktivite: number }[] }) {
  const W = 560;
  const H = 160;
  const pad = { l: 36, r: 12, t: 12, b: 28 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;
  const maxVal = Math.max(...veriler.map((v) => Math.max(v.kullanici, v.isletme, v.aktivite)), 1);
  const stepX = innerW / Math.max(veriler.length - 1, 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;

  function pathIcin(key: 'kullanici' | 'isletme' | 'aktivite') {
    return veriler.map((v, i) => `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(v[key])}`).join(' ');
  }

  const labelStep = Math.max(1, Math.floor(veriler.length / 6));

  return (
    <div className="overflow-x-auto">
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full" style={{ minWidth: 300 }}>
        {[0, 0.5, 1].map((t) => (
          <line key={t} x1={pad.l} y1={pad.t + scaleY(maxVal * t)} x2={pad.l + innerW} y2={pad.t + scaleY(maxVal * t)} stroke="var(--yd-color-border)" strokeWidth="1" strokeDasharray="4 4" />
        ))}
        <path d={pathIcin('kullanici')} fill="none" stroke="#3b82f6" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        <path d={pathIcin('isletme')} fill="none" stroke="#10b981" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        <path d={pathIcin('aktivite')} fill="none" stroke="#f97316" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        {veriler.filter((_, i) => i % labelStep === 0 || i === veriler.length - 1).map((v, fi) => {
          const i = veriler.indexOf(v);
          return (
            <text key={fi} x={pad.l + i * stepX} y={H - 6} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">
              {v.label}
            </text>
          );
        })}
        <text x={pad.l - 4} y={pad.t + scaleY(0) + 4} textAnchor="end" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">0</text>
        <text x={pad.l - 4} y={pad.t + scaleY(maxVal) + 4} textAnchor="end" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">{maxVal}</text>
      </svg>
    </div>
  );
}

// ─── İkonlar ─────────────────────────────────────────────────────────────────

function BuildingIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>;
}
function UsersIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function ActivityIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>;
}
function CrownIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m2 20 2-11 5 5 3-8 3 8 5-5 2 11Z" /></svg>;
}
function ScaleIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="3" x2="12" y2="21" /><path d="M3 6l9 6 9-6" /><path d="M6 18H3l3-9 3 9z" /><path d="M18 18h3l-3-9-3 9z" /></svg>;
}
function InboxIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12" /><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></svg>;
}
function ClipboardIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" /><rect x="8" y="2" width="8" height="4" rx="1" ry="1" /></svg>;
}
function FileTextIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /><line x1="16" y1="13" x2="8" y2="13" /><line x1="16" y1="17" x2="8" y2="17" /></svg>;
}
function ListChecksIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 6h11" /><path d="M9 12h11" /><path d="M9 18h11" /><path d="m3 6 1 1 2-2" /><path d="m3 12 1 1 2-2" /><path d="m3 18 1 1 2-2" /></svg>;
}
function FlagIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>;
}
function FlagFeatureIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /><circle cx="19" cy="19" r="3" fill="var(--yd-color-primary)" stroke="none" /></svg>;
}
