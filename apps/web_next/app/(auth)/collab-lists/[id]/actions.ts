'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

type ActionResult = { error: string } | null;

export async function voteOnItem(listId: string, itemId: string, vote: 1 | -1 | 0): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  try {
    const { error } = await supabase.rpc('upsert_collab_vote_v1' as never, {
      p_item_id: itemId,
      p_vote: vote,
    } as never);
    if (error) return { error: error.message };
  } catch {
    return { error: 'Oy kaydedilemedi' };
  }

  revalidatePath(`/collab-lists/${listId}`);
  return null;
}
