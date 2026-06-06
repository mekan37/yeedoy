import Link from 'next/link';

interface TwoFactorBannerProps {
  hasTwoFactor: boolean;
}

/**
 * 2FA etkin olmayan kullaniciya soft warning banner gosterir.
 * Erisimi engellemez — sadece bilgilendirme ve yonlendirme.
 * hasTwoFactor=true ise ya da MFA API hatasi varsa hic render edilmez.
 */
export function TwoFactorBanner({ hasTwoFactor }: TwoFactorBannerProps) {
  if (hasTwoFactor) return null;

  return (
    <div
      role="alert"
      aria-label="iki-faktor-dogrulama-uyarisi"
      className="flex items-center justify-between gap-4 border-b border-amber-200 bg-amber-50 px-4 py-2.5 text-sm text-amber-900 dark:border-amber-800/40 dark:bg-amber-950/30 dark:text-amber-200"
    >
      <div className="flex min-w-0 items-center gap-2">
        <svg
          viewBox="0 0 24 24"
          className="h-4 w-4 shrink-0 fill-amber-500 dark:fill-amber-400"
          aria-hidden="true"
        >
          <path d="M12 1L2 20h20L12 1zm0 3.5L19.7 19H4.3L12 4.5zM11 10v4h2v-4h-2zm0 6v2h2v-2h-2z" />
        </svg>
        <span className="font-[700]">Hesabın daha güvenli olabilir</span>
        <span className="hidden sm:inline text-amber-700 dark:text-amber-300">
          — 2FA etkinleştirerek hesabını koru.
        </span>
      </div>
      <Link
        href="/profil/security"
        className="shrink-0 rounded-lg bg-amber-500 px-3 py-1.5 text-xs font-[800] text-white transition-colors hover:bg-amber-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-400"
      >
        2FA Aç
      </Link>
    </div>
  );
}
