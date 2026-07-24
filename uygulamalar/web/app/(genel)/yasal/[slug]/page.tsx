import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const revalidate = 3600;

const STATIC_CONTENT: Record<string, { title: string; body: string }> = {
  terms: {
    title: 'Kullanım Şartları',
    body: `
## 1. Kabul

Yeedoy hizmetlerini kullanarak bu şartları kabul etmiş sayılırsınız.

## 2. Hizmet Tanımı

Yeedoy, restoran menülerini dijitalleştiren, fiyat katkısı ve yorum platformu ile işletme paneli sunan bir hizmettir.

## 3. Kullanıcı Hesapları

Hesap açmak için 18 yaşında veya üzeri olmanız gerekmektedir. Hesap güvenliğinden siz sorumlusunuz.

## 4. Kabul Edilemez Kullanım

Sistemi kötüye kullanmak, spam göndermek, başkalarını taklit etmek veya zararlı içerik paylaşmak yasaktır.

## 5. Fikri Mülkiyet

Yeedoy markası, logosu ve orijinal içerikler telif hakkıyla korunmaktadır.

## 6. Sorumluluk Sınırlaması

Yeedoy, kullanıcı tarafından oluşturulan içeriklerden doğan zararlardan sorumlu tutulamaz.

## 7. Değişiklikler

Şartları önceden haber vererek değiştirme hakkımızı saklı tutarız. Güncel şartlar daima bu sayfada yayımlanır.

## 8. İletişim

Sorularınız için: hukuk@yeedoy.com
    `.trim(),
  },
  privacy: {
    title: 'Gizlilik Politikası',
    body: `
## 1. Topladığımız Veriler

Ad, e-posta, konum (isteğe bağlı), kullanım verileri ve cihaz bilgisi toplanmaktadır.

## 2. Verilerin Kullanımı

Veriler; hizmet sunumu, kişiselleştirme, iletişim ve yasal yükümlülükler için kullanılır.

## 3. Veri Paylaşımı

Verileriniz üçüncü taraflara satılmaz. Hizmet sağlayıcılarla ve yasal zorunluluk halinde yetkililere paylaşılabilir.

## 4. KVKK / GDPR

6698 sayılı KVKK ve GDPR kapsamında haklarınız: erişim, düzeltme, silme, itiraz ve veri taşınabilirliği.

## 5. Çerezler

Teknik çerezler zorunludur; pazarlama çerezleri için onayınız alınır.

## 6. Veri Güvenliği

Verileriniz şifreleme ve erişim kontrolü ile korunmaktadır.

## 7. Veri Talebi

kvkk@yeedoy.com adresinden veri erişim, düzeltme veya silme talebinde bulunabilirsiniz.
    `.trim(),
  },
  cookies: {
    title: 'Çerez Politikası',
    body: `
## Çerez Nedir?

Çerezler, tarayıcınıza yerleştirilen küçük metin dosyalarıdır.

## Kullandığımız Çerezler

**Zorunlu Çerezler:** Giriş oturumu, güvenlik tokeni gibi teknik işlevler için gereklidir.

**Analitik Çerezler:** Kullanım istatistikleri için anonimleştirilmiş veri toplanır (isteğe bağlı onay).

**Tercih Çerezleri:** Tema, dil ve konum tercihleri için kullanılır.

## Çerez Yönetimi

Tarayıcı ayarlarından çerezleri yönetebilirsiniz. Zorunlu çerezleri devre dışı bırakmak hizmetin çalışmasını engelleyebilir.

## İletişim

cerez@yeedoy.com
    `.trim(),
  },
};

function renderMarkdown(text: string) {
  const lines = text.split('\n');
  const elements: React.ReactNode[] = [];
  let key = 0;
  for (const line of lines) {
    if (line.startsWith('## ')) {
      elements.push(<h2 key={key++} className="mt-6 mb-2 text-base font-black text-textStrong">{line.slice(3)}</h2>);
    } else if (line.startsWith('**') && line.endsWith('**')) {
      elements.push(<p key={key++} className="font-extrabold text-textStrong">{line.slice(2, -2)}</p>);
    } else if (line.trim()) {
      elements.push(<p key={key++} className="text-sm leading-7 text-text">{line}</p>);
    }
  }
  return elements;
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const title = STATIC_CONTENT[slug]?.title ?? 'Yasal Belge';
  return { title: `${title} | Yeedoy` };
}

export default async function LegalDocPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;

  // Try DB first
  let title = '';
  let body = '';
  try {
    const supabase = await createSupabaseServerClient();
    const { data } = await (supabase as any)
      .from('legal_documents')
      .select('title, content')
      .eq('slug', slug)
      .eq('is_published', true)
      .maybeSingle() as { data: { title: string; content: string } | null };
    if (data) {
      title = data.title;
      body = data.content;
    }
  } catch {}

  // Fallback to static content
  if (!body) {
    const fallback = STATIC_CONTENT[slug];
    if (!fallback) notFound();
    title = fallback.title;
    body = fallback.body;
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-12">
        <div className="mb-8">
          <Link href="/yasal" className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
            ← Yasal Bilgilere Dön
          </Link>
        </div>

        <h1 className="mb-8 text-3xl font-black text-textStrong">{title}</h1>

        <div className="space-y-1">
          {renderMarkdown(body)}
        </div>

        <div className="mt-12 border-t border-border pt-8">
          <p className="text-xs text-muted">Sorularınız için: <a href="mailto:hukuk@yeedoy.com" className="text-primary hover:underline">hukuk@yeedoy.com</a></p>
        </div>
      </div>
    </main>
  );
}
