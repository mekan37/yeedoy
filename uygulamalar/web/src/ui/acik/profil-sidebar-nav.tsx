import Link from 'next/link';

// Kimlik alanındaki tüm profil sayfalarının (profil, favoriler, yorumlarım,
// önerilerim, gelen-kutusu, profil/ayarlar) ortak sol menüsü — tek kaynak,
// her sayfa kendi kopyasını tutmasın diye buradan paylaşılıyor.
export const PROFIL_NAV_ITEMS = [
  { href: '/profil', label: 'Profilim' },
  { href: '/favoriler', label: 'Favorilerim' },
  { href: '/yorumlarim', label: 'Yorumlarım' },
  { href: '/onerilerim', label: 'Önerilerim' },
  { href: '/gelen-kutusu', label: 'Bildirimlerim' },
  { href: '/profil/ayarlar', label: 'Ayarlar' },
  { href: '/yardim', label: 'Yardım & Destek' },
] as const;

export function ProfilSidebarNav({ active }: { active: string }) {
  return (
    <nav className="rounded-2xl border border-border bg-card shadow-yd1 overflow-hidden">
      {PROFIL_NAV_ITEMS.map(({ href, label }) => {
        const isActive = href === active;
        return (
          <Link
            key={href}
            href={href}
            className={`flex items-center gap-3 px-4 py-3 text-sm font-extrabold border-b border-border last:border-0 transition-colors ${
              isActive ? 'bg-primary/8 text-primary' : 'text-textStrong hover:bg-cardAlt hover:text-primary'
            }`}
          >
            {isActive && <span className="h-1.5 w-1.5 rounded-full bg-primary shrink-0" aria-hidden="true" />}
            {label}
          </Link>
        );
      })}
      <button
        type="button"
        className="flex w-full items-center gap-3 px-4 py-3 text-sm font-extrabold text-danger transition-colors hover:bg-danger/5"
      >
        Çıkış Yap
      </button>
    </nav>
  );
}
