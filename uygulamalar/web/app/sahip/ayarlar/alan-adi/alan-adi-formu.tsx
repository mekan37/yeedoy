'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import {
  domainEkle,
  domainDogrula,
  domainSil,
  type DomainDurumu,
  type DomainIslemSonucu,
} from './alan-adi-islemleri';

// ─── Types ─────────────────────────────────────────────────────────────────────

interface Props {
  businessId: string;
  businessName: string;
  initialDurum: DomainDurumu;
}

// ─── Main component ─────────────────────────────────────────────────────────────

export function AlanAdiFormu({ businessId, businessName, initialDurum }: Props) {
  const [durum, setDurum] = useState<DomainDurumu>(initialDurum);
  const [domainInput, setDomainInput] = useState('');
  const [sonuc, setSonuc] = useState<DomainIslemSonucu | null>(null);
  const [isPending, startTransition] = useTransition();

  // Step 1: register / reset the domain row and get the TXT token
  function handleEkle(e: React.FormEvent) {
    e.preventDefault();
    setSonuc(null);
    startTransition(async () => {
      const res = await domainEkle(businessId, domainInput);
      setSonuc(res);
      if (res.basarili && res.durum === 'kayit_eklendi') {
        setDurum({
          domain: res.domain,
          dns_txt_token: res.token,
          verified_at: null,
          is_active: false,
        });
        setDomainInput('');
      }
    });
  }

  // Step 2: poll DNS verification via edge function
  function handleDogrula() {
    if (!durum?.domain) return;
    setSonuc(null);
    startTransition(async () => {
      const res = await domainDogrula(businessId, durum.domain);
      setSonuc(res);
      if (res.basarili && res.durum === 'dogrulandi') {
        setDurum((prev) =>
          prev ? { ...prev, verified_at: new Date().toISOString(), is_active: true } : prev,
        );
      }
    });
  }

  // Delete
  function handleSil() {
    setSonuc(null);
    startTransition(async () => {
      const res = await domainSil(businessId);
      setSonuc(res);
      if (res.basarili) {
        setDurum(null);
        setDomainInput('');
      }
    });
  }

  const isVerified = Boolean(durum?.verified_at);

  return (
    <div className="flex flex-col gap-5">
      {/* Current status display */}
      {durum && (
        <div className="flex flex-col gap-3">
          <div>
            <p className="text-xs font-[700] uppercase tracking-wide text-muted mb-1.5">
              Mevcut Domain
            </p>
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-lg border border-border bg-card px-3 py-1.5 font-mono text-sm font-[700] text-textStrong">
                {durum.domain}
              </span>
              {isVerified ? (
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-[800] text-emerald-700 border border-emerald-200">
                  <CheckIcon /> Dogrulandi
                </span>
              ) : (
                <span className="rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-[800] text-amber-700 border border-amber-200">
                  DNS bekleniyor
                </span>
              )}
            </div>
          </div>

          {/* TXT record instructions — show when not yet verified */}
          {!isVerified && durum.dns_txt_token && (
            <DnsTalimat domain={durum.domain} token={durum.dns_txt_token} />
          )}

          {/* Action buttons for existing domain */}
          <div className="flex flex-wrap gap-2 pt-1">
            {!isVerified && (
              <PanelActionButton
                variant="primary"
                loading={isPending}
                onClick={handleDogrula}
              >
                DNS&apos;i Dogrula
              </PanelActionButton>
            )}
            <PanelActionButton
              variant="danger"
              loading={isPending}
              onClick={handleSil}
            >
              {isVerified ? 'Domaini Kaldir' : 'Iptal Et'}
            </PanelActionButton>
          </div>
        </div>
      )}

      {/* Add / change domain form */}
      {!durum && (
        <form onSubmit={handleEkle} className="flex flex-col gap-3">
          <label className="text-sm font-[700] text-textStrong">
            Domain Adresi
          </label>
          <input
            type="text"
            value={domainInput}
            onChange={(e) => setDomainInput(e.target.value)}
            placeholder="menu.isletmem.com"
            className="rounded-xl border border-border bg-card px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            disabled={isPending}
            autoComplete="off"
            spellCheck={false}
          />
          <p className="text-xs text-muted">
            Sadece hostname girin (http:// veya path eklemeyin).
            Ornek: <code className="rounded bg-zinc-100 px-1 py-0.5">siparis.cafeabc.com</code>
          </p>
          <PanelActionButton
            type="submit"
            variant="primary"
            loading={isPending}
            disabled={!domainInput.trim()}
          >
            Domain Ekle
          </PanelActionButton>
        </form>
      )}

      {/* Change domain link when domain already exists */}
      {durum && (
        <button
          type="button"
          onClick={() => {
            setDurum(null);
            setSonuc(null);
            setDomainInput(durum.domain);
          }}
          className="self-start text-xs font-[700] text-primary underline underline-offset-2 hover:opacity-80"
        >
          Farklı domain ekle
        </button>
      )}

      {/* Result feedback */}
      {sonuc && <SonucBandı sonuc={sonuc} />}
    </div>
  );
}

// ─── DNS TXT record instructions panel ─────────────────────────────────────────

function DnsTalimat({ domain, token }: { domain: string; token: string }) {
  const [kopyalandi, setKopyalandi] = useState(false);

  function handleKopyala() {
    navigator.clipboard.writeText(token).then(() => {
      setKopyalandi(true);
      setTimeout(() => setKopyalandi(false), 2000);
    });
  }

  return (
    <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 flex flex-col gap-3">
      <p className="text-sm font-[700] text-amber-800">
        DNS Dogrulama Adimi
      </p>
      <p className="text-xs text-amber-700">
        Domain saglayicinizin DNS yonetim panelinde asagidaki TXT kaydini ekleyin, ardindan &quot;DNS&apos;i Dogrula&quot; dugmesine tiklayin.
      </p>
      <div className="rounded-lg bg-white/70 border border-amber-100 p-3 flex flex-col gap-2 font-mono text-xs">
        <DnsRow label="Kayit tipi" value="TXT" />
        <DnsRow label="Ad (Host)" value={domain} />
        <DnsRow label="Deger (Value)" value={token} />
      </div>
      <button
        type="button"
        onClick={handleKopyala}
        className="self-start rounded-lg border border-amber-300 bg-white/80 px-3 py-1.5 text-xs font-[700] text-amber-800 hover:bg-white transition-colors"
      >
        {kopyalandi ? 'Kopyalandi!' : 'Degeri Kopyala'}
      </button>
      <p className="text-[11px] text-amber-600">
        DNS yayilimi 5 dakika ile 24 saat arasinda surebilir. Kaydi ekledikten sonra dogrulamayi tekrar deneyin.
      </p>
    </div>
  );
}

function DnsRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex flex-col gap-0.5 sm:flex-row sm:gap-3">
      <span className="min-w-[100px] font-sans font-[700] text-muted">{label}:</span>
      <span className="break-all text-textStrong">{value}</span>
    </div>
  );
}

// ─── Result feedback banner ─────────────────────────────────────────────────────

function SonucBandı({ sonuc }: { sonuc: DomainIslemSonucu }) {
  if (!sonuc.basarili) {
    return (
      <div className="rounded-xl border border-rose-200 bg-rose-50 p-4">
        <p className="text-sm font-[700] text-rose-700">{sonuc.hata}</p>
      </div>
    );
  }

  if (sonuc.durum === 'kayit_eklendi') {
    return (
      <div className="rounded-xl border border-blue-200 bg-blue-50 p-4">
        <p className="text-sm font-[700] text-blue-700">
          Domain kaydedildi. Asagidaki DNS talimatlarini izleyin.
        </p>
      </div>
    );
  }

  if (sonuc.durum === 'dogrulandi') {
    return (
      <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4">
        <p className="text-sm font-[700] text-emerald-700">
          Domain basariyla dogrulandi!
        </p>
      </div>
    );
  }

  if (sonuc.durum === 'txt_bekleniyor') {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 flex flex-col gap-2">
        <p className="text-sm font-[700] text-amber-700">
          TXT kaydı henüz bulunamadı. DNS yayılımı biraz zaman alabilir.
        </p>
        {sonuc.found_records && sonuc.found_records.length > 0 && (
          <div className="text-xs text-amber-600">
            <p className="font-[700]">Mevcut TXT kayitlari:</p>
            <ul className="mt-1 space-y-0.5 font-mono">
              {sonuc.found_records.map((r, i) => (
                <li key={i} className="break-all">{r}</li>
              ))}
            </ul>
          </div>
        )}
        {sonuc.found_records?.length === 0 && (
          <p className="text-xs text-amber-600">
            Sorgulanan domaine ait hicbir TXT kaydi bulunamadı.
          </p>
        )}
      </div>
    );
  }

  if (sonuc.durum === 'silindi') {
    return (
      <div className="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
        <p className="text-sm font-[700] text-muted">Domain kaldirildi.</p>
      </div>
    );
  }

  return null;
}

// ─── Icons ──────────────────────────────────────────────────────────────────────

function CheckIcon() {
  return (
    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
