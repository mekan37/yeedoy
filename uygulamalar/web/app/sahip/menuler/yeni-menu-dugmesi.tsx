'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createMenuAction } from './menu-islemleri';

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
    const result = await createMenuAction(businessId, title);
    if ('error' in result) {
      setError(result.error);
      setPending(false);
      return;
    }
    router.push(`/sahip/menuler/${result.menuId}/duzenle`);
  }

  return (
    <>
      {variant === 'card' ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex min-h-[200px] cursor-pointer flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-border bg-card transition hover:border-primary/50 hover:bg-primary/[0.03]"
        >
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-bg text-muted">
            <PlusIcon size={22} />
          </div>
          <div className="text-center">
            <p className="text-[13px] font-[800] text-textStrong">Yeni Menü Ekle</p>
            <p className="mt-0.5 text-[11px] text-muted">Taslak olarak oluşturulur</p>
          </div>
        </button>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="btn-primary flex cursor-pointer items-center gap-2 rounded-xl px-4 py-2 text-xs font-[800] text-white shadow-sm transition hover:opacity-90"
        >
          <PlusIcon size={13} />
          Yeni Menü
        </button>
      )}

      {open && (
        <>
          <div
            className="fixed inset-0 z-40 bg-black/50 backdrop-blur-[2px]"
            onClick={() => !pending && setOpen(false)}
          />
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-md rounded-2xl bg-card shadow-lg">
              <div className="flex items-center justify-between border-b border-border px-6 py-4">
                <h2 className="text-base font-[900] text-textStrong">Yeni Menü Oluştur</h2>
                <button
                  type="button"
                  onClick={() => !pending && setOpen(false)}
                  className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-xl border border-border text-muted hover:bg-bg disabled:opacity-50"
                >
                  <XIcon />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="flex flex-col gap-4 px-6 py-5">
                {businesses.length > 1 && (
                  <div className="flex flex-col gap-1">
                    <label className="text-[11px] font-[700] text-textStrong">İşletme *</label>
                    <select
                      name="business_id"
                      required
                      className="w-full rounded-xl border border-border px-3 py-2 text-sm text-textStrong outline-none focus:border-primary focus:ring-2 focus:ring-primary/25"
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
                    <div className="flex items-center gap-2 rounded-xl bg-bg px-3 py-2.5 text-xs font-[700] text-textStrong">
                      <BuildingIcon />
                      {businesses[0].name}
                    </div>
                  </>
                )}
                {businesses.length === 0 && (
                  <p className="rounded-xl bg-amber-50 px-3 py-2 text-xs font-[600] text-amber-700">
                    Önce bir işletme eklemeniz gerekiyor.
                  </p>
                )}

                <div className="flex flex-col gap-1">
                  <label className="text-[11px] font-[700] text-textStrong">Menü Adı *</label>
                  <input
                    name="title"
                    required
                    autoFocus
                    placeholder="ör: Ana Menü, Ramazan Menüsü, Kahvaltı…"
                    className="w-full rounded-xl border border-border px-3 py-2 text-sm text-textStrong placeholder:text-muted outline-none focus:border-primary focus:ring-2 focus:ring-primary/25"
                  />
                </div>

                <div className="flex items-start gap-2 rounded-xl bg-bg px-3 py-2.5 text-[11px] text-muted">
                  <InfoIcon />
                  Menü taslak olarak oluşturulur. Editörde hazırladıktan sonra aktif yapabilirsiniz.
                </div>

                {error && (
                  <p className="rounded-xl bg-red-50 px-3 py-2 text-xs font-[600] text-danger">{error}</p>
                )}

                <div className="flex items-center justify-end gap-3 pt-1">
                  <button
                    type="button"
                    onClick={() => !pending && setOpen(false)}
                    className="cursor-pointer rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong hover:bg-bg"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    disabled={pending || businesses.length === 0}
                    className="btn-primary flex cursor-pointer items-center gap-2 rounded-xl px-5 py-2 text-sm font-[700] text-white shadow-sm transition hover:opacity-90 disabled:opacity-60"
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
