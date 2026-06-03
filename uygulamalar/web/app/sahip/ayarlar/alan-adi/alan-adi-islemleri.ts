'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { revalidatePath } from 'next/cache';

// ─── Validation ────────────────────────────────────────────────────────────────

/** Hostname-only validation: strips http/https, rejects paths and query strings. */
function validateHostname(input: string): { valid: boolean; hostname: string | null } {
  const trimmed = input.trim().toLowerCase();
  if (!trimmed) return { valid: false, hostname: null };
  if (trimmed.startsWith('http')) return { valid: false, hostname: null };
  if (trimmed.includes('/')) return { valid: false, hostname: null };
  if (trimmed.includes('?')) return { valid: false, hostname: null };
  if (!/^[a-z0-9.-]+$/.test(trimmed)) return { valid: false, hostname: null };
  if (!trimmed.includes('.')) return { valid: false, hostname: null };
  return { valid: true, hostname: trimmed };
}

// ─── Types ─────────────────────────────────────────────────────────────────────

export type DomainDurumu = {
  domain: string;
  dns_txt_token: string;
  verified_at: string | null;
  is_active: boolean;
} | null;

export type DomainIslemSonucu =
  | { basarili: true; durum: 'kayit_eklendi'; token: string; domain: string }
  | { basarili: true; durum: 'dogrulandi' }
  | { basarili: true; durum: 'txt_bekleniyor'; token: string; found_records?: string[] }
  | { basarili: true; durum: 'silindi' }
  | { basarili: false; hata: string };

// ─── Action: Fetch current domain status ──────────────────────────────────────

export async function getDomainDurumu(businessId: string): Promise<DomainDurumu> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const canManage = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManage) return null;

  const { data, error } = await (supabase as any).rpc('get_custom_domain_v1', {
    p_business_id: businessId,
  });

  if (error || !data) return null;
  return data as DomainDurumu;
}

// ─── Action: Register / update domain (Step 1) ────────────────────────────────

export async function domainEkle(
  businessId: string,
  domain: string,
): Promise<DomainIslemSonucu> {
  const { valid, hostname } = validateHostname(domain);
  if (!valid || !hostname) {
    return {
      basarili: false,
      hata: 'Geçersiz domain formatı. Sadece hostname girin (örn: menu.isletmem.com).',
    };
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const canManage = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManage) return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };

  const { data, error } = await (supabase as any).rpc('upsert_custom_domain_v1', {
    p_business_id: businessId,
    p_domain: hostname,
  });

  if (error) {
    const msg = (error as { message?: string }).message ?? '';
    if (msg.includes('domain_taken')) return { basarili: false, hata: 'Bu domain başka bir işletme tarafından kullanılıyor.' };
    if (msg.includes('not_owner')) return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };
    if (msg.includes('invalid_domain')) return { basarili: false, hata: 'Geçersiz domain formatı.' };
    return { basarili: false, hata: 'Domain eklenemedi. Lütfen tekrar deneyin.' };
  }

  const row = data as { dns_txt_token: string; domain: string } | null;
  if (!row) return { basarili: false, hata: 'Sunucu yanıtı beklenen formatta değil.' };

  revalidatePath('/sahip/ayarlar/alan-adi');

  return {
    basarili: true,
    durum: 'kayit_eklendi',
    token: row.dns_txt_token,
    domain: row.domain,
  };
}

// ─── Action: Trigger DNS verification (Step 2) ────────────────────────────────

export async function domainDogrula(
  businessId: string,
  domain: string,
): Promise<DomainIslemSonucu> {
  const { valid, hostname } = validateHostname(domain);
  if (!valid || !hostname) {
    return { basarili: false, hata: 'Geçersiz domain.' };
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const canManage = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManage) return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };

  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.access_token) return { basarili: false, hata: 'Oturum süresi dolmuş.' };

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) return { basarili: false, hata: 'Sistem yapılandırma hatası.' };

  let result: {
    verified?: boolean;
    already_verified?: boolean;
    error?: string;
    expected?: string;
    found_records?: string[];
  };

  try {
    const res = await fetch(`${supabaseUrl}/functions/v1/verify-domain`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ business_id: businessId, domain: hostname }),
    });

    result = await res.json();

    if (!res.ok) {
      const errCode = result.error ?? 'unknown';
      if (errCode === 'domain_not_found') {
        return {
          basarili: false,
          hata: 'Domain kaydı bulunamadı. Önce domain ekleyin.',
        };
      }
      if (errCode === 'dns_lookup_failed') {
        return {
          basarili: false,
          hata: 'DNS sorgulama başarısız. Ağ bağlantısı sorunlu olabilir.',
        };
      }
      return { basarili: false, hata: result.error ?? 'Doğrulama başarısız.' };
    }
  } catch {
    return { basarili: false, hata: 'Ağ hatası. Lütfen tekrar deneyin.' };
  }

  if (result.verified) {
    revalidatePath('/sahip/ayarlar/alan-adi');
    return { basarili: true, durum: 'dogrulandi' };
  }

  // DNS TXT record not yet propagated
  return {
    basarili: true,
    durum: 'txt_bekleniyor',
    token: result.expected ?? '',
    found_records: result.found_records,
  };
}

// ─── Action: Delete domain ────────────────────────────────────────────────────

export async function domainSil(businessId: string): Promise<DomainIslemSonucu> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const canManage = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManage) return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };

  const { error } = await (supabase as any).rpc('delete_custom_domain_v1', {
    p_business_id: businessId,
  });

  if (error) {
    return { basarili: false, hata: 'Domain silinemedi.' };
  }

  revalidatePath('/sahip/ayarlar/alan-adi');
  return { basarili: true, durum: 'silindi' };
}
