import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { OlaylarTablosu } from './olaylar-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import {
  yuzdeDegisim, olayTuruEtiketi, insanilesir, SONUC_ETIKETLERI, ACTOR_ROLE_ETIKETLERI,
  AUDIT_EYLEM_ETIKETLERI, ANALYTICS_OLAY_ETIKETLERI, RAPOR_HEDEF_ETIKETLERI,
  type OlaySatiri, type SonucTuru, type OlayKaynagi,
} from './olaylar-yardimcilari';

export const metadata: Metadata = {
  title: 'Olaylar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; tarih?: string; tur?: string; sonuc?: string; page?: string }> };
const PAGE_SIZE = 20;

const TARIH_SECENEKLERI = [
  { value: 'all', label: 'Tümü' },
  { value: '24h', label: 'Son 24 Saat' },
  { value: '7d', label: 'Son 7 Gün' },
  { value: '30d', label: 'Son 30 Gün' },
];

type SbRpc = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };

export default async function AdminEventsPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:olaylar');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Olaylar" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Olaylar" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', tarih = 'all', tur = '', sonuc = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  // Filtreleme, sayfalama ve metrik hesaplaması artık DB'de (admin_list_events_v1
  // / admin_events_summary_v1) — önceden her kaynaktan en yeni 1000-5000 satır
  // bellek içine çekilip TÜM bu işlemler JS'te yapılıyordu; eski/az sık
  // kaynaklardaki kayıtlar sessizce kayboluyordu (bkz. denetim raporu).
  const tarihSinirIso = tarih !== 'all'
    ? new Date(Date.now() - (tarih === '24h' ? 1 : tarih === '7d' ? 7 : 30) * 86400000).toISOString()
    : null;

  const [listRes, summaryRes] = await Promise.all([
    sb.rpc('admin_list_events_v1', {
      p_since: tarihSinirIso,
      p_tur: tur || null,
      p_sonuc: sonuc || null,
      p_q: q.trim() || null,
      p_limit: PAGE_SIZE,
      p_offset: (pageNum - 1) * PAGE_SIZE,
    }),
    sb.rpc('admin_events_summary_v1'),
  ]);

  if (listRes.error || summaryRes.error) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetim" title="Olaylar" description="Sistemde gerçekleşen olayları ve aktiviteleri görüntüleyin." />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState icon={<CalendarIcon />} title="Olaylar yüklenemedi" description="Lütfen sayfayı yenileyin." />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const listData = listRes.data as { rows: RawEventRow[]; total: number };
  const summary = summaryRes.data as EventsSummary;
  const rawRows = listData.rows ?? [];
  const total = listData.total ?? 0;

  const serviceClient = createSupabaseServiceClient();
  const sbData = (serviceClient ?? supabase) as any;

  // ── Hedef adlarını topluca çözümle — yalnızca GÜNCEL SAYFANIN (≤20 satır)
  // target id'leri için. Önceden bu çözümleme binlerce satır için yapılıyordu. ──
  const auditRows = rawRows.filter((r) => r.source === 'admin_audit_log');
  const claimTargetIds = Array.from(new Set(auditRows.filter((a) => a.raw.target_table === 'owner_claims').map((a) => a.raw.target_id)));
  const menuTargetIds = Array.from(new Set(auditRows.filter((a) => a.raw.target_table === 'menus').map((a) => a.raw.target_id)));
  const submissionTargetIds = Array.from(new Set(auditRows.filter((a) => a.raw.target_table === 'business_submissions').map((a) => a.raw.target_id)));
  const suggestionTargetIds = Array.from(new Set(auditRows.filter((a) => a.raw.target_table === 'business_suggestions').map((a) => a.raw.target_id)));
  const directBusinessTargetIds = auditRows.filter((a) => a.raw.target_table === 'businesses').map((a) => a.raw.target_id);

  const [claimsRes, menusRes, submissionsRes, suggestionsRes] = await Promise.all([
    claimTargetIds.length > 0 ? sbData.from('owner_claims').select('id, business_id, full_name').in('id', claimTargetIds) : Promise.resolve({ data: [] }),
    menuTargetIds.length > 0 ? sbData.from('menus').select('id, title').in('id', menuTargetIds) : Promise.resolve({ data: [] }),
    submissionTargetIds.length > 0 ? sbData.from('business_submissions').select('id, name').in('id', submissionTargetIds) : Promise.resolve({ data: [] }),
    suggestionTargetIds.length > 0 ? sbData.from('business_suggestions').select('id, name').in('id', suggestionTargetIds) : Promise.resolve({ data: [] }),
  ]);

  const claimRows = (claimsRes.data ?? []) as Array<{ id: string; business_id: string | null; full_name: string | null }>;
  const claimById = new Map(claimRows.map((c) => [c.id, c]));
  const menuNameById = new Map<string, string>((menusRes.data ?? []).map((m: any) => [m.id, m.title]));
  const submissionNameById = new Map<string, string>((submissionsRes.data ?? []).map((s: any) => [s.id, s.name]));
  const suggestionNameById = new Map<string, string>((suggestionsRes.data ?? []).map((s: any) => [s.id, s.name]));

  const allBusinessIds = Array.from(new Set([
    ...directBusinessTargetIds,
    ...claimRows.map((c) => c.business_id).filter(Boolean),
    ...rawRows.filter((r) => r.source === 'analytics_events').map((r) => r.raw.business_id).filter(Boolean),
    ...rawRows.filter((r) => r.source === 'reports').map((r) => r.raw.business_id).filter(Boolean),
  ])) as string[];
  const { data: businessRows } = allBusinessIds.length > 0
    ? await sbData.from('businesses').select('id, name').in('id', allBusinessIds)
    : { data: [] };
  const businessNameById = new Map<string, string>((businessRows ?? []).map((b: any) => [b.id, b.name]));

  const adCtx: AdCozumlemeBaglami = { businessNameById, menuNameById, submissionNameById, suggestionNameById, claimById };

  let pageRows: OlaySatiri[] = rawRows.map((row) => {
    if (row.source === 'analytics_events') return mapAnalyticsEvent(row.raw, adCtx);
    if (row.source === 'edge_rate_limit_events') return mapRateLimitEvent(row.raw);
    if (row.source === 'admin_audit_log') return mapAuditLog(row.raw, adCtx);
    return mapReport(row.raw, adCtx);
  });

  // Kullanıcı adlarını topluca çözümle (user_profiles) — yalnızca güncel sayfa için.
  const userIds = Array.from(new Set(pageRows.map((r) => r.userId).filter(Boolean))) as string[];
  if (userIds.length > 0) {
    const { data: profiles } = await sbData.from('user_profiles').select('user_id, display_name').in('user_id', userIds);
    const nameByUser = new Map<string, string>((profiles ?? []).map((p: any) => [p.user_id as string, (p.display_name as string) ?? '—']));
    pageRows = pageRows.map((r) => (r.userId ? { ...r, userName: r.userName ?? nameByUser.get(r.userId) ?? null } : r));
  }

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const turSecenekleri = (summary.tur_secenekleri ?? [])
    .map((t) => [t.deger, olayTuruEtiketi(t.kaynak as OlayKaynagi, t.deger)] as [string, string])
    .sort((a, b) => a[1].localeCompare(b[1], 'tr-TR'));

  // ── Olay Dağılımı donut ──
  const donutHam: Array<[string, number, string]> = [
    ['Başarılı', summary.basarili, '#059669'],
    ['Uyarı', summary.uyari, '#d97706'],
    ['Hata', summary.hata, '#dc2626'],
    ['Bilgi', summary.bilgi, '#2563eb'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const trendVerisi: { label: string; value: number }[] = (summary.gunluk_trend ?? []).map((t) => ({ label: t.gun, value: t.deger }));

  const queryBase = buildQueryString({ q, tarih, tur, sonuc });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Olaylar"
        description="Sistemde gerçekleşen olayları ve aktiviteleri görüntüleyin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <MetricCard title="Toplam Olay" value={summary.toplam.toLocaleString('tr-TR')} tone="blue" icon={<CalendarIcon />} trend={{ value: yuzdeDegisim(summary.bugun, summary.dun), label: `Dün: ${summary.dun.toLocaleString('tr-TR')}` }} />
            <MetricCard title="Başarılı İşlem" value={summary.basarili.toLocaleString('tr-TR')} tone="green" icon={<ShieldIcon />} trend={{ value: yuzdeDegisim(summary.bugun_basarili, summary.dun_basarili), label: summary.toplam > 0 ? `Başarı Oranı: %${Math.round((summary.basarili / summary.toplam) * 100)}` : undefined }} />
            <MetricCard title="Uyarı" value={summary.uyari.toLocaleString('tr-TR')} tone="orange" icon={<AlertIcon />} trend={{ value: yuzdeDegisim(summary.bugun_uyari, summary.dun_uyari) }} />
            <MetricCard title="Hata" value={summary.hata.toLocaleString('tr-TR')} tone="pink" icon={<XCircleIcon />} trend={{ value: yuzdeDegisim(summary.bugun_hata, summary.dun_hata) }} />
            <MetricCard title="Aktif Kullanıcı" value={summary.aktif_kullanici_son_24s.toLocaleString('tr-TR')} subtitle="Son 24 saat" tone="purple" icon={<UsersIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Olaylarda ara (kullanıcı, işlem, açıklama...)"
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="tarih" defaultValue={tarih} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {TARIH_SECENEKLERI.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <select name="sonuc" defaultValue={sonuc} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Sonuç: Tümü</option>
                  {(Object.keys(SONUC_ETIKETLERI) as SonucTuru[]).map((s) => <option key={s} value={s}>{SONUC_ETIKETLERI[s]}</option>)}
                </select>
                <select name="tur" defaultValue={tur} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2">
                  <option value="">Olay Türü: Tümü</option>
                  {turSecenekleri.map(([deger, etiket]) => <option key={deger} value={deger}>{etiket}</option>)}
                </select>
                <div className="flex gap-2 lg:col-span-2">
                  <button type="submit" className="min-h-11 flex-1 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/olaylar" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<CalendarIcon />} title="Olay bulunamadı" description={q || tur || sonuc || tarih !== 'all' ? 'Bu filtrelerle eşleşen olay yok.' : 'Henüz kaydedilmiş olay yok.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <OlaylarTablosu rows={pageRows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {total.toLocaleString('tr-TR')} olay</p>
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
              <PanelBolumKarti title="Olay Dağılımı">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <SonucDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Son 30 Gün Olay Trendi">
                <TrendGrafik veriler={trendVerisi} />
                <p className="mt-2 text-xs font-bold text-muted">Toplam {trendVerisi.reduce((s, v) => s + v.value, 0).toLocaleString('tr-TR')} olay</p>
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <Link href="/yonetici/raporlar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Raporlar <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/kullanicilar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Kullanıcılar <ArrowIcon />
                  </Link>
                  <DisaAktarButonu rows={pageRows} />
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Bilgilendirme">
                <ul className="flex flex-col gap-2 text-xs text-muted">
                  <li>• Bu liste analytics_events, edge_rate_limit_events, admin_audit_log ve reports tablolarının birleşimidir.</li>
                  <li>• IP adresi yalnızca istek üzerinden yakalanabildiğinde görünür; sistem tetiklemeli kayıtlarda genellikle boştur.</li>
                  <li>• Rate limit kayıtlarında ham IP saklanmaz, yalnızca geri döndürülemez bir hash tutulur.</li>
                  <li>• &quot;Dışa Aktar&quot; yalnızca bu sayfadaki (görünen) satırları indirir.</li>
                </ul>
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
  Object.entries(input).forEach(([key, value]) => { if (value && value !== 'all') params.set(key, value); });
  return params.toString();
}

type RawEventRow = {
  id: string;
  created_at: string;
  source: OlayKaynagi;
  incident_type: string;
  sonuc: SonucTuru;
  user_id: string | null;
  raw: any;
};

type EventsSummary = {
  toplam: number; basarili: number; uyari: number; hata: number; bilgi: number;
  bugun: number; dun: number;
  bugun_basarili: number; dun_basarili: number;
  bugun_uyari: number; dun_uyari: number;
  bugun_hata: number; dun_hata: number;
  aktif_kullanici_son_24s: number;
  gunluk_trend: Array<{ gun: string; deger: number }>;
  tur_secenekleri: Array<{ deger: string; kaynak: string; sayi: number }>;
};

type AdCozumlemeBaglami = {
  businessNameById: Map<string, string>;
  menuNameById: Map<string, string>;
  submissionNameById: Map<string, string>;
  suggestionNameById: Map<string, string>;
  claimById: Map<string, { id: string; business_id: string | null; full_name: string | null }>;
};

function analyticsSonuc(eventName: string): SonucTuru {
  const n = eventName.toLowerCase();
  if (n.includes('error') || n.includes('fail') || n.includes('denied')) return 'error';
  if (n.includes('warn') || n.includes('blocked') || n.includes('rate')) return 'warning';
  return 'success';
}

function mapAnalyticsEvent(e: any, ctx: AdCozumlemeBaglami): OlaySatiri {
  const eventName = String(e.event_name ?? 'analytics_event');
  const etiket = ANALYTICS_OLAY_ETIKETLERI[eventName] ?? insanilesir(eventName);
  const isletmeAdi = e.business_id ? ctx.businessNameById.get(e.business_id) : null;
  return {
    id: `analytics:${e.id ?? `${eventName}:${e.created_at}`}`,
    createdAt: e.created_at ?? new Date(0).toISOString(),
    incidentType: eventName,
    description: isletmeAdi ? `${etiket}: ${isletmeAdi}` : etiket,
    source: 'analytics_events' as OlayKaynagi,
    sonuc: analyticsSonuc(eventName),
    userId: e.user_id ?? null,
    userName: null,
    userRole: null,
    ip: null,
    ipHashPrefix: null,
    meta: { business_id: e.business_id, source: e.source },
  };
}

function mapRateLimitEvent(e: any): OlaySatiri {
  const action = String(e.action ?? 'rate_limit');
  const parts = [`${insanilesir(action)} işlemi için hız sınırına takıldı`, e.scope ? `kapsam: ${insanilesir(e.scope)}` : null].filter(Boolean);
  return {
    id: `rate-limit:${e.id ?? `${action}:${e.created_at}`}`,
    createdAt: e.created_at ?? new Date(0).toISOString(),
    incidentType: action,
    description: parts.join(' · '),
    source: 'edge_rate_limit_events' as OlayKaynagi,
    sonuc: 'warning',
    userId: e.user_id ?? null,
    userName: null,
    userRole: null,
    ip: null,
    ipHashPrefix: e.ip_hash ? String(e.ip_hash).slice(0, 8) : null,
    meta: { scope: e.scope },
  };
}

function mapAuditLog(e: any, ctx: AdCozumlemeBaglami): OlaySatiri {
  const action = String(e.action ?? 'audit');
  const etiket = AUDIT_EYLEM_ETIKETLERI[action] ?? insanilesir(action);

  let hedefAdi: string | null = null;
  if (e.target_table === 'businesses') {
    hedefAdi = ctx.businessNameById.get(e.target_id) ?? null;
  } else if (e.target_table === 'menus') {
    hedefAdi = ctx.menuNameById.get(e.target_id) ?? null;
  } else if (e.target_table === 'business_submissions') {
    hedefAdi = ctx.submissionNameById.get(e.target_id) ?? null;
  } else if (e.target_table === 'business_suggestions') {
    hedefAdi = ctx.suggestionNameById.get(e.target_id) ?? null;
  } else if (e.target_table === 'owner_claims') {
    const claim = ctx.claimById.get(e.target_id);
    if (claim) {
      const isletmeAdi = claim.business_id ? ctx.businessNameById.get(claim.business_id) : null;
      hedefAdi = [isletmeAdi ?? 'İşletme', claim.full_name ? `talep eden: ${claim.full_name}` : null].filter(Boolean).join(' · ');
    }
  }

  const aciklama = hedefAdi
    ? `${etiket}: ${hedefAdi}`
    : e.target_table
      ? `${etiket} (${insanilesir(e.target_table)})`
      : etiket;

  return {
    id: `audit:${e.id ?? `${action}:${e.created_at}`}`,
    createdAt: e.created_at ?? new Date(0).toISOString(),
    incidentType: action,
    description: aciklama,
    source: 'admin_audit_log' as OlayKaynagi,
    sonuc: 'success',
    userId: e.actor_id ?? null,
    userName: null,
    userRole: e.actor_role ? (ACTOR_ROLE_ETIKETLERI[e.actor_role] ?? e.actor_role) : null,
    ip: e.ip ?? null,
    ipHashPrefix: null,
    meta: e.meta && Object.keys(e.meta).length > 0 ? e.meta : null,
  };
}

function mapReport(r: any, ctx: AdCozumlemeBaglami): OlaySatiri {
  const hedefTuru = RAPOR_HEDEF_ETIKETLERI[r.target_type] ?? `Rapor (${insanilesir(r.target_type ?? 'item')})`;
  const isletmeAdi = r.business_id ? ctx.businessNameById.get(r.business_id) : null;
  const baslik = isletmeAdi ? `${hedefTuru}: ${isletmeAdi}` : hedefTuru;
  const parts = [baslik, r.reason ? `Sebep: ${r.reason}` : null, String(r.details ?? '').trim() || null].filter(Boolean);
  return {
    id: `report:${r.id}`,
    createdAt: r.created_at ?? new Date(0).toISOString(),
    incidentType: `report_${r.target_type ?? 'item'}`,
    description: parts.join(' · '),
    source: 'reports' as OlayKaynagi,
    sonuc: r.status === 'closed' ? 'success' : 'warning',
    userId: r.reporter_user_id ?? r.user_id ?? null,
    userName: null,
    userRole: null,
    ip: null,
    ipHashPrefix: null,
    meta: { status: r.status, business_id: r.business_id, review_id: r.review_id },
  };
}

function TrendGrafik({ veriler }: { veriler: { label: string; value: number }[] }) {
  const W = 260, H = 90;
  const pad = { l: 4, r: 4, t: 8, b: 4 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;
  const maxVal = Math.max(...veriler.map((v) => v.value), 1);
  const stepX = innerW / Math.max(veriler.length - 1, 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;
  const linePath = veriler.map((v, i) => `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(v.value)}`).join(' ');

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="w-full">
      <path d={linePath} fill="none" stroke="#059669" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
    </svg>
  );
}

function SonucDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
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

function CalendarIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function AlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>; }
function XCircleIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></svg>; }
function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
