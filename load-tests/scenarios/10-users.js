/**
 * Baseline load test — 10 concurrent users for 5 minutes.
 * This validates the default chart sizing (mysql.maxConnections=50, DB_CONNECTION_LIMIT=10).
 *
 * Simulates a mix of:
 *   - Public visitors browsing the church site (B1App SSR)
 *   - Members/staff hitting the API (church lookup, service times)
 *
 * Run:
 *   k6 run --env BASE_URL=https://api-b1-test.hz.ledoweb.com load-tests/scenarios/10-users.js
 *
 * Pass credentials for authenticated endpoints:
 *   k6 run --env BASE_URL=... --env TEST_EMAIL=admin@demo.church --env TEST_PASSWORD=... ...
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, THRESHOLDS, churchLookup, randomBetween } from '../lib/common.js';

export const options = {
  // Ramp up to 10 VUs over 30s, hold for 4 minutes, ramp down
  stages: [
    { duration: '30s', target: 10 },
    { duration: '4m',  target: 10 },
    { duration: '30s', target: 0  },
  ],
  thresholds: THRESHOLDS,
};

export function setup() {
  // Verify target is reachable before wasting a full test run
  const health = http.get(`${BASE_URL}/health`);
  if (health.status !== 200) {
    throw new Error(`API not healthy: ${health.status} — aborting test`);
  }
}

export default function () {
  // Weight of each scenario per VU iteration (roughly matches real traffic mix):
  const roll = Math.random();

  if (roll < 0.5) {
    // 50% — public site hit (church lookup → the root SSR trigger)
    churchLookup();
    sleep(randomBetween(2, 5));

  } else if (roll < 0.8) {
    // 30% — service times listing
    const res = http.get(
      `${BASE_URL}/membership/services`,
      { tags: { type: 'api' } }
    );
    check(res, { 'services 200 or 404': (r) => r.status === 200 || r.status === 404 });
    sleep(randomBetween(1, 3));

  } else {
    // 20% — group/event listing (common member portal action)
    const res = http.get(
      `${BASE_URL}/membership/groups`,
      { tags: { type: 'api' } }
    );
    check(res, { 'groups 200 or 401': (r) => r.status === 200 || r.status === 401 });
    sleep(randomBetween(1, 4));
  }
}
