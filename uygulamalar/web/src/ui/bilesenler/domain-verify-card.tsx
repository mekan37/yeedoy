'use client';

import { useState } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';

interface DomainVerifyCardProps {
  businessId: string;
  currentDomain: string | null;
}

type Step = 'input' | 'verify' | 'done';

export function DomainVerifyCard({ businessId, currentDomain }: DomainVerifyCardProps) {
  // currentDomain varsa input'u önceden doldur; adım her zaman 'input' başlar
  // (aktif domain rozeti sayfa tarafında ayrıca gösterilir)
  const [step, setStep] = useState<Step>('input');
  const [domain, setDomain] = useState(currentDomain ?? '');
  const [txtToken, setTxtToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleAdd() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/owner/domain', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, domain: domain.trim() }),
      });
      const json = (await res.json()) as {
        data?: { dns_txt_token: string };
        error?: string;
      };
      if (!res.ok) {
        const msg =
          json.error === 'domain_taken'
            ? 'Bu domain başka bir işletme tarafından kullanılıyor.'
            : json.error === 'rate_limited'
              ? 'Çok fazla istek. Lütfen bir saat bekleyin.'
              : json.error === 'invalid_domain'
                ? 'Geçerli bir domain adresi girin (örn: menu.siteniz.com).'
                : (json.error ?? 'Bir hata oluştu. Lütfen tekrar deneyin.');
        setError(msg);
        return;
      }
      setTxtToken(json.data!.dns_txt_token);
      setStep('verify');
    } catch {
      setError('Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.');
    } finally {
      setLoading(false);
    }
  }

  async function handleVerify() {
    setLoading(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const {
        data: { session },
      } = await supabase.auth.getSession();
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
      const res = await fetch(`${supabaseUrl}/functions/v1/verify-domain`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session?.access_token ?? ''}`,
        },
        body: JSON.stringify({ business_id: businessId, domain: domain.trim() }),
      });
      const json = (await res.json()) as {
        verified?: boolean;
        already_verified?: boolean;
        error?: string;
      };
      if (json.verified) {
        setStep('done');
      } else {
        const msg =
          json.error === 'txt_record_not_found'
            ? 'TXT kaydı henüz bulunamadı. DNS yayılması 24–48 saat sürebilir.'
            : json.error === 'domain_not_found'
              ? 'Önce domain ekleyin.'
              : json.error === 'dns_lookup_failed'
                ? 'DNS sorgusu başarısız. Lütfen daha sonra tekrar deneyin.'
                : (json.error ?? 'Doğrulama başarısız. Lütfen tekrar deneyin.');
        setError(msg);
      }
    } catch {
      setError('Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.');
    } finally {
      setLoading(false);
    }
  }

  // Doğrulama bu oturumda tamamlandı
  if (step === 'done') {
    return (
      <div className="flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3">
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="shrink-0 text-green-600"
        >
          <polyline points="20 6 9 17 4 12" />
        </svg>
        <span className="text-sm font-[700] text-green-700">{domain} doğrulandı</span>
      </div>
    );
  }

  // DNS TXT kaydı bekleniyor
  if (step === 'verify' && txtToken) {
    return (
      <div className="flex flex-col gap-3">
        <div className="rounded-lg border border-border bg-zinc-50 p-4">
          <p className="mb-3 text-sm font-[700] text-textStrong">DNS TXT Kaydı Ekleyin</p>
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center gap-2 text-xs">
              <span className="w-14 shrink-0 text-muted">Domain</span>
              <span className="font-mono font-[700] text-textStrong">{domain}</span>
            </div>
            <div className="flex items-center gap-2 text-xs">
              <span className="w-14 shrink-0 text-muted">Tür</span>
              <span className="font-mono font-[700] text-textStrong">TXT</span>
            </div>
            <div className="flex flex-col gap-1 text-xs">
              <span className="text-muted">Değer</span>
              <code className="block break-all rounded border border-border bg-white px-2 py-2 font-mono text-xs text-textStrong">
                {txtToken}
              </code>
            </div>
          </div>
          <p className="mt-3 text-[11px] text-muted">
            DNS kayıtlarınızın yayılması 24–48 saat sürebilir.
          </p>
        </div>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <div className="flex gap-2">
          <button
            onClick={handleVerify}
            disabled={loading}
            className="rounded-lg bg-primary px-4 py-2.5 text-sm font-[700] text-white transition-opacity disabled:opacity-50"
          >
            {loading ? 'Doğrulanıyor...' : 'DNS Kaydını Doğrula'}
          </button>
          <button
            onClick={() => {
              setStep('input');
              setTxtToken(null);
              setError(null);
            }}
            disabled={loading}
            className="rounded-lg border border-border bg-card px-4 py-2.5 text-sm font-[700] text-textStrong transition-opacity hover:bg-black/[0.04] disabled:opacity-50"
          >
            Geri
          </button>
        </div>
      </div>
    );
  }

  // Domain giriş formu
  return (
    <div className="flex flex-col gap-3">
      <div>
        <label className="mb-1.5 block text-xs font-[700] uppercase tracking-wide text-muted">
          {currentDomain ? 'Domain Güncelle' : 'Domain Ekle'}
        </label>
        <input
          type="text"
          value={domain}
          onChange={(e) => setDomain(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && domain.trim()) void handleAdd();
          }}
          placeholder="menu.ornekdomain.com"
          className="w-full rounded-lg border border-border bg-bg px-3 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button
        onClick={() => void handleAdd()}
        disabled={loading || !domain.trim()}
        className="self-start rounded-lg bg-primary px-4 py-2.5 text-sm font-[700] text-white transition-opacity disabled:opacity-50"
      >
        {loading ? 'Ekleniyor...' : currentDomain ? 'Güncelle ve Doğrula' : 'Domain Ekle'}
      </button>
    </div>
  );
}
