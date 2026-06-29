import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import {
  AiAnalysisClient,
  type Business,
} from '@/src/ui/bolumler/ai-analysis-client';

export const metadata: Metadata = {
  title: 'AI Menu Analizi | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerAiAnalysisPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: businesses } = (await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id)
    .order('created_at', { ascending: false })) as {
    data: Business[] | null;
  };

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 flex flex-col gap-6">
      <div>
        <p className="text-xs font-[700] uppercase tracking-wide text-muted mb-1">
          Yapay Zeka
        </p>
        <h1 className="text-2xl font-[900] text-textStrong">AI Menu Analizi</h1>
        <p className="mt-1 text-sm text-muted">
          Menu gorseli URL&apos;si veya metin girerek AI ile menu ogelerini cikarın.
        </p>
      </div>
      <AiAnalysisClient businesses={businesses ?? []} />
    </div>
  );
}
