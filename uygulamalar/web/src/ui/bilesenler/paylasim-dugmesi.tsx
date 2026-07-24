'use client';

import { useState } from 'react';

interface PaylasimDugmesiProps {
  url: string;
  title: string;
  text?: string;
  className?: string;
  /** Küçük icon-only buton için true */
  compact?: boolean;
}

/**
 * Web Share API (mobil) veya URL kopyalama (masaüstü) ile paylaşım sağlar.
 * Her iki ortamda da sorunsuz çalışır.
 */
export function PaylasimDugmesi({ url, title, text, className = '', compact = false }: PaylasimDugmesiProps) {
  const [copied, setCopied] = useState(false);
  const [sharing, setSharing] = useState(false);

  async function handleShare() {
    if (sharing) return;
    setSharing(true);

    // Web Share API — mobil/modern tarayıcı
    if (navigator.share) {
      try {
        await navigator.share({ title, text: text ?? title, url });
      } catch (e) {
        // Kullanıcı iptal etti — hata değil
      } finally {
        setSharing(false);
      }
      return;
    }

    // Fallback: URL panoya kopyala
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      // Clipboard erişimi yok — URL seçili göster
      window.prompt('Bağlantıyı kopyalayın:', url);
    } finally {
      setSharing(false);
    }
  }

  if (compact) {
    return (
      <button
        type="button"
        onClick={handleShare}
        aria-label="Paylaş"
        title={copied ? 'Kopyalandı!' : 'Paylaş'}
        className={`inline-flex min-h-[40px] min-w-[40px] items-center justify-center rounded-full border border-border bg-cardAlt text-muted transition-all hover:border-primary/30 hover:text-textStrong focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30 ${className}`}
      >
        {copied ? <CheckIcon /> : <ShareIcon />}
      </button>
    );
  }

  return (
    <button
      type="button"
      onClick={handleShare}
      className={`inline-flex min-h-[44px] items-center gap-2 rounded-2xl border border-border bg-cardAlt px-4 text-sm font-extrabold text-textStrong transition-all hover:bg-textStrong/[0.06] hover:border-borderStrong focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30 ${className}`}
    >
      {copied ? (
        <>
          <CheckIcon />
          <span>Kopyalandı!</span>
        </>
      ) : (
        <>
          <ShareIcon />
          <span>Paylaş</span>
        </>
      )}
    </button>
  );
}

function ShareIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="18" cy="5" r="3" />
      <circle cx="6" cy="12" r="3" />
      <circle cx="18" cy="19" r="3" />
      <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
      <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
