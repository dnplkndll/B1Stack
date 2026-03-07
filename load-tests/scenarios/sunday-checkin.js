/**
 * Sunday morning burst — check-in simulation.
 *
 * Church size reference:
 *   500-member church: 3 services, ~60% weekend attendance = 300 people
 *   Families of 2-4 → ~100-150 kiosk transactions over 15 minutes per service
 *
 *   5,000-member church: same math ×10 → 1,000-1,500 transactions
 *   At that scale: managed DB + HPA required. See values.yaml sizing table.
 *
 * This test models the 500-member church (150 VU peak).
 *
 * Run:
 *   k6 run --env BASE_URL=http://localhost:8084 load-tests/scenarios/sunday-checkin.js
 *
 * IMPORTANT: This creates real visit records in the DB.
 * Clean up after testing: docker exec church-mysql-1 sh -c \
 *   "mysql -uroot -pb1stack_root attendance -e 'DELETE FROM visits WHERE visitDate >= CURDATE()'"
 */
import { sleep } from 'k6';
import {
  smokeCheck, login, churchLookup, staffPeopleSearch,
  checkinVisit, staffAttendanceReport,
  randomBetween, pickRandom, PERSON_IDS, THRESHOLDS,
} from '../lib/common.js';
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '2m',  target: 20  },   // Doors open — early arrivals
    { duration: '3m',  target: 150 },   // Main arrival wave (pre-service rush)
    { duration: '5m',  target: 80  },   // Steady checkins (service in progress, late arrivals)
    { duration: '3m',  target: 20  },   // Post-service activity
    { duration: '2m',  target: 0   },
  ],
  thresholds: {
    // Checkin failure = family blocked at the door — zero tolerance
    http_req_failed: ['rate<0.001'],
    'http_req_duration{flow:checkin}': ['p(95)<2000', 'p(99)<4000'],
    'http_req_duration{flow:anon}':   ['p(95)<1000'],
  },
};

export function setup() {
  smokeCheck();
  const tokens = login();
  if (!tokens) throw new Error('Login failed in setup');

  // Get a current session ID from the DB (Sunday morning session)
  // In production this would be created by staff before service
  return { tokens, sessionId: 'SES00000028' };
}

export default function ({ tokens, sessionId }) {
  // Each VU = one kiosk or phone check-in

  // Step 1: Kiosk loads — church lookup happens on every device boot/refresh
  if (Math.random() < 0.3) {  // Not every checkin triggers this (kiosks stay warm)
    churchLookup();
    sleep(randomBetween(0.1, 0.3));
  }

  // Step 2: Family name search (simulates someone typing at kiosk)
  const nameTerms = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis', 'Wilson'];
  staffPeopleSearch(tokens, pickRandom(nameTerms));
  sleep(randomBetween(0.3, 1.0));  // time for person to select their record

  // Step 3: Check in each family member (1-4 people per transaction)
  const familySize = Math.floor(Math.random() * 3) + 1;
  for (let i = 0; i < familySize; i++) {
    const pid = pickRandom(PERSON_IDS);
    checkinVisit(tokens, pid, sessionId);
    sleep(0.1);  // brief gap between family members
  }

  // Step 4: Think time before next family
  sleep(randomBetween(0.5, 2.0));
}

/**
 * After the burst, verify attendance totals are sane.
 * k6 teardown() runs once after all VUs complete.
 */
export function teardown({ tokens }) {
  staffAttendanceReport(tokens);
}
