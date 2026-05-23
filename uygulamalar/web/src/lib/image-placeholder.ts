function encodeSvg(svg: string) {
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

export function getImageBlurDataUrl(input: {
  placeholderBase: string;
  placeholderHighlight: string;
}) {
  return encodeSvg(`
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800" preserveAspectRatio="none">
      <defs>
        <linearGradient id="g" x1="0" x2="1" y1="0" y2="1">
          <stop offset="0%" stop-color="${input.placeholderBase}" />
          <stop offset="50%" stop-color="${input.placeholderHighlight}" />
          <stop offset="100%" stop-color="${input.placeholderBase}" />
        </linearGradient>
      </defs>
      <rect width="1200" height="800" fill="url(#g)" />
    </svg>
  `);
}
