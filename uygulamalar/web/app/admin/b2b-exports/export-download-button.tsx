'use client';

import { useCallback, useState } from 'react';

interface ExportDownloadButtonProps {
  exportType: 'inflation' | 'trends' | 'regional';
  days: number;
  label: string;
}

export function ExportDownloadButton({ exportType, days, label }: ExportDownloadButtonProps) {
  const [status, setStatus] = useState<'idle' | 'loading' | 'error'>('idle');

  const handleDownload = useCallback(async () => {
    setStatus('loading');
    try {
      const params = new URLSearchParams({ type: exportType, days: String(days) });
      const res = await fetch(`/api/admin/b2b-export?${params.toString()}`);

      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        console.error('B2B export failed', body);
        setStatus('error');
        setTimeout(() => setStatus('idle'), 3000);
        return;
      }

      const blob = await res.blob();
      const disposition = res.headers.get('Content-Disposition') ?? '';
      const filenameMatch = disposition.match(/filename="([^"]+)"/);
      const filename = filenameMatch?.[1] ?? `yeedoy-export-${exportType}.csv`;

      const url = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = filename;
      anchor.click();
      URL.revokeObjectURL(url);
      setStatus('idle');
    } catch {
      setStatus('error');
      setTimeout(() => setStatus('idle'), 3000);
    }
  }, [exportType, days]);

  const isLoading = status === 'loading';
  const isError = status === 'error';

  return (
    <button
      type="button"
      onClick={handleDownload}
      disabled={isLoading}
      className="inline-flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong transition-colors hover:bg-black/[0.04] disabled:cursor-not-allowed disabled:opacity-60"
    >
      {isLoading ? (
        <SpinnerIcon />
      ) : isError ? (
        <ErrorIcon />
      ) : (
        <DownloadIcon />
      )}
      {isLoading ? 'İndiriliyor...' : isError ? 'Hata — Tekrar dene' : label}
    </button>
  );
}

function DownloadIcon() {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}

function SpinnerIcon() {
  return (
    <svg
      className="h-3 w-3 animate-spin"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      aria-hidden="true"
    >
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
  );
}

function ErrorIcon() {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="8" x2="12" y2="12" />
      <line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}
