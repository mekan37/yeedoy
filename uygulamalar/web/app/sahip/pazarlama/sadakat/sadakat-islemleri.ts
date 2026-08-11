'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';
import { rateLimit } from '@/src/lib/oran-siniri';

const REVALIDATE = '/sahip/pazarlama/sadakat';

type EylemSonucu = { error: string } | { ok: true };

const ProgramOlusturSemasi = z.object({
  business_id: z.string().uuid(),
  mode: z.enum(['stamp', 'points']),
  name: z.string().min(1).max(80),
  reward_desc: z.string().min(1).max(200),
  reward_threshold: z.coerce.number().int().min(1).max(1000),
});

export async function programOlustur(
  _prev: EylemSonucu | null,
  formData: FormData,
): Promise<EylemSonucu> {
  const parsed = ProgramOlusturSemasi.safeParse({
    business_id: formData.get('business_id'),
    mode: formData.get('mode'),
    name: formData.get('name'),
    reward_desc: formData.get('reward_desc'),
    reward_threshold: formData.get('reward_threshold'),
  });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (userId) => {
    const limitResult = rateLimit(`sadakat-program-olustur:${userId}`, 10, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('create_loyalty_program_v1', {
      p_business_id: d.business_id,
      p_mode: d.mode,
      p_name: d.name,
      p_reward_desc: d.reward_desc,
      p_reward_threshold: d.reward_threshold,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return { ok: true };
  });
}

const AktiflikSemasi = z.object({
  program_id: z.string().uuid(),
  is_active: z.coerce.boolean(),
});

export async function programAktiflikDegistir(
  programId: string,
  isActive: boolean,
): Promise<EylemSonucu> {
  const parsed = AktiflikSemasi.safeParse({ program_id: programId, is_active: isActive });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (userId) => {
    const limitResult = rateLimit(`sadakat-aktiflik:${userId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('set_loyalty_program_active_v1', {
      p_program_id: d.program_id,
      p_is_active: d.is_active,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return { ok: true };
  });
}

const ProgramGuncelleSemasi = z.object({
  program_id: z.string().uuid(),
  name: z.string().min(1).max(80),
  reward_desc: z.string().min(1).max(200),
  reward_threshold: z.coerce.number().int().min(1).max(1000),
});

export async function programGuncelle(
  programId: string,
  name: string,
  rewardDesc: string,
  rewardThreshold: number,
): Promise<EylemSonucu> {
  const parsed = ProgramGuncelleSemasi.safeParse({
    program_id: programId,
    name,
    reward_desc: rewardDesc,
    reward_threshold: rewardThreshold,
  });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (userId) => {
    const limitResult = rateLimit(`sadakat-program-guncelle:${userId}`, 10, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('update_loyalty_program_v1', {
      p_program_id: d.program_id,
      p_name: d.name,
      p_reward_desc: d.reward_desc,
      p_reward_threshold: d.reward_threshold,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return { ok: true };
  });
}

const ProgramSilSemasi = z.object({ program_id: z.string().uuid() });

export async function programSil(programId: string): Promise<EylemSonucu> {
  const parsed = ProgramSilSemasi.safeParse({ program_id: programId });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (userId) => {
    const limitResult = rateLimit(`sadakat-program-sil:${userId}`, 5, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('delete_loyalty_program_v1', {
      p_program_id: d.program_id,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return { ok: true };
  });
}

const QrOkutSemasi = z.object({
  business_id: z.string().uuid(),
  user_id: z.string().uuid(),
  amount: z.coerce.number().int().min(1).max(1000).default(1),
});

export type QrOkutSonucu =
  | { error: string }
  | { ok: true; member_id: string; progress: number; reward_threshold: number; reward_ready: boolean };

export async function qrOkut(
  businessId: string,
  userId: string,
  amount?: number,
): Promise<QrOkutSonucu> {
  const parsed = QrOkutSemasi.safeParse({ business_id: businessId, user_id: userId, amount });
  if (!parsed.success) return { error: 'Geçersiz QR içeriği' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`sadakat-qr-okut:${ownerId}`, 60, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { data, error } = (await (supabase as any).rpc('scan_loyalty_qr_v1', {
      p_business_id: d.business_id,
      p_user_id: d.user_id,
      p_amount: d.amount,
    })) as {
      data: { member_id: string; progress: number; reward_threshold: number; reward_ready: boolean } | null;
      error: { message: string } | null;
    };

    if (error) return { error: error.message };
    if (!data) return { error: 'Beklenmeyen yanıt' };
    revalidatePath(REVALIDATE);
    return {
      ok: true,
      member_id: data.member_id,
      progress: data.progress,
      reward_threshold: data.reward_threshold,
      reward_ready: data.reward_ready,
    };
  });
}

const OdulKullanSemasi = z.object({ member_id: z.string().uuid() });

export type OdulKullanSonucu = { error: string } | { ok: true; progress: number };

export async function odulKullan(memberId: string): Promise<OdulKullanSonucu> {
  const parsed = OdulKullanSemasi.safeParse({ member_id: memberId });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`sadakat-odul-kullan:${ownerId}`, 30, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { data, error } = (await (supabase as any).rpc('redeem_loyalty_reward_v1', {
      p_member_id: d.member_id,
    })) as { data: { member_id: string; progress: number } | null; error: { message: string } | null };

    if (error) return { error: error.message };
    if (!data) return { error: 'Beklenmeyen yanıt' };
    revalidatePath(REVALIDATE);
    return { ok: true, progress: data.progress };
  });
}
