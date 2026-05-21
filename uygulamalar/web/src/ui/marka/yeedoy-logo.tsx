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
  // Aspect ratio 821:834 — render near-square, slight height advantage
  const w = size;
  const h = Math.round(size * (834 / 821));

  return (
    <span
      className={className}
      style={{ display: 'inline-flex', alignItems: 'center', gap: size * 0.18 }}
      aria-label="Yeedoy"
    >
      <svg
        width={w}
        height={h}
        viewBox="0 0 821 834"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <defs>
          <linearGradient id="yeedoyMain" x1="10" y1="91" x2="810" y2="823" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor="#DC2626" />
            <stop offset="0.55" stopColor="#7F1D1D" />
            <stop offset="1" stopColor="#5C1515" />
          </linearGradient>
          <linearGradient id="yeedoyAccent" x1="575" y1="10" x2="640" y2="203" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor="#F87171" />
            <stop offset="1" stopColor="#DC2626" />
          </linearGradient>
        </defs>
        {/* Y mark — ana gövde */}
        <path
          d="M10 91L116 169L298 498L313 727L292 788L253 823L344 821L376 794L386 690L360 626L372 515L376 619L391 516L398 615L399 515L416 615L419 517L429 621L402 685L410 791L444 821L526 823L488 788L467 725L480 495L734 141L810 90L686 113L520 242L391 406L351 535L358 453L397 366L302 234L311 142L226 93Z"
          fill="url(#yeedoyMain)"
          fillRule="evenodd"
        />
        {/* Nokta vurgu */}
        <path
          d="M629 10L621 12L598 25L586 37L576 55L575 74L579 86L594 104L600 116L600 137L594 152L584 166L564 186L543 203L551 201L551 199L573 187L604 165L624 146L636 128L640 109L637 94L632 86L615 69L609 57L609 40L618 22Z"
          fill="url(#yeedoyAccent)"
          fillRule="evenodd"
        />
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
