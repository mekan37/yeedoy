// Firebase Messaging Service Worker
// Handles background push notifications for Yeedoy web app.
// This file is served from /firebase-messaging-sw.js (public root).

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Config injected at registration time via postMessage or hardcoded here.
// Values come from NEXT_PUBLIC_FIREBASE_* env vars baked into the app bundle.
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'FIREBASE_CONFIG') {
    if (self.__firebaseConfigured) return;
    self.__firebaseConfigured = true;
    firebase.initializeApp(event.data.config);
    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
      const title = payload.notification?.title ?? 'Yeedoy';
      const body = payload.notification?.body ?? '';
      const icon = payload.notification?.icon ?? '/android-chrome-192x192.png';
      const url = payload.data?.url ?? '/';
      self.registration.showNotification(title, {
        body,
        icon,
        badge: '/favicon-32x32.png',
        data: { url },
        tag: payload.data?.tag ?? 'yeedoy-push',
      });
    });
  }
});

// Handle notification click — open the associated URL
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url ?? '/';
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        for (const client of windowClients) {
          if (client.url === url && 'focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(url);
        }
      }),
  );
});
