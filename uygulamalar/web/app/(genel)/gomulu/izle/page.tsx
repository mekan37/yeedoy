'use client';

import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { Suspense, useMemo } from 'react';

function toEmbedUrl(raw: string): { url: string; type: 'youtube' | 'generic' } | null {
  try {
    const u = new URL(raw);
    // YouTube
    const ytMatch =
      (u.hostname === 'youtu.be' ? u.pathname.slice(1) : null) ??
      (u.hostname.includes('youtube.com') ? u.searchParams.get('v') : null);
    if (ytMatch) {
      return { url: `https://www.youtube-nocookie.com/embed/${ytMatch}`, type: 'youtube' };
    }
    // Only allow https for generic embeds
    if (u.protocol === 'https:') {
      return { url: raw, type: 'generic' };
    }
  } catch {
    // invalid URL — ignore
  }
  return null;
}

function EmbedIcerigi() {
  const params = useSearchParams();
  const rawUrl = params.get('url') ?? '';
  const embed = useMemo(() => toEmbedUrl(rawUrl), [rawUrl]);

  if (!rawUrl) {
    return (
      <div className="flex min-h-[400px] flex-col items-center justify-center gap-4 rounded-2xl border border-border bg-card p-8 text-center">
        <p className="text-sm font-[900] text-textStrong">URL belirtilmedi</p>
        <p className="text-xs text-muted">Gömülü içerik URL&apos;sini <code className="rounded bg-border px-1">?url=</code> parametresi ile verin.</p>
      </div>
    );
  }

  if (!embed) {
    return (
      <div className="flex min-h-[400px] flex-col items-center justify-center gap-4 rounded-2xl border border-danger/20 bg-danger/[0.05] p-8 text-center">
        <p className="text-sm font-[900] text-danger">Geçersiz URL</p>
        <p className="text-xs text-muted">Sadece HTTPS YouTube ve web adresleri desteklenir.</p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
      <div className="flex min-h-[52px] items-center gap-3 border-b border-border px-4">
        <span className="h-2.5 w-2.5 rounded-full bg-danger" />
        <span className="h-2.5 w-2.5 rounded-full bg-warning" />
        <span className="h-2.5 w-2.5 rounded-full bg-success" />
        <span className="ml-2 max-w-[60%] truncate text-xs text-muted">{rawUrl}</span>
        <a
          href={rawUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="ml-auto text-xs font-[900] text-primary hover:underline"
        >
          Yeni sekmede aç ↗
        </a>
      </div>
      <iframe
        src={embed.url}
        title="Gömülü içerik"
        className="h-[70vh] w-full border-0"
        allow={embed.type === 'youtube' ? 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture' : undefined}
        allowFullScreen
        sandbox={embed.type === 'generic' ? 'allow-scripts allow-same-origin allow-forms allow-popups' : undefined}
        loading="lazy"
      />
    </div>
  );
}

export default function GomoluIzlePage() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <Link
          href="/"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
        >
          ← Ana Sayfa
        </Link>
        <h1 className="mb-6 text-2xl font-[900] text-textStrong">Gömülü İçerik</h1>
        <Suspense
          fallback={
            <div className="flex min-h-[400px] items-center justify-center rounded-2xl border border-border bg-card">
              <p className="text-sm text-muted">Yükleniyor…</p>
            </div>
          }
        >
          <EmbedIcerigi />
        </Suspense>
      </div>
    </main>
  );
}
