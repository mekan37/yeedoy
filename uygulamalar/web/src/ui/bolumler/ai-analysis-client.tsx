'use client';

import { useState } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';

// ─── Types ────────────────────────────────────────────────────────────────────

export type Business = { id: string; name: string };

type AnalysisItem = {
  id: string;
  ocr_job_id: string | null;
  source_text: string;
  normalized_text: string | null;
  ingredients_json: string[] | null;
  allergens_json: string[] | null;
  calorie_min: number | null;
  calorie_max: number | null;
  confidence: number;
  requires_review: boolean;
  status: string;
  ai_model: string | null;
};

type Phase =
  | { tag: 'idle' }
  | { tag: 'loading' }
  | { tag: 'results'; items: AnalysisItem[] }
  | { tag: 'error'; message: string };

interface Props {
  businesses: Business[];
}

// ─── Main component ───────────────────────────────────────────────────────────

export function AiAnalysisClient({ businesses }: Props) {
  const [phase, setPhase] = useState<Phase>({ tag: 'idle' });
  const [selectedBizId, setSelectedBizId] = useState(
    businesses[0]?.id ?? '',
  );
  const [inputMode, setInputMode] = useState<'file_url' | 'raw_text'>(
    'file_url',
  );
  const [fileUrl, setFileUrl] = useState('');
  const [rawText, setRawText] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedBizId) return;

    const body: Record<string, string> = { business_id: selectedBizId };
    if (inputMode === 'file_url') {
      if (!fileUrl.trim()) return;
      body.file_url = fileUrl.trim();
    } else {
      if (!rawText.trim()) return;
      body.raw_text = rawText.trim();
    }

    setPhase({ tag: 'loading' });

    try {
      const res = await fetch('/api/owner/ai-analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      const json = (await res.json()) as {
        data?: { job_id: string; item_count: number };
        error?: string;
      };

      if (!res.ok || !json.data) {
        setPhase({
          tag: 'error',
          message:
            errorLabel(json.error) ??
            'Bir hata oluştu. Lütfen tekrar deneyin.',
        });
        return;
      }

      const jobId = json.data.job_id;

      const supabase = createSupabaseBrowserClient();
      const { data: items, error: fetchError } = await (supabase as any)
        .from('menu_item_ai_analysis')
        .select('*')
        .eq('ocr_job_id', jobId);

      if (fetchError) {
        setPhase({ tag: 'error', message: 'Sonuçlar alınamadı.' });
        return;
      }

      setPhase({
        tag: 'results',
        items: (items ?? []) as AnalysisItem[],
      });
    } catch {
      setPhase({ tag: 'error', message: 'Ağ hatası. Lütfen tekrar deneyin.' });
    }
  }

  if (businesses.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-6 text-center">
        <p className="text-sm text-muted">
          AI analizi için önce bir işletme eklemeniz gerekiyor.
        </p>
      </div>
    );
  }

  if (phase.tag === 'loading') {
    return (
      <div className="flex flex-col items-center gap-4 py-16">
        <LoadingSpinner />
        <p className="text-sm font-[700] text-textStrong">
          Menünüz analiz ediliyor...
        </p>
        <p className="text-xs text-muted">
          Bu işlem 30–90 saniye sürebilir.
        </p>
      </div>
    );
  }

  if (phase.tag === 'error') {
    return (
      <div className="flex flex-col gap-4">
        <div className="rounded-xl border border-rose-200 bg-rose-50 p-4">
          <p className="text-sm font-[800] text-rose-800">Hata</p>
          <p className="mt-0.5 text-sm text-rose-700">{phase.message}</p>
        </div>
        <button
          type="button"
          onClick={() => setPhase({ tag: 'idle' })}
          className="self-start text-xs text-muted hover:text-primary"
        >
          Geri don
        </button>
      </div>
    );
  }

  if (phase.tag === 'results') {
    return (
      <ResultsView
        items={phase.items}
        onBack={() => setPhase({ tag: 'idle' })}
      />
    );
  }

  // idle — input form
  const isSubmitDisabled =
    !selectedBizId ||
    (inputMode === 'file_url' ? !fileUrl.trim() : !rawText.trim());

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-5">
      {/* Business select */}
      <div className="flex flex-col gap-1.5">
        <label
          className="text-xs font-[700] text-muted"
          htmlFor="biz-select"
        >
          İşletme
        </label>
        <select
          id="biz-select"
          value={selectedBizId}
          onChange={(e) => setSelectedBizId(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong outline-none focus:border-primary focus:ring-1 focus:ring-primary"
        >
          {businesses.map((b) => (
            <option key={b.id} value={b.id}>
              {b.name}
            </option>
          ))}
        </select>
      </div>

      {/* Input mode toggle */}
      <div className="flex gap-2">
        <button
          type="button"
          onClick={() => setInputMode('file_url')}
          className={`rounded-full border px-3 py-1 text-xs font-[700] transition ${
            inputMode === 'file_url'
              ? 'border-primary bg-red-50 text-primary'
              : 'border-border text-muted hover:border-primary/30'
          }`}
        >
          Gorsel URL
        </button>
        <button
          type="button"
          onClick={() => setInputMode('raw_text')}
          className={`rounded-full border px-3 py-1 text-xs font-[700] transition ${
            inputMode === 'raw_text'
              ? 'border-primary bg-red-50 text-primary'
              : 'border-border text-muted hover:border-primary/30'
          }`}
        >
          Ham Metin
        </button>
      </div>

      {/* Conditional input */}
      {inputMode === 'file_url' ? (
        <div className="flex flex-col gap-1.5">
          <label
            className="text-xs font-[700] text-muted"
            htmlFor="file-url"
          >
            Menu Gorseli URL
          </label>
          <input
            id="file-url"
            type="url"
            value={fileUrl}
            onChange={(e) => setFileUrl(e.target.value)}
            placeholder="https://..."
            className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
        </div>
      ) : (
        <div className="flex flex-col gap-1.5">
          <label
            className="text-xs font-[700] text-muted"
            htmlFor="raw-text"
          >
            Ham Menu Metni
          </label>
          <textarea
            id="raw-text"
            value={rawText}
            onChange={(e) => setRawText(e.target.value)}
            rows={8}
            placeholder="Menu ogelerini buraya yapistirin..."
            className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
        </div>
      )}

      <button
        type="submit"
        disabled={isSubmitDisabled}
        className="self-start rounded-xl bg-primary px-5 py-2.5 text-sm font-[800] text-white transition hover:bg-red-900 disabled:opacity-50"
      >
        Analiz Et
      </button>
    </form>
  );
}

// ─── Results view ─────────────────────────────────────────────────────────────

function ResultsView({
  items,
  onBack,
}: {
  items: AnalysisItem[];
  onBack: () => void;
}) {
  if (items.length === 0) {
    return (
      <div className="flex flex-col gap-4">
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
          <p className="text-sm font-[800] text-amber-800">Sonuc bulunamadi</p>
          <p className="mt-0.5 text-xs text-amber-700">
            Analiz tamamlandi ancak menu ogesi tespit edilemedi.
          </p>
        </div>
        <button
          type="button"
          onClick={onBack}
          className="self-start text-xs text-muted hover:text-primary"
        >
          Geri don
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <p className="text-sm font-[800] text-textStrong">
          {items.length} urun tespit edildi
        </p>
        <button
          type="button"
          onClick={onBack}
          className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong"
        >
          Geri
        </button>
      </div>

      <div className="flex flex-col gap-3">
        {items.map((item) => (
          <AnalysisItemCard key={item.id} item={item} />
        ))}
      </div>
    </div>
  );
}

// ─── Item card ────────────────────────────────────────────────────────────────

function AnalysisItemCard({ item }: { item: AnalysisItem }) {
  const allergens = item.allergens_json ?? [];
  const hasCalories = item.calorie_min !== null || item.calorie_max !== null;

  return (
    <div className="rounded-xl border border-border bg-card p-4 flex flex-col gap-2">
      <div className="flex items-start justify-between">
        <p className="font-[800] text-textStrong">
          {item.normalized_text ?? item.source_text}
        </p>
        {item.requires_review && (
          <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-[700] text-amber-700">
            Inceleme Gerekli
          </span>
        )}
      </div>
      {allergens.length > 0 && (
        <div className="flex gap-1 flex-wrap">
          {allergens.map((a) => (
            <span
              key={a}
              className="rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-[700] text-red-600"
            >
              {a}
            </span>
          ))}
        </div>
      )}
      {hasCalories && (
        <p className="text-xs text-muted">
          {item.calorie_min ?? '?'}&#x2013;{item.calorie_max ?? '?'} kcal
        </p>
      )}
      <p className="text-xs text-muted">Kaynak: {item.source_text}</p>
    </div>
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function errorLabel(code: string | undefined): string | undefined {
  switch (code) {
    case 'rate_limited':
      return 'Saatlik limit asildi. Lutfen daha sonra tekrar deneyin.';
    case 'unauthorized':
    case 'session_expired':
      return 'Oturumunuz sonlanmis. Sayfayi yenileyip tekrar deneyin.';
    case 'forbidden':
      return 'Bu isletme icin yetkiniz yok.';
    case 'business_not_found':
      return 'Isletme bulunamadi.';
    case 'job_creation_failed':
      return 'Analiz gorevi olusturulamadi. Lutfen tekrar deneyin.';
    case 'already_processing':
      return 'Bu gorev zaten isleniyor. Lutfen bekleyin.';
    case 'already_completed':
      return 'Bu gorev zaten tamamlandi.';
    case 'no_text_extracted':
      return 'Menu gorselinden metin cikarılamadi. Daha net bir fotograf deneyin.';
    case 'no_items_detected':
      return 'Menude urun tespit edilemedi. Ham metni kontrol edin.';
    case 'analysis_timeout':
      return 'Analiz zaman asimina ugradi. Lutfen tekrar deneyin.';
    case 'analysis_failed':
      return 'Analiz su an kullanılamıyor. Lutfen tekrar deneyin.';
    default:
      return undefined;
  }
}

// ─── Icons ────────────────────────────────────────────────────────────────────

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
