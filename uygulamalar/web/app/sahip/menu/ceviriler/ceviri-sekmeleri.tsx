'use client';

import { useState, type ReactNode } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';

type Sekme = 'otomatik' | 'manuel';

interface CeviriSekmeleriProps {
  otomatikIcerik: ReactNode;
  manuelIcerik: ReactNode;
  varsayilanSekme?: Sekme;
}

export function CeviriSekmeleri({
  otomatikIcerik,
  manuelIcerik,
  varsayilanSekme = 'otomatik',
}: CeviriSekmeleriProps) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [aktifSekme, setAktifSekme] = useState<Sekme>(varsayilanSekme);

  function sekmeSec(sekme: Sekme) {
    setAktifSekme(sekme);
    // URL'deki sekme parametresini senkron tut — işletme seçici formu
    // (tam sayfa GET navigasyonu) bu değeri gizli alan olarak taşıyıp
    // aktif sekmenin kaybolmasını önler.
    const params = new URLSearchParams(searchParams.toString());
    if (sekme === 'otomatik') {
      params.delete('sekme');
    } else {
      params.set('sekme', sekme);
    }
    const query = params.toString();
    router.replace(query ? `${pathname}?${query}` : pathname, { scroll: false });
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex gap-1 self-start rounded-xl border border-border bg-card p-1">
        <SekmeButonu aktif={aktifSekme === 'otomatik'} onClick={() => sekmeSec('otomatik')}>
          Otomatik Çeviri
        </SekmeButonu>
        <SekmeButonu aktif={aktifSekme === 'manuel'} onClick={() => sekmeSec('manuel')}>
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
