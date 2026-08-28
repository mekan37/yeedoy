'use client';

import { useRef, useState } from 'react';
import { Camera, Image as ImageIcon, LoaderCircle, PenLine, Upload } from 'lucide-react';
import { updateBusinessBranding } from '../ayarlar-islemleri';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';

interface Props {
  businessId: string;
  initialLogoUrl: string | null;
  initialCoverUrl: string | null;
  businessName: string;
}

type UploadResponse = {
  ok?: boolean;
  error?: string;
  data?: { url?: string };
};

export function BrandingEditor({ businessId, initialLogoUrl, initialCoverUrl, businessName }: Props) {
  const [logoUrl, setLogoUrl]       = useState(initialLogoUrl);
  const [coverUrl, setCoverUrl]     = useState(initialCoverUrl);
  const [logoV, setLogoV]           = useState(0);
  const [coverV, setCoverV]         = useState(0);
  const [uploading, setUploading]   = useState<'logo' | 'cover' | null>(null);
  const [error, setError]           = useState<string | null>(null);

  const logoInputRef  = useRef<HTMLInputElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);

  async function handleUpload(file: File, type: 'logo' | 'cover') {
    setError(null);
    setUploading(type);
    try {
      const maxPx = type === 'logo' ? 512 : 1920;
      const compressed = await compressToWebP(file, maxPx);

      const fd = new FormData();
      fd.append('businessId', businessId);
      fd.append('type', type);
      fd.append('file', compressed);

      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body: fd });
      const result = await response.json().catch(() => null) as UploadResponse | null;

      if (!response.ok) {
        setError(
          result?.error === 'rate_limited' ? 'Çok fazla istek, bekleyin.' :
          result?.error === 'file_too_large' ? 'Dosya çok büyük.' :
          result?.error === 'invalid_mime_type' ? 'Desteklenmeyen dosya türü.' :
          result?.error === 'forbidden' ? 'Bu işletmeyi düzenleme yetkiniz yok.' : 'Yükleme başarısız.',
        );
        return;
      }

      const url = result?.data?.url;
      if (!url) throw new Error('invalid_upload_response');

      const persistResult = await updateBusinessBranding(businessId, type, url);
      if ('error' in persistResult) {
        setError(persistResult.error);
        return;
      }

      if (type === 'logo') { setLogoUrl(url); setLogoV((v) => v + 1); }
      else                 { setCoverUrl(url); setCoverV((v) => v + 1); }
    } catch (uploadError) {
      setError(
        uploadError instanceof Error && ['compress_failed', 'load_failed'].includes(uploadError.message)
          ? 'Görsel işlenemedi, farklı bir dosya deneyin.'
          : 'Yükleme sırasında bir bağlantı hatası oluştu. Lütfen tekrar deneyin.',
      );
    } finally {
      setUploading(null);
    }
  }

  function onFileChange(e: React.ChangeEvent<HTMLInputElement>, type: 'logo' | 'cover') {
    const f = e.target.files?.[0];
    if (f) handleUpload(f, type);
    e.target.value = '';
  }

  const coverSrc = coverUrl ? `${coverUrl}${coverV > 0 ? `?v=${coverV}` : ''}` : null;
  const logoSrc  = logoUrl  ? `${logoUrl}${logoV  > 0 ? `?v=${logoV}`  : ''}` : null;

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card">
      {/* ── Kapak ── */}
      <button
        type="button"
        className="group relative block h-[190px] w-full overflow-hidden bg-linear-to-br from-primary to-primaryStrong focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
        onClick={() => coverInputRef.current?.click()}
        disabled={!!uploading}
        aria-label={coverUrl ? 'Kapak fotoğrafını değiştir' : 'Kapak fotoğrafı yükle'}
      >
        {coverSrc && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={coverSrc} alt="" className="absolute inset-0 h-full w-full object-cover" />
        )}
        {!coverSrc && (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 opacity-30">
            <ImageIcon aria-hidden="true" className="h-9 w-9" strokeWidth={1.5} />
            <span className="text-xs font-bold text-white">Kapak fotoğrafı yok</span>
          </div>
        )}
        {/* Hover overlay */}
        <div className="absolute inset-0 flex items-center justify-center bg-black/0 transition-all duration-200 group-hover:bg-black/45 group-focus-visible:bg-black/45">
          <div className="flex flex-col items-center gap-2 opacity-0 transition-opacity group-hover:opacity-100 group-focus-visible:opacity-100">
            {uploading === 'cover' ? (
              <LoaderCircle aria-hidden="true" className="h-7 w-7 animate-spin text-white" />
            ) : (
              <>
                <div className="flex h-11 w-11 items-center justify-center rounded-full bg-white/20 backdrop-blur-xs">
                  <Camera aria-hidden="true" className="h-5 w-5 text-white" />
                </div>
                <span className="text-sm font-extrabold text-white drop-shadow-xs">
                  {coverUrl ? 'Kapak Değiştir' : 'Kapak Yükle'}
                </span>
              </>
            )}
          </div>
        </div>
      </button>
      <input ref={coverInputRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden"
             onChange={(e) => onFileChange(e, 'cover')} />

      {/* ── Logo + bilgi satırı ── */}
      <div className="relative flex items-end gap-4 px-5 pb-4 pt-0">
        {/* Logo — cover'ın altına taşıyor */}
        <div className="relative -mt-8 shrink-0">
          <button
            type="button"
            className="relative block h-16 w-16 overflow-hidden rounded-2xl border-[3px] border-card bg-white shadow-md focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary"
            onClick={() => logoInputRef.current?.click()}
            disabled={!!uploading}
            aria-label={logoUrl ? 'Logoyu değiştir' : 'Logo yükle'}
          >
            {logoSrc ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={logoSrc} alt={businessName} className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-cardAlt text-2xl font-black text-primaryStrong">
                {businessName.charAt(0).toUpperCase()}
              </div>
            )}
            {uploading === 'logo' && (
              <div className="absolute inset-0 flex items-center justify-center rounded-2xl bg-black/40">
                <LoaderCircle aria-hidden="true" className="h-5 w-5 animate-spin text-white" />
              </div>
            )}
          </button>
          <button
            type="button"
            onClick={() => logoInputRef.current?.click()}
            disabled={!!uploading}
            className="absolute -bottom-2 -right-3 flex h-11 w-11 items-center justify-center rounded-full bg-primary text-white shadow-xs transition hover:bg-primary/90 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-40"
            title="Logo Değiştir"
            aria-label="Logo değiştir"
          >
            <PenLine aria-hidden="true" className="h-4 w-4" />
          </button>
          <input ref={logoInputRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden"
                 onChange={(e) => onFileChange(e, 'logo')} />
        </div>

        {/* Bilgi + butonlar */}
        <div className="flex flex-1 flex-wrap items-center gap-x-4 gap-y-2 pb-1 pt-3">
          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-extrabold uppercase tracking-wider text-muted">Logo & Kapak Fotoğrafı</p>
            <p className="mt-0.5 text-xs text-muted">Keşfet listelerinde, QR sayfasında ve mobil uygulamada görünür</p>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <button
              type="button"
              onClick={() => logoInputRef.current?.click()}
              disabled={!!uploading}
              className="flex min-h-11 items-center gap-1.5 rounded-xl border border-border px-3 text-xs font-extrabold text-textStrong transition hover:bg-bg focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-40"
            >
              <Upload aria-hidden="true" className="h-4 w-4" />
              Logo
            </button>
            <button
              type="button"
              onClick={() => coverInputRef.current?.click()}
              disabled={!!uploading}
              className="flex min-h-11 items-center gap-1.5 rounded-xl bg-primary px-3 text-xs font-extrabold text-white transition hover:bg-primary/90 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-40"
            >
              <Upload aria-hidden="true" className="h-4 w-4" />
              Kapak
            </button>
          </div>
        </div>
      </div>
      {error && (
        <p role="alert" className="border-t border-border px-5 py-3 text-xs font-bold text-danger">
          {error}
        </p>
      )}
    </div>
  );
}
