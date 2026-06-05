import { createSign } from 'crypto';
import { logger } from '@/src/lib/logger';

export type FcmSendResult = {
  success_count: number;
  failure_count: number;
  provider_not_configured?: true;
};

/**
 * Sends a push notification to multiple FCM tokens.
 * Fails safely when Firebase credentials are not configured.
 * Uses FCM HTTP v1 API directly — no firebase-admin package needed.
 * Private key and access token are never logged.
 */
export async function sendFcmBatch(
  tokens: string[],
  notification: { title: string; body: string; imageUrl?: string },
): Promise<FcmSendResult> {
  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n').trim();

  if (!projectId || !clientEmail || !privateKey) {
    logger.warn('fcm: provider not configured — FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY missing');
    return { success_count: 0, failure_count: 0, provider_not_configured: true };
  }

  if (tokens.length === 0) {
    logger.info('fcm: no tokens to send to');
    return { success_count: 0, failure_count: 0 };
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(clientEmail, privateKey);
  } catch (err) {
    logger.warn('fcm: failed to obtain access token', {
      message: err instanceof Error ? err.message : 'unknown',
    });
    return { success_count: 0, failure_count: tokens.length };
  }

  // Split into batches of max 100 tokens (FCM HTTP v1 sends one message per token)
  const BATCH_SIZE = 100;
  let totalSuccess = 0;
  let totalFailure = 0;

  for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
    const batch = tokens.slice(i, i + BATCH_SIZE);
    const { success, failure } = await sendBatch(
      batch,
      notification,
      projectId,
      accessToken,
    );
    totalSuccess += success;
    totalFailure += failure;
  }

  logger.info('fcm: batch send complete', {
    success_count: totalSuccess,
    failure_count: totalFailure,
  });

  return { success_count: totalSuccess, failure_count: totalFailure };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

async function sendBatch(
  tokens: string[],
  notification: { title: string; body: string; imageUrl?: string },
  projectId: string,
  accessToken: string,
): Promise<{ success: number; failure: number }> {
  const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const results = await Promise.allSettled(
    tokens.map((token) =>
      sendSingleMessage(token, notification, endpoint, accessToken),
    ),
  );

  let success = 0;
  let failure = 0;

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value) {
      success++;
    } else {
      failure++;
    }
  }

  return { success, failure };
}

async function sendSingleMessage(
  token: string,
  notification: { title: string; body: string; imageUrl?: string },
  endpoint: string,
  accessToken: string,
): Promise<boolean> {
  try {
    const body: Record<string, unknown> = {
      message: {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
          ...(notification.imageUrl ? { image: notification.imageUrl } : {}),
        },
      },
    };

    const res = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (res.status === 401 || res.status === 403) {
      // Auth failure — do not expose token or key details
      logger.warn('fcm: send auth failed', { status: res.status });
      return false;
    }

    return res.ok;
  } catch {
    // Network or parse error — never surface token in log
    return false;
  }
}

async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = Buffer.from(
    JSON.stringify({ alg: 'RS256', typ: 'JWT' }),
  ).toString('base64url');

  const payload = Buffer.from(
    JSON.stringify({
      iss: clientEmail,
      sub: clientEmail,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }),
  ).toString('base64url');

  const sign = createSign('RSA-SHA256');
  sign.update(`${header}.${payload}`);
  const signature = sign.sign(privateKey, 'base64url');
  const jwt = `${header}.${payload}.${signature}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  // Parse and validate — access_token value never logged
  const data = (await res.json()) as { access_token?: string };
  if (!data.access_token) {
    throw new Error('fcm: oauth token exchange returned no access_token');
  }
  return data.access_token;
}
