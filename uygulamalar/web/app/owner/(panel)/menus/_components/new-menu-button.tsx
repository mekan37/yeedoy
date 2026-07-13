'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createMenu } from '../actions';

type Biz = { id: string; name: string };

export function NewMenuButton({
  businesses,
  variant = 'button',
}: {
  businesses: Biz[];
  variant?: 'button' | 'card';
}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setPending(true);
    setError(null);
    const fd = new FormData(e.currentTarget);
    const businessId = String(fd.get('business_id') ?? '');
    const title = String(fd.get('title') ?? '');
    const result = await createMenu(businessId, title);
    if ('error' in result) {
      setError(result.error);
      setPending(false);
      return;
    }
    router.push(`/owner/menus/${result.menuId}/edit`);
  }

  return (
    <>
      {variant === 'card' ? (
        /* Dashed add card — grid içinde */
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex min-h-[200px] flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-[#e5e7eb] bg-white transition hover:border-[#dc2626]/50 hover:bg-[#fff8f8] cursor-pointer"
        >
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#f3f4f6] text-[#94a3b8]">
            <PlusIcon size={22} />
          </div>
          <div className="text-center">
            <p className="text-[13px] font-[800] text-[#475569]">Yeni Menü Ekle</p>
            <p className="mt-0.5 text-[11px] text-[#94a3b8]">Taslak olarak oluşturulur</p>
          </div>
        </button>
      ) : (
        /* Compact button — header'da */
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-[#dc2626] px-4 py-2 text-[12px] font-[800] text-white shadow-[0_2px_6px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c] cursor-pointer"
        >
          <PlusIcon size={13} />
          Yeni Menü
        </button>
      )}

      {/* Modal */}
      {open && (
        <>
          <div
            className="fixed inset-0 z-40 bg-black/50 backdrop-blur-[2px]"
            onClick={() => !pending && setOpen(false)}
          />
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-md rounded-2xl bg-white shadow-[0_24px_64px_rgba(0,0,0,0.18)]">
              {/* Header */}
              <div className="flex items-center justify-between border-b border-[#f0f0f0] px-6 py-4">
                <h2 className="text-base font-[900] text-[#1a1a2e]">Yeni Menü Oluştur</h2>
                <button
                  type="button"
                  onClick={() => !pending && setOpen(false)}
                  className="flex h-8 w-8 items-center justify-center rounded-xl border border-[#e5e7eb] text-[#94a3b8] hover:bg-[#f3f4f6] disabled:opacity-50 cursor-pointer"
                >
                  <XIcon />
                </button>
              </div>

              {/* Form */}
              <form onSubmit={handleSubmit} className="flex flex-col gap-4 px-6 py-5">

                {/* İşletme seçici — birden fazla işletme varsa */}
                {businesses.length > 1 && (
                  <div className="flex flex-col gap-1">
                    <label className="text-[11px] font-[700] text-[#475569]">İşletme *</label>
                    <select
                      name="business_id"
                      required
                      className="w-full rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]"
                    >
                      <option value="">— İşletme Seç —</option>
                      {businesses.map((b) => (
                        <option key={b.id} value={b.id}>{b.name}</option>
                      ))}
                    </select>
                  </div>
                )}
                {businesses.length === 1 && (
                  <>
                    <input type="hidden" name="business_id" value={businesses[0].id} />
                    <div className="flex items-center gap-2 rounded-xl bg-[#fafafa] px-3 py-2.5 text-[12px] font-[700] text-[#475569]">
                      <BuildingIcon />
                      {businesses[0].name}
                    </div>
                  </>
                )}
                {businesses.length === 0 && (
                  <p className="rounded-xl bg-amber-50 px-3 py-2 text-[12px] font-[600] text-amber-700">
                    Önce bir işletme eklemeniz gerekiyor.
                  </p>
                )}

                {/* Menü adı */}
                <div className="flex flex-col gap-1">
                  <label className="text-[11px] font-[700] text-[#475569]">Menü Adı *</label>
                  <input
                    name="title"
                    required
                    autoFocus
                    placeholder="ör: Ana Menü, Ramazan Menüsü, Kahvaltı…"
                    className="w-full rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]"
                  />
                </div>

                <div className="flex items-start gap-2 rounded-xl bg-[#fafafa] px-3 py-2.5 text-[11px] text-[#94a3b8]">
                  <InfoIcon />
                  Menü taslak olarak oluşturulur. Editörde hazırladıktan sonra aktif yapabilirsiniz.
                </div>

                {error && (
                  <p className="rounded-xl bg-red-50 px-3 py-2 text-[12px] font-[600] text-[#dc2626]">{error}</p>
                )}

                <div className="flex items-center justify-end gap-3 pt-1">
                  <button
                    type="button"
                    onClick={() => !pending && setOpen(false)}
                    className="rounded-xl border border-[#e5e7eb] px-4 py-2 text-sm font-[700] text-[#475569] hover:bg-[#f8fafc] cursor-pointer"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    disabled={pending || businesses.length === 0}
                    className="flex items-center gap-2 rounded-xl bg-[#dc2626] px-5 py-2 text-sm font-[700] text-white shadow-[0_2px_6px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c] disabled:opacity-60 cursor-pointer"
                  >
                    {pending && (
                      <svg className="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <path d="M21 12a9 9 0 1 1-6.219-8.56" />
                      </svg>
                    )}
                    {pending ? 'Oluşturuluyor…' : 'Oluştur ve Düzenle →'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </>
      )}
    </>
  );
}

function PlusIcon({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function XIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M18 6 6 18M6 6l12 12" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-0.5 shrink-0">
      <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  );
}
