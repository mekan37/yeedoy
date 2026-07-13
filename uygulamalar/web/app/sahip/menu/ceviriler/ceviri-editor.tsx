'use client';

import { useState, useTransition } from 'react';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { menuCevirisiniKaydet } from './ceviri-islemleri';
import {
  DESTEKLENEN_DILLER,
  DIL_ETIKETLERI,
  type CeviriSatiri,
  type DestekDil,
} from './ceviri-sabitleri';

interface CeviriEditorProps {
  satirlar: CeviriSatiri[];
  businessId: string;
}

type DilState = Record<
  string, // itemId
  Record<DestekDil, { name: string; description: string }>
>;

type SaveState = Record<
  string, // `${itemId}-${locale}`
  { loading: boolean; success?: boolean; hata?: string }
>;

export function CeviriEditor({ satirlar, businessId }: CeviriEditorProps) {
  const [aktifDil, setAktifDil] = useState<DestekDil>(DESTEKLENEN_DILLER[0]);
  const [dilState, setDilState] = useState<DilState>(() => {
    const initial: DilState = {};
    for (const satir of satirlar) {
      initial[satir.itemId] = {} as Record<
        DestekDil,
        { name: string; description: string }
      >;
      for (const locale of DESTEKLENEN_DILLER) {
        initial[satir.itemId][locale] = {
          name: satir.translations[locale]?.name ?? '',
          description: satir.translations[locale]?.description ?? '',
        };
      }
    }
    return initial;
  });

  const [saveState, setSaveState] = useState<SaveState>({});
  const [, startTransition] = useTransition();

  function handleChange(
    itemId: string,
    locale: DestekDil,
    field: 'name' | 'description',
    value: string,
  ) {
    setDilState((prev) => ({
      ...prev,
      [itemId]: {
        ...prev[itemId],
        [locale]: {
          ...prev[itemId][locale],
          [field]: value,
        },
      },
    }));
    // Kaydet durumunu sıfırla
    const key = `${itemId}-${locale}`;
    setSaveState((prev) => ({ ...prev, [key]: { loading: false } }));
  }

  function handleSave(itemId: string, locale: DestekDil) {
    const key = `${itemId}-${locale}`;
    const { name, description } = dilState[itemId][locale];

    setSaveState((prev) => ({ ...prev, [key]: { loading: true } }));

    startTransition(async () => {
      const sonuc = await menuCevirisiniKaydet(
        businessId,
        itemId,
        locale,
        name,
        description,
      );
      setSaveState((prev) => ({
        ...prev,
        [key]: {
          loading: false,
          success: sonuc.success,
          hata: sonuc.success ? undefined : sonuc.hata,
        },
      }));
    });
  }

  // Menü başlıklarına göre grupla
  const menuGruplari = groupByMenu(satirlar);

  return (
    <div className="flex flex-col gap-6">
      {/* Dil sekmeleri */}
      <div className="flex items-center gap-2">
        <span className="text-xs font-[800] uppercase tracking-wide text-muted">
          Hedef Dil:
        </span>
        <div className="flex gap-1 rounded-xl border border-border bg-card p-1">
          {DESTEKLENEN_DILLER.map((locale) => (
            <button
              key={locale}
              type="button"
              onClick={() => setAktifDil(locale)}
              className={`rounded-lg px-4 py-1.5 text-sm font-[800] transition-all duration-150 ${
                aktifDil === locale
                  ? 'bg-primary text-white shadow-sm'
                  : 'text-textStrong hover:bg-black/[0.05]'
              }`}
            >
              {DIL_ETIKETLERI[locale]}
            </button>
          ))}
        </div>
      </div>

      {/* Menü grupları */}
      {menuGruplari.map(({ menuTitle, items }) => (
        <PanelBolumKarti
          key={menuTitle}
          title={menuTitle}
          description={`${items.length} ürün — ${DIL_ETIKETLERI[aktifDil]} çevirisi`}
        >
          <div className="flex flex-col gap-4">
            {items.map((satir) => {
              const key = `${satir.itemId}-${aktifDil}`;
              const state = saveState[key] ?? { loading: false };
              const current = dilState[satir.itemId][aktifDil];
              const hasDirtyName = current.name.trim() !== (satir.translations[aktifDil]?.name ?? '');
              const hasDirtyDesc = current.description.trim() !== (satir.translations[aktifDil]?.description ?? '');
              const isDirty = hasDirtyName || hasDirtyDesc;

              return (
                <div
                  key={satir.itemId}
                  className="rounded-xl border border-border bg-bg p-4"
                >
                  {/* Ürün başlığı */}
                  <div className="mb-3 flex items-start justify-between gap-2">
                    <div>
                      <p className="text-sm font-[900] text-textStrong">
                        {satir.itemNameTr}
                      </p>
                      {satir.itemDescTr && (
                        <p className="mt-0.5 text-xs leading-relaxed text-muted line-clamp-2">
                          {satir.itemDescTr}
                        </p>
                      )}
                      <p className="mt-1 text-[11px] font-[700] text-muted opacity-70">
                        {satir.sectionName}
                      </p>
                    </div>
                    {/* Çeviri durumu rozeti */}
                    {satir.translations[aktifDil]?.name ? (
                      <span className="shrink-0 rounded-full bg-green-50 px-2.5 py-0.5 text-[11px] font-[800] text-green-700">
                        Çevrildi
                      </span>
                    ) : (
                      <span className="shrink-0 rounded-full bg-amber-50 px-2.5 py-0.5 text-[11px] font-[800] text-amber-700">
                        Eksik
                      </span>
                    )}
                  </div>

                  {/* Çeviri alanları */}
                  <div className="flex flex-col gap-2">
                    <div>
                      <label className="mb-1 block text-xs font-[800] text-muted">
                        Ad ({DIL_ETIKETLERI[aktifDil]})
                      </label>
                      <input
                        type="text"
                        value={current.name}
                        onChange={(e) =>
                          handleChange(satir.itemId, aktifDil, 'name', e.target.value)
                        }
                        placeholder={`${satir.itemNameTr} (${DIL_ETIKETLERI[aktifDil]})`}
                        className="w-full rounded-lg border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted/60 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30"
                      />
                    </div>

                    <div>
                      <label className="mb-1 block text-xs font-[800] text-muted">
                        Açıklama ({DIL_ETIKETLERI[aktifDil]}) — isteğe bağlı
                      </label>
                      <textarea
                        value={current.description}
                        onChange={(e) =>
                          handleChange(satir.itemId, aktifDil, 'description', e.target.value)
                        }
                        placeholder={satir.itemDescTr ?? ''}
                        rows={2}
                        className="w-full resize-none rounded-lg border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted/60 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30"
                      />
                    </div>

                    {/* Durum + Kaydet */}
                    <div className="flex items-center justify-between gap-3 pt-1">
                      <div className="text-xs">
                        {state.success && (
                          <span className="font-[800] text-green-600">Kaydedildi</span>
                        )}
                        {state.hata && (
                          <span className="font-[800] text-red-600">{state.hata}</span>
                        )}
                      </div>
                      <PanelActionButton
                        variant={isDirty || state.success ? 'primary' : 'secondary'}
                        loading={state.loading}
                        disabled={!current.name.trim()}
                        onClick={() => handleSave(satir.itemId, aktifDil)}
                      >
                        Kaydet
                      </PanelActionButton>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </PanelBolumKarti>
      ))}
    </div>
  );
}

function groupByMenu(
  satirlar: CeviriSatiri[],
): Array<{ menuTitle: string; items: CeviriSatiri[] }> {
  const map = new Map<string, CeviriSatiri[]>();
  for (const satir of satirlar) {
    const existing = map.get(satir.menuTitle);
    if (existing) {
      existing.push(satir);
    } else {
      map.set(satir.menuTitle, [satir]);
    }
  }
  return Array.from(map.entries()).map(([menuTitle, items]) => ({
    menuTitle,
    items,
  }));
}
