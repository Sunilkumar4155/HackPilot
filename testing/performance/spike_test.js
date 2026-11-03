import http from 'k6/http';
import { check, sleep } from 'k6';

// Spike Test: Sudden surge in concurrent users
export const options = {
  stages: [
    { duration: '10s', target: 20 },
    { duration: '15s', target: 200 }, // sudden traffic spike
    { duration: '10s', target: 20 },  // recovery
  ],
  thresholds: {
    http_req_duration: ['p(95)<3500'],
    http_req_failed: ['rate<0.15'],
  },
};

const BASE_URL = __ENV.HACKPILOT_TEST_URL || 'http://127.0.0.1:8765';

export default function () {
  const res = http.get(`${BASE_URL}/`, { tags: { name: 'Spike_Profile' } });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.5);
}

