import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const rawTitle = searchParams.get('title') ?? '';
  const title = (rawTitle
    .replace(/[<>"'&]/g, (c) => ({'<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;','&':'&amp;'}[c] ?? c))
    .slice(0, 120)
    .trim()) || 'Yeedoy Karekod Menu';

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: 56,
          background:
            'linear-gradient(135deg, rgba(127,29,29,1) 0%, rgba(220,38,38,1) 100%)',
          color: '#fff',
        }}
      >
        <div style={{ fontSize: 28, letterSpacing: 6, textTransform: 'uppercase', opacity: 0.82 }}>
          Yeedoy Karekod Menu
        </div>
        <div style={{ marginTop: 18, fontSize: 60, fontWeight: 800, lineHeight: 1.1 }}>{title}</div>
      </div>
    ),
    { width: 1200, height: 630 },
  );
}
