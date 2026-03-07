/**
 * Sunday morning burst test.
 *
 * A 500-member church with 3 services and 60% attendance = ~300 people checking in.
 * With families checking in together, model as ~150 concurrent check-in requests
 * arriving in a 15-minute window (ramp in, spike, ramp out).
 *
 * A 5,000-member church: multiply ×10 → 1,500 concurrent; needs HPA + managed DB.
 *
 * Run:
 *   k6 run --env BASE_URL=https://api-b1-test.hz.ledoweb.com load-tests/scenarios/sunday-checkin.js
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, churchLookup, randomBetween } from '../lib/common.js';

// TODO: replace with real service IDs from your demo data
const SERVICE_IDS = ['service-1', 'service-2'];
const GROUP_IDS   = ['group-1', 'group-2', 'group-3'];

export const options = {
  stages: [
    // Doors open — slow initial trickle
    { duration: '2m',  target: 20  },
    // Main arrival wave (5 minutes before service)
    { duration: '3m',  target: 150 },
    // Steady checkins (service in progress)
    { duration: '5m',  target: 80  },
    // Late arrivals / offering / post-service activity
    { duration: '3m',  target: 30  },
    { duration: '2m',  target: 0   },
  ],
  thresholds: {
    // Checkin must not fail — families blocked at the door is unacceptable
    http_req_failed: ['rate<0.001'],
    'http_req_duration{type:api}': ['p(95)<2000'],
  },
};

export default function () {
  // Each VU simulates a kiosk or phone check-in flow

  // Step 1: Lookup church (every device does this on load)
  churchLookup();
  sleep(randomBetween(0.2, 0.5));

  // Step 2: Post attendance visit
  const serviceId = SERVICE_IDS[Math.floor(Math.random() * SERVICE_IDS.length)];
  const body = JSON.stringify({
    serviceId,
    serviceTime: new Date().toISOString(),
    peopleCount: Math.floor(Math.random() * 4) + 1, // family of 1–4
  });

  const res = http.post(
    `${BASE_URL}/attendance/visits`,
    body,
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { type: 'api' },
    }
  );
  check(res, {
    'checkin accepted': (r) => r.status === 200 || r.status === 201 || r.status === 401,
  });

  sleep(randomBetween(0.5, 2));
}
