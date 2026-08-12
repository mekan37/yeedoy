'use client';

import { useState } from 'react';
import { notEkle, etiketEkle, etiketSil } from '../musteriler-islemleri';

export type MusteriEtiketi = { id: string; tag: string };

export function EtiketNotFormu({
  businessId,
  userId,
  mevcutEtiketler,
}: {
  businessId: string;
  userId: string;
  mevcutEtiketler: MusteriEtiketi[];
}) {
  const [yeniEtiket, setYeniEtiket] = useState('');
  const [etiketPending, setEtiketPending] = useState(false);
  const [etiketError, setEtiketError] = useState<string | null>(null);

  const [yeniNot, setYeniNot] = useState('');
  const [notPending, setNotPending] = useState(false);
  const [notError, setNotError] = useState<string | null>(null);
  const [notEklendi, setNotEklendi] = useState(false);

  return (
    <div className="flex flex-col gap-4 border-t border-border pt-4">
      <div>
        <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Etiketler</p>
        <div className="mb-2 flex flex-wrap gap-1.5">
          {mevcutEtiketler.map((t) => (
            <span
              key={t.id}
              className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-bold text-primary"
            >
              {t.tag}
              <button
                type="button"
                aria-label={`${t.tag} etiketini kaldır`}
                onClick={async () => {
                  await etiketSil(t.id, userId);
                }}
                className="text-primary/60 hover:text-primary"
              >
                ×
              </button>
            </span>
          ))}
        </div>
        <div className="flex gap-2">
          <input
            value={yeniEtiket}
            onChange={(e) => setYeniEtiket(e.target.value)}
            placeholder="Etiket ekle — örn. VIP"
            maxLength={40}
            className="flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-xs"
          />
          <button
            type="button"
            disabled={etiketPending || !yeniEtiket.trim()}
            onClick={async () => {
              setEtiketPending(true);
              setEtiketError(null);
              const result = await etiketEkle(businessId, userId, yeniEtiket.trim());
              setEtiketPending(false);
              if ('error' in result) {
                setEtiketError(result.error);
                return;
              }
              setYeniEtiket('');
            }}
            className="rounded-lg bg-primary px-3 py-1 text-xs font-bold text-white disabled:opacity-50"
          >
            Ekle
          </button>
        </div>
        {etiketError && <p className="mt-1 text-xs font-bold text-red-600">{etiketError}</p>}
      </div>

      <div>
        <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Not ekle</p>
        <textarea
          value={yeniNot}
          onChange={(e) => setYeniNot(e.target.value)}
          placeholder="Bu müşteri için bir not yazın..."
          maxLength={1000}
          rows={3}
          className="w-full rounded-lg border border-border bg-bg px-2 py-1 text-xs"
        />
        <button
          type="button"
          disabled={notPending || !yeniNot.trim()}
          onClick={async () => {
            setNotPending(true);
            setNotError(null);
            const result = await notEkle(businessId, userId, yeniNot.trim());
            setNotPending(false);
            if ('error' in result) {
              setNotError(result.error);
              return;
            }
            setYeniNot('');
            setNotEklendi(true);
          }}
          className="mt-2 rounded-lg bg-primary px-3 py-1 text-xs font-bold text-white disabled:opacity-50"
        >
          {notPending ? 'Kaydediliyor…' : 'Kaydet'}
        </button>
        {notError && <p className="mt-1 text-xs font-bold text-red-600">{notError}</p>}
        {notEklendi && <p className="mt-1 text-xs text-muted">Not eklendi, zaman çizelgesinde görünüyor.</p>}
      </div>
    </div>
  );
}
