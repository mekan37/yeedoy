'use client';

import { useState } from 'react';
import { Button } from '@/src/ui/components/button';
import { Card } from '@/src/ui/components/card';

export function QrGenerator({ businessId }: { businessId: string }) {
  const [result, setResult] = useState<{ url?: string; short_url?: string } | null>(null);
  const [loading, setLoading] = useState(false);

  async function generate(format: 'svg' | 'png' | 'poster_pdf') {
    try {
      setLoading(true);
      const res = await fetch('/api/qr', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, format }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        alert(data.error ?? 'QR olusturma basarisiz');
        return;
      }
      setResult(data);
      if (data.url) {
        const a = document.createElement('a');
        a.href = data.url;
        a.target = '_blank';
        a.click();
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : 'QR olusturma sirasinda beklenmeyen bir hata olustu.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Card className="rounded-3xl">
      <h2 className="mb-3 text-lg font-bold">QR Varliklari</h2>
      <div className="flex flex-wrap gap-2">
        <Button disabled={loading} onClick={() => generate('svg')}>SVG Indir</Button>
        <Button disabled={loading} className="bg-slate-700" onClick={() => generate('png')}>PNG Indir</Button>
        <Button disabled={loading} className="bg-slate-700" onClick={() => generate('poster_pdf')}>PDF Indir</Button>
      </div>
      {result?.short_url && (
        <p className="mt-3 text-sm text-slate-600">Kisa link: <a className="underline" href={result.short_url}>{result.short_url}</a></p>
      )}
    </Card>
  );
}
