import { ImageResponse } from 'next/og';
import { getMarketplaceBusinessBySlug } from '@/src/lib/veri/pazar-okuma';

export const runtime = 'edge';
export const alt = 'Yeedoy';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

type Props = { params: Promise<{ slug: string }> };

export default async function Image({ params }: Props) {
  const { slug } = await params;
  const business = await getMarketplaceBusinessBySlug(slug).catch(() => null);

  const name = business?.name ?? 'Yeedoy';
  const category = business?.category ?? '';
  const city = business?.city ?? '';
  const rating = business?.avgRating ? `★ ${business.avgRating.toFixed(1)}` : '';
  const subtitle = [category, city].filter(Boolean).join(' · ');

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'flex-end',
          padding: 56,
          background: 'linear-gradient(160deg, #1c0404 0%, #7f1d1d 55%, #dc2626 100%)',
          color: '#fff',
          fontFamily: 'sans-serif',
        }}
      >
        {/* Top: Yeedoy brand */}
        <div
          style={{
            position: 'absolute',
            top: 48,
            left: 56,
            display: 'flex',
            alignItems: 'center',
            gap: 10,
          }}
        >
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 8,
              background: 'rgba(255,255,255,0.15)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 20,
              fontWeight: 900,
            }}
          >
            Y
          </div>
          <span style={{ fontSize: 18, fontWeight: 700, opacity: 0.85, letterSpacing: 1 }}>
            yeedoy.com
          </span>
        </div>

        {/* Rating badge */}
        {rating ? (
          <div
            style={{
              position: 'absolute',
              top: 48,
              right: 56,
              background: 'rgba(255,255,255,0.15)',
              borderRadius: 12,
              padding: '8px 16px',
              fontSize: 22,
              fontWeight: 800,
            }}
          >
            {rating}
          </div>
        ) : null}

        {/* Main content */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {subtitle ? (
            <div style={{ fontSize: 22, fontWeight: 600, opacity: 0.75, letterSpacing: 0.5 }}>
              {subtitle}
            </div>
          ) : null}
          <div
            style={{
              fontSize: name.length > 30 ? 52 : 68,
              fontWeight: 900,
              lineHeight: 1.05,
              letterSpacing: -1,
            }}
          >
            {name}
          </div>
          <div style={{ fontSize: 18, opacity: 0.65, marginTop: 4 }}>
            Menü · Fiyatlar · Yorumlar — Yeedoy
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
