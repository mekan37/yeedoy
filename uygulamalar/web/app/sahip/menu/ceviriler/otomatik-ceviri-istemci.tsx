'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

const TARGET_LANGS = [
  { code: 'en', label: 'İngilizce' },
  { code: 'de', label: 'Almanca' },
  { code: 'ar', label: 'Arapça' },
  { code: 'fr', label: 'Fransızca' },
  { code: 'ru', label: 'Rusça' },
  { code: 'zh', label: 'Çince' },
];

const LANG_LABELS: Record<string, string> = Object.fromEntries(TARGET_LANGS.map((l) => [l.code, l.label]));

export function OtomatikCeviriPanel({ menuIds }: { menuIds: string[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selectedLangs, setSelectedLangs] = useState<string[]>(['en']);
  const [result, setResult] = useState<{ ok: boolean; message: string; skippedLocales?: string[] } | null>(null);

  const toggleLang = (code: string) =>
    setSelectedLangs(prev =>
      prev.includes(code) ? prev.filter(l => l !== code) : [...prev, code]
    );

  const translate = () => {
    if (menuIds.length === 0) { setResult({ ok: false, message: 'Çevrilecek menü bulunamadı.' }); return; }
    if (selectedLangs.length === 0) { setResult({ ok: false, message: 'En az bir dil seçin.' }); return; }

    startTransition(async () => {
      const res = await fetch('/sunucu/sahip/ceviriler-otomatik', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ menuIds, targetLocales: selectedLangs }),
      });
      const data = await res.json() as { ok?: boolean; translated?: number; skippedLocales?: string[]; error?: string };
      if (data.ok) {
        const skipped = data.skippedLocales ?? [];
        const skippedMsg = skipped.length > 0
          ? ` Plan limitiniz nedeniyle atlanan diller: ${skipped.map(c => LANG_LABELS[c] ?? c).join(', ')}.`
          : '';
        setResult({ ok: true, message: `${data.translated ?? 0} öğe çevrildi.${skippedMsg} Sayfa yenileniyor…`, skippedLocales: skipped });
        setTimeout(() => router.refresh(), 1500);
      } else {
        setResult({ ok: false, message: data.error ?? 'Çeviri başarısız.' });
      }
    });
  };

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">
        Menünüzdeki tüm kategori ve ürün adlarını (ve varsa açıklamalarını) seçilen dillere otomatik çevirin.
        Mevcut çeviriler üzerine yazılmaz — sadece eksik olanlar eklenir.
      </p>

      {/* Languages */}
      <div>
        <p className="mb-2 text-xs font-bold text-muted">Hedef Diller</p>
        <div className="flex flex-wrap gap-2">
          {TARGET_LANGS.map(lang => (
            <button
              key={lang.code}
              onClick={() => toggleLang(lang.code)}
              className={`rounded-lg border px-3 py-1.5 text-xs font-bold transition-colors ${selectedLangs.includes(lang.code) ? 'border-primary bg-primary text-white' : 'border-border text-muted hover:border-primary hover:text-primary'}`}
            >
              {lang.label}
            </button>
          ))}
        </div>
      </div>

      {result && (
        <div className={`rounded-lg px-4 py-3 text-sm font-bold ${result.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
          {result.ok ? '✓' : '✕'} {result.message}
        </div>
      )}

      <button
        disabled={isPending || menuIds.length === 0 || selectedLangs.length === 0}
        onClick={translate}
        className="self-start rounded-xl bg-primary px-5 py-2.5 text-sm font-extrabold text-white hover:bg-primary/90 disabled:opacity-50"
      >
        {isPending ? 'Çeviriliyor…' : `Otomatik Çevir — ${selectedLangs.length} dil`}
      </button>
    </div>
  );
}
