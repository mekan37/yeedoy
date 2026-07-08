export function OsmHarita({
  lat,
  lng,
  name,
  className,
}: {
  lat: number;
  lng: number;
  name: string;
  className?: string;
}) {
  const delta = 0.012;
  const bbox = `${lng - delta},${lat - delta},${lng + delta},${lat + delta}`;
  const src = `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&marker=${lat},${lng}&layer=mapnik`;

  return (
    <iframe
      title={`${name} konumu`}
      src={src}
      className={className}
      width="100%"
      height="100%"
      loading="lazy"
      referrerPolicy="no-referrer"
      aria-label={`${name} haritası`}
      style={{ border: 0 }}
    />
  );
}
