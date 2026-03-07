/**
 * Stress test — ramp to 50 concurrent users.
 * Validates the 50-user chart sizing:
 *   mysql.maxConnections=100, api.replicaCount=2, DB_CONNECTION_LIMIT=15
 *
 * Expected chart overrides for this test:
 *   --set mysql.maxConnections=100
 *   --set api.replicaCount=2
 *   --set api.env.DB_CONNECTION_LIMIT=15
 *   --set api.resources.limits.cpu=1000m
 *   --set api.resources.requests.memory=512Mi
 *
 * Run:
 *   k6 run --env BASE_URL=https://api-b1-test.hz.ledoweb.com load-tests/scenarios/50-users.js
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, THRESHOLDS, churchLookup, randomBetween } from '../lib/common.js';

export const options = {
  stages: [
    { duration: '1m',  target: 10 },   // warm up
    { duration: '2m',  target: 50 },   // ramp to 50
    { duration: '5m',  target: 50 },   // hold steady — watch for connection exhaustion
    { duration: '2m',  target: 10 },   // ramp down
    { duration: '30s', target: 0  },   // done
  ],
  thresholds: {
    ...THRESHOLDS,
    // At 50 users we allow slightly more latency on SSR
    'http_req_duration{type:ssr}': ['p(95)<5000'],
  },
};

export default function () {
  const roll = Math.random();

  if (roll < 0.4) {
    churchLookup();
    sleep(randomBetween(1, 3));
  } else if (roll < 0.7) {
    const res = http.get(`${BASE_URL}/membership/services`, { tags: { type: 'api' } });
    check(res, { 'services ok': (r) => r.status < 500 });
    sleep(randomBetween(1, 2));
  } else if (roll < 0.9) {
    // People (member listing — DB-intensive, good stress test)
    const res = http.get(`${BASE_URL}/membership/people`, { tags: { type: 'api' } });
    check(res, { 'people ok': (r) => r.status < 500 });
    sleep(randomBetween(2, 4));
  } else {
    // Attendance post (write load)
    const payload = JSON.stringify({ serviceId: 'test', count: 1 });
    const res = http.post(`${BASE_URL}/attendance/visits`, payload, {
      headers: { 'Content-Type': 'application/json' },
      tags: { type: 'api' },
    });
    check(res, { 'attendance post ok': (r) => r.status < 500 });
    sleep(randomBetween(1, 2));
  }
}
