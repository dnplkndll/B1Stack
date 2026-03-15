/**
 * Stress test — ramp to 50 concurrent users, 10 minutes.
 *
 * Requires chart upscaling before running:
 *   --set mysql.maxConnections=200
 *   --set api.replicaCount=2
 *
 * Traffic mix shifts toward writes and heavier reads at scale:
 *   30% — anon public visitors (SSR triggers, church lookup)
 *   30% — staff reads (people search, person details, attendance)
 *   25% — staff writes (person updates, group management)
 *   15% — member self-service
 *
 * Run:
 *   k6 run --env BASE_URL=http://localhost:8084 load-tests/scenarios/50-users.js
 */
import { sleep } from 'k6';
import {
  smokeCheck, login, churchLookup, publicPages,
  staffPeopleList, staffPeopleSearch, staffPersonDetail, staffPersonUpdate,
  staffGroupList, staffAttendanceReport,
  memberViewProfile, memberUpdateProfile, memberBrowseGroups,
  checkinVisit, viewFunds, randomBetween, pickRandom,
  PERSON_IDS,
} from '../lib/common.js';

export const options = {
  stages: [
    { duration: '1m',  target: 10  },  // warm up at baseline
    { duration: '2m',  target: 50  },  // ramp to target
    { duration: '5m',  target: 50  },  // hold — watch for connection exhaustion
    { duration: '1m',  target: 10  },  // cool down
    { duration: '30s', target: 0   },
  ],
  thresholds: {
    'http_req_duration{type:api}': ['p(95)<1500', 'p(99)<3000'],
    'http_req_duration{type:ssr}': ['p(95)<5000'],
    'http_req_duration{flow:checkin}': ['p(95)<2000'],
    'http_req_duration{flow:staff-write}': ['p(95)<2000'],
    http_req_failed: ['rate<0.005'],
  },
};

export function setup() {
  smokeCheck();
  const tokens = login();
  if (!tokens) throw new Error('Login failed');

  // Dynamically fetch a valid session ID from the DB instead of hardcoding
  const sessRes = staffAttendanceReport(tokens);
  let sessionId = null;
  try {
    const sessions = JSON.parse(sessRes.body);
    if (Array.isArray(sessions) && sessions.length > 0) {
      sessionId = sessions[0].id;
    }
  } catch (_) { /* ignored */ }
  if (!sessionId) console.warn('No sessions found — checkin visits will likely fail');

  return { ...tokens, sessionId };
}

export default function ({ sessionId, ...tokens }) {
  const roll = Math.random();

  if (roll < 0.30) {
    // ── Anon public visitor ───────────────────────────────────────────────────
    churchLookup();
    sleep(randomBetween(0.5, 1.5));
    if (Math.random() < 0.4) publicPages(tokens);
    if (Math.random() < 0.2) viewFunds();
    sleep(randomBetween(1, 3));

  } else if (roll < 0.60) {
    // ── Staff reads ───────────────────────────────────────────────────────────
    const r2 = Math.random();
    if (r2 < 0.35) {
      staffPeopleSearch(tokens, pickRandom(['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Davis']));
    } else if (r2 < 0.60) {
      staffPersonDetail(tokens, pickRandom(PERSON_IDS));
    } else if (r2 < 0.80) {
      staffAttendanceReport(tokens);
    } else {
      staffPeopleList(tokens);
    }
    sleep(randomBetween(1, 3));

  } else if (roll < 0.85) {
    // ── Staff writes ──────────────────────────────────────────────────────────
    if (Math.random() < 0.6) {
      // Person profile update (most common write)
      staffPersonUpdate(tokens, pickRandom(PERSON_IDS));
    } else {
      // Attendance checkin (second most common write on Sundays)
      checkinVisit(tokens, pickRandom(PERSON_IDS), sessionId);
    }
    sleep(randomBetween(1, 2));

  } else {
    // ── Member self-service ───────────────────────────────────────────────────
    memberViewProfile(tokens);
    sleep(randomBetween(1, 2));
    if (Math.random() < 0.5) memberBrowseGroups(tokens);
    if (Math.random() < 0.2) memberUpdateProfile(tokens);
    sleep(randomBetween(2, 5));
  }
}
