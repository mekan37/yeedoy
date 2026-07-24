import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Önerilerim | Yeedoy',
  robots: { index: false, follow: false },
};

type SuggestionRow = {
  id: string;
  name: string;
  city: string | null;
  category: string | null;
  status: string;
  created_at: string;
};

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  pending: {
    label: 'İncelemede',
    className: 'border-amber-200 bg-amber-50 text-amber-700',
  },
  approved: {
    label: 'Onaylandı',
    className: 'border-green-200 bg-green-50 text-green-700',
  },
  rejected: {
    label: 'Reddedildi',
    className: 'border-red-200 bg-red-50 text-red-700',
  },
};

export default async function OnerilerimPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  let list: SuggestionRow[] = [];
  let fetchError = false;

  try {
    const { data, error } = await (supabase as any)
      .from('business_suggestions')
      .select('id, name, city, category, status, created_at')
      .eq('user_id', user!.id)
      .order('created_at', { ascending: false }) as {
      data: SuggestionRow[] | null;
      error: { code?: string; message?: string } | null;
    };

    if (error && error.code !== '42P01') {
      fetchError = true;
    } else {
      list = data ?? [];
    }
  } catch {
    fetchError = true;
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        {/* Geri */}
        <Link
          href="/profil"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
        >
          <svg
            viewBox="0 0 24 24"
            className="h-3.5 w-3.5 fill-none stroke-current"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <polyline points="15 18 9 12 15 6" />
          </svg>
          Profilime Dön
        </Link>

        {/* Başlık */}
        <div className="mb-8">
          <h1 className="text-2xl font-black text-textStrong">Önerilerim</h1>
          <p className="mt-1.5 text-sm text-muted">
            Yeedoy&apos;a eklenmesini önerdiğiniz işletmelerin durumunu buradan takip edebilirsiniz.
          </p>
        </div>

        {/* Hata */}
        {fetchError && (
          <div className="rounded-2xl border border-danger/20 bg-danger/6 px-5 py-4 text-sm font-bold text-danger">
            Öneriler yüklenirken bir sorun oluştu. Lütfen sayfayı yenileyin.
          </div>
        )}

        {/* Boş durum */}
        {!fetchError && list.length === 0 && (
          <div className="rounded-[20px] border border-border bg-card px-5 py-14 text-center shadow-yd1">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-3xl bg-cardAlt text-muted">
              <svg
                viewBox="0 0 64 64"
                className="h-9 w-9"
                fill="none"
                stroke="currentColor"
                strokeWidth="3"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M32 10 L40 26 L58 28 L45 41 L48 58 L32 50 L16 58 L19 41 L6 28 L24 26 Z" />
              </svg>
            </div>
            <p className="text-base font-black text-textStrong">Henüz önerin yok</p>
            <p className="mx-auto mt-2 max-w-xs text-sm leading-relaxed text-muted">
              Yeedoy&apos;da görmek istediğin bir işletme varsa ekibimize önerebilirsin.
            </p>
            <Link
              href="/oneri"
              className="mt-6 inline-flex min-h-10 items-center gap-2 rounded-2xl border border-border bg-bg px-5 text-sm font-extrabold text-textStrong hover:border-primary/30 hover:text-primary focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
            >
              İşletme Öner
            </Link>
          </div>
        )}

        {/* Liste */}
        {!fetchError && list.length > 0 && (
          <>
            <p className="mb-3 text-xs font-black uppercase tracking-wide text-muted">
              {list.length} öneri
            </p>
            <div className="flex flex-col gap-3">
              {list.map((s) => {
                const st =
                  STATUS_MAP[s.status] ?? {
                    label: s.status,
                    className: 'border-border bg-cardAlt text-muted',
                  };
                const meta = [s.category, s.city].filter(Boolean).join(' · ');
                const date = new Date(s.created_at).toLocaleDateString('tr-TR', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                });

                return (
                  <div
                    key={s.id}
                    className="flex items-start justify-between gap-3 rounded-[20px] border border-border bg-card px-5 py-4 shadow-yd1"
                  >
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-extrabold text-textStrong">{s.name}</p>
                      {meta && (
                        <p className="mt-0.5 truncate text-xs text-muted">{meta}</p>
                      )}
                      <p className="mt-1 text-[11px] text-muted">{date}</p>
                    </div>
                    <span
                      className={`mt-0.5 shrink-0 rounded-full border px-2.5 py-1 text-[11px] font-bold ${st.className}`}
                    >
                      {st.label}
                    </span>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </main>
  );
}
