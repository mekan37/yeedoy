import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PhotosClient } from './photos-client';
import type { PhotoItem } from './photos-client';

export const metadata: Metadata = {
  title: 'Fotoğraflar | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerPhotosPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  // İşletmeleri al
  const { data: claims } = await (supabase as any)
    .from('owner_claims')
    .select('business_id, businesses(id, name)')
    .eq('user_id', user.id)
    .eq('status', 'approved') as {
      data: { business_id: string; businesses: { id: string; name: string } }[] | null
    };

  const businesses = (claims ?? [])
    .map((c) => c.businesses)
    .filter(Boolean) as { id: string; name: string }[];

  const businessIds = businesses.map((b) => b.id);
  const defaultBusinessId = businessIds[0] ?? null;

  // İşletmeye ait fotoğrafları çek
  const { data: photos } = businessIds.length > 0
    ? await (supabase as any)
        .from('business_media')
        .select('id, business_id, url, url_thumb, status, kind, created_at')
        .in('business_id', businessIds)
        .eq('is_hidden', false)
        .neq('status', 'rejected')
        .order('created_at', { ascending: false })
        .limit(200)
    : { data: [] };

  const photoList = (photos ?? []) as PhotoItem[];

  const approvedCount = photoList.filter((p) => p.status === 'approved').length;
  const pendingCount  = photoList.filter((p) => p.status === 'pending').length;

  const descParts = [
    approvedCount > 0 ? `${approvedCount} yayında` : null,
    pendingCount  > 0 ? `${pendingCount} incelemede` : null,
  ].filter(Boolean);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Fotoğraflar"
        description={
          descParts.length > 0
            ? descParts.join(' · ')
            : 'İşletmenize ait galeri fotoğrafları'
        }
      />
      <PhotosClient
        initialPhotos={photoList}
        businesses={businesses}
        defaultBusinessId={defaultBusinessId}
      />
    </div>
  );
}
