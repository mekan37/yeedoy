type ProvinceMapRow = {
  province_name: string;
  business_count: number;
  active_count: number;
  verified_count: number;
  geojson: string;
};

type Ring = [number, number][];
type PolygonCoords = Ring[];

function parseGeojson(geojson: string): PolygonCoords[] {
  const parsed = JSON.parse(geojson) as { type: string; coordinates: unknown };
  if (parsed.type === 'Polygon') return [parsed.coordinates as PolygonCoords];
  if (parsed.type === 'MultiPolygon') return parsed.coordinates as PolygonCoords[];
  return [];
}

const W = 460;
const H = 220;
const PAD = 8;

function renkAra(oran: number): string {
  // Açık maviden koyu maviye — düşük yoğunluktan yüksek yoğunluğa
  const stops: Array<[number, string]> = [
    [0, '#eef2ff'],
    [0.25, '#c7d9fb'],
    [0.5, '#93b8f5'],
    [0.75, '#5a8cec'],
    [1, '#1d4ed8'],
  ];
  for (let i = 0; i < stops.length - 1; i++) {
    const [t0, c0] = stops[i];
    const [t1, c1] = stops[i + 1];
    if (oran >= t0 && oran <= t1) {
      const localT = t1 === t0 ? 0 : (oran - t0) / (t1 - t0);
      return karistir(c0, c1, localT);
    }
  }
  return stops[stops.length - 1][1];
}

function karistir(hex1: string, hex2: string, t: number): string {
  const a = parseInt(hex1.slice(1), 16);
  const b = parseInt(hex2.slice(1), 16);
  const ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
  const br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
  const r = Math.round(ar + (br - ar) * t);
  const g = Math.round(ag + (bg - ag) * t);
  const bl = Math.round(ab + (bb - ab) * t);
  return `#${((1 << 24) + (r << 16) + (g << 8) + bl).toString(16).slice(1)}`;
}

export function TurkiyeHaritasi({ rows }: { rows: ProvinceMapRow[] }) {
  const parsedRows = rows.map((r) => ({ ...r, polygons: parseGeojson(r.geojson) }));

  let lonMin = Infinity, lonMax = -Infinity, latMin = Infinity, latMax = -Infinity;
  for (const r of parsedRows) {
    for (const poly of r.polygons) {
      for (const ring of poly) {
        for (const [lon, lat] of ring) {
          if (lon < lonMin) lonMin = lon;
          if (lon > lonMax) lonMax = lon;
          if (lat < latMin) latMin = lat;
          if (lat > latMax) latMax = lat;
        }
      }
    }
  }

  const latMid = (latMin + latMax) / 2;
  const lonCos = Math.cos((latMid * Math.PI) / 180);
  const lonSpan = (lonMax - lonMin) * lonCos;
  const latSpan = latMax - latMin;
  const scale = Math.min((W - PAD * 2) / lonSpan, (H - PAD * 2) / latSpan);
  const offsetX = PAD + ((W - PAD * 2) - lonSpan * scale) / 2;
  const offsetY = PAD + ((H - PAD * 2) - latSpan * scale) / 2;

  function project([lon, lat]: [number, number]): [number, number] {
    const x = offsetX + (lon - lonMin) * lonCos * scale;
    const y = offsetY + (latMax - lat) * scale;
    return [x, y];
  }

  function ringToPath(ring: Ring): string {
    return ring.map(([lon, lat], i) => {
      const [x, y] = project([lon, lat]);
      return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`;
    }).join(' ') + 'Z';
  }

  const maxCount = Math.max(...parsedRows.map((r) => r.business_count), 1);
  const maxLog = Math.log(maxCount + 1);

  return (
    <div className="flex flex-col gap-2">
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full" role="img" aria-label="Türkiye illerine göre işletme yoğunluğu">
        {parsedRows.map((r) => {
          const oran = maxLog > 0 ? Math.log(r.business_count + 1) / maxLog : 0;
          const d = r.polygons.map((poly) => poly.map(ringToPath).join(' ')).join(' ');
          return (
            <path
              key={r.province_name}
              d={d}
              fill={r.business_count > 0 ? renkAra(oran) : '#f1f5f9'}
              stroke="#ffffff"
              strokeWidth="0.6"
              fillRule="evenodd"
            >
              <title>{`${r.province_name}: ${r.business_count.toLocaleString('tr-TR')} işletme${r.business_count > 0 ? ` (%${Math.round((r.active_count / r.business_count) * 100)} aktif)` : ''}`}</title>
            </path>
          );
        })}
      </svg>
      <div className="flex items-center gap-2 px-1">
        <span className="text-[10px] font-bold text-muted">Düşük</span>
        <div className="h-2 flex-1 rounded-full" style={{ background: 'linear-gradient(90deg, #eef2ff, #93b8f5, #1d4ed8)' }} />
        <span className="text-[10px] font-bold text-muted">Yüksek</span>
      </div>
    </div>
  );
}
