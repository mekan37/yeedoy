'use client';

import { useState } from 'react';

export function ReferralButonu() {
  const [copied, setCopied] = useState(false);

  const mesaj =
    'Merhaba! İşletmem için Yeedoy QR Menü kullanıyorum — fiyat güncellemesi 2 dakika sürüyor ve ücretsiz. Sana da bağlantıyı atayım: https://yeedoy.com/sahip/baslangic';

  function handleCopy() {
    if (typeof navigator !== 'undefined' && navigator.clipboard) {
      void navigator.clipboard.writeText(mesaj).then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 2500);
      });
    }
  }

  return (
    <div className="mx-3 mb-3 rounded-xl border border-border bg-card/60 p-3">
      <p className="text-[11px] font-[800] text-textStrong mb-2">Arkadaşını Davet Et</p>
      <p className="text-[10px] text-muted mb-2 leading-relaxed">
        Referralın ücretsiz QR menü aldığında 1 ay sponsorluk kredisi kazan.
      </p>
      <div className="flex gap-1.5">
        <a
          href={`whatsapp://send?text=${encodeURIComponent(mesaj)}`}
          className="flex flex-1 items-center justify-center gap-1 rounded-lg bg-[#25D366] px-2 py-1.5 text-[10px] font-[800] text-white hover:opacity-90 transition-opacity"
        >
          <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413z"/>
            <path d="M12 0C5.373 0 0 5.373 0 12c0 2.122.552 4.112 1.512 5.84L0 24l6.336-1.494A11.928 11.928 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 21.818a9.797 9.797 0 0 1-5.028-1.384l-.36-.214-3.732.879.894-3.63-.235-.373A9.796 9.796 0 0 1 2.182 12C2.182 6.573 6.573 2.182 12 2.182S21.818 6.573 21.818 12 17.427 21.818 12 21.818z"/>
          </svg>
          WhatsApp
        </a>
        <button
          onClick={handleCopy}
          className="flex items-center gap-1 rounded-lg border border-border bg-card px-2 py-1.5 text-[10px] font-[800] text-muted hover:bg-border/40 transition-colors"
        >
          {copied ? (
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="20 6 9 17 4 12" />
            </svg>
          ) : (
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
              <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
            </svg>
          )}
          {copied ? 'Kopyalandı' : 'Kopyala'}
        </button>
      </div>
    </div>
  );
}
