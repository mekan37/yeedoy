'use client';

import { useState, useTransition } from 'react';
import {
  analizBaslat,
  analiziOnayla,
  analiziReddet,
  analizSonuclariniGetir,
  type AnalizBaslatSonucu,
  type AnalizSonucu,
  type OcrJobDurumu,
} from './yapay-zeka-analiz-islemi';

// ─── Types ─────────────────────────────────────────────────────────────────────

interface Props {
  businessId: string;
  businessName: string;
  initialJobs: OcrJobDurumu[];
}

type KartDurumu =
  | { tag: 'bekleniyor' }
  | { tag: 'analiz_ediliyor' }
  | { tag: 'tamamlandi'; item_count: number }
  | { tag: 'hata'; mesaj: string; providerEksik?: boolean }
  | { tag: 'sonuclar'; sonuclar: AnalizSonucu[] };

// ─── Helpers ───────────────────────────────────────────────────────────────────

const ALLERGEN_TR: Record<string, string> = {
  gluten: 'Gluten', crustaceans: 'Kabuklu deniz ürünleri', eggs: 'Yumurta',
  fish: 'Balık', peanuts: 'Yer fıstığı', soybeans: 'Soya', milk: 'Süt',
  nuts: 'Sert kabuklu yemişler', celery: 'Kereviz', mustard: 'Hardal',
  sesame: 'Susam', sulphites: 'Kükürt dioksit', lupin: 'Acı bakla',
  molluscs: 'Yumuşakçalar',
};

const STATUS_LABEL: Record<string, string> = {
  queued: 'Sırada', processing: 'İşleniyor', completed: 'Tamamlandı', failed: 'Başarısız',
};

const STATUS_CLS: Record<string, string> = {
  queued: 'bg-zinc-100 text-zinc-600',
  processing: 'bg-amber-50 text-amber-700',
  completed: 'bg-emerald-50 text-emerald-700',
  failed: 'bg-rose-50 text-rose-700',
};

function ConfidenceBadge({ value }: { value: number }) {
  const pct = Math.round(value * 100);
  const cls =
    pct >= 85
      ? 'bg-emerald-50 text-emerald-700'
      : pct >= 60
      ? 'bg-amber-50 text-amber-700'
      : 'bg-rose-50 text-rose-700';
  return (
    <span className={`inline-flex items-center rounded-lg px-2 py-0.5 text-[11px] font-bold ${cls}`}>
      %{pct}
    </span>
  );
}

// ─── Job list section ──────────────────────────────────────────────────────────

function JobListesi({
  jobs,
  onAnalizEt,
  aktifJobId,
}: {
  jobs: OcrJobDurumu[];
  onAnalizEt: (jobId: string) => void;
  aktifJobId: string | null;
}) {
  if (jobs.length === 0) {
    return (
      <p className="py-6 text-center text-sm text-muted">
        Henüz OCR görevi oluşturulmamış. Menü görseli yükleyerek başlayın.
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-2">
      {jobs.map((job) => (
        <div
          key={job.id}
          className="flex flex-col gap-2 rounded-xl border border-border bg-card p-4 sm:flex-row sm:items-center sm:justify-between"
        >
          <div className="flex flex-col gap-1">
            <p className="text-sm font-bold text-textStrong">
              {job.file_name ?? `Görev ${job.id.slice(0, 8)}`}
            </p>
            <div className="flex items-center gap-2">
              <span
                className={`inline-flex items-center rounded-lg px-2 py-0.5 text-[11px] font-bold ${STATUS_CLS[job.status] ?? 'bg-zinc-100 text-zinc-600'}`}
              >
                {STATUS_LABEL[job.status] ?? job.status}
              </span>
              {job.item_count !== null && (
                <span className="text-xs text-muted">{job.item_count} ürün</span>
              )}
              {job.error_message && (
                <span className="text-xs text-rose-600">{job.error_message.slice(0, 60)}</span>
              )}
            </div>
            <p className="text-[11px] text-muted">
              {new Date(job.created_at).toLocaleString('tr-TR')}
            </p>
          </div>

          {(job.status === 'queued' || job.status === 'failed') && (
            <button
              onClick={() => onAnalizEt(job.id)}
              disabled={aktifJobId === job.id}
              className="shrink-0 rounded-xl bg-primary px-4 py-2 text-xs font-extrabold text-white disabled:opacity-50"
            >
              {aktifJobId === job.id ? 'Analiz ediliyor...' : 'Analiz Et'}
            </button>
          )}
          {job.status === 'completed' && (
            <button
              onClick={() => onAnalizEt(job.id)}
              className="shrink-0 rounded-xl border border-border bg-card px-4 py-2 text-xs font-bold text-textStrong"
            >
              Sonuçları Gör
            </button>
          )}
        </div>
      ))}
    </div>
  );
}

// ─── Analysis results ──────────────────────────────────────────────────────────

function AnalizSonucListesi({
  sonuclar,
  onGeri,
}: {
  sonuclar: AnalizSonucu[];
  onGeri: () => void;
}) {
  const [onaylananlar, setOnaylananlar] = useState<Set<string>>(new Set());
  const [reddedilenler, setReddedilenler] = useState<Set<string>>(new Set());
  const [islemdeId, setIslemdeId] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const handleOnayla = (id: string) => {
    setIslemdeId(id);
    startTransition(async () => {
      const res = await analiziOnayla(id);
      if (res.basarili) setOnaylananlar((prev) => new Set([...prev, id]));
      setIslemdeId(null);
    });
  };

  const handleReddet = (id: string) => {
    setIslemdeId(id);
    startTransition(async () => {
      const res = await analiziReddet(id);
      if (res.basarili) setReddedilenler((prev) => new Set([...prev, id]));
      setIslemdeId(null);
    });
  };

  const bekleyenler = sonuclar.filter((s) => s.requires_review && !onaylananlar.has(s.id) && !reddedilenler.has(s.id));
  const digerler = sonuclar.filter((s) => !s.requires_review || onaylananlar.has(s.id) || reddedilenler.has(s.id));

  return (
    <div className="flex flex-col gap-5">
      {/* Özet */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-extrabold text-textStrong">{sonuclar.length} ürün tespit edildi</p>
          <p className="text-xs text-muted">
            {bekleyenler.length} inceleme bekliyor · {onaylananlar.size} onaylı · {reddedilenler.size} reddedildi
          </p>
        </div>
        <button
          onClick={onGeri}
          className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-bold text-textStrong"
        >
          Geri
        </button>
      </div>

      {/* İnceleme bekleyenler */}
      {bekleyenler.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-[11px] font-extrabold uppercase tracking-wide text-muted">
            Inceleme Bekleyenler
          </p>
          {bekleyenler.map((s) => (
            <AnalizSatiri
              key={s.id}
              item={s}
              onOnayla={() => handleOnayla(s.id)}
              onReddet={() => handleReddet(s.id)}
              disabled={islemdeId === s.id || isPending}
            />
          ))}
        </div>
      )}

      {/* Diğerleri */}
      {digerler.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-[11px] font-extrabold uppercase tracking-wide text-muted">
            Diger Urunler
          </p>
          {digerler.map((s) => (
            <AnalizSatiri
              key={s.id}
              item={s}
              onOnayla={onaylananlar.has(s.id) ? undefined : () => handleOnayla(s.id)}
              onReddet={reddedilenler.has(s.id) ? undefined : () => handleReddet(s.id)}
              disabled={islemdeId === s.id || isPending}
              onayli={onaylananlar.has(s.id)}
              reddedildi={reddedilenler.has(s.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function AnalizSatiri({
  item,
  onOnayla,
  onReddet,
  disabled,
  onayli,
  reddedildi,
}: {
  item: AnalizSonucu;
  onOnayla?: () => void;
  onReddet?: () => void;
  disabled?: boolean;
  onayli?: boolean;
  reddedildi?: boolean;
}) {
  const [acik, setAcik] = useState(false);
  const allergenler = (item.allergens_json ?? [])
    .map((a) => ALLERGEN_TR[a] ?? a)
    .join(', ');

  return (
    <div
      className={`rounded-xl border p-4 transition-colors ${
        onayli
          ? 'border-emerald-200 bg-emerald-50'
          : reddedildi
          ? 'border-rose-200 bg-rose-50'
          : 'border-border bg-card'
      }`}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <p className="text-sm font-bold text-textStrong">
              {item.normalized_text ?? item.source_text}
            </p>
            <ConfidenceBadge value={item.confidence} />
            {onayli && (
              <span className="text-[11px] font-bold text-emerald-700">Onaylandi</span>
            )}
            {reddedildi && (
              <span className="text-[11px] font-bold text-rose-700">Reddedildi</span>
            )}
          </div>
          {allergenler && (
            <p className="mt-1 text-xs text-muted">Alerjenler: {allergenler}</p>
          )}
          {(item.calorie_min !== null || item.calorie_max !== null) && (
            <p className="text-xs text-muted">
              {item.calorie_min ?? '?'}–{item.calorie_max ?? '?'} kcal
            </p>
          )}
        </div>

        <div className="flex shrink-0 flex-col items-end gap-1.5">
          {!onayli && !reddedildi && onOnayla && (
            <button
              onClick={onOnayla}
              disabled={disabled}
              className="rounded-lg bg-emerald-600 px-3 py-1 text-[11px] font-extrabold text-white disabled:opacity-50"
            >
              Onayla
            </button>
          )}
          {!onayli && !reddedildi && onReddet && (
            <button
              onClick={onReddet}
              disabled={disabled}
              className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-1 text-[11px] font-extrabold text-rose-700 disabled:opacity-50"
            >
              Reddet
            </button>
          )}
          <button
            onClick={() => setAcik((p) => !p)}
            className="text-[11px] text-muted hover:text-primary"
          >
            {acik ? 'Kapat' : 'Ham metin'}
          </button>
        </div>
      </div>

      {acik && (
        <div className="mt-3 rounded-lg border border-border bg-zinc-50 px-3 py-2">
          <p className="text-[11px] font-bold text-muted">Kaynak metin</p>
          <p className="mt-0.5 text-xs text-textStrong">{item.source_text}</p>
          {item.ingredients_json?.length > 0 && (
            <>
              <p className="mt-2 text-[11px] font-bold text-muted">İcindekiler</p>
              <p className="text-xs text-textStrong">{item.ingredients_json.join(', ')}</p>
            </>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Main card ─────────────────────────────────────────────────────────────────

export function YapayZekaAnalizKarti({ businessId, businessName, initialJobs }: Props) {
  const [durum, setDurum] = useState<KartDurumu>({ tag: 'bekleniyor' });
  const [jobs] = useState<OcrJobDurumu[]>(initialJobs);
  const [aktifJobId, setAktifJobId] = useState<string | null>(null);

  const handleAnalizEt = async (jobId: string) => {
    setAktifJobId(jobId);
    setDurum({ tag: 'analiz_ediliyor' });

    const sonuc: AnalizBaslatSonucu = await analizBaslat(businessId, jobId);

    if (sonuc.basarili) {
      // Edge fn tamamlandı — sonuçları çek
      const listeSonuc = await analizSonuclariniGetir(businessId, jobId);
      if (listeSonuc.basarili && listeSonuc.veri.length > 0) {
        setDurum({ tag: 'sonuclar', sonuclar: listeSonuc.veri });
      } else {
        setDurum({ tag: 'tamamlandi', item_count: sonuc.item_count });
      }
    } else {
      setDurum({
        tag: 'hata',
        mesaj: sonuc.hata,
        providerEksik: sonuc.providerYapılandırılmamış,
      });
    }

    setAktifJobId(null);
  };

  const handleSonuclariGor = async (jobId: string) => {
    const listeSonuc = await analizSonuclariniGetir(businessId, jobId);
    if (listeSonuc.basarili) {
      setDurum({ tag: 'sonuclar', sonuclar: listeSonuc.veri });
    } else {
      setDurum({ tag: 'hata', mesaj: listeSonuc.hata });
    }
  };

  const handleJobIslem = async (jobId: string) => {
    const job = jobs.find((j) => j.id === jobId);
    if (!job) return;

    if (job.status === 'completed') {
      await handleSonuclariGor(jobId);
    } else {
      await handleAnalizEt(jobId);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      {/* Header */}
      <div className="flex items-start gap-3">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[rgba(127,29,29,0.08)]">
          <SparklesIcon />
        </div>
        <div>
          <h3 className="text-base font-black text-textStrong">AI Menü Analizi</h3>
          <p className="text-sm text-muted">
            {businessName} — OCR ile çıkarılan menü metni yapay zeka tarafından analiz edilir.
            Alerjenler, kalori tahmini ve içerik normalleştirme yapılır.
          </p>
        </div>
      </div>

      {/* İçerik */}
      {durum.tag === 'bekleniyor' && (
        <JobListesi
          jobs={jobs}
          onAnalizEt={handleJobIslem}
          aktifJobId={aktifJobId}
        />
      )}

      {durum.tag === 'analiz_ediliyor' && (
        <div className="flex flex-col items-center gap-3 py-10">
          <LoadingSpinner />
          <p className="text-sm font-bold text-textStrong">Analiz ediliyor...</p>
          <p className="text-xs text-muted">
            Görsel OCR ve AI analizi birlikte çalışıyor. Bu 30–90 saniye sürebilir.
          </p>
        </div>
      )}

      {durum.tag === 'tamamlandi' && (
        <div className="flex flex-col gap-4">
          <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4">
            <p className="text-sm font-extrabold text-emerald-800">
              Analiz tamamlandı — {durum.item_count} ürün tespit edildi
            </p>
            <p className="mt-1 text-xs text-emerald-700">
              Sonuçlar veritabanına kaydedildi. İşletme sonuçlarını görmek için ilgili görev satırına tıklayın.
            </p>
          </div>
          <button
            onClick={() => setDurum({ tag: 'bekleniyor' })}
            className="self-start text-xs text-muted hover:text-primary"
          >
            Geri don
          </button>
        </div>
      )}

      {durum.tag === 'hata' && (
        <div className="flex flex-col gap-4">
          {durum.providerEksik ? (
            <div className="rounded-xl border border-border bg-card p-4">
              <p className="text-sm font-extrabold text-textStrong">
                AI analiz motoru aktif degil
              </p>
              <p className="mt-1 text-xs text-muted">
                Servis yakında aktive edilecek. Şimdilikleri OCR görevini sırada bekleyin.
              </p>
            </div>
          ) : (
            <div className="rounded-xl border border-rose-200 bg-rose-50 p-4">
              <p className="text-sm font-extrabold text-rose-800">Hata</p>
              <p className="mt-0.5 text-sm text-rose-700">{durum.mesaj}</p>
            </div>
          )}
          <button
            onClick={() => setDurum({ tag: 'bekleniyor' })}
            className="self-start text-xs text-muted hover:text-primary"
          >
            Geri don
          </button>
        </div>
      )}

      {durum.tag === 'sonuclar' && (
        <AnalizSonucListesi
          sonuclar={durum.sonuclar}
          onGeri={() => setDurum({ tag: 'bekleniyor' })}
        />
      )}
    </div>
  );
}

// ─── Icons ─────────────────────────────────────────────────────────────────────

function SparklesIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="text-primary"
    >
      <path d="M12 3l1.88 5.76L20 9l-5.12 3.73L16.76 18 12 14.6 7.24 18l1.88-5.27L4 9l6.12-.24L12 3z" />
    </svg>
  );
}

function LoadingSpinner() {
  return (
    <svg
      className="h-8 w-8 animate-spin text-primary"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
      />
    </svg>
  );
}
