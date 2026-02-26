import Link from 'next/link';
import { requireBusinessOwner } from '@/src/lib/auth';
import { getOwnedBusinessByIdOrSlug } from '@/src/lib/owned-business';
import { Card } from '@/src/ui/components/card';
import { QrGenerator } from '@/src/ui/sections/qr-generator';

type Props = { params: Promise<{ id: string }> };

export default async function BusinessQrPage({ params }: Props) {
  const { id } = await params;
  await requireBusinessOwner(id);

  const business = await getOwnedBusinessByIdOrSlug(id);

  if (!business) {
    return (
      <Card className="rounded-3xl">
        <h1 className="text-xl font-bold text-slate-900">QR sayfasi acilamadi</h1>
        <p className="mt-2 text-sm text-slate-600">Bu isletme bulunamadi. Gelen ID/Slug: {id}</p>
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
      <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <h1 className="text-2xl font-extrabold">QR Uretici - {business.business_name}</h1>
        <p className="mt-2 text-sm text-slate-600">SVG/PNG/PDF indir, masalara koy ve kisa link ile menuyu paylas.</p>
      </div>
      <div className="flex items-center justify-between">
        <span className="text-sm text-slate-500">QR varliklarini tek tikla olustur.</span>
        <Link href={`/dashboard/businesses/${business.business_id}/menu`} className="rounded-xl border border-slate-300 bg-white px-4 py-2">
          Menuye Don
        </Link>
      </div>
      <QrGenerator businessId={business.business_id} />
    </div>
  );
}
