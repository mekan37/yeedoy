import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import {
  flagDurum, DURUM_ETIKETLERI, PROJE_SECENEKLERI, TUR_SECENEKLERI, ORTAM_ETIKETLERI, trend,
  type FeatureFlag,
} from './flag-yardimcilari';
import { FlagTablosu } from './flag-tablosu';
import { YeniFlagButonu } from './yeni-flag-modal';
import { DisaAktarButonu } from './disa-aktar-butonu';

export const metadata: Metadata = {
  title: 'Feature Flags | Yönetici Paneli',
  robots: { index: false, follow: false },
};

const DAY = 86_400_000;

type Props = {
  searchParams: Promise<{ q?: string; proje?: string; ortam?: string; durum?: string; tur?: string }>;
};

export default async function FeatureFlagsPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:feature-flags');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Feature Flags" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Feature Flags" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', proje = '', ortam = '', durum = '', tur = '' } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const { data: rawFlags } = await sb
    .from('runtime_feature_flags')
    .select('key, enabled, rollout_percent, allowed_regions, metadata, updated_by, updated_at')
    .order('key', { ascending: true }) as { data: FeatureFlag[] | null };

  const flags = rawFlags ?? [];

  const updaterIds = Array.from(new Set(flags.map((f) => f.updated_by).filter((v): v is string => !!v)));
  const nameByUserId = new Map<string, string>();
  if (updaterIds.length > 0) {
    const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', updaterIds);
    for (const p of (profiles ?? []) as Array<{ user_id: string; display_name: string | null }>) {
      if (p.display_name) nameByUserId.set(p.user_id, p.display_name);
    }
  }
  const withNames: FeatureFlag[] = flags.map((f) => ({ ...f, updated_by_name: f.updated_by ? nameByUserId.get(f.updated_by) ?? null : null }));

  // ── Filtreleme ──
  const qNorm = q.trim().toLocaleLowerCase('tr-TR');
  const filtered = withNames.filter((f) => {
    if (proje && f.metadata?.project !== proje) return false;
    if (ortam && f.metadata?.environment !== ortam) return false;
    if (durum && flagDurum(f) !== durum) return false;
    if (tur && f.metadata?.type !== tur) return false;
    if (qNorm) {
      const hay = `${f.key} ${f.metadata?.description ?? ''}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });

  // ── Stat kartları (tüm flagler, filtresiz) ──
  const total = flags.length;
  const activeCount = flags.filter((f) => flagDurum(f) === 'active').length;
  const disabledCount = flags.filter((f) => flagDurum(f) === 'disabled').length;
  const draftCount = flags.filter((f) => flagDurum(f) === 'draft').length;
  const partialRollout = flags.filter((f) => flagDurum(f) === 'active' && f.rollout_percent > 0 && f.rollout_percent < 100).length;

  const now = Date.now();
  const thisWeek = flags.filter((f) => new Date(f.updated_at).getTime() >= now - 7 * DAY).length;
  const lastWeek = flags.filter((f) => {
    const ts = new Date(f.updated_at).getTime();
    return ts >= now - 14 * DAY && ts < now - 7 * DAY;
  }).length;

  // ── Dağılımlar ──
  const durumDagilimi: Array<[string, number, string]> = [
    ['Aktif', activeCount, '#059669'],
    ['Kapalı', disabledCount, '#94a3b8'],
    ['Taslak', draftCount, '#7c3aed'],
  ].filter(([, n]) => (n as number) > 0) as Array<[string, number, string]>;

  const ortamDagilimi = Object.entries(
    flags.reduce<Record<string, number>>((acc, f) => {
      const key = f.metadata?.environment ?? 'belirsiz';
      acc[key] = (acc[key] ?? 0) + 1;
      return acc;
    }, {}),
  ).sort((a, b) => b[1] - a[1]);

  const turDagilimi = Object.entries(
    flags.reduce<Record<string, number>>((acc, f) => {
      const key = f.metadata?.type ?? 'diger';
      acc[key] = (acc[key] ?? 0) + 1;
      return acc;
    }, {}),
  ).sort((a, b) => b[1] - a[1]);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Feature Flags"
        description="Özellik bayraklarınızı yönetin, rollout yapın ve etkilerini izleyin."
        actions={<YeniFlagButonu />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Flag" value={total.toLocaleString('tr-TR')} tone="blue" icon={<FlagIcon />} />
            <MetricCard title="Aktif" value={activeCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((activeCount / total) * 100)}` : undefined} tone="green" icon={<FlagIcon />} />
            <MetricCard title="Kapalı" value={disabledCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((disabledCount / total) * 100)}` : undefined} tone="orange" icon={<CircleIcon />} />
            <MetricCard title="Taslak" value={draftCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((draftCount / total) * 100)}` : undefined} tone="purple" icon={<EditIcon />} />
            <MetricCard title="Kısmi Yayılımda" value={partialRollout.toLocaleString('tr-TR')} subtitle="0-100 arası rollout" tone="pink" icon={<TrendIcon />} />
            <MetricCard title="Değişiklik (Son 7 Gün)" value={thisWeek.toLocaleString('tr-TR')} trend={trend(thisWeek, lastWeek)} tone="primary" icon={<PulseIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-5">
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Feature flag ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="proje" defaultValue={proje} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Projeler</option>
                  {PROJE_SECENEKLERI.map((p) => <option key={p} value={p}>{p}</option>)}
                </select>
                <select name="ortam" defaultValue={ortam} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Ortamlar</option>
                  {Object.entries(ORTAM_ETIKETLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
                <select name="durum" defaultValue={durum} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Durumlar</option>
                  {Object.entries(DURUM_ETIKETLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
                <select name="tur" defaultValue={tur} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Türler</option>
                  {Object.entries(TUR_SECENEKLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
                <div className="flex gap-2 md:col-span-5">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/feature-flags" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  <div className="ml-auto">
                    <DisaAktarButonu rows={filtered} />
                  </div>
                </div>
              </form>

              {filtered.length === 0 ? (
                <PanelEmptyState
                  icon={<FlagIcon />}
                  title={total === 0 ? 'Henüz flag yok' : 'Sonuç bulunamadı'}
                  description={total === 0 ? '"Yeni Feature Flag" ile ilk flag\'i oluşturun.' : 'Seçili filtrelere uygun flag yok.'}
                />
              ) : (
                <FlagTablosu flags={filtered} />
              )}
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Rollout Dağılımı">
                {durumDagilimi.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <Donut veriler={durumDagilimi} toplam={total} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Ortam Dağılımı">
                {ortamDagilimi.length === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-3">
                    {ortamDagilimi.map(([key, n]) => (
                      <div key={key} className="flex flex-col gap-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-textStrong">{ORTAM_ETIKETLERI[key] ?? key}</span>
                          <span className="font-extrabold text-muted">{n} (%{Math.round((n / total) * 100)})</span>
                        </div>
                        <div className="h-2 overflow-hidden rounded-full bg-black/8">
                          <div className="h-full rounded-full bg-primary" style={{ width: `${(n / total) * 100}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Tür Dağılımı">
                {turDagilimi.length === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-1.5">
                    {turDagilimi.map(([key, n]) => (
                      <div key={key} className="flex items-center justify-between text-[11px]">
                        <span className="font-bold text-textStrong">{TUR_SECENEKLERI[key] ?? 'Diğer'}</span>
                        <span className="font-extrabold text-muted">{n} (%{Math.round((n / total) * 100)})</span>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <YeniFlagButonu variant="list" />
                  <p className="rounded-xl border border-border px-3 py-2.5 text-[10px] text-muted">
                    Toplu rollout güncellemek için tablodan flag seçin — seçim çubuğu orada belirir.
                  </p>
                  <HizliIslemButonu label="Flag Şablonları" description="Hazır şablonlardan oluşturun" icon={<TemplateIcon />} disabled title="Henüz uygulanmadı" />
                  <HizliIslemButonu label="Flag Etkisi Raporu" description="Flag''lerin performans etkisini inceleyin" icon={<ChartIcon />} disabled title="KPI/analitik bağlantısı yok — ayrı bir iş olarak planlanabilir" />
                </div>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function HizliIslemButonu({ label, description, icon, disabled, title }: { label: string; description: string; icon: React.ReactNode; disabled?: boolean; title?: string }) {
  return (
    <button
      type="button"
      disabled={disabled}
      title={title}
      className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors enabled:hover:border-primary/30 enabled:hover:bg-black/2 disabled:cursor-not-allowed disabled:opacity-50"
    >
      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)">{icon}</div>
      <div className="min-w-0">
        <p className="text-xs font-extrabold text-textStrong">{label}</p>
        <p className="truncate text-[10px] text-muted">{description}</p>
      </div>
    </button>
  );
}

function Donut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE} strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
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

function FlagIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>; }
function CircleIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="8" width="18" height="8" rx="4" /></svg>; }
function EditIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1 1-4z" /></svg>; }
function TrendIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" /></svg>; }
function PulseIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>; }
function TemplateIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /></svg>; }
function ChartIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>; }
