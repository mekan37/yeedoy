import Link from 'next/link';
import { notFound } from 'next/navigation';

const requiredKeys = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'STORAGE_BUCKET_PUBLIC',
  'BASE_URL_WEB_NEXT',
  'BASE_URL_PANEL',
  'DEV_TOOLS_ENABLED',
] as const;

function envSnapshot() {
  const pairs = requiredKeys.map((key) => {
    const value = process.env[key];
    return {
      key,
      ok: Boolean(value && value.trim().length > 0),
      valuePreview: value ? `${value.slice(0, 8)}...` : '(missing)',
    };
  });
  return pairs;
}

export default function DevToolsPage() {
  const enabled = process.env.DEV_TOOLS_ENABLED === 'true';
  const prod = process.env.NODE_ENV === 'production';
  if (!enabled || prod) {
    notFound();
  }

  const snapshot = envSnapshot();
  const ok = snapshot.every((x) => x.ok);

  return (
    <main style={{ maxWidth: 960, margin: '0 auto', padding: 24 }}>
      <h1 style={{ fontSize: 28, fontWeight: 800 }}>DevTools</h1>
      <p style={{ color: '#6b7280' }}>
        Runtime env validation, SEO checks and download/api smoke links.
      </p>

      <section style={{ marginTop: 20 }}>
        <h2 style={{ fontSize: 20, fontWeight: 700 }}>Env Check</h2>
        <p>Status: {ok ? 'OK' : 'Missing values'}</p>
        <ul>
          {snapshot.map((row) => (
            <li key={row.key}>
              <strong>{row.key}</strong>: {row.ok ? 'ok' : 'missing'} ({row.valuePreview})
            </li>
          ))}
        </ul>
      </section>

      <section style={{ marginTop: 20 }}>
        <h2 style={{ fontSize: 20, fontWeight: 700 }}>SEO + Download Smoke</h2>
        <ul>
          <li>
            <Link href="/api/og">/api/og</Link>
          </li>
          <li>
            <Link href="/api/qr">/api/qr</Link>
          </li>
          <li>
            <Link href="/api/menu/export/demo">/api/menu/export/demo</Link>
          </li>
        </ul>
      </section>
    </main>
  );
}
