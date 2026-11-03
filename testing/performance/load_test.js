import http from 'k6/http';
import { check, sleep } from 'k6';

// HackPilot Load Performance Test (Ramping Load Profile)
export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 150 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.HACKPILOT_TEST_URL || 'http://127.0.0.1:8765';

export default function () {
  const res = http.get(`${BASE_URL}/`, { tags: { name: 'Load_Shell' } });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1.5);
}

