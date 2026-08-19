'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState, useEffect, useCallback } from 'react';

type PushStatus = 'idle' | 'granted' | 'denied' | 'unsupported' | 'subscribed';

const VAPID_KEY = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY ?? '';
const FIREBASE_CONFIG = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? '',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? '',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? '',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ?? '',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? '',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? '',
};

const firebaseConfigured = Object.values(FIREBASE_CONFIG).every(Boolean) && VAPID_KEY;

async function registerFirebasePush(): Promise<string | null> {
  if (!firebaseConfigured || typeof window === 'undefined') return null;
  try {
    const { initializeApp, getApps } = await import('firebase/app');
    const { getMessaging, getToken, isSupported } = await import('firebase/messaging');

    if (!await isSupported()) return null;

    const app = getApps().length ? getApps()[0] : initializeApp(FIREBASE_CONFIG);
    const messaging = getMessaging(app);

    const reg = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
    // Pass config to SW so it can init firebase-compat
    reg.active?.postMessage({ type: 'FIREBASE_CONFIG', config: FIREBASE_CONFIG });

    const token = await getToken(messaging, {
      vapidKey: VAPID_KEY,
      serviceWorkerRegistration: reg,
    });
    return token || null;
  } catch (err) {
    console.warn('[push] Firebase registration failed:', err);
    return null;
  }
}

async function savePushToken(token: string) {
  const supabase = createSupabaseBrowserClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;
  await (supabase as any).from('push_subscriptions').upsert(
    { user_id: user.id, token, platform: 'web', updated_at: new Date().toISOString() },
    { onConflict: 'user_id,platform' },
  );
}

export function PushIzinButonu() {
  const [status, setStatus] = useState<PushStatus>('idle');
  const [requesting, setRequesting] = useState(false);

  useEffect(() => {
    // Notification API tarayıcı durumunu okur — UI dışı bir kaynaktan senkronizasyon.
    if (!('Notification' in window)) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setStatus('unsupported');
      return;
    }
    if (Notification.permission === 'granted') {
      setStatus('granted');
    } else if (Notification.permission === 'denied') {
      setStatus('denied');
    }
  }, []);

  const requestPermission = useCallback(async () => {
    if (!('Notification' in window)) {
      setStatus('unsupported');
      return;
    }
    setRequesting(true);
    try {
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        setStatus('denied');
        return;
      }
      setStatus('granted');

      // Attempt Firebase VAPID registration if configured
      if (firebaseConfigured) {
        const token = await registerFirebasePush();
        if (token) {
          await savePushToken(token);
          setStatus('subscribed');
        }
      }
    } catch {
      setStatus('denied');
    } finally {
      setRequesting(false);
    }
  }, []);

  if (status === 'unsupported') {
    return (
      <p className="rounded-2xl border border-border bg-card px-5 py-4 text-sm text-muted">
        Tarayıcınız push bildirimleri desteklemiyor.
      </p>
    );
  }

  if (status === 'subscribed') {
    return (
      <div className="flex items-center gap-3 rounded-2xl border border-success/25 bg-success/10 px-5 py-4">
        <svg viewBox="0 0 24 24" className="h-5 w-5 shrink-0 fill-none stroke-current text-success" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="20 6 9 17 4 12" />
        </svg>
        <p className="text-sm font-extrabold text-success">Push bildirimleri aktif ve kayıtlı</p>
      </div>
    );
  }

  if (status === 'granted') {
    return (
      <div className="flex items-center gap-3 rounded-2xl border border-success/25 bg-success/10 px-5 py-4">
        <svg viewBox="0 0 24 24" className="h-5 w-5 shrink-0 fill-none stroke-current text-success" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="20 6 9 17 4 12" />
        </svg>
        <p className="text-sm font-extrabold text-success">
          Bildirimler aktif{!firebaseConfigured && ' (VAPID yapılandırılmadı)'}
        </p>
      </div>
    );
  }

  if (status === 'denied') {
    return (
      <div className="rounded-2xl border border-warning/25 bg-warning/10 px-5 py-4">
        <p className="text-sm font-extrabold text-textStrong">Bildirimler engellenmiş</p>
        <p className="mt-1 text-xs leading-relaxed text-muted">
          Tarayıcı ayarlarınızdan bu site için bildirimlere izin verin. Adres çubuğundaki kilit simgesine tıklayarak erişebilirsiniz.
        </p>
      </div>
    );
  }

  return (
    <button
      type="button"
      disabled={requesting}
      onClick={requestPermission}
      className="inline-flex min-h-[52px] w-full items-center justify-center gap-2 rounded-2xl px-5 text-sm font-black text-white disabled:opacity-60 disabled:cursor-not-allowed"
      style={{ background: 'var(--yd-gradient-primary)' }}
    >
      <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
        <path d="M13.73 21a2 2 0 0 1-3.46 0" />
      </svg>
      {requesting ? 'Kaydediliyor…' : 'Bildirimlere İzin Ver'}
    </button>
  );
}
