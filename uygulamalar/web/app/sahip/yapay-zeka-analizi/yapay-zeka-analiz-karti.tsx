'use client';

import { useState } from 'react';
import {
  analizBaslat,
  type AnalizOgesi,
  type Isletme,
} from './yapay-zeka-analiz-islemi';

// ─── Types ─────────────────────────────────────────────────────────────────────

type GirdiTuru = 'gorsel_url' | 'ham_metin';

type KartDurumu =
  | { tag: 'bekleniyor' }
  | { tag: 'analiz_ediliyor' }
  | { tag: 'sonuclar'; ogeler: AnalizOgesi[] }
  | { tag: 'hata'; mesaj: string };

interface Props {
  isletmeler: Isletme[];
}

// ─── Main component ───────────────────────────────────────────────────────────

export function YapayZekaAnalizKarti({ isletmeler }: Props) {
  const [durum, setDurum] = useState<KartDurumu>({ tag: 'bekleniyor' });
  const [secilenIsletmeId, setSecilenIsletmeId] = useState(
    isletmeler[0]?.id ?? '',
  );
  const [girdiTuru, setGirdiTuru] = useState<GirdiTuru>('gorsel_url');
  const [gorselUrl, setGorselUrl] = useState('');
  const [hamMetin, setHamMetin] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!secilenIsletmeId) return;

    const deger = girdiTuru === 'gorsel_url' ? gorselUrl.trim() : hamMetin.trim();
    if (!deger) return;

    setDurum({ tag: 'analiz_ediliyor' });

    const sonuc = await analizBaslat(secilenIsletmeId, { tur: girdiTuru, deger });

    if (sonuc.basarili) {
      setDurum({ tag: 'sonuclar', ogeler: sonuc.ogeler });
    } else {
      setDurum({ tag: 'hata', mesaj: sonuc.hata });
    }
  }

  if (isletmeler.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-6 text-center">
        <p className="text-sm text-muted">
          AI analizi için önce bir işletme eklemeniz gerekiyor.
        </p>
      </div>
    );
  }

  if (durum.tag === 'analiz_ediliyor') {
    return (
      <div className="flex flex-col items-center gap-4 py-16">
        <LoadingSpinner />
        <p className="text-sm font-[700] text-textStrong">
          Menünüz analiz ediliyor...
        </p>
        <p className="text-xs text-muted">Bu işlem 30–90 saniye sürebilir.</p>
      </div>
    );
  }

  if (durum.tag === 'hata') {
    return (
      <div className="flex flex-col gap-4">
        <div className="rounded-xl border border-rose-200 bg-rose-50 p-4">
          <p className="text-sm font-[800] text-rose-800">Hata</p>
          <p className="mt-0.5 text-sm text-rose-700">{durum.mesaj}</p>
        </div>
        <button
          type="button"
          onClick={() => setDurum({ tag: 'bekleniyor' })}
          className="self-start text-xs text-muted hover:text-primary"
        >
          Geri dön
        </button>
      </div>
    );
  }

  if (durum.tag === 'sonuclar') {
    return (
      <SonucGorunumu
        ogeler={durum.ogeler}
        onGeri={() => setDurum({ tag: 'bekleniyor' })}
      />
    );
  }

  // bekleniyor — giriş formu
  const gonderilemez =
    !secilenIsletmeId ||
    (girdiTuru === 'gorsel_url' ? !gorselUrl.trim() : !hamMetin.trim());

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-5">
      {/* İşletme seçimi */}
      <div className="flex flex-col gap-1.5">
        <label className="text-xs font-[700] text-muted" htmlFor="isletme-select">
          İşletme
        </label>
        <select
          id="isletme-select"
          value={secilenIsletmeId}
          onChange={(e) => setSecilenIsletmeId(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong outline-none focus:border-primary focus:ring-1 focus:ring-primary"
        >
          {isletmeler.map((i) => (
            <option key={i.id} value={i.id}>
              {i.name}
            </option>
          ))}
        </select>
      </div>

      {/* Girdi türü seçimi */}
      <div className="flex gap-2">
        <button
          type="button"
          onClick={() => setGirdiTuru('gorsel_url')}
          className={`rounded-full border px-3 py-1 text-xs font-[700] transition ${
            girdiTuru === 'gorsel_url'
              ? 'border-primary bg-red-50 text-primary'
              : 'border-border text-muted hover:border-primary/30'
          }`}
        >
          Görsel URL
        </button>
        <button
          type="button"
          onClick={() => setGirdiTuru('ham_metin')}
          className={`rounded-full border px-3 py-1 text-xs font-[700] transition ${
            girdiTuru === 'ham_metin'
              ? 'border-primary bg-red-50 text-primary'
              : 'border-border text-muted hover:border-primary/30'
          }`}
        >
          Ham Metin
        </button>
      </div>

      {/* Koşullu girdi */}
      {girdiTuru === 'gorsel_url' ? (
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-[700] text-muted" htmlFor="gorsel-url">
            Menü Görseli URL
          </label>
          <input
            id="gorsel-url"
            type="url"
            value={gorselUrl}
            onChange={(e) => setGorselUrl(e.target.value)}
            placeholder="https://..."
            className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
        </div>
      ) : (
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-[700] text-muted" htmlFor="ham-metin">
            Ham Menü Metni
          </label>
          <textarea
            id="ham-metin"
            value={hamMetin}
            onChange={(e) => setHamMetin(e.target.value)}
            rows={8}
            placeholder="Menü ögelerini buraya yapıştırın..."
            className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
        </div>
      )}

      <button
        type="submit"
        disabled={gonderilemez}
        className="self-start rounded-xl bg-primary px-5 py-2.5 text-sm font-[800] text-white transition hover:bg-red-900 disabled:opacity-50"
      >
        Analiz Et
      </button>
    </form>
  );
}

// ─── Results view ─────────────────────────────────────────────────────────────

function SonucGorunumu({
  ogeler,
  onGeri,
}: {
  ogeler: AnalizOgesi[];
  onGeri: () => void;
}) {
  if (ogeler.length === 0) {
    return (
      <div className="flex flex-col gap-4">
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
          <p className="text-sm font-[800] text-amber-800">Sonuç bulunamadı</p>
          <p className="mt-0.5 text-xs text-amber-700">
            Analiz tamamlandı ancak menü ögesi tespit edilemedi.
          </p>
        </div>
        <button
          type="button"
          onClick={onGeri}
          className="self-start text-xs text-muted hover:text-primary"
        >
          Geri dön
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <p className="text-sm font-[800] text-textStrong">
          {ogeler.length} ürün tespit edildi
        </p>
        <button
          type="button"
          onClick={onGeri}
          className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong"
        >
          Geri
        </button>
      </div>

      <div className="flex flex-col gap-3">
        {ogeler.map((oge) => (
          <OgeKarti key={oge.id} oge={oge} />
        ))}
      </div>
    </div>
  );
}

// ─── Item card ────────────────────────────────────────────────────────────────

function OgeKarti({ oge }: { oge: AnalizOgesi }) {
  const alerjenler = oge.allergens_json ?? [];
  const kaloriVar = oge.calorie_min !== null || oge.calorie_max !== null;

  return (
    <div className="rounded-xl border border-border bg-card p-4 flex flex-col gap-2">
      <div className="flex items-start justify-between">
        <p className="font-[800] text-textStrong">
          {oge.normalized_text ?? oge.source_text}
        </p>
        {oge.requires_review && (
          <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-[700] text-amber-700">
            İnceleme Gerekli
          </span>
        )}
      </div>
      {alerjenler.length > 0 && (
        <div className="flex gap-1 flex-wrap">
          {alerjenler.map((a) => (
            <span
              key={a}
              className="rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-[700] text-red-600"
            >
              {a}
            </span>
          ))}
        </div>
      )}
      {kaloriVar && (
        <p className="text-xs text-muted">
          {oge.calorie_min ?? '?'}&#x2013;{oge.calorie_max ?? '?'} kcal
        </p>
      )}
      <p className="text-xs text-muted">Kaynak: {oge.source_text}</p>
    </div>
  );
}

// ─── Icons ────────────────────────────────────────────────────────────────────

function LoadingSpinner() {
  return (
    <svg
      className="h-8 w-8 animate-spin text-primary"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
      />
    </svg>
  );
}
