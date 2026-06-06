'use client';

import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';
import {
  hepsiniOkunduIsaretle,
  bildirimiOkunduIsaretle,
  bildirimiSil,
  eskiBildirimleriSil,
} from './bildirim-islemleri';

export function HepsiniOkunduButonu({ disabled }: { disabled?: boolean }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [done, setDone] = useState(false);
  const [hata, setHata] = useState(false);

  function handleClick() {
    setHata(false);
    startTransition(async () => {
      const sonuc = await hepsiniOkunduIsaretle();
      if (sonuc.ok) {
        setDone(true);
        router.refresh();
      } else {
        setHata(true);
      }
    });
  }

  if (done) {
    return (
      <span className="inline-flex items-center gap-1 rounded-xl border border-success/25 bg-success/[0.08] px-3 py-1.5 text-xs font-[700] text-success">
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="20 6 9 17 4 12" />
        </svg>
        Tümü okundu
      </span>
    );
  }

  if (hata) {
    return (
      <span className="inline-flex items-center gap-1 rounded-xl border border-danger/25 bg-danger/[0.08] px-3 py-1.5 text-xs font-[700] text-danger">
        Bir sorun oluştu
      </span>
    );
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={disabled || pending}
      className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong transition-colors hover:border-primary/30 disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {pending ? 'İşleniyor…' : 'Hepsini Okundu İşaretle'}
    </button>
  );
}

export function BildirimiOkunduButonu({ notifId }: { notifId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function handleClick() {
    startTransition(async () => {
      await bildirimiOkunduIsaretle(notifId);
      router.refresh();
    });
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={pending}
      className="mt-1 text-[11px] font-[700] text-muted hover:text-primary disabled:opacity-50"
    >
      {pending ? '…' : 'Okundu işaretle'}
    </button>
  );
}

export function BildirimiSilButonu({ notifId }: { notifId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function handleClick() {
    startTransition(async () => {
      await bildirimiSil(notifId);
      router.refresh();
    });
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={pending}
      className="mt-1 text-[11px] font-[700] text-muted hover:text-danger disabled:opacity-50"
      title="Bildirimi sil"
    >
      {pending ? '…' : 'Sil'}
    </button>
  );
}

export function EskiBildirimleriSilButonu() {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [done, setDone] = useState(false);

  function handleClick() {
    if (!confirm('30 günden eski, okunmuş bildirimler silinecek. Devam et?')) return;
    startTransition(async () => {
      await eskiBildirimleriSil();
      setDone(true);
      router.refresh();
    });
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={pending || done}
      className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-muted transition-colors hover:border-danger/30 hover:text-danger disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {done ? 'Temizlendi' : pending ? '…' : 'Eskilerini Temizle'}
    </button>
  );
}
