// This file configures the initialization of Sentry on the client.
// The added config here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: "https://1960d8a51dd860f83af1893a8d29bd0c@o4511903059738624.ingest.de.sentry.io/4511903317491792",

  // Session Replay entegrasyonu init sırasında EKLENMİYOR — SDK'sı (~150 KiB'lik
  // ayrı bir chunk) PageSpeed'de "Kullanılmayan JavaScript" ve "Uzun ana iş
  // parçacığı görevleri" bulgularının doğrudan kaynağıydı: %10 örnekleme oranına
  // rağmen kod her sayfa yüklemesinde eagerly indirilip parse ediliyordu (görüş
  // ilk boyamayla/LCP ile yarışıyordu). Aşağıda ilk boyamadan sonra ekleniyor;
  // replaysSessionSampleRate/replaysOnErrorSampleRate ayarları entegrasyon ne
  // zaman eklenirse eklensin aynı şekilde uygulanır (Sentry SDK davranışı).
  integrations: [],

  // Define how likely traces are sampled. Adjust this value in production, or use tracesSampler for greater control.
  // 1 (yüzde 100) canlıda aşırıydı — her ziyaretçinin her sayfa geçişi tam
  // izleme overhead'i (fetch/XHR sarmalama, span oluşturma) taşıyordu.
  tracesSampleRate: 0.2,
  // Enable logs to be sent to Sentry
  enableLogs: true,

  // Define how likely Replay events are sampled.
  // This sets the sample rate to be 10%. You may want this to be 100% while
  // in development and sample at a lower rate in production
  replaysSessionSampleRate: 0.1,

  // Define how likely Replay events are sampled when an error occurs.
  replaysOnErrorSampleRate: 1.0,

  dataCollection: {
    // To disable sending user data and HTTP bodies, uncomment the lines below. For more info visit:
    // https://docs.sentry.io/platforms/javascript/guides/nextjs/configuration/options/#dataCollection
    // userInfo: false,
    // httpBodies: [],
  },
});

if (typeof window !== 'undefined') {
  // Sentry.replayIntegration'a buradaki gibi statik import edilen Sentry
  // namespace'i üzerinden erişmek (Sentry.replayIntegration()), rrweb tabanlı
  // Replay uygulamasının bu dosyanın da parçası olduğu ana (eager) client
  // chunk'ına gömülmesine yol açıyordu — requestIdleCallback sadece
  // AKTİVASYONU erteliyordu, KOD İNDİRME/PARSE'ı değil. Canlı Lighthouse'ta bu
  // chunk anasayfa LCP'sini ~5.9s'ye kadar geciktiren 2.2s'lik ana iş parçacığı
  // bloğunun kaynağıydı. Gerçek kod bölünmesi için replayIntegration'ı SADECE
  // dinamik import edilen modülden almak gerekiyor.
  const addReplay = async () => {
    const { replayIntegration } = await import('@sentry/nextjs');
    Sentry.addIntegration(replayIntegration());
  };
  if ('requestIdleCallback' in window) {
    window.requestIdleCallback(() => { void addReplay(); });
  } else {
    setTimeout(() => { void addReplay(); }, 3000);
  }
}

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
