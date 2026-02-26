import Link from 'next/link';
import { Card } from '@/src/ui/components/card';
import { requireUser } from '@/src/lib/auth';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

type OwnerBusiness = {
  business_id: string;
};

export default async function DashboardPage() {
  const user = await requireUser();
  const supabase = await createSupabaseServerClient();

  const { data: ownedRows } = await supabase.rpc('owner_list_my_businesses_v2', {
    p_status: 'approved',
    p_limit: 200,
    p_offset: 0,
  });

  const businessIds = ((ownedRows ?? []) as OwnerBusiness[]).map((x) => x.business_id);
  let itemCount = 0;
  if (businessIds.length > 0) {
    const { count } = await supabase
      .from('menu_items')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds);
    itemCount = count ?? 0;
  }

  return (
    <div className="grid gap-6">
      <div className="rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-slate-100 p-6">
        <p className="text-sm font-medium text-slate-500">Hos geldin</p>
        <h1 className="mt-1 text-2xl font-extrabold text-slate-900">{user.email}</h1>
        <p className="mt-2 text-sm text-slate-600">
          Isletmelerini yonet, menunu guncelle ve QR varliklarini tek yerden olustur.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="rounded-3xl">
          <p className="text-sm text-slate-500">Isletme Sayisi</p>
          <p className="mt-1 text-3xl font-bold text-slate-900">{businessIds.length}</p>
        </Card>
        <Card className="rounded-3xl">
          <p className="text-sm text-slate-500">Menu Urunu</p>
          <p className="mt-1 text-3xl font-bold text-slate-900">{itemCount}</p>
        </Card>
        <Card className="rounded-3xl">
          <p className="text-sm text-slate-500">Hizli Islem</p>
          <div className="mt-3">
            <Link
              className="inline-flex items-center rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-700"
              href="/dashboard/businesses"
            >
              Isletmelerimi Yonet
            </Link>
          </div>
        </Card>
      </div>
    </div>
  );
}
