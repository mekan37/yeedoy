import Image from 'next/image';

type YeedoyLogoProps = {
  /** Logo yüksekliği px cinsinden */
  size?: number;
  /** true = tam wordmark "Yeedoy", false = kare marka işareti */
  showText?: boolean;
  className?: string;
  /** Açık arkaplan için varsayılan. Koyu bg için "white" ver. */
  textColor?: string;
};

function wordmarkSrc(textColor?: string) {
  const normalized = textColor?.toLowerCase();
  if (normalized === 'white' || normalized === '#fff' || normalized === '#ffffff') {
    return '/logos/yeedoy-wordmark-white.svg';
  }
  return '/logos/yeedoy-wordmark.svg';
}

export function YeedoyLogo({
  size = 40,
  showText = true,
  className,
  textColor,
}: YeedoyLogoProps) {
  const src = showText ? wordmarkSrc(textColor) : '/logos/yeedoy-mark.svg';
  const width = showText ? Math.round(size * (1811 / 566)) : size;

  return (
    <span
      className={className}
      style={{ display: 'inline-flex', alignItems: 'center', width, height: size }}
      aria-label="Yeedoy"
    >
      <Image
        src={src}
        alt=""
        width={width}
        height={size}
        priority={size >= 34}
        unoptimized
        style={{ width, height: size, objectFit: 'contain' }}
        aria-hidden="true"
      />
    </span>
  );
}
