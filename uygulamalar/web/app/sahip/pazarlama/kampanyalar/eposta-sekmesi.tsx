'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import type { Kampanya } from './kampanya-formu';

export type EpostaKampanyaOzet = {
  id: string;
  subject: string;
  target_segment: string;
  sent_at: string | null;
  sent_count: number;
  created_at: string;
  campaign_id: string | null;
  campaign_title: string | null;
};

function segmentEtiketi(segment: string): string {
  if (segment.startsWith('tag:')) return `Etiket: ${segment.slice(4)}`;
  if (segment === 'all_followers') return 'Tüm takipçiler';
  if (segment === 'new_30d') return 'Son 30 gün yeni takipçiler';
  if (segment === 'inactive_30d') return '30+ gündür pasif takipçiler';
  return segment;
}

interface Props {
  businessId: string;
  etiketler: string[];
  kampanyalar: Kampanya[];
  initialEmailKampanyalar: EpostaKampanyaOzet[];
  onKampanyaOlusturTikla: () => void;
}

export function EpostaSekmesi({ businessId, etiketler, kampanyalar, initialEmailKampanyalar, onKampanyaOlusturTikla }: Props) {
  const [emailKampanyalar, setEmailKampanyalar] = useState(initialEmailKampanyalar);
  const [campaignId, setCampaignId] = useState(kampanyalar[0]?.id ?? '');
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

  useEffect(() => {
    if (kampanyalar.length > 0) tahminiGetir(segment);
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
        body: JSON.stringify({ businessId, campaignId, subject, body, targetSegment: segment }),
      });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error ?? 'internal_error');
        return;
      }
      setResult(json.data);
      setEmailKampanyalar((prev) => [
        {
          id: json.data.emailCampaignId,
          subject,
          target_segment: segment,
          sent_at: new Date().toISOString(),
          sent_count: json.data.sentCount,
          created_at: new Date().toISOString(),
          campaign_id: campaignId,
          campaign_title: kampanyalar.find((k) => k.id === campaignId)?.title ?? null,
        },
        ...prev,
      ]);
      setSubject('');
      setBody('');
    });
  };

  if (kampanyalar.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-border py-16 text-center">
        <p className="text-sm font-bold text-textStrong">Önce bir kampanya oluşturun</p>
        <p className="max-w-sm text-xs text-muted">
          E-posta gönderebilmek için önce &quot;Kampanyalar&quot; sekmesinden bir kampanya oluşturmanız gerekir —
          e-postalar her zaman bir kampanyaya bağlı olarak gönderilir.
        </p>
        <button
          type="button"
          onClick={onKampanyaOlusturTikla}
          className="mt-1 rounded-xl bg-primary px-5 py-2.5 text-sm font-extrabold text-white shadow-xs transition hover:opacity-90"
        >
          Kampanya Oluştur
        </button>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 gap-5 md:grid-cols-[1fr_320px]">
      <div className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-5">
        <h3 className="text-sm font-black text-textStrong">Yeni E-posta Kampanyası</h3>

        <label className="flex flex-col gap-1 text-sm">
          Bağlı Kampanya
          <select
            className="rounded-lg border border-border p-2"
            value={campaignId}
            onChange={(e) => setCampaignId(e.target.value)}
          >
            {kampanyalar.map((k) => (
              <option key={k.id} value={k.id}>{k.title}</option>
            ))}
          </select>
        </label>

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
          disabled={isPending || !campaignId || !subject.trim() || !body.trim() || estimate === 0}
          onClick={gonder}
        >
          {isPending ? 'Gönderiliyor…' : 'Gönder'}
        </button>
      </div>

      <div className="rounded-2xl border border-border bg-card p-5">
        <h3 className="mb-3 text-sm font-black text-textStrong">Geçmiş E-posta Kampanyaları</h3>
        {emailKampanyalar.length === 0 ? (
          <p className="text-sm text-muted">Henüz gönderilmiş bir e-posta kampanyası yok.</p>
        ) : (
          <ul className="flex flex-col gap-3">
            {emailKampanyalar.map((k) => (
              <li key={k.id} className="rounded-xl border border-border bg-bg p-3">
                <p className="font-semibold text-textStrong">{k.subject}</p>
                {k.campaign_title && (
                  <p className="mt-0.5 text-xs font-bold text-primary">{k.campaign_title}</p>
                )}
                <p className="text-sm text-muted">
                  {segmentEtiketi(k.target_segment)} — {k.sent_at ? `${k.sent_count} alıcıya gönderildi` : 'Henüz gönderilmedi'}
                </p>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
