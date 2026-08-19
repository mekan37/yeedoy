'use client';

import { useActionState, useEffect, useRef, useState, useCallback } from 'react';
import { upsertQrCode, deleteQrCode } from './kod-islemleri';
import { addPngWatermark } from '@/src/ui/bolumler/karekod-uretici';

export interface QrCode {
  id: string;
  name: string;
  description: string | null;
  type: 'dynamic_menu' | 'static_menu' | 'custom';
  target_url: string | null;
  language: string;
  scan_count: number;
  is_active: boolean;
  created_at: string;
}

export interface QrStats {
  total_codes: number;
  active_codes: number;
  total_scans: number;
  unique_visitors: number;
}

interface Props {
  businessId: string;
  businessSlug: string | null;
  siteUrl: string;
  initialCodes: QrCode[];
  stats: QrStats;
  showQrWatermark: boolean;
}

const TYPE_LABELS: Record<string, string> = {
  dynamic_menu: 'Dinamik Menü',
  static_menu:  'Sabit Menü',
  custom:       'Özel Yönlendirme',
};

const TYPE_DESC: Record<string, string> = {
  dynamic_menu: 'Menüdeki değişiklikler anında yansır.',
  static_menu:  'Belirli bir menü sürümünü gösterir.',
  custom:       'Belirli bir sayfaya yönlendirir.',
};

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' });
}

function formatNum(n: number) {
  return n >= 1000 ? (n / 1000).toFixed(1).replace('.', ',') + ' B' : String(n);
}

export function KodlarIstemcisi({ businessId, businessSlug, siteUrl, initialCodes, stats, showQrWatermark }: Props) {
  const [codes, setCodes] = useState<QrCode[]>(initialCodes);
  const [selected, setSelected] = useState<QrCode | null>(initialCodes[0] ?? null);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'active' | 'passive'>('all');
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<QrCode | null>(null);
  const [menuOpenId, setMenuOpenId] = useState<string | null>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null);
  const [qrError, setQrError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const targetUrl = useCallback((qr: QrCode) => {
    if (qr.type === 'custom' && qr.target_url) return qr.target_url;
    const slug = businessSlug ?? businessId;
    return `${siteUrl}/m/${slug}`;
  }, [businessId, businessSlug, siteUrl]);

  // Kod yokken önizleme için varsayılan URL
  const defaultMenuUrl = `${siteUrl}/m/${businessSlug ?? businessId}`;

  // Seçim değiştiğinde (veya ilk yüklemede varsayılan için) QR kod üret
  useEffect(() => {
    let alive = true;
    const url = selected ? targetUrl(selected) : defaultMenuUrl;
    // Asenkron QR üretimi başlamadan önce önceki sonucu temizler — dış `qrcode`
    // kütüphanesiyle senkronizasyon, derive-from-render'a taşınamaz.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setQrDataUrl(null);
    setQrError(null);

    async function generateQr() {
      const qrCode = await import('qrcode');
      const dataUrl = await qrCode.toDataURL(url, {
        errorCorrectionLevel: 'H',
        margin: 2,
        // 1280px (not the display size — the <img> is CSS-sized to h-48 w-48) so the
        // downloaded PNG matches QR Studio's resolution and, critically, so the watermark's
        // geometry (tuned in karekod-uretici.tsx for width=1280) stays inside the quiet zone.
        // At the previous 256px width the same QR_WATERMARK_PNG_* constants overflow into
        // the real QR modules — verified against the `qrcode` package's own module count.
        width: 1280,
        color: { dark: '#1a1a1a', light: '#ffffff' },
      });

      if (!alive) return;
      setQrDataUrl(showQrWatermark ? await addPngWatermark(dataUrl) : dataUrl);
    }

    void generateQr().catch(() => {
      if (!alive) return;
      setQrError('QR kod oluşturulamadı. Lütfen tekrar deneyin.');
    });

    return () => {
      alive = false;
    };
  }, [selected, targetUrl, defaultMenuUrl, showQrWatermark]);

  const filtered = codes.filter((c) => {
    if (search && !c.name.toLowerCase().includes(search.toLowerCase())) return false;
    if (filter === 'active' && !c.is_active) return false;
    if (filter === 'passive' && c.is_active) return false;
    return true;
  });

  const handleDelete = async (qr: QrCode) => {
    if (!confirm(`"${qr.name}" QR kodunu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.`)) return;
    setMenuOpenId(null);
    setDeleteError(null);
    setDeleting(qr.id);
    const result = await deleteQrCode(qr.id, businessId);
    if (result?.error) {
      setDeleteError(result.error);
      setDeleting(null);
      return;
    }
    setCodes((prev) => prev.filter((c) => c.id !== qr.id));
    if (selected?.id === qr.id) setSelected(codes.find((c) => c.id !== qr.id) ?? null);
    setDeleting(null);
  };

  const downloadPng = () => {
    if (!qrDataUrl) return;
    const name = selected?.name ?? 'menu-qr';
    const link = document.createElement('a');
    link.download = `${name.replace(/\s+/g, '-').toLowerCase()}.png`;
    link.href = qrDataUrl;
    link.click();
  };

  return (
    <div className="flex flex-col gap-6">
      {/* İstatistikler */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatCard icon={<QrGridIcon />} color="text-primary" label="Aktif QR Kod" value={stats.active_codes} sub="Toplam aktif kodunuz" />
        <StatCard icon={<ScanIcon />}   color="text-emerald-600" label="Toplam Tarama" value={formatNum(stats.total_scans)} sub="Son 30 günde" />
        <StatCard icon={<UserIcon />}   color="text-amber-500" label="Benzersiz Ziyaretçi" value={formatNum(stats.unique_visitors)} sub="Son 30 günde" />
        <StatCard icon={<HeartIcon />}  color="text-rose-500" label="Ortalama Etkileşim" value={stats.total_codes > 0 ? '%68.4' : '—'} sub="Menü görüntüleme oranı" />
      </div>

      {deleteError && (
        <div className="rounded-xl bg-red-50 px-4 py-3 text-sm font-bold text-red-600">
          {deleteError}
        </div>
      )}

      {/* Ana 2 sütunlu düzen */}
      <div className="grid grid-cols-1 gap-6 xl:grid-cols-[1fr_320px]">
        {/* Sol: QR listesi */}
        <div className="flex flex-col gap-4">
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <div className="mb-4 flex items-center justify-between gap-3">
              <h2 className="text-sm font-black text-textStrong">QR Kodlarım</h2>
              <button
                onClick={() => { setEditing(null); setFormOpen(true); }}
                className="flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-xs font-extrabold text-white transition hover:opacity-90"
              >
                <PlusIcon /> Yeni QR Kod
              </button>
            </div>

            {/* Arama + Filtre */}
            <div className="mb-4 flex flex-col gap-2 sm:flex-row">
              <div className="relative flex-1">
                <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="QR kod adı ara..."
                  className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/20"
                />
              </div>
              <select
                value={filter}
                onChange={(e) => setFilter(e.target.value as typeof filter)}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/20"
              >
                <option value="all">Tümü</option>
                <option value="active">Aktif</option>
                <option value="passive">Pasif</option>
              </select>
            </div>

            {/* Liste */}
            {filtered.length === 0 ? (
              <div className="flex flex-col items-center gap-2 py-12 text-center">
                <QrGridIcon className="h-10 w-10 text-muted/40" />
                <p className="text-sm font-bold text-textStrong">QR kod bulunamadı</p>
                <p className="text-xs text-muted">Yeni bir QR kod oluşturarak başlayın.</p>
              </div>
            ) : (
              <div className="divide-y divide-border">
                {filtered.map((qr) => (
                  <div
                    key={qr.id}
                    onClick={() => setSelected(qr)}
                    className={`flex cursor-pointer items-start gap-4 py-4 transition ${selected?.id === qr.id ? 'opacity-100' : 'opacity-80 hover:opacity-100'}`}
                  >
                    {/* Mini QR ön izleme */}
                    <div className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-xl border-2 ${selected?.id === qr.id ? 'border-primary bg-primary/5' : 'border-border bg-bg'}`}>
                      <QrGridIcon className="h-8 w-8 text-textStrong/70" />
                    </div>

                    {/* Bilgi */}
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-sm font-extrabold text-textStrong">{qr.name}</span>
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${qr.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>
                          {qr.is_active ? 'Aktif' : 'Pasif'}
                        </span>
                      </div>
                      {qr.description && (
                        <p className="mt-0.5 truncate text-xs text-muted">{qr.description}</p>
                      )}
                      <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-muted">
                        <span className="flex items-center gap-1"><MenuIcon />{TYPE_LABELS[qr.type]}</span>
                        <span className="flex items-center gap-1"><LangIcon />{qr.language === 'tr' ? 'Türkçe' : 'İngilizce'}</span>
                        <span className="flex items-center gap-1"><CalIcon />Oluşturma: {formatDate(qr.created_at)}</span>
                      </div>
                    </div>

                    {/* Tarama + işlemler */}
                    <div className="flex shrink-0 flex-col items-end gap-2" onClick={(e) => e.stopPropagation()}>
                      <span className="text-xs text-muted">Tarama</span>
                      <span className="text-base font-black text-textStrong">{qr.scan_count.toLocaleString('tr-TR')}</span>
                      <div className="relative flex items-center gap-1">
                        <button
                          onClick={() => setSelected(qr)}
                          className="rounded-xl border border-border px-3 py-1.5 text-xs font-extrabold text-textStrong transition hover:bg-bg"
                        >
                          Görüntüle
                        </button>
                        <button
                          onClick={() => setMenuOpenId(menuOpenId === qr.id ? null : qr.id)}
                          className="flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted transition hover:bg-bg"
                        >
                          <DotsIcon />
                        </button>
                        {menuOpenId === qr.id && (
                          <div className="absolute right-0 top-8 z-20 w-40 rounded-xl border border-border bg-card shadow-yd2">
                            <button
                              onClick={() => { setEditing(qr); setFormOpen(true); setMenuOpenId(null); }}
                              className="flex w-full items-center gap-2 px-3 py-2.5 text-xs font-bold text-textStrong hover:bg-bg"
                            >
                              <EditIcon /> Düzenle
                            </button>
                            <button
                              onClick={() => handleDelete(qr)}
                              disabled={deleting === qr.id}
                              className="flex w-full items-center gap-2 px-3 py-2.5 text-xs font-bold text-danger hover:bg-bg disabled:opacity-50"
                            >
                              <TrashIcon /> Sil
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Bilgi şeridi */}
            <div className="mt-4 flex items-center gap-3 rounded-xl bg-primary/5 px-4 py-3">
              <InfoIcon className="h-4 w-4 shrink-0 text-primary" />
              <p className="flex-1 text-xs text-textStrong">
                QR kodlarınız dinamik çalışır. Menünüzdeki yaptığınız değişiklikler anında QR kodlarınıza yansır.
              </p>
              <a href={`/karekod/${businessId}`} className="shrink-0 text-xs font-extrabold text-primary hover:underline">
                QR Studio&apos;ya Git
              </a>
            </div>
          </div>

          {/* İpuçları */}
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <h3 className="mb-4 text-sm font-black text-textStrong">QR Kod Kullanım Önerileri</h3>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {TIPS.map((tip) => (
                <div key={tip.title} className="flex flex-col items-center gap-2 rounded-xl bg-bg p-3 text-center">
                  <tip.icon className="h-6 w-6 text-primary" />
                  <p className="text-xs font-extrabold text-textStrong">{tip.title}</p>
                  <p className="text-[11px] leading-relaxed text-muted">{tip.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Sağ: Önizleme */}
        <div className="flex flex-col gap-4">
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <h3 className="mb-4 text-sm font-black text-textStrong">QR Kod Önizleme</h3>
            <div className="flex items-center justify-center rounded-xl bg-bg p-4">
                {qrDataUrl ? (
                  <img
                    src={qrDataUrl}
                    alt={selected?.name ?? 'Menü QR'}
                    className="h-48 w-48 rounded-lg"
                  />
                ) : qrError ? (
                  <div className="flex h-48 w-48 flex-col items-center justify-center gap-2 rounded-lg bg-border/30 px-3 text-center">
                    <InfoIcon className="h-5 w-5 text-danger" />
                    <p className="text-xs font-bold text-danger">{qrError}</p>
                  </div>
                ) : (
                  <div className="flex h-48 w-48 items-center justify-center rounded-lg bg-border/30">
                    <SpinIcon className="h-6 w-6 animate-spin text-muted" />
                  </div>
                )}
              </div>
              <p className="mt-3 text-center text-sm font-extrabold text-textStrong">
                {selected?.name ?? 'Menü QR Kodu'}
              </p>
              <p className="mt-1 break-all text-center text-[11px] text-muted">
                {selected ? targetUrl(selected) : defaultMenuUrl}
              </p>
              <div className="mt-4 flex flex-col gap-2">
                <button
                  onClick={downloadPng}
                  disabled={!qrDataUrl}
                  className="flex w-full items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm font-extrabold text-textStrong transition hover:bg-bg disabled:opacity-50"
                >
                  <DownloadIcon /> PNG İndir
                </button>
                <button
                  onClick={() => window.print()}
                  className="flex w-full items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm font-extrabold text-textStrong transition hover:bg-bg"
                >
                  <PrintIcon /> Yazdır
                </button>
              </div>
          </div>

          {/* QR Tipleri */}
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <h3 className="mb-3 text-sm font-black text-textStrong">QR Kod Tipleri</h3>
            <div className="flex flex-col gap-3">
              {Object.entries(TYPE_DESC).map(([type, desc]) => (
                <div key={type} className="flex items-start gap-3">
                  <div className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${typeColor(type)}`}>
                    <QrGridIcon className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="text-xs font-extrabold text-textStrong">{TYPE_LABELS[type]}</p>
                    <p className="text-[11px] text-muted">{desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Oluştur/Düzenle Modalı */}
      {formOpen && (
        <QrForm
          businessId={businessId}
          qr={editing}
          onClose={() => { setFormOpen(false); setEditing(null); }}
          onSuccess={(newQr) => {
            setCodes((prev) => {
              const exists = prev.findIndex((c) => c.id === newQr.id);
              if (exists >= 0) {
                const updated = [...prev];
                updated[exists] = newQr;
                return updated;
              }
              return [newQr, ...prev];
            });
            setSelected(newQr);
          }}
        />
      )}

      {/* Dropdown için arka plan */}
      {menuOpenId && (
        <div className="fixed inset-0 z-10" onClick={() => setMenuOpenId(null)} />
      )}
    </div>
  );
}

// ── Form ──────────────────────────────────────────────────────────────────────

function QrForm({
  businessId,
  qr,
  onClose,
  onSuccess,
}: {
  businessId: string;
  qr: QrCode | null;
  onClose: () => void;
  onSuccess: (q: QrCode) => void;
}) {
  const [state, action, pending] = useActionState(upsertQrCode, null);
  const hasSubmitted = useRef(false);
  const [type, setType] = useState<string>(qr?.type ?? 'dynamic_menu');

  useEffect(() => {
    if (hasSubmitted.current && state === null && !pending) onClose();
  }, [state, pending, onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-xs" onClick={onClose} />
      <div className="relative z-10 w-full max-w-md rounded-t-2xl bg-card shadow-2xl border border-border sm:rounded-2xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-black text-textStrong">
            {qr ? 'QR Kodu Düzenle' : 'Yeni QR Kod'}
          </h2>
          <button type="button" onClick={onClose} className="flex h-8 w-8 items-center justify-center rounded-xl text-muted hover:bg-bg">
            <CloseIcon />
          </button>
        </div>

        <form
          action={action}
          onSubmit={() => { hasSubmitted.current = true; }}
          className="max-h-[80vh] overflow-y-auto space-y-4 px-6 py-5"
        >
          <input type="hidden" name="business_id" value={businessId} />
          {qr && <input type="hidden" name="id" value={qr.id} />}

          <Field label="QR Kod Adı" required>
            <input name="name" defaultValue={qr?.name ?? ''} placeholder="Örn: Masa QR - İç Mekan" maxLength={100} required className={inputCls} />
          </Field>

          <Field label="Açıklama">
            <textarea name="description" defaultValue={qr?.description ?? ''} placeholder="Bu QR kodun amacını açıklayın..." rows={2} maxLength={300} className={`${inputCls} resize-none`} />
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Field label="Tip" required>
              <select name="type" defaultValue={qr?.type ?? 'dynamic_menu'} onChange={(e) => setType(e.target.value)} className={inputCls} required>
                <option value="dynamic_menu">Dinamik Menü</option>
                <option value="static_menu">Sabit Menü</option>
                <option value="custom">Özel Yönlendirme</option>
              </select>
            </Field>
            <Field label="Dil">
              <select name="language" defaultValue={qr?.language ?? 'tr'} className={inputCls}>
                <option value="tr">Türkçe</option>
                <option value="en">İngilizce</option>
              </select>
            </Field>
          </div>

          {type === 'custom' && (
            <Field label="Hedef URL" required>
              <input name="target_url" type="url" defaultValue={qr?.target_url ?? ''} placeholder="https://..." className={inputCls} required={type === 'custom'} />
            </Field>
          )}

          <Field label="Durum">
            <select name="is_active" defaultValue={qr?.is_active === false ? 'false' : 'true'} className={inputCls}>
              <option value="true">Aktif</option>
              <option value="false">Pasif</option>
            </select>
          </Field>

          {state?.error && (
            <p className="rounded-xl bg-red-50 px-4 py-3 text-sm font-bold text-red-600">{state.error}</p>
          )}

          <div className="flex items-center justify-end gap-3 border-t border-border pt-4">
            <button type="button" onClick={onClose} className="h-9 rounded-xl border border-border px-4 text-sm font-extrabold text-textStrong hover:bg-bg">
              İptal
            </button>
            <button type="submit" disabled={pending} className="flex h-9 items-center gap-2 rounded-xl bg-primary px-5 text-sm font-extrabold text-white hover:opacity-90 disabled:opacity-50">
              {pending && <SpinIcon className="animate-spin" />}
              {qr ? 'Kaydet' : 'Oluştur'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ── StatCard ──────────────────────────────────────────────────────────────────

function StatCard({ icon, color, label, value, sub }: {
  icon: React.ReactNode; color: string; label: string; value: string | number; sub: string;
}) {
  return (
    <div className="rounded-[20px] border border-border bg-card p-4 shadow-yd1">
      <div className="mb-2 flex items-center gap-2">
        <span className={`${color} opacity-80`}>{icon}</span>
        <span className="text-xs font-bold text-muted">{label}</span>
      </div>
      <p className="text-xl font-black text-textStrong">{value}</p>
      <p className="mt-0.5 text-[11px] text-muted">{sub}</p>
    </div>
  );
}

// ── Yardımcılar ───────────────────────────────────────────────────────────────

const TIPS = [
  { icon: TableIcon, title: 'Masalarınıza Yerleştirin', desc: 'Müşterilerinizin kolayca görebileceği masaların üzerine yerleştirin.' },
  { icon: StandIcon, title: 'Dikey Stand Kullanın', desc: 'Daha iyi tarama deneyimi için dikey stand önerilir.' },
  { icon: CloudIcon, title: 'Hava Koşullarına Dikkat', desc: 'Açık alanda kullanılan QR kodların korumalı olmasına özen gösterin.' },
  { icon: SearchIcon, title: 'Temiz ve Okunaklı Tutun', desc: 'QR kodların temiz ve hasarsız olmasından emin olun.' },
];

function typeColor(type: string) {
  if (type === 'dynamic_menu') return 'bg-primary/10 text-primary';
  if (type === 'static_menu')  return 'bg-emerald-100 text-emerald-700';
  return 'bg-amber-100 text-amber-700';
}

function Field({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-bold text-muted">
        {label}{required && <span className="ml-1 text-danger">*</span>}
      </label>
      {children}
    </div>
  );
}

const inputCls = 'w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/20 transition-shadow';

// ── İkonlar ───────────────────────────────────────────────────────────────────

function QrGridIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h.01M14 17h.01M17 14h.01M17 17h.01M20 14h.01M20 17h.01M20 20h.01"/></svg>;
}
function ScanIcon() { return <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/><line x1="3" y1="12" x2="21" y2="12"/></svg>; }
function UserIcon() { return <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg>; }
function HeartIcon() { return <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>; }
function PlusIcon() { return <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>; }
function SearchIcon({ className = 'h-4 w-4' }: { className?: string }) { return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>; }
function DotsIcon() { return <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>; }
function EditIcon() { return <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>; }
function TrashIcon() { return <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>; }
function DownloadIcon() { return <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>; }
function PrintIcon() { return <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>; }
function CloseIcon() { return <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>; }
function SpinIcon({ className = 'h-4 w-4' }: { className?: string }) { return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>; }
function InfoIcon({ className = 'h-4 w-4' }: { className?: string }) { return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>; }
function MenuIcon() { return <svg className="h-3 w-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>; }
function LangIcon() { return <svg className="h-3 w-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>; }
function CalIcon() { return <svg className="h-3 w-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>; }
function TableIcon({ className = 'h-6 w-6' }: { className?: string }) { return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7h18M5 7v13M19 7v13M9 20v-6h6v6"/></svg>; }
function StandIcon({ className = 'h-6 w-6' }: { className?: string }) { return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="6" y="3" width="12" height="14" rx="1"/><path d="M9 21h6M12 17v4"/></svg>; }
function CloudIcon({ className = 'h-6 w-6' }: { className?: string }) { return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.5 19H9a5 5 0 1 1 1.3-9.8A6 6 0 0 1 22 12.5 4.5 4.5 0 0 1 17.5 19z"/></svg>; }
