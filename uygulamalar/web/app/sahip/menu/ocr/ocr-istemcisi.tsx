'use client';

import { useState, useTransition } from 'react';
import { ocrTaramasiBaslat, ocrTaramaDurumu, ocrOnerisiniMenuyeEkle, ocrOnerisiniReddet } from './ocr-islemleri';

type Analiz = {
  id: string;
  sourceText: string;
  normalizedText: string | null;
  allergens: string[];
  calorieMin: number | null;
  calorieMax: number | null;
  confidence: number;
  status: string;
};

export function OcrIstemcisi({
  businessId,
  sections,
}: {
  businessId: string;
  sections: Array<{ id: string; label: string }>;
}) {
  const [isPending, startTransition] = useTransition();
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [jobId, setJobId] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const [analizler, setAnalizler] = useState<Analiz[]>([]);
  const [sectionId, setSectionId] = useState(sections[0]?.id ?? '');

  async function uploadAndScan(file: File | null) {
    if (!file) return;
    setUploading(true);
    setError(null);

    try {
      const formData = new FormData();
      formData.set('businessId', businessId);
      formData.set('type', 'item');
      formData.set('file', file);

      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body: formData });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;
      if (!response.ok || !payload?.data?.url) throw new Error('upload_failed');

      const result = await ocrTaramasiBaslat(businessId, payload.data.url, file.name);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setJobId(result.jobId);
      await pollStatus(result.jobId);
    } catch {
      setError('Yükleme başarısız oldu.');
    } finally {
      setUploading(false);
    }
  }

  async function pollStatus(id: string) {
    const result = await ocrTaramaDurumu(businessId, id);
    if ('error' in result) {
      setError(result.error);
      return;
    }
    setStatus(result.status);
    setAnalizler(result.analizler);
    if (result.status === 'queued' || result.status === 'processing') {
      setTimeout(() => pollStatus(id), 3000);
    }
  }

  function ekle(analysisId: string) {
    if (!sectionId) {
      setError('Önce bir bölüm seçin.');
      return;
    }
    startTransition(async () => {
      const result = await ocrOnerisiniMenuyeEkle(businessId, analysisId, sectionId);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setAnalizler((prev) => prev.filter((a) => a.id !== analysisId));
    });
  }

  function reddet(analysisId: string) {
    startTransition(async () => {
      const result = await ocrOnerisiniReddet(businessId, analysisId);
      if (result?.error) {
        setError(result.error);
        return;
      }
      setAnalizler((prev) => prev.filter((a) => a.id !== analysisId));
    });
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6 p-6">
      <h1 className="text-2xl font-black text-textStrong">Fotoğraftan Menü Oluştur</h1>

      <div className="rounded-2xl border border-dashed border-border bg-card p-6">
        <label className="inline-flex cursor-pointer items-center rounded-xl border border-border bg-bg px-4 py-3 text-sm font-bold text-textStrong hover:bg-white">
          {uploading ? 'Yükleniyor...' : 'Menü fotoğrafı seç'}
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            disabled={uploading}
            onChange={(event) => uploadAndScan(event.target.files?.[0] ?? null)}
            className="sr-only"
          />
        </label>
        {status && <p className="mt-3 text-xs font-bold text-muted">Durum: {status}</p>}
      </div>

      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

      {analizler.length > 0 && (
        <div className="space-y-3">
          <label className="text-xs font-bold text-muted">Eklenecek bölüm</label>
          <select
            value={sectionId}
            onChange={(event) => setSectionId(event.target.value)}
            className="w-full rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
          >
            {sections.map((section) => (
              <option key={section.id} value={section.id}>
                {section.label}
              </option>
            ))}
          </select>

          <div className="divide-y divide-border rounded-2xl border border-border bg-card">
            {analizler.map((analiz) => (
              <div key={analiz.id} className="flex items-center justify-between gap-4 px-5 py-3">
                <div className="min-w-0 flex-1">
                  <p className="font-semibold text-textStrong">{analiz.normalizedText ?? analiz.sourceText}</p>
                  <p className="text-xs text-muted">
                    {analiz.allergens.length > 0 ? `${analiz.allergens.length} alerjen` : 'Alerjen yok'}
                    {analiz.calorieMin ? ` · ${analiz.calorieMin}-${analiz.calorieMax} kcal` : ''}
                  </p>
                </div>
                <div className="flex shrink-0 gap-2">
                  <button
                    onClick={() => ekle(analiz.id)}
                    disabled={isPending}
                    className="rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-white disabled:opacity-60"
                  >
                    Menüye Ekle
                  </button>
                  <button
                    onClick={() => reddet(analiz.id)}
                    disabled={isPending}
                    className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted disabled:opacity-60"
                  >
                    Reddet
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
