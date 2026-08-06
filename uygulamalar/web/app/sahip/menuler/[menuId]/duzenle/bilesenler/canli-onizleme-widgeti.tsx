import Image from 'next/image';
import { Item, formatPrice } from '../menu-duzenleyici-yardimcilari';

export function CanliOnizlemeWidgeti({ item }: { item: Item | null }) {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-1 text-sm font-black text-textStrong">Canlı Önizleme</h3>
      <p className="mb-3 text-xs text-muted">Müşterileriniz ürünü bu şekilde görür.</p>
      {!item ? (
        <div className="flex flex-col items-center justify-center gap-1 rounded-xl border border-dashed border-border py-8 text-center">
          <p className="text-xs font-bold text-muted">Önizlemek için bir ürün seçin</p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-border">
          <div className="relative h-32 w-full bg-bg">
            {item.image_url ? (
              <Image src={item.image_url} alt={item.name} fill sizes="320px" className="object-cover" unoptimized />
            ) : (
              <div className="flex h-full items-center justify-center text-xs font-bold text-muted">Görsel yok</div>
            )}
            <span className={`absolute right-2 top-2 rounded-full px-2 py-0.5 text-[10px] font-extrabold ${item.is_available ? 'bg-green-600 text-white' : 'bg-zinc-500 text-white'}`}>
              {item.is_available ? 'Aktif' : 'Pasif'}
            </span>
          </div>
          <div className="p-3">
            <div className="flex items-start justify-between gap-2">
              <p className="font-black text-textStrong">{item.name}</p>
              <p className="shrink-0 font-black text-primary">{formatPrice(item.price_cents)}</p>
            </div>
            {item.description && <p className="mt-1 text-xs text-muted">{item.description}</p>}
            <div className="mt-2 flex flex-wrap gap-2 text-[11px] font-bold text-muted">
              {item.portion_size && item.portion_unit && (
                <span>⚖ {item.portion_size} {item.portion_unit}</span>
              )}
              {item.calories_min !== null && <span>🔥 {item.calories_min} kcal</span>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
