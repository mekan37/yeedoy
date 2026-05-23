type YeedoyLogoProps = {
  size?: number;
  showText?: boolean;
  className?: string;
  textColor?: string;
};

export function YeedoyLogo({
  size = 40,
  showText = true,
  className,
  textColor = '#111827',
}: YeedoyLogoProps) {
  const wordSize = Math.round(size * 0.78);

  return (
    <span
      className={className}
      style={{ display: 'inline-flex', alignItems: 'center', gap: size * 0.18 }}
      aria-label="Yeedoy"
    >
      <svg
        width={size}
        height={size}
        viewBox="0 0 512 512"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <defs>
          <linearGradient id="yeedoyLight" x1="112" y1="82" x2="294" y2="336" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor="#F87171" />
            <stop offset="0.55" stopColor="#DC2626" />
            <stop offset="1" stopColor="#7F1D1D" />
          </linearGradient>
          <linearGradient id="yeedoyBrand" x1="122" y1="80" x2="391" y2="430" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor="#DC2626" />
            <stop offset="0.52" stopColor="#7F1D1D" />
            <stop offset="1" stopColor="#5C1515" />
          </linearGradient>
        </defs>
        <path
          d="M141 111C138 105 142 98 149 98H200C236 98 268 119 283 151L330 251C341 275 327 303 302 309C279 314 256 302 246 280L141 111Z"
          fill="url(#yeedoyLight)"
        />
        <path
          d="M330 97C346 97 358 110 352 125L277 310C254 367 212 404 155 412C148 413 144 405 150 401C183 379 207 351 225 308L287 158C302 122 317 97 330 97Z"
          fill="url(#yeedoyBrand)"
        />
        <circle cx="351" cy="98" r="36" fill="url(#yeedoyBrand)" />
      </svg>
      {showText && (
        <span
          style={{
            color: textColor,
            fontSize: wordSize,
            lineHeight: 1,
            fontWeight: 800,
            letterSpacing: -size * 0.045,
            fontFamily: 'Flexing, var(--yd-font-family), "Segoe UI", sans-serif',
          }}
        >
          eedoy
        </span>
      )}
    </span>
  );
}
