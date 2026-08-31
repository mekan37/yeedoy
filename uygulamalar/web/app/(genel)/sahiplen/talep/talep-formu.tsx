'use client';

import { useState, useRef } from 'react';
import { useRouter } from 'next/navigation';

interface TalepFormuProps {
  businessId: string;
}

const ACCEPTED = '.pdf,.jpg,.jpeg,.png,.webp';
const MAX_MB   = 10;

export function TalepFormu({ businessId }: TalepFormuProps) {
  const router   = useRouter();
  const fileRef  = useRef<HTMLInputElement>(null);

  const [fullName, setFullName] = useState('');
  const [phone,    setPhone]    = useState('');
  const [note,     setNote]     = useState('');
  const [file,     setFile]     = useState<File | null>(null);
  const [fileErr,  setFileErr]  = useState('');
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState('');

  function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    setFileErr('');
    const f = e.target.files?.[0] ?? null;
    if (!f) { setFile(null); return; }
    if (f.size > MAX_MB * 1024 * 1024) {
      setFileErr(`Dosya ${MAX_MB} MB'tan büyük olamaz.`);
      setFile(null);
      return;
    }
    setFile(f);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!fullName.trim() || !phone.trim()) {
      setError('Ad soyad ve telefon zorunludur.');
      return;
    }

    setLoading(true);
    try {
      // 1. Dosya varsa yükle
      let evidenceUrl: string | null = null;
      let evidencePath: string | null = null;
      if (file) {
        const fd = new FormData();
        fd.append('file', file);
        const res  = await fetch('/sunucu/sahiplik-kaniti-yukle', { method: 'POST', body: fd });
        const data = await res.json();
        if (!res.ok) {
          setError(data.error ?? 'Dosya yüklenemedi.');
          setLoading(false);
          return;
        }
        evidenceUrl = data.url;
        evidencePath = data.path;
      }

      // 2. Talebi gönder
      const res = await fetch('/sunucu/sahiplik-talebi', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ businessId, fullName, phone, note, evidenceUrl, evidencePath }),
      });
      const data = await res.json();

      if (!res.ok) {
        setError(data.error ?? 'Talep gönderilemedi.');
        setLoading(false);
        return;
      }

      router.push('/sahip/gosterge-panosu?bilgi=talep_alindi');
    } catch {
      setError('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="flex flex-col gap-1.5">
        <label className="text-xs font-extrabold text-muted">Ad Soyad *</label>
        <input
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          required
          placeholder="Adınız ve soyadınız"
          className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
        />
      </div>

      <div className="flex flex-col gap-1.5">
        <label className="text-xs font-extrabold text-muted">Telefon *</label>
        <input
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          type="tel"
          required
          placeholder="05XX XXX XX XX"
          className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
        />
      </div>

      {/* Dosya yükleme */}
      <div className="flex flex-col gap-1.5">
        <label className="text-xs font-extrabold text-muted">
          Sahiplik Kanıtı{' '}
          <span className="font-normal text-muted">(opsiyonel · maks. {MAX_MB} MB)</span>
        </label>
        <p className="text-xs text-muted">
          Vergi levhası, kira sözleşmesi veya resmi yazışma. PDF, JPG ya da PNG olarak yükleyin.
        </p>

        <input
          ref={fileRef}
          type="file"
          accept={ACCEPTED}
          onChange={handleFile}
          className="hidden"
        />

        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          className="flex items-center gap-3 rounded-xl border-2 border-dashed border-border bg-bg px-4 py-4 text-sm text-muted transition-colors hover:border-primary/40 hover:bg-primary/4"
        >
          <UploadIcon />
          <span className="font-bold">
            {file ? file.name : 'Dosya seç veya sürükle…'}
          </span>
          {file && (
            <span className="ml-auto text-xs text-muted">
              {(file.size / 1024 / 1024).toFixed(1)} MB
            </span>
          )}
        </button>

        {fileErr && <p className="text-xs font-bold text-red-600">{fileErr}</p>}
        {file && (
          <button
            type="button"
            onClick={() => { setFile(null); if (fileRef.current) fileRef.current.value = ''; }}
            className="self-start text-xs font-bold text-muted hover:text-red-600"
          >
            × Dosyayı kaldır
          </button>
        )}
      </div>

      <div className="flex flex-col gap-1.5">
        <label className="text-xs font-extrabold text-muted">
          Ek Not <span className="font-normal text-muted">(opsiyonel)</span>
        </label>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          rows={2}
          placeholder="Eklemek istediğiniz bilgi varsa yazın…"
          className="rounded-xl border border-border bg-bg px-3 py-2.5 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
        />
      </div>

      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-800">
        <p className="font-extrabold">Talep süreci</p>
        <p className="mt-1">
          Talebiniz gönderildikten sonra admin ekibimiz inceleyecek. Onay öncesinde
          panele giriş yapabilirsiniz, ancak menü yayınlama onay sonrasında aktif olur.
        </p>
      </div>

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-bold text-red-700">
          {error}
        </div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-xl bg-primary py-3.5 text-sm font-black text-white transition-opacity hover:opacity-90 disabled:opacity-60"
      >
        {loading ? 'Gönderiliyor…' : 'Talebi Gönder →'}
      </button>
    </form>
  );
}

function UploadIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="17 8 12 3 7 8" />
      <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
  );
}
