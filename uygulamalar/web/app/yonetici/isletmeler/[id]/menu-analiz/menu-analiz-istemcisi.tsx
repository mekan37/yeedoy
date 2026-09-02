'use client';

import { clsx } from 'clsx';
import { useEffect, useRef, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import {
  menuAnalizBaslatUrl,
  menuAnalizDurumSorgula,
  menuAnalizOgeleriListele,
  menuAnalizOgeGuncelle,
  menuAnalizOgeHaricTut,
  isletmeMenuOgeleriListele,
  menuAnalizUygula,
  type MenuAnalizOge,
  type IsletmeMenuOgesi,
  type MenuAnalizUygulaKarari,
} from './menu-analiz-islemleri';

type Asama = 'giris' | 'bekliyor' | 'tamamlandi' | 'basarisiz' | 'onizleme' | 'sonuc';
type Karar = { action: 'create' | 'update' | 'skip'; targetId?: string };

const POLL_ARALIGI_MS = 2800;
const YUKLEME_LIMIT_BAYT = 30 * 1024 * 1024;

const HATA_METINLERI: Record<string, string> = {
  rate_limited: 'Çok fazla istek gönderildi. Lütfen biraz bekleyip tekrar deneyin.',
  size_limit: 'Dosya çok büyük. Maksimum 30 MB kabul edilir.',
  invalid_payload: 'Geçersiz istek, lütfen bilgileri kontrol edin.',
  unauthorized: 'Bu işlem için yetkiniz yok.',
  forbidden: 'Bu işlem için yetkiniz yok.',
  not_found: 'İşletme bulunamadı, sayfa yenilenmiş olabilir.',
  internal_error: 'Analiz başlatılamadı, tekrar deneyin.',
};

function hataCevir(kod: unknown): string {
  if (typeof kod === 'string' && HATA_METINLERI[kod]) return HATA_METINLERI[kod];
  return 'Analiz başlatılamadı, tekrar deneyin.';
}

function fiyatGoster(cents: number | null, currency: string): string {
  if (cents == null) return '—';
  return `${(cents / 100).toFixed(2)} ${currency}`;
}

function eslesmeBul(ad: string, mevcutMenu: IsletmeMenuOgesi[]): IsletmeMenuOgesi | null {
  const norm = ad.trim().toLowerCase();
  if (!norm) return null;
  return mevcutMenu.find((m) => m.name.trim().toLowerCase() === norm) ?? null;
}

export function MenuAnalizIstemcisi({
  businessId,
  businessName,
  initialJobId,
}: {
  businessId: string;
  businessName: string;
  initialJobId: string | null;
}) {
  const router = useRouter();
  const pathname = usePathname();

  const [asama, setAsama] = useState<Asama>(initialJobId ? 'bekliyor' : 'giris');
  const [jobId, setJobId] = useState<string | null>(initialJobId);
  const [durum, setDurum] = useState<'queued' | 'started'>('queued');
  const [hataMesaji, setHataMesaji] = useState<string | null>(null);
  const [baslatiliyor, setBaslatiliyor] = useState(false);

  const [mod, setMod] = useState<'url' | 'dosya'>('url');
  const [urlDegeri, setUrlDegeri] = useState('');
  const [dosya, setDosya] = useState<File | null>(null);

  const [ogeler, setOgeler] = useState<MenuAnalizOge[]>([]);
  const [ogelerYukleniyor, setOgelerYukleniyor] = useState(false);

  const [mevcutMenu, setMevcutMenu] = useState<IsletmeMenuOgesi[]>([]);
  const [kararlar, setKararlar] = useState<Record<string, Karar>>({});
  const [onizlemeYukleniyor, setOnizlemeYukleniyor] = useState(false);
  const [aktariliyor, setAktariliyor] = useState(false);

  const [sonuc, setSonuc] = useState<{ created: number; updated: number; skipped: number } | null>(null);

  const pollTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const aktifJobId = useRef<string | null>(null);

  // ── Polling ──
  useEffect(() => {
    if (!jobId || asama !== 'bekliyor') return;
    aktifJobId.current = jobId;
    let durduruldu = false;

    async function birTur() {
      const res = await menuAnalizDurumSorgula(jobId as string);
      if (durduruldu || aktifJobId.current !== jobId) return;

      if (!res.ok) {
        // Extractor'a geçici ulaşılamama — sessizce bir sonraki turu dener.
        pollTimer.current = setTimeout(birTur, POLL_ARALIGI_MS);
        return;
      }
      if (res.data.status === 'finished') {
        setAsama('tamamlandi');
        return;
      }
      if (res.data.status === 'failed') {
        setHataMesaji(res.data.errorMessage ?? 'Analiz başarısız oldu.');
        setAsama('basarisiz');
        return;
      }
      setDurum(res.data.status);
      pollTimer.current = setTimeout(birTur, POLL_ARALIGI_MS);
    }

    void birTur();

    return () => {
      durduruldu = true;
      if (pollTimer.current) {
        clearTimeout(pollTimer.current);
        pollTimer.current = null;
      }
    };
  }, [jobId, asama]);

  // ── Tamamlanınca kalemleri getir ──
  useEffect(() => {
    if (asama !== 'tamamlandi' || !jobId) return;
    let iptal = false;
    setOgelerYukleniyor(true);
    menuAnalizOgeleriListele(jobId).then((data) => {
      if (iptal) return;
      setOgeler(data);
      setOgelerYukleniyor(false);
    });
    return () => {
      iptal = true;
    };
  }, [asama, jobId]);

  function jobBaslatildi(yeniJobId: string) {
    setJobId(yeniJobId);
    setDurum('queued');
    setHataMesaji(null);
    setAsama('bekliyor');
    router.replace(`${pathname}?job=${yeniJobId}`, { scroll: false });
  }

  async function urlIleBaslat() {
    setHataMesaji(null);
    if (!urlDegeri.trim()) {
      setHataMesaji('Menü URL\'si zorunlu.');
      return;
    }
    setBaslatiliyor(true);
    const res = await menuAnalizBaslatUrl(businessId, urlDegeri.trim());
    setBaslatiliyor(false);
    if (!res.ok) {
      setHataMesaji(res.error);
      return;
    }
    jobBaslatildi(res.jobId);
  }

  async function dosyaIleBaslat() {
    setHataMesaji(null);
    if (!dosya) {
      setHataMesaji('Bir dosya seçin.');
      return;
    }
    if (dosya.size > YUKLEME_LIMIT_BAYT) {
      setHataMesaji('Dosya çok büyük. Maksimum 30 MB kabul edilir.');
      return;
    }
    setBaslatiliyor(true);
    try {
      const formData = new FormData();
      formData.append('business_id', businessId);
      formData.append('file', dosya);
      const resp = await fetch('/sunucu/yonetici/menu-analiz/baslat', { method: 'POST', body: formData });
      const json = (await resp.json().catch(() => null)) as { data?: { job_id: string }; error?: string } | null;
      if (!resp.ok || !json?.data?.job_id) {
        setHataMesaji(hataCevir(json?.error));
        return;
      }
      jobBaslatildi(json.data.job_id);
    } catch {
      setHataMesaji('Analiz servisine ulaşılamadı.');
    } finally {
      setBaslatiliyor(false);
    }
  }

  function yenidenDene() {
    setAsama('giris');
    setJobId(null);
    setHataMesaji(null);
    setOgeler([]);
    setSonuc(null);
    setUrlDegeri('');
    setDosya(null);
    router.replace(pathname, { scroll: false });
  }

  async function ogeKaydet(oge: MenuAnalizOge, patch: { categoryName: string | null; name: string; description: string | null; priceCents: number | null }) {
    setOgeler((prev) => prev.map((o) => (o.id === oge.id ? { ...o, category_name: patch.categoryName, name: patch.name, description: patch.description, price_cents: patch.priceCents } : o)));
    const res = await menuAnalizOgeGuncelle({
      itemId: oge.id,
      categoryName: patch.categoryName,
      name: patch.name,
      description: patch.description,
      priceCents: patch.priceCents,
      currency: oge.currency,
    });
    if (!res.ok) setHataMesaji(res.error);
  }

  async function ogeHaricTutDegistir(oge: MenuAnalizOge, excluded: boolean) {
    setOgeler((prev) => prev.map((o) => (o.id === oge.id ? { ...o, excluded } : o)));
    const res = await menuAnalizOgeHaricTut(oge.id, excluded);
    if (!res.ok) {
      setOgeler((prev) => prev.map((o) => (o.id === oge.id ? { ...o, excluded: !excluded } : o)));
      setHataMesaji(res.error);
    }
  }

  const dahilOgeler = ogeler.filter((o) => !o.excluded);

  async function onizlemeyeGec() {
    setHataMesaji(null);
    setOnizlemeYukleniyor(true);
    const menu = await isletmeMenuOgeleriListele(businessId);
    setMevcutMenu(menu);

    const yeniKararlar: Record<string, Karar> = {};
    for (const oge of dahilOgeler) {
      if (oge.price_cents == null) {
        yeniKararlar[oge.id] = { action: 'skip' };
        continue;
      }
      const eslesen = eslesmeBul(oge.name, menu);
      yeniKararlar[oge.id] = eslesen ? { action: 'update', targetId: eslesen.id } : { action: 'create' };
    }
    setKararlar(yeniKararlar);
    setOnizlemeYukleniyor(false);
    setAsama('onizleme');
  }

  async function aktarimiOnayla() {
    if (!jobId) return;
    setHataMesaji(null);
    const decisions: MenuAnalizUygulaKarari[] = dahilOgeler.map((oge) => {
      const karar = kararlar[oge.id] ?? { action: 'skip' };
      return {
        item_id: oge.id,
        action: karar.action,
        target_menu_item_id: karar.action === 'update' ? karar.targetId : undefined,
      };
    });
    setAktariliyor(true);
    const res = await menuAnalizUygula(jobId, decisions);
    setAktariliyor(false);
    if (!res.ok) {
      setHataMesaji(res.error);
      return;
    }
    setSonuc({ created: res.created, updated: res.updated, skipped: res.skipped });
    setAsama('sonuc');
  }

  return (
    <div className="flex flex-col gap-6">
      {asama === 'giris' && (
        <GirisAlani
          mod={mod}
          setMod={setMod}
          urlDegeri={urlDegeri}
          setUrlDegeri={setUrlDegeri}
          dosya={dosya}
          setDosya={setDosya}
          baslatiliyor={baslatiliyor}
          hataMesaji={hataMesaji}
          onUrlBaslat={urlIleBaslat}
          onDosyaBaslat={dosyaIleBaslat}
        />
      )}

      {asama === 'bekliyor' && <BeklemeAlani durum={durum} />}

      {asama === 'basarisiz' && <BasarisizAlani hataMesaji={hataMesaji} onTekrarDene={yenidenDene} />}

      {(asama === 'tamamlandi' || asama === 'onizleme' || asama === 'sonuc') && ogelerYukleniyor && (
        <p className="py-8 text-center text-sm font-bold text-muted">Kalemler yükleniyor...</p>
      )}

      {asama === 'tamamlandi' && !ogelerYukleniyor && (
        <OgelerTablosu
          ogeler={ogeler}
          onKaydet={ogeKaydet}
          onHaricTutDegistir={ogeHaricTutDegistir}
          onOnizlemeyeGec={onizlemeyeGec}
          onizlemeYukleniyor={onizlemeYukleniyor}
          hataMesaji={hataMesaji}
        />
      )}

      {asama === 'onizleme' && (
        <OnizlemeAlani
          businessName={businessName}
          dahilOgeler={dahilOgeler}
          mevcutMenu={mevcutMenu}
          kararlar={kararlar}
          setKararlar={setKararlar}
          onGeriDon={() => setAsama('tamamlandi')}
          onOnayla={aktarimiOnayla}
          aktariliyor={aktariliyor}
          hataMesaji={hataMesaji}
        />
      )}

      {asama === 'sonuc' && sonuc && <SonucAlani sonuc={sonuc} onYeniAnaliz={yenidenDene} />}
    </div>
  );
}

// ─── Giriş: URL / Dosya seçimi ────────────────────────────────────────────────

function GirisAlani({
  mod,
  setMod,
  urlDegeri,
  setUrlDegeri,
  dosya,
  setDosya,
  baslatiliyor,
  hataMesaji,
  onUrlBaslat,
  onDosyaBaslat,
}: {
  mod: 'url' | 'dosya';
  setMod: (m: 'url' | 'dosya') => void;
  urlDegeri: string;
  setUrlDegeri: (v: string) => void;
  dosya: File | null;
  setDosya: (f: File | null) => void;
  baslatiliyor: boolean;
  hataMesaji: string | null;
  onUrlBaslat: () => void;
  onDosyaBaslat: () => void;
}) {
  return (
    <PanelBolumKarti title="Menü Kaynağı" description="Bir menü URL'si girin veya PDF/görsel dosya yükleyin. Analiz tamamlanınca çıkarılan kalemleri gözden geçirip onaylayacaksınız.">
      <div className="flex flex-col gap-4">
        <div className="flex gap-1 border-b border-border">
          <ModSekmesi active={mod === 'url'} onClick={() => setMod('url')}>Menü Linki (URL)</ModSekmesi>
          <ModSekmesi active={mod === 'dosya'} onClick={() => setMod('dosya')}>Dosya Yükle (PDF/Görsel)</ModSekmesi>
        </div>

        {mod === 'url' ? (
          <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
            <div className="flex-1">
              <label className="mb-1 block text-xs font-bold uppercase tracking-wide text-muted">Menü URL&apos;si</label>
              <input
                value={urlDegeri}
                onChange={(e) => setUrlDegeri(e.target.value)}
                placeholder="https://ornek-restoran.com/menu"
                className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
              />
            </div>
            <PanelActionButton variant="primary" loading={baslatiliyor} disabled={baslatiliyor || !urlDegeri.trim()} onClick={onUrlBaslat}>
              Analizi Başlat
            </PanelActionButton>
          </div>
        ) : (
          <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
            <div className="flex-1">
              <label className="mb-1 block text-xs font-bold uppercase tracking-wide text-muted">Dosya (PDF veya görsel, maks. 30 MB)</label>
              <input
                type="file"
                accept="application/pdf,image/*"
                onChange={(e) => setDosya(e.target.files?.[0] ?? null)}
                className="block w-full text-sm text-textStrong file:mr-3 file:rounded-lg file:border-0 file:bg-primary/10 file:px-3 file:py-2 file:text-xs file:font-extrabold file:text-primary"
              />
            </div>
            <PanelActionButton variant="primary" loading={baslatiliyor} disabled={baslatiliyor || !dosya} onClick={onDosyaBaslat}>
              Analizi Başlat
            </PanelActionButton>
          </div>
        )}

        {hataMesaji && <p className="text-xs font-bold text-(--yd-color-danger)">{hataMesaji}</p>}
      </div>
    </PanelBolumKarti>
  );
}

function ModSekmesi({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'rounded-t-lg px-4 py-2 text-sm font-extrabold transition-colors',
        active ? 'border-b-2 border-primary text-primary' : 'text-muted hover:text-textStrong',
      )}
    >
      {children}
    </button>
  );
}

// ─── Bekleme (polling) ────────────────────────────────────────────────────────

function BeklemeAlani({ durum }: { durum: 'queued' | 'started' }) {
  return (
    <PanelBolumKarti>
      <div className="flex flex-col items-center gap-3 py-10 text-center">
        <SpinnerIcon />
        <p className="text-sm font-extrabold text-textStrong">{durum === 'queued' ? 'Sırada...' : 'İşleniyor...'}</p>
        <p className="max-w-sm text-xs text-muted">
          Menü analiz ediliyor, bu birkaç dakika sürebilir. Bu sayfayı kapatmanız gerekirse iş bilgisi bağlantıya kaydedildi — sayfayı yeniden açtığınızda kaldığı yerden devam eder.
        </p>
      </div>
    </PanelBolumKarti>
  );
}

function SpinnerIcon() {
  return (
    <svg className="h-8 w-8 animate-spin text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
  );
}

// ─── Başarısız ─────────────────────────────────────────────────────────────

function BasarisizAlani({ hataMesaji, onTekrarDene }: { hataMesaji: string | null; onTekrarDene: () => void }) {
  return (
    <PanelBolumKarti>
      <div className="flex flex-col items-center gap-3 py-8 text-center">
        <span className="flex h-10 w-10 items-center justify-center rounded-full bg-red-50 text-(--yd-color-danger)">
          <ErrorIcon />
        </span>
        <p className="text-sm font-extrabold text-textStrong">Analiz başarısız oldu</p>
        {hataMesaji && <p className="max-w-sm text-xs text-muted">{hataMesaji}</p>}
        <PanelActionButton variant="primary" onClick={onTekrarDene}>Tekrar Dene</PanelActionButton>
      </div>
    </PanelBolumKarti>
  );
}

function ErrorIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}

// ─── Kalemler tablosu ──────────────────────────────────────────────────────

function OgelerTablosu({
  ogeler,
  onKaydet,
  onHaricTutDegistir,
  onOnizlemeyeGec,
  onizlemeYukleniyor,
  hataMesaji,
}: {
  ogeler: MenuAnalizOge[];
  onKaydet: (oge: MenuAnalizOge, patch: { categoryName: string | null; name: string; description: string | null; priceCents: number | null }) => void;
  onHaricTutDegistir: (oge: MenuAnalizOge, excluded: boolean) => void;
  onOnizlemeyeGec: () => void;
  onizlemeYukleniyor: boolean;
  hataMesaji: string | null;
}) {
  const dahilSayisi = ogeler.filter((o) => !o.excluded).length;
  const fiyatEksikSayisi = ogeler.filter((o) => !o.excluded && o.price_cents == null).length;

  return (
    <PanelBolumKarti
      title="Çıkarılan Kalemler"
      description={`${ogeler.length} kalem bulundu · ${dahilSayisi} dahil edilecek${fiyatEksikSayisi > 0 ? ` · ${fiyatEksikSayisi} kalemde fiyat eksik` : ''}`}
      noPadding
      actions={
        <PanelActionButton variant="primary" loading={onizlemeYukleniyor} disabled={onizlemeYukleniyor || dahilSayisi === 0} onClick={onOnizlemeyeGec}>
          Menüye Aktar
        </PanelActionButton>
      }
    >
      {ogeler.length === 0 ? (
        <p className="px-5 py-8 text-center text-sm font-bold text-muted">Hiç kalem çıkarılamadı.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left text-xs font-bold uppercase text-muted">
                <th className="px-3 py-2.5">Kategori</th>
                <th className="px-3 py-2.5">Ürün Adı</th>
                <th className="px-3 py-2.5">Açıklama</th>
                <th className="px-3 py-2.5">Fiyat</th>
                <th className="px-3 py-2.5">Güven</th>
                <th className="px-3 py-2.5">Notlar</th>
                <th className="px-3 py-2.5 text-center">Dahil Et</th>
              </tr>
            </thead>
            <tbody>
              {ogeler.map((oge) => (
                <OgeSatiri key={oge.id} oge={oge} onKaydet={onKaydet} onHaricTutDegistir={onHaricTutDegistir} />
              ))}
            </tbody>
          </table>
        </div>
      )}
      {hataMesaji && <p className="px-5 py-3 text-xs font-bold text-(--yd-color-danger)">{hataMesaji}</p>}
    </PanelBolumKarti>
  );
}

function OgeSatiri({
  oge,
  onKaydet,
  onHaricTutDegistir,
}: {
  oge: MenuAnalizOge;
  onKaydet: (oge: MenuAnalizOge, patch: { categoryName: string | null; name: string; description: string | null; priceCents: number | null }) => void;
  onHaricTutDegistir: (oge: MenuAnalizOge, excluded: boolean) => void;
}) {
  const [category, setCategory] = useState(oge.category_name ?? '');
  const [name, setName] = useState(oge.name);
  const [description, setDescription] = useState(oge.description ?? '');
  const [priceStr, setPriceStr] = useState(oge.price_cents != null ? (oge.price_cents / 100).toFixed(2) : '');

  const parsedPrice = priceStr.trim() ? Number.parseFloat(priceStr.replace(',', '.')) : null;
  const priceEksik = parsedPrice === null || !Number.isFinite(parsedPrice);

  function kaydet() {
    const priceCents = priceEksik ? null : Math.round((parsedPrice as number) * 100);
    onKaydet(oge, {
      categoryName: category.trim() || null,
      name: name.trim() || oge.name,
      description: description.trim() || null,
      priceCents,
    });
  }

  const notlar = [...(oge.requires_review ? ['İncelenmeli'] : []), ...oge.review_reasons, ...oge.warnings];
  const inputClass = 'min-h-9 w-full rounded-lg border border-border bg-bg px-2 py-1 text-xs text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30';

  return (
    <tr className={clsx('border-b border-border last:border-0 align-top', oge.requires_review && 'bg-amber-50/50')}>
      <td className="px-3 py-2 min-w-[110px]">
        <input value={category} onChange={(e) => setCategory(e.target.value)} onBlur={kaydet} className={inputClass} />
      </td>
      <td className="px-3 py-2 min-w-[140px]">
        <input value={name} onChange={(e) => setName(e.target.value)} onBlur={kaydet} className={clsx(inputClass, 'font-bold')} />
      </td>
      <td className="px-3 py-2 min-w-[160px]">
        <input value={description} onChange={(e) => setDescription(e.target.value)} onBlur={kaydet} className={inputClass} />
      </td>
      <td className="px-3 py-2 min-w-[110px]">
        <input
          value={priceStr}
          onChange={(e) => setPriceStr(e.target.value)}
          onBlur={kaydet}
          placeholder={priceEksik ? 'Zorunlu' : undefined}
          className={clsx(inputClass, priceEksik && 'border-red-400 bg-red-50 placeholder:font-extrabold placeholder:text-red-500')}
        />
      </td>
      <td className="px-3 py-2">
        <ConfidenceBadge value={oge.confidence} />
      </td>
      <td className="px-3 py-2 min-w-[140px]">
        {notlar.length > 0 && (
          <div className="flex flex-col gap-0.5">
            {notlar.map((n, i) => (
              <span key={i} className="text-[11px] font-bold text-amber-700">{n}</span>
            ))}
          </div>
        )}
      </td>
      <td className="px-3 py-2 text-center">
        <input
          type="checkbox"
          checked={!oge.excluded && !priceEksik}
          disabled={priceEksik}
          onChange={(e) => onHaricTutDegistir(oge, !e.target.checked)}
          title={priceEksik ? 'Fiyat girilmeden dahil edilemez' : undefined}
          className="h-4 w-4 rounded border-border disabled:opacity-40"
        />
      </td>
    </tr>
  );
}

function ConfidenceBadge({ value }: { value: number | null }) {
  if (value == null) return <span className="text-xs text-muted">—</span>;
  const pct = Math.round(value * 100);
  const tone = pct >= 85 ? 'bg-emerald-50 text-emerald-700' : pct >= 60 ? 'bg-amber-50 text-amber-700' : 'bg-red-50 text-red-700';
  return <span className={clsx('inline-block rounded-full px-2 py-0.5 text-[11px] font-extrabold', tone)}>%{pct}</span>;
}

// ─── Önizleme / onay ──────────────────────────────────────────────────────────

function OnizlemeAlani({
  businessName,
  dahilOgeler,
  mevcutMenu,
  kararlar,
  setKararlar,
  onGeriDon,
  onOnayla,
  aktariliyor,
  hataMesaji,
}: {
  businessName: string;
  dahilOgeler: MenuAnalizOge[];
  mevcutMenu: IsletmeMenuOgesi[];
  kararlar: Record<string, Karar>;
  setKararlar: (updater: (prev: Record<string, Karar>) => Record<string, Karar>) => void;
  onGeriDon: () => void;
  onOnayla: () => void;
  aktariliyor: boolean;
  hataMesaji: string | null;
}) {
  const yeniSayisi = dahilOgeler.filter((o) => o.price_cents != null && kararlar[o.id]?.action === 'create').length;
  const guncellenecekSayisi = dahilOgeler.filter((o) => o.price_cents != null && kararlar[o.id]?.action === 'update').length;
  const engelliSayisi = dahilOgeler.filter((o) => o.price_cents == null).length;
  const aktarilacakSayisi = yeniSayisi + guncellenecekSayisi;

  return (
    <PanelBolumKarti
      title="Menüye Aktarım Önizlemesi"
      description={`${businessName} — bu ekranı onaylamadan hiçbir veri gerçek menüye yazılmaz.`}
      noPadding
      actions={
        <div className="flex items-center gap-2">
          <PanelActionButton variant="secondary" onClick={onGeriDon} disabled={aktariliyor}>Geri</PanelActionButton>
          <PanelActionButton variant="primary" loading={aktariliyor} disabled={aktariliyor || aktarilacakSayisi === 0} onClick={onOnayla}>
            Onayla ve Aktar
          </PanelActionButton>
        </div>
      }
    >
      <div className="border-b border-border px-5 py-3 text-xs font-bold text-muted">
        {yeniSayisi} yeni ürün · {guncellenecekSayisi} mevcut ürün güncellenecek
        {engelliSayisi > 0 && ` · ${engelliSayisi} kalem fiyat eksikliğinden aktarılamıyor`}
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-xs font-bold uppercase text-muted">
              <th className="px-3 py-2.5">Ürün Adı</th>
              <th className="px-3 py-2.5">Kategori</th>
              <th className="px-3 py-2.5">Fiyat</th>
              <th className="px-3 py-2.5">İşlem</th>
            </tr>
          </thead>
          <tbody>
            {dahilOgeler.map((oge) => (
              <OnizlemeSatiri
                key={oge.id}
                oge={oge}
                mevcutMenu={mevcutMenu}
                karar={kararlar[oge.id] ?? { action: 'skip' }}
                onKararDegistir={(karar) => setKararlar((prev) => ({ ...prev, [oge.id]: karar }))}
              />
            ))}
          </tbody>
        </table>
      </div>
      {hataMesaji && <p className="px-5 py-3 text-xs font-bold text-(--yd-color-danger)">{hataMesaji}</p>}
    </PanelBolumKarti>
  );
}

function OnizlemeSatiri({
  oge,
  mevcutMenu,
  karar,
  onKararDegistir,
}: {
  oge: MenuAnalizOge;
  mevcutMenu: IsletmeMenuOgesi[];
  karar: Karar;
  onKararDegistir: (karar: Karar) => void;
}) {
  const priceEksik = oge.price_cents == null;
  const eslesen = karar.action === 'update' && karar.targetId ? mevcutMenu.find((m) => m.id === karar.targetId) : null;
  const olasiEslesme = eslesmeBul(oge.name, mevcutMenu);

  return (
    <tr className="border-b border-border last:border-0">
      <td className="px-3 py-2 font-bold text-textStrong">{oge.name}</td>
      <td className="px-3 py-2 text-muted">{oge.category_name ?? '—'}</td>
      <td className="px-3 py-2">
        {priceEksik ? (
          <span className="text-xs font-extrabold text-(--yd-color-danger)">Fiyat eksik</span>
        ) : eslesen ? (
          <span className="text-xs">
            <span className="text-muted line-through">{fiyatGoster(eslesen.price_cents, eslesen.currency)}</span>
            {' → '}
            <span className="font-extrabold text-textStrong">{fiyatGoster(oge.price_cents, oge.currency)}</span>
          </span>
        ) : (
          <span className="text-xs font-extrabold text-emerald-700">{fiyatGoster(oge.price_cents, oge.currency)} (yeni)</span>
        )}
      </td>
      <td className="px-3 py-2">
        {priceEksik ? (
          <span className="text-xs text-muted">Atlanacak — fiyat girilmeden aktarılamaz</span>
        ) : (
          <select
            value={karar.action}
            onChange={(e) => {
              const action = e.target.value as Karar['action'];
              onKararDegistir(action === 'update' ? { action, targetId: olasiEslesme?.id } : { action });
            }}
            className="min-h-9 rounded-lg border border-border bg-bg px-2 py-1 text-xs font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          >
            {olasiEslesme && <option value="update">Mevcut ürünü güncelle</option>}
            <option value="create">Ayrı yeni ürün olarak ekle</option>
            <option value="skip">Atla</option>
          </select>
        )}
      </td>
    </tr>
  );
}

// ─── Sonuç ─────────────────────────────────────────────────────────────────

function SonucAlani({ sonuc, onYeniAnaliz }: { sonuc: { created: number; updated: number; skipped: number }; onYeniAnaliz: () => void }) {
  return (
    <PanelBolumKarti>
      <div className="flex flex-col items-center gap-4 py-8 text-center">
        <span className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-50 text-emerald-700">
          <CheckIcon />
        </span>
        <p className="text-sm font-extrabold text-textStrong">Menüye aktarım tamamlandı</p>
        <div className="flex gap-6 text-xs font-bold text-muted">
          <span><span className="text-base font-black text-textStrong">{sonuc.created}</span> yeni oluşturuldu</span>
          <span><span className="text-base font-black text-textStrong">{sonuc.updated}</span> güncellendi</span>
          <span><span className="text-base font-black text-textStrong">{sonuc.skipped}</span> atlandı</span>
        </div>
        <PanelActionButton variant="secondary" onClick={onYeniAnaliz}>Yeni Analiz Başlat</PanelActionButton>
      </div>
    </PanelBolumKarti>
  );
}

function CheckIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 6 9 17l-5-5" />
    </svg>
  );
}
