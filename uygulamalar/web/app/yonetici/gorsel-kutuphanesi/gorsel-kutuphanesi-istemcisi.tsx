'use client';

import Image from 'next/image';
import { useState, useTransition } from 'react';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';
import { gorselKaydet, gorselPasiflestir, gorselSil } from './gorsel-kutuphanesi-islemleri';

export type StokGorsel = {
  id: string;
  image_url: string;
  keywords: string[];
  is_active: boolean;
  created_at: string;
};

export function GorselKutuphanesiIstemcisi({ initialGorseller }: { initialGorseller: StokGorsel[] }) {
  const [gorseller, setGorseller] = useState(initialGorseller);
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);

  // ── Yeni görsel ekleme formu ──
  const [uploading, setUploading] = useState(false);
  const [yeniUrl, setYeniUrl] = useState('');
  const [yeniKeywordsInput, setYeniKeywordsInput] = useState('');

  async function dosyaYukle(file: File | null) {
    if (!file) return;
    setUploading(true);
    setFormError(null);
    try {
      const compressed = await compressToWebP(file, 1600);
      const formData = new FormData();
      formData.set('file', compressed);
      const response = await fetch('/sunucu/medya/yonetici-yukleme', { method: 'POST', body: formData });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;
      if (!response.ok || !payload?.data?.url) throw new Error('upload_failed');
      setYeniUrl(payload.data.url);
    } catch {
      setFormError('Görsel yüklenemedi.');
    } finally {
      setUploading(false);
    }
  }

  function yeniGorselEkle() {
    if (!yeniUrl.trim()) {
      setFormError('Önce bir görsel yükleyin.');
      return;
    }
    const keywords = yeniKeywordsInput.split(',').map((k) => k.trim()).filter(Boolean);
    if (keywords.length === 0) {
      setFormError('En az bir anahtar ifade girin.');
      return;
    }
    setFormError(null);
    startTransition(async () => {
      const result = await gorselKaydet(null, yeniUrl, keywords, true);
      if (!result.ok) {
        setFormError(result.error);
        return;
      }
      setGorseller((prev) => [
        { id: result.id, image_url: yeniUrl, keywords, is_active: true, created_at: new Date().toISOString() },
        ...prev,
      ]);
      setYeniUrl('');
      setYeniKeywordsInput('');
    });
  }

  function pasifDegistir(id: string, aktif: boolean) {
    startTransition(async () => {
      const result = await gorselPasiflestir(id, aktif);
      if (!result.ok) {
        setFormError(result.error);
        return;
      }
      setGorseller((prev) => prev.map((g) => (g.id === id ? { ...g, is_active: aktif } : g)));
    });
  }

  function sil(id: string) {
    if (!confirm('Bu görseli kalıcı olarak silmek istediğinize emin misiniz? Bu görseli daha önce seçmiş ürünler etkilenmez, ama görsel yeni önerilerde artık görünmeyecek.')) return;
    startTransition(async () => {
      const result = await gorselSil(id);
      if (!result.ok) {
        setFormError(result.error);
        return;
      }
      setGorseller((prev) => prev.filter((g) => g.id !== id));
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-2xl border border-border bg-card p-4">
        <h2 className="text-sm font-black text-textStrong">Yeni Görsel Ekle</h2>
        <div className="mt-3 grid gap-3 sm:grid-cols-[96px_1fr]">
          <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-xl border border-border bg-bg text-[11px] font-extrabold text-muted">
            {yeniUrl ? <Image src={yeniUrl} alt="" fill sizes="96px" className="object-cover" unoptimized /> : 'Görsel yok'}
          </div>
          <div className="flex flex-col gap-2">
            <label className="inline-flex min-h-10 w-fit cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
              {uploading ? 'Yükleniyor...' : 'Görsel seç'}
              <input type="file" accept="image/png,image/jpeg,image/webp,image/gif,image/heic,image/heif" disabled={uploading} onChange={(e) => dosyaYukle(e.target.files?.[0] ?? null)} className="sr-only" />
            </label>
            <input
              type="text"
              value={yeniKeywordsInput}
              onChange={(e) => setYeniKeywordsInput(e.target.value)}
              placeholder="Anahtar ifadeler, virgülle ayır (ör: mercimek çorbası, kırmızı mercimek çorbası)"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <button
              type="button"
              onClick={yeniGorselEkle}
              disabled={isPending || uploading}
              className="self-start rounded-xl bg-primary px-3 py-2 text-xs font-extrabold text-white disabled:opacity-60"
            >
              Kütüphaneye Ekle
            </button>
            {formError && <p className="text-xs font-bold text-red-600">{formError}</p>}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        {gorseller.map((g) => (
          <div key={g.id} className={`flex flex-col gap-2 rounded-2xl border border-border bg-card p-3 ${!g.is_active ? 'opacity-50' : ''}`}>
            <div className="relative h-28 w-full overflow-hidden rounded-xl">
              <Image src={g.image_url} alt="" fill sizes="200px" className="object-cover" unoptimized />
            </div>
            <div className="flex flex-wrap gap-1">
              {g.keywords.map((k) => (
                <span key={k} className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-bold text-muted">{k}</span>
              ))}
            </div>
            <div className="mt-auto flex items-center justify-between gap-2">
              <label className="flex items-center gap-1.5 text-[11px] font-bold text-textStrong">
                <input type="checkbox" checked={g.is_active} onChange={(e) => pasifDegistir(g.id, e.target.checked)} className="rounded" />
                Aktif
              </label>
              <button type="button" onClick={() => sil(g.id)} className="text-[11px] font-bold text-red-600 hover:underline">Sil</button>
            </div>
          </div>
        ))}
        {gorseller.length === 0 && (
          <p className="col-span-full text-sm text-muted">Henüz kütüphanede görsel yok.</p>
        )}
      </div>
    </div>
  );
}
