import Link from 'next/link';
import { requireBusinessOwner } from '@/src/lib/auth';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { Card } from '@/src/ui/components/card';

type Props = { params: Promise<{ id: string }> };

async function findBusiness(admin: ReturnType<typeof createServiceRoleClient>, idOrSlug: string) {
  const byId = await admin.from('businesses').select('*').eq('id', idOrSlug).maybeSingle();
  if (byId.data) return byId.data;
  const bySlug = await admin.from('businesses').select('*').eq('slug', idOrSlug).maybeSingle();
  return bySlug.data ?? null;
}

export default async function BusinessDetailPage({ params }: Props) {
  const { id } = await params;
  await requireBusinessOwner(id);

  const admin = createServiceRoleClient();
  const business = await findBusiness(admin, id);

  if (!business) {
    return (
      <Card className="rounded-3xl">
        <h1 className="text-xl font-bold text-slate-900">Isletme bulunamadi</h1>
        <p className="mt-2 text-sm text-slate-600">ID/Slug: {id}</p>
        <div className="mt-4">
          <Link href="/dashboard/businesses" className="rounded-xl bg-slate-900 px-4 py-2 text-white">
            Isletmelere Don
          </Link>
        </div>
      </Card>
    );
  }

  return (
    <div className="grid gap-6">
      <Card className="rounded-3xl">
        <h1 className="text-2xl font-extrabold">{business.name}</h1>
        <p className="mt-2 text-sm text-slate-600">
          {business.city ?? '-'} {business.district ? `- ${business.district}` : ''}
        </p>
      </Card>

      <div className="flex flex-wrap gap-2">
        <Link href={`/dashboard/businesses/${business.id}/menu`} className="rounded-xl bg-slate-900 px-4 py-2 text-white">
          Menu Duzenle
        </Link>
        <Link href={`/dashboard/businesses/${business.id}/qr`} className="rounded-xl border border-slate-300 bg-white px-4 py-2">
          QR Varliklari
        </Link>
        {business.slug ? (
          <Link href={`/b/${business.slug}`} target="_blank" className="rounded-xl border border-slate-300 bg-white px-4 py-2">
            Public Menuyu Ac
          </Link>
        ) : null}
      </div>
    </div>
  );
}
