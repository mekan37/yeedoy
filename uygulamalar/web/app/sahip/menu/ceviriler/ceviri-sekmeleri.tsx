'use client';

import { useState, type ReactNode } from 'react';

interface CeviriSekmeleriProps {
  otomatikIcerik: ReactNode;
  manuelIcerik: ReactNode;
}

type Sekme = 'otomatik' | 'manuel';

export function CeviriSekmeleri({ otomatikIcerik, manuelIcerik }: CeviriSekmeleriProps) {
  const [aktifSekme, setAktifSekme] = useState<Sekme>('otomatik');

  return (
    <div className="flex flex-col gap-5">
      <div className="flex gap-1 self-start rounded-xl border border-border bg-card p-1">
        <SekmeButonu
          aktif={aktifSekme === 'otomatik'}
          onClick={() => setAktifSekme('otomatik')}
        >
          Otomatik Çeviri
        </SekmeButonu>
        <SekmeButonu
          aktif={aktifSekme === 'manuel'}
          onClick={() => setAktifSekme('manuel')}
        >
          Manuel Düzenle
        </SekmeButonu>
      </div>

      <div className={aktifSekme === 'otomatik' ? 'flex flex-col gap-5' : 'hidden'}>
        {otomatikIcerik}
      </div>
      <div className={aktifSekme === 'manuel' ? 'flex flex-col gap-5' : 'hidden'}>
        {manuelIcerik}
      </div>
    </div>
  );
}

function SekmeButonu({
  aktif,
  onClick,
  children,
}: {
  aktif: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-lg px-4 py-2 text-sm font-[800] transition-all duration-150 ${
        aktif ? 'bg-primary text-white shadow-sm' : 'text-textStrong hover:bg-black/[0.05]'
      }`}
    >
      {children}
    </button>
  );
}
