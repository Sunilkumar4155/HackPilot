import http from 'k6/http';
import { check, sleep } from 'k6';

// Stress Test: Pushing towards upper concurrency limits (250 VUs)
export const options = {
  stages: [
    { duration: '30s', target: 100 },
    { duration: '1m', target: 250 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.10'],
  },
};

const BASE_URL = __ENV.HACKPILOT_TEST_URL || 'http://127.0.0.1:8765';

export default function () {
  const res = http.get(`${BASE_URL}/`, { tags: { name: 'Stress_Profile' } });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}

