'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { CokluSubeOverview } from './coklu-sube-yardimcilari';

export type AddableBusiness = { business_id: string; name: string; city: string | null };

async function requireUser() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false as const, error: 'Oturum bulunamadı' };
  return { ok: true as const, supabase, user };
}

export async function subeYonetimVerisiGetir(businessId: string): Promise<{ error: string } | CokluSubeOverview> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { data, error } = (await (context.supabase as any).rpc('owner_get_chain_overview_v1', {
    p_business_id: businessId,
  })) as { data: CokluSubeOverview | null; error: { message: string } | null };

  if (error) return { error: error.message };
  return data ?? { chain_id: null, chain_name: null, branches: [], total_views: 0, total_reservations: 0 };
}

export async function zincirOlustur(
  businessId: string,
  chainName: string,
): Promise<{ error: string } | { chainId: string }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const trimmed = chainName.trim();
  if (!trimmed) return { error: 'Zincir adı boş olamaz' };

  const { data, error } = (await (context.supabase as any).rpc('owner_create_chain_v1', {
    p_business_id: businessId,
    p_chain_name: trimmed,
  })) as { data: string | null; error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return { chainId: data ?? '' };
}

export async function subeEkle(
  chainId: string,
  businessId: string,
  branchLabel: string,
): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { error } = (await (context.supabase as any).rpc('owner_add_business_to_chain_v1', {
    p_chain_id: chainId,
    p_business_id: businessId,
    p_branch_label: branchLabel.trim() || null,
  })) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return null;
}

export async function subeCikar(businessId: string): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { error } = (await (context.supabase as any).rpc('owner_remove_business_from_chain_v1', {
    p_business_id: businessId,
  })) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return null;
}

export async function subeSirasiGuncelle(businessId: string, newSortOrder: number): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { error } = (await (context.supabase as any).rpc('owner_reorder_chain_branch_v1', {
    p_business_id: businessId,
    p_new_sort_order: newSortOrder,
  })) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return null;
}

export async function eklenebilirIsletmeleriListele(): Promise<{ error: string } | { businesses: AddableBusiness[] }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { data, error } = (await (context.supabase as any).rpc('owner_list_addable_businesses_v1')) as {
    data: AddableBusiness[] | null;
    error: { message: string } | null;
  };

  if (error) return { error: error.message };
  return { businesses: data ?? [] };
}
