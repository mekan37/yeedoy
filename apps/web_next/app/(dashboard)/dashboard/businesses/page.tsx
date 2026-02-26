import Link from 'next/link';
import { requireUser } from '@/src/lib/auth';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { Card } from '@/src/ui/components/card';
import { BusinessCreateForm } from '@/src/ui/sections/business-create-form';

type OwnerBusiness = {
  business_id: string;
  business_name: string;
  city: string;
  district: string;
  claim_status: string;
  branch_label: string | null;
  owner_role: string | null;
};

export default async function BusinessesPage() {
  await requireUser();
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase.rpc('owner_list_my_businesses_v2', {
    p_status: 'approved',
    p_limit: 100,
    p_offset: 0,
  });

  const businesses = (data ?? []) as OwnerBusiness[];

  return (
    <div className="grid gap-6 lg:grid-cols-3">
      <Card className="lg:col-span-1">
        <h2 className="mb-2 text-xl font-bold text-slate-900">Yeni Isletme Basvurusu</h2>
        <p className="mb-4 text-sm text-slate-500">
          Isletmeni eklemek icin temel bilgileri gir. Talep admin onayina gider.
        </p>
        <BusinessCreateForm />
      </Card>

      <Card className="lg:col-span-2">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-xl font-bold text-slate-900">Isletmelerim</h2>
          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
            {businesses.length} kayit
          </span>
        </div>

        <div className="space-y-3">
          {businesses.map((b) => (
            <Link
              key={b.business_id}
              href={`/dashboard/businesses/${encodeURIComponent(b.business_id)}`}
              className="block rounded-2xl border border-slate-200 bg-white p-4 transition hover:border-slate-300 hover:shadow-sm"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-base font-semibold text-slate-900">{b.business_name}</p>
                  <p className="mt-1 text-sm text-slate-500">
                    {b.city || '-'} {b.district ? `- ${b.district}` : ''}
                  </p>
                </div>
                <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                  Onayli
                </span>
              </div>
            </Link>
          ))}

          {businesses.length === 0 && (
            <div className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-6 text-center text-sm text-slate-500">
              Henuz gorunur bir isletmen yok. Eger claim onaylandiysa sayfayi yenile.
            </div>
          )}
        </div>
      </Card>
    </div>
  );
}
