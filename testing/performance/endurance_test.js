import http from 'k6/http';
import { check, sleep } from 'k6';

// Endurance Test: Sustained steady concurrency over prolonged duration
export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '3m', target: 50 }, // sustained endurance
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<1500'],
    http_req_failed: ['rate<0.02'],
  },
};

const BASE_URL = __ENV.HACKPILOT_TEST_URL || 'http://127.0.0.1:8765';

export default function () {
  const res = http.get(`${BASE_URL}/`, { tags: { name: 'Endurance_Profile' } });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(2);
}

