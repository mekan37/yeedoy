'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

export function KampanyaFormuIstemcisi({ businessId, etiketler }: { businessId: string; etiketler: string[] }) {
  const [segment, setSegment] = useState('all_followers');
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [estimate, setEstimate] = useState<number | null>(null);
  const [result, setResult] = useState<{ sentCount: number; providerNotConfigured: boolean } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  // En son istenen segmenti tutar — yarışan (out-of-order) tahmin yanıtlarının
  // ekranda o an seçili olmayan bir segmentin sayısını göstermesini engeller.
  const istenenSegmentRef = useRef(segment);

  const tahminiGetir = (value: string) => {
    istenenSegmentRef.current = value;
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      const { data } = await (supabase as any).rpc('estimate_email_segment_v1', {
        p_business_id: businessId,
        p_segment: value,
      });
      if (istenenSegmentRef.current !== value) return;
      setEstimate(typeof data === 'number' ? data : 0);
    });
  };

  // Sayfa ilk açıldığında varsayılan segment ("Tüm takipçiler") için de
  // tahmini alıcı sayısını getir — aksi halde gönder butonunun "0 alıcı"
  // koruması, owner dropdown'ı hiç değiştirmeden gönderirse devre dışı kalır.
  useEffect(() => {
    tahminiGetir(segment);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- yalnızca ilk yüklemede çalışmalı
  }, []);

  const segmentDegisti = (value: string) => {
    setSegment(value);
    setResult(null);
    tahminiGetir(value);
  };

  const gonder = () => {
    setError(null);
    startTransition(async () => {
      const res = await fetch('/sunucu/sahip/eposta-kampanya', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId, subject, body, targetSegment: segment }),
      });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error ?? 'internal_error');
        return;
      }
      setResult(json.data);
      setSubject('');
      setBody('');
    });
  };

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-border bg-card p-4">
      <label className="flex flex-col gap-1 text-sm">
        Hedef Segment
        <select
          className="rounded-lg border border-border p-2"
          value={segment}
          onChange={(e) => segmentDegisti(e.target.value)}
        >
          <option value="all_followers">Tüm takipçiler</option>
          <option value="new_30d">Son 30 gün yeni takipçiler</option>
          <option value="inactive_30d">30+ gündür pasif takipçiler</option>
          {etiketler.map((tag) => (
            <option key={tag} value={`tag:${tag}`}>
              Etiket: {tag}
            </option>
          ))}
        </select>
      </label>
      {estimate !== null && (
        <p className="text-sm text-muted">Tahmini alıcı sayısı: {estimate}</p>
      )}
      <label className="flex flex-col gap-1 text-sm">
        Konu
        <input
          className="rounded-lg border border-border p-2"
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
          maxLength={200}
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        İçerik
        <textarea
          className="min-h-32 rounded-lg border border-border p-2"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          maxLength={5000}
        />
      </label>
      {error && <p className="text-sm text-danger">Bir hata oluştu: {error}</p>}
      {result && (
        <p className="text-sm text-primary">
          {result.providerNotConfigured
            ? 'Kampanya kaydedildi ama e-posta sağlayıcısı yapılandırılmadığı için gönderilmedi.'
            : `${result.sentCount} alıcıya gönderildi.`}
        </p>
      )}
      <button
        type="button"
        className="self-start rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white disabled:opacity-50"
        disabled={isPending || !subject.trim() || !body.trim() || estimate === 0}
        onClick={gonder}
      >
        {isPending ? 'Gönderiliyor…' : 'Gönder'}
      </button>
    </div>
  );
}
