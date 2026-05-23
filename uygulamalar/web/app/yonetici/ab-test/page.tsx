import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { AbTestYonetici } from './ab-test-istemci';

export const metadata: Metadata = {
  title: 'A/B Test | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function AbTestPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  // Fetch existing A/B tests (linked to feature_flags with variant config)
  const { data: tests } = await (supabase as any)
    .from('runtime_feature_flags')
    .select('key, enabled, rollout_percent, metadata, updated_at')
    .ilike('key', 'ab_%')
    .order('updated_at', { ascending: false })
    .limit(50) as { data: Array<{
      key: string; enabled: boolean; rollout_percent: number;
      metadata: {
        description?: string;
        environment?: string;
        impressions_a?: number;
        impressions_b?: number;
        conversions_a?: number;
        conversions_b?: number;
        winner?: 'a' | 'b' | null;
        created_at?: string;
      } | null;
      updated_at: string;
    }> | null };

  const allTests = (tests ?? []).map((test) => ({
      id: test.key,
      name: test.key,
      description: test.metadata?.description ?? '',
      enabled: test.enabled,
      rollout_percent: test.rollout_percent,
      environment: test.metadata?.environment ?? 'all',
      created_at: test.metadata?.created_at ?? test.updated_at,
      updated_at: test.updated_at,
      impressions_a: test.metadata?.impressions_a ?? 0,
      impressions_b: test.metadata?.impressions_b ?? 0,
      conversions_a: test.metadata?.conversions_a ?? 0,
      conversions_b: test.metadata?.conversions_b ?? 0,
      winner: test.metadata?.winner ?? null,
    })) as Array<{
      id: string; name: string; description: string; enabled: boolean;
      rollout_percent: number; environment: string; created_at: string; updated_at: string;
      impressions_a?: number; impressions_b?: number;
      conversions_a?: number; conversions_b?: number;
      winner?: 'a' | 'b' | null;
    }>;

  // Platform stats for context
  const { count: userCount } = await (supabase as any)
    .from('user_profiles')
    .select('user_id', { count: 'exact', head: true });

  const active = allTests.filter(t => t.enabled);
  const completed = allTests.filter(t => !t.enabled);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="A/B Test"
        description="Platform genelinde deney oluştur, yayılım oranı belirle ve sonuçları izle"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <AbTestYonetici tests={allTests} totalUsers={userCount ?? 0} />
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
