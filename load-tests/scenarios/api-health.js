/**
 * Smoke test — 1 VU for 30 seconds.
 * Run before any load test to verify the target is up.
 *
 *   k6 run --env BASE_URL=https://api-b1-test.hz.ledoweb.com load-tests/scenarios/api-health.js
 */
import { smokeCheck, churchLookup } from '../lib/common.js';
import { sleep } from 'k6';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{type:api}': ['p(95)<1000'],
  },
};

export default function () {
  smokeCheck();
  churchLookup();
  sleep(2);
}
