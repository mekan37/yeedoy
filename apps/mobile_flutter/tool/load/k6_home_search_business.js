import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://example.supabase.co/functions/v1';
const AUTH_HEADER = __ENV.AUTH_HEADER || '';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<800'],
    checks: ['rate>0.99'],
  },
};

function headers() {
  const result = {
    'Content-Type': 'application/json',
  };
  if (AUTH_HEADER) {
    result.Authorization = AUTH_HEADER;
  }
  return result;
}

export default function () {
  const homeRes = http.post(
    `${BASE_URL}/home-feed-v1`,
    JSON.stringify({
      city: 'Ankara',
      district: 'Yenimahalle',
      near_open_limit: 8,
      top_categories_limit: 6,
      trending_limit: 8,
    }),
    { headers: headers() },
  );
  check(homeRes, {
    'home_feed status 200': (r) => r.status === 200,
    'home_feed latency < 1200ms': (r) => r.timings.duration < 1200,
  });

  const searchRes = http.post(
    `${BASE_URL}/search-businesses-v1`,
    JSON.stringify({
      query: 'doner',
      city: 'Ankara',
      district: 'Yenimahalle',
      limit: 20,
      offset: 0,
    }),
    { headers: headers() },
  );
  check(searchRes, {
    'search status 200': (r) => r.status === 200,
    'search latency < 800ms': (r) => r.timings.duration < 800,
  });

  const businessRes = http.post(
    `${BASE_URL}/business-detail-v1`,
    JSON.stringify({
      business_id: __ENV.BUSINESS_ID || '00000000-0000-0000-0000-000000000000',
    }),
    { headers: headers() },
  );
  check(businessRes, {
    'business status 200': (r) => r.status === 200,
    'business latency < 800ms': (r) => r.timings.duration < 800,
  });

  sleep(1);
}
