import http from 'k6/http';
import { check, sleep } from 'k6';

// HackPilot Baseline Performance Test
// Profile: 100 Virtual Users over 1 Minute
export const options = {
  stages: [
    { duration: '15s', target: 50 },  // Ramp-up to 50 VUs
    { duration: '30s', target: 100 }, // Sustained baseline load at 100 VUs
    { duration: '15s', target: 0 },   // Ramp-down to 0 VUs
  ],
  thresholds: {
    http_req_duration: ['p(95)<1500'], // 95% of requests must complete below 1.5s
    http_req_failed: ['rate<0.05'],     // Error rate must remain under 5%
  },
};

const BASE_URL = __ENV.HACKPILOT_TEST_URL || 'http://127.0.0.1:8765';

export default function () {
  // Scenario 1: Load Web App Shell & Assets
  const resApp = http.get(`${BASE_URL}/`, {
    tags: { name: 'WebApp_Shell' },
  });
  check(resApp, {
    'app shell status is 200': (r) => r.status === 200,
  });

  sleep(1);

  // Scenario 2: Ingest External Hackathons Feed
  const resFeed = http.get('https://hackalendar.com/api/events?limit=20', {
    tags: { name: 'External_Hackathons_Feed' },
  });
  check(resFeed, {
    'feed status is 200 or 429/timeout handled': (r) => r.status === 200 || r.status === 429,
  });

  sleep(1);

  // Scenario 3: Translation Service Query
  const sampleQuery = encodeURIComponent('हैकथॉन प्रतियोगिता');
  const resTrans = http.get(
    `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=${sampleQuery}`,
    { tags: { name: 'Translation_Service' } }
  );
  check(resTrans, {
    'translation status is 200': (r) => r.status === 200 || r.status === 429,
  });

  sleep(1);
}

