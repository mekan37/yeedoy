import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const title = searchParams.get('title') || 'Yeedoy QR Menu';

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: 48,
          background: '#0f172a',
          color: '#fff',
        }}
      >
        <div style={{ fontSize: 30, opacity: 0.9 }}>Digital QR Menu</div>
        <div style={{ marginTop: 16, fontSize: 56, fontWeight: 700 }}>{title}</div>
      </div>
    ),
    { width: 1200, height: 630 },
  );
}
