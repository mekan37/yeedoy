import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Ayarlar | Yeedoy',
  robots: { index: false, follow: false },
};

// ── Setting link definitions ──────────────────────────────────────────────────

type SettingLink = {
  href: string;
  title: string;
  description: string;
};

const ACCOUNT_SETTINGS: SettingLink[] = [
  {
    href: '/profil/ayarlar',
    title: 'Profil Ayarları',
    description: 'Ad, biyografi, konum ve profil fotoğrafı',
  },
  {
    href: '/sifre-degistir',
    title: 'Şifre Değiştir',
    description: 'Hesap şifrenizi güncelleyin',
  },
  {
    href: '/sosyal-hesaplar',
    title: 'Bağlı Sosyal Hesaplar',
    description: 'Instagram, X, TikTok ve diğer sosyal medya profilleriniz',
  },
];

const NOTIFICATION_SETTINGS: SettingLink[] = [
  {
    href: '/bildirim-tercihleri',
    title: 'Bildirim Tercihleri',
    description: 'Kanallar (push, e-posta) ve bildirim kategorileri',
  },
  {
    href: '/bildirim-ayarlari',
    title: 'Bildirim Ayarları',
    description: 'Push izni ve pazarlama e-posta tercihleri',
  },
];

const SECURITY_SETTINGS: SettingLink[] = [
  {
    href: '/profil/guvenlik',
    title: 'Hesap Güvenliği',
    description: 'İki faktörlü doğrulama ve aktif oturum yönetimi',
  },
];

// ── Setting row ───────────────────────────────────────────────────────────────

function SettingRow({ href, title, description }: SettingLink) {
  return (
    <Link
      href={href}
      className="flex min-h-[64px] items-center justify-between rounded-2xl border border-border bg-bg px-5 py-4 transition-colors hover:border-primary/30 hover:bg-cardAlt focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
    >
      <div className="min-w-0">
        <p className="font-black text-textStrong">{title}</p>
        <p className="mt-0.5 text-xs text-muted">{description}</p>
      </div>
      <svg
        viewBox="0 0 24 24"
        className="ml-4 h-4 w-4 shrink-0 fill-none stroke-current text-muted"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        aria-hidden="true"
      >
        <path d="M9 18l6-6-6-6" />
      </svg>
    </Link>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function AyarlarPage() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            href="/profil"
            className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
          >
            ← Profilime Dön
          </Link>
          <h1 className="text-xl font-black text-textStrong">Ayarlar</h1>
        </div>

        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-black uppercase tracking-wide text-muted">Hesap</h2>
          {ACCOUNT_SETTINGS.map((s) => (
            <SettingRow key={s.href} {...s} />
          ))}
        </section>

        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-black uppercase tracking-wide text-muted">Bildirimler</h2>
          {NOTIFICATION_SETTINGS.map((s) => (
            <SettingRow key={s.href} {...s} />
          ))}
        </section>

        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-black uppercase tracking-wide text-muted">Güvenlik</h2>
          {SECURITY_SETTINGS.map((s) => (
            <SettingRow key={s.href} {...s} />
          ))}
        </section>
      </div>
    </main>
  );
}
