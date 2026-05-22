import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const revalidate = 86400;

export const metadata: Metadata = {
  title: 'Yasal Bilgiler | Yeedoy',
  description: 'Gizlilik politikası, kullanım şartları ve diğer yasal belgeler',
};

const FALLBACK_DOCS = [
  { slug: 'privacy',          title: 'Gizlilik Politikası',         description: 'Kişisel verilerinizin nasıl işlendiği' },
  { slug: 'terms',            title: 'Kullanım Şartları',            description: 'Hizmet kullanım koşulları' },
  { slug: 'cookies',          title: 'Çerez Politikası',             description: 'Çerez kullanımı hakkında bilgi' },
  { slug: 'yorum-politikasi', title: 'Yorum ve İçerik Politikası',  description: 'Yorum, fiyat katkısı ve içerik paylaşım kuralları' },
];

export default async function LegalPage() {
  const supabase = await createSupabaseServerClient();

  type DocRow = { slug: string; title: string; updated_at: string };
  let docs: DocRow[] = [];
  let useFallback = false;

  try {
    const { data, error } = await (supabase as any)
      .from('legal_documents')
      .select('slug, title, updated_at')
      .eq('is_published', true)
      .order('sort_order') as { data: DocRow[] | null; error: any };
    if (error?.code === '42P01') useFallback = true;
    else docs = data ?? [];
    if (docs.length === 0) useFallback = true;
  } catch {
    useFallback = true;
  }

  const displayDocs = useFallback
    ? FALLBACK_DOCS.map((d) => ({ ...d, updated_at: null as string | null }))
    : docs.map((d) => ({ ...d, description: null as string | null }));

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <h1 className="mb-2 text-3xl font-[900] text-textStrong">Yasal Bilgiler</h1>
        <p className="mb-8 text-sm text-muted">Yeedoy hizmetlerine ilişkin yasal belgeler</p>

        <div className="flex flex-col gap-4">
          {displayDocs.map((doc) => (
            <Link
              key={doc.slug}
              href={`/yasal/${doc.slug}`}
              className="flex items-center justify-between rounded-2xl border border-border bg-card px-6 py-5 transition-colors hover:border-primary/30 cursor-pointer"
            >
              <div>
                <p className="font-[700] text-textStrong">{doc.title}</p>
                {(doc as any).description && (
                  <p className="mt-0.5 text-sm text-muted">{(doc as any).description}</p>
                )}
                {(doc as any).updated_at && (
                  <p className="mt-0.5 text-[12px] text-muted">
                    Güncellendi: {new Date((doc as any).updated_at).toLocaleDateString('tr-TR')}
                  </p>
                )}
              </div>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted"><path d="M9 18l6-6-6-6" /></svg>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}

