/**
 * Baseline load test — 10 concurrent users, 5 minutes.
 *
 * Simulates realistic mix of:
 *   40% — anonymous public site visitors (church lookup → pages)
 *   25% — staff using B1Admin (people list, search, profile view)
 *   20% — staff writing (person updates, attendance reports)
 *   15% — members using B1App portal (self-service profile, groups, giving)
 *
 * Validates the default chart sizing:
 *   mysql.maxConnections=50, api.replicaCount=1, DB_CONNECTION_LIMIT=10
 *
 * Run:
 *   k6 run --env BASE_URL=http://localhost:8084 load-tests/scenarios/10-users.js
 *
 * While running, watch MySQL in another terminal:
 *   watch -n2 'docker exec church-mysql-1 sh -c \
 *     "mysql -uroot -pb1stack_root -e \"SHOW STATUS LIKE '"'"'Threads_connected'"'"';\""'
 */
import { sleep } from 'k6';
import {
  smokeCheck, login, churchLookup, publicPages,
  staffPeopleList, staffPeopleSearch, staffPersonDetail, staffPersonUpdate,
  staffGroupList, staffAttendanceReport,
  memberViewProfile, memberUpdateProfile, memberBrowseGroups,
  viewFunds, randomBetween, pickRandom, PERSON_IDS, THRESHOLDS,
} from '../lib/common.js';

export const options = {
  stages: [
    { duration: '30s', target: 10 },  // warm up
    { duration: '4m',  target: 10 },  // hold steady
    { duration: '30s', target: 0  },  // ramp down
  ],
  thresholds: THRESHOLDS,
};

export function setup() {
  smokeCheck();
  const tokens = login();
  if (!tokens) throw new Error('Login failed in setup — check TEST_EMAIL/TEST_PW');
  return tokens;
}

export default function (tokens) {
  const roll = Math.random();

  if (roll < 0.40) {
    // ── Anonymous public visitor ──────────────────────────────────────────────
    churchLookup();
    sleep(randomBetween(1, 2));
    if (Math.random() < 0.5) publicPages(tokens);
    if (Math.random() < 0.3) viewFunds();
    sleep(randomBetween(2, 5));

  } else if (roll < 0.65) {
    // ── Staff: read-only B1Admin work ─────────────────────────────────────────
    const r2 = Math.random();
    if (r2 < 0.4) {
      staffPeopleList(tokens);
    } else if (r2 < 0.7) {
      staffPeopleSearch(tokens, pickRandom(['Smith', 'Johnson', 'Williams', 'Brown', 'Jones']));
    } else {
      staffPersonDetail(tokens, pickRandom(PERSON_IDS));
    }
    sleep(randomBetween(2, 4));
    staffGroupList(tokens);
    sleep(randomBetween(1, 3));

  } else if (roll < 0.85) {
    // ── Staff: write operations (person update, attendance) ───────────────────
    if (Math.random() < 0.5) {
      // Update a person record
      staffPersonUpdate(tokens, pickRandom(PERSON_IDS));
    } else {
      // View attendance report (DB-heavy read)
      staffAttendanceReport(tokens);
    }
    sleep(randomBetween(2, 5));

  } else {
    // ── Member portal: self-service ───────────────────────────────────────────
    memberViewProfile(tokens);
    sleep(randomBetween(1, 2));
    memberBrowseGroups(tokens);
    if (Math.random() < 0.3) {
      memberUpdateProfile(tokens);  // self-edit own profile
    }
    sleep(randomBetween(3, 6));
  }
}
