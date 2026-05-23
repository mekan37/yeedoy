'use client';

import { useState, useRef } from 'react';
import Link from 'next/link';

type OcrSonuc = {
  tarih?: string | null;
  isletme?: string | null;
  toplam?: string | null;
  kdv?: string | null;
  kalemler?: Array<{ ad: string; adet?: number; fiyat: string; kategori?: string }>;
  guven?: number;
  restoranFisi?: boolean;
  model?: string;
  mesaj?: string | null;
  rawOcr?: string | null;
};

export default function MakbuzYuklePage() {
  const inputRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [sonuc, setSonuc] = useState<OcrSonuc | null>(null);
  const [error, setError] = useState<string | null>(null);

  function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0] ?? null;
    setFile(f);
    setSonuc(null);
    setError(null);
    if (f) {
      const reader = new FileReader();
      reader.onload = (ev) => setPreview(ev.target?.result as string);
      reader.readAsDataURL(f);
    } else {
      setPreview(null);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file) return;

    setLoading(true);
    setError(null);
    setSonuc(null);

    try {
      const form = new FormData();
      form.append('makbuz', file);

      const res = await fetch('/sunucu/makbuz-ocr', { method: 'POST', body: form });
      if (!res.ok) {
        const { error: msg } = await res.json().catch(() => ({ error: 'İşlem başarısız' }));
        throw new Error(msg ?? 'İşlem başarısız');
      }
      const data = await res.json();
      setSonuc(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
          ← Ana Sayfa
        </Link>
        <h1 className="mb-2 text-2xl font-[900] text-textStrong">Fişini Fotoğrafla</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Yemek fişinizin fotoğrafını çekin veya yükleyin. Fiyatları ve ürünleri otomatik okuyalım.
        </p>

        <form onSubmit={handleSubmit} className="grid gap-6">
          {/* Dropzone */}
          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            className="flex min-h-[200px] w-full flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-border bg-card p-6 text-center transition-colors hover:border-primary/50 hover:bg-cardAlt"
          >
            {preview ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={preview} alt="Makbuz önizleme" className="max-h-48 rounded-xl object-contain" />
            ) : (
              <>
                <svg viewBox="0 0 24 24" className="h-10 w-10 text-muted fill-none stroke-current" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                  <polyline points="17 8 12 3 7 8" />
                  <line x1="12" y1="3" x2="12" y2="15" />
                </svg>
                <p className="text-sm font-[900] text-textStrong">Fotoğraf seç veya sürükle</p>
                <p className="text-xs text-muted">JPG, PNG · Maks 8 MB</p>
              </>
            )}
          </button>
          <input
            ref={inputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp,image/heic"
            className="sr-only"
            onChange={onFileChange}
          />

          {file && (
            <p className="text-xs text-muted truncate">{file.name} · {(file.size / 1024).toFixed(0)} KB</p>
          )}

          <button
            type="submit"
            disabled={!file || loading}
            className="min-h-[52px] rounded-2xl text-sm font-[900] text-white disabled:opacity-50 disabled:cursor-not-allowed"
            style={{ background: 'var(--yd-gradient-primary)' }}
          >
            {loading ? 'Analiz ediliyor…' : 'Makbuzu Analiz Et'}
          </button>
        </form>

        {error && (
          <div className="mt-6 rounded-2xl border border-danger/20 bg-danger/[0.06] px-4 py-4">
            <p className="text-sm font-[900] text-danger">{error}</p>
          </div>
        )}

        {sonuc && (
          <div className="mt-6 rounded-2xl border border-border bg-card p-6">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-base font-[900] text-textStrong">Çıkarılan Bilgiler</h2>
              {sonuc.guven != null && sonuc.guven > 0 && (
                <GuvenBadge guven={sonuc.guven} />
              )}
            </div>
            {sonuc.mesaj && (
              <p className="mb-4 rounded-xl border border-warning/20 bg-warning/[0.08] px-3 py-2 text-xs text-muted">
                {sonuc.mesaj}
              </p>
            )}
            {sonuc.restoranFisi === false && (
              <p className="mb-4 rounded-xl border border-danger/20 bg-danger/[0.06] px-3 py-2 text-xs text-danger font-[700]">
                Bu görüntü bir restoran fişi gibi görünmüyor.
              </p>
            )}
            <div className="grid gap-3">
              {sonuc.isletme && <Row label="İşletme" value={sonuc.isletme} />}
              {sonuc.tarih && <Row label="Tarih" value={sonuc.tarih} />}
              {sonuc.kdv && <Row label="KDV" value={sonuc.kdv} />}
              {sonuc.toplam && <Row label="Toplam" value={sonuc.toplam} highlight />}
            </div>
            {sonuc.kalemler && sonuc.kalemler.length > 0 && (
              <div className="mt-4">
                <p className="mb-2 text-xs font-[900] uppercase text-muted">
                  Kalemler ({sonuc.kalemler.length})
                </p>
                <div className="grid gap-2">
                  {sonuc.kalemler.map((item, idx) => (
                    <div key={idx} className="flex items-center justify-between rounded-xl border border-border px-3 py-2">
                      <div className="flex items-center gap-2">
                        {item.adet && item.adet > 1 && (
                          <span className="text-xs font-[900] text-muted">{item.adet}×</span>
                        )}
                        <span className="text-sm text-textStrong">{item.ad}</span>
                        {item.kategori && item.kategori !== 'diger' && (
                          <span className="text-[10px] font-[700] text-muted opacity-60">{item.kategori}</span>
                        )}
                      </div>
                      <span className="text-sm font-[900] text-primary">{item.fiyat}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {sonuc.model && (
              <p className="mt-3 text-[10px] text-muted">
                Motor: {sonuc.model === 'gpt-4o-mini' ? 'GPT-4o Vision' : sonuc.model === 'deepseek-ocr' ? 'DeepSeek OCR' : sonuc.model}
              </p>
            )}
            {sonuc.rawOcr && (
              <details className="mt-3">
                <summary className="cursor-pointer text-[11px] font-[700] text-muted hover:text-primary">Ham OCR metnini göster</summary>
                <pre className="mt-2 overflow-x-auto rounded-xl bg-cardAlt p-3 text-[11px] leading-relaxed text-muted whitespace-pre-wrap">{sonuc.rawOcr}</pre>
              </details>
            )}
            <p className="mt-4 text-[11px] leading-relaxed text-muted">
              Bilgiler fişinizden otomatik okundu. Yanlış bir şey varsa düzelterek Yeedoy&apos;a katkı sağlayabilirsiniz.
            </p>
            <Link href="/katki" className="mt-3 inline-flex text-sm font-[900] text-primary hover:underline">
              Fiyatı onayla →
            </Link>
          </div>
        )}
      </div>
    </main>
  );
}

function Row({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  return (
    <div className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5">
      <span className="text-xs font-[900] uppercase text-muted">{label}</span>
      <span className={highlight ? 'text-base font-[900] text-primary' : 'text-sm font-[900] text-textStrong'}>{value}</span>
    </div>
  );
}

function GuvenBadge({ guven }: { guven: number }) {
  const pct = Math.round(guven * 100);
  const color = pct >= 80 ? 'text-success border-success/30 bg-success/10'
    : pct >= 60 ? 'text-warning border-warning/30 bg-warning/10'
    : 'text-muted border-border bg-cardAlt';
  return (
    <span className={`rounded-full border px-2.5 py-0.5 text-[11px] font-[900] ${color}`}>
      %{pct} güven
    </span>
  );
}
