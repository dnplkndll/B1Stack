/**
 * Shared helpers for B1Stack k6 load tests.
 *
 * Auth pattern:
 *   The ChurchApps API uses per-API JWTs returned on login.
 *   - user.jwt       → simple user identity token
 *   - userChurches[0].jwt       → church-scoped JWT (groups, people, attendance)
 *   - userChurches[0].apis[name].jwt → per-API JWTs (MembershipApi, AttendanceApi, etc.)
 *
 * All authenticated endpoints require: Authorization: Bearer <jwt>
 */

import http from 'k6/http';
import { check, sleep } from 'k6';

// ── Environment (override with --env flags) ──────────────────────────────────
export const BASE_URL    = __ENV.BASE_URL    || 'http://localhost:8084';
export const TEST_EMAIL  = __ENV.TEST_EMAIL  || 'demo@b1.church';
export const TEST_PW     = __ENV.TEST_PW     || 'TestPass123!';
export const CHURCH_SLUG = __ENV.CHURCH_SLUG || 'grace';

// ── Known IDs (from initdb demo data — change if using a different DB) ───────
export const CHURCH_ID       = 'CHU00000001';
export const SVC_SUNDAY_AM   = 'SER00000001';   // Sunday Morning Service
export const SVC_SUNDAY_PM   = 'SER00000002';   // Sunday Evening Service
export const SVC_WEDNESDAY   = 'SER00000003';   // Wednesday Evening
export const SVCTIME_9AM     = 'SST00000001';
export const SVCTIME_1030AM  = 'SST00000002';
export const GROUP_SUNDAY_AM = 'GRP00000001';   // Sunday Morning Service group
export const GROUP_BIBLE     = 'GRP00000004';   // Adult Bible Class
// Sample person IDs for realistic read targets
export const PERSON_IDS = [
  'PER00000001','PER00000002','PER00000003','PER00000004','PER00000005',
  'PER00000006','PER00000007','PER00000008','PER00000009','PER00000010',
];

// ── Standard thresholds (validated against real API behaviour) ───────────────
export const THRESHOLDS = {
  'http_req_duration{type:api}': ['p(95)<1000', 'p(99)<2000'],
  'http_req_duration{type:ssr}': ['p(95)<3000', 'p(99)<5000'],
  http_req_failed: ['rate<0.005'],
};

// ── Auth ──────────────────────────────────────────────────────────────────────

/**
 * Login and return a token bag with all API JWTs.
 * Call from k6 setup() so it runs once before VUs start.
 *
 * Returns { userJwt, churchJwt, membershipJwt, attendanceJwt, givingJwt, contentJwt }
 */
export function login(email = TEST_EMAIL, password = TEST_PW) {
  const res = http.post(
    `${BASE_URL}/membership/users/login`,
    JSON.stringify({ email, password }),
    { headers: { 'Content-Type': 'application/json' }, tags: { type: 'api' } }
  );

  check(res, { 'login 200': (r) => r.status === 200 });
  if (res.status !== 200) return null;

  const body = JSON.parse(res.body);
  const user  = body.user;
  const uc    = body.userChurches?.[0];

  const jwtMap = {};
  (uc?.apis || []).forEach((api) => { jwtMap[api.keyName] = api.jwt; });

  return {
    userJwt:       user?.jwt,
    churchJwt:     uc?.jwt,
    membershipJwt: jwtMap['MembershipApi'],
    attendanceJwt: jwtMap['AttendanceApi'],
    givingJwt:     jwtMap['GivingApi'],
    contentJwt:    jwtMap['ContentApi'],
    churchId:      uc?.church?.id || CHURCH_ID,
    personId:      uc?.person?.id,
  };
}

/** Auth headers for a given JWT. */
export function authHeaders(jwt) {
  return { 'Authorization': `Bearer ${jwt}`, 'Content-Type': 'application/json' };
}

// ── Anon flows (public site, no auth) ────────────────────────────────────────

/** Church lookup — triggered by every B1App SSR page load. The original "too many connections" call. */
export function churchLookup() {
  const res = http.get(
    `${BASE_URL}/membership/churches/lookup?subDomain=${CHURCH_SLUG}`,
    { tags: { type: 'api', flow: 'anon' } }
  );
  check(res, {
    'church lookup 200': (r) => r.status === 200,
    'church lookup has id': (r) => { try { return !!JSON.parse(r.body).id; } catch { return false; } },
  });
  return res;
}

/** Public pages — content that any visitor loads. */
export function publicPages(tokens) {
  const jwt = tokens?.contentJwt;
  const headers = jwt ? authHeaders(jwt) : { 'Content-Type': 'application/json' };
  const pages = http.get(`${BASE_URL}/content/pages`, { headers, tags: { type: 'api', flow: 'anon' } });
  check(pages, { 'pages 200': (r) => r.status === 200 });
  return pages;
}

// ── Staff flows (B1Admin — authenticated) ─────────────────────────────────────

/** Staff: load the people directory (common first action in B1Admin). */
export function staffPeopleList(tokens) {
  const res = http.get(
    `${BASE_URL}/membership/people`,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'staff' } }
  );
  check(res, { 'people list 200': (r) => r.status === 200 });
  return res;
}

/** Staff: search for a person by name. */
export function staffPeopleSearch(tokens, term = 'Smith') {
  const res = http.get(
    `${BASE_URL}/membership/people/search?term=${term}`,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'staff' } }
  );
  check(res, { 'people search 200': (r) => r.status === 200 });
  return res;
}

/** Staff: view a specific person's full profile. */
export function staffPersonDetail(tokens, personId = PERSON_IDS[0]) {
  const res = http.get(
    `${BASE_URL}/membership/people/${personId}`,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'staff' } }
  );
  check(res, {
    'person detail 200 or 404': (r) => r.status === 200 || r.status === 404,
  });
  return res;
}

/**
 * Staff: update a person's profile (write operation).
 * Uses a deterministic personId so concurrent VUs don't race on random new records.
 * In a real test with many users, use a pool of person IDs distributed across VUs.
 */
export function staffPersonUpdate(tokens, personId = PERSON_IDS[0]) {
  // People endpoint takes an array of person objects.
  // name is nested; contactInfo must be present (even if empty).
  const payload = JSON.stringify([{
    id: personId,
    churchId: tokens.churchId,
    name: { first: 'LoadTest', last: 'Updated' },
    contactInfo: {},
    membershipStatus: 'Member',
  }]);
  const res = http.post(
    `${BASE_URL}/membership/people`,
    payload,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'staff-write' } }
  );
  check(res, {
    'person update 200 or 401': (r) => r.status === 200 || r.status === 401,
  });
  return res;
}

/** Staff: list groups. */
export function staffGroupList(tokens) {
  const res = http.get(
    `${BASE_URL}/membership/groups`,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'staff' } }
  );
  check(res, { 'groups 200': (r) => r.status === 200 });
  return res;
}

/** Staff: view attendance for a service (heavy read — joins 3 tables). */
export function staffAttendanceReport(tokens) {
  const res = http.get(
    `${BASE_URL}/attendance/sessions`,
    { headers: authHeaders(tokens.attendanceJwt), tags: { type: 'api', flow: 'staff' } }
  );
  check(res, { 'sessions 200': (r) => r.status === 200 });
  return res;
}

// ── Check-in flows (kiosk / mobile) ──────────────────────────────────────────

/**
 * Checkin: record a visit for a person (write — the critical Sunday load path).
 * Takes an array of visits. Endpoint: POST /attendance/visits
 */
export function checkinVisit(tokens, personId, sessionId) {
  const payload = JSON.stringify([{
    churchId: tokens.churchId,
    personId: personId || tokens.personId || PERSON_IDS[0],
    serviceId: SVC_SUNDAY_AM,
    groupId: GROUP_SUNDAY_AM,
    visitDate: new Date().toISOString(),
    sessionId: sessionId,
  }]);
  const res = http.post(
    `${BASE_URL}/attendance/visits`,
    payload,
    { headers: authHeaders(tokens.attendanceJwt), tags: { type: 'api', flow: 'checkin' } }
  );
  check(res, {
    'checkin 200': (r) => r.status === 200,
    'checkin returns ids': (r) => {
      try { return Array.isArray(JSON.parse(r.body)) && JSON.parse(r.body).length > 0; } catch { return false; }
    },
  });
  return res;
}

/**
 * Checkin: full kiosk flow — lookup church → find person → record visit.
 * This is the complete path that triggered "Too many connections" on prod.
 */
export function kioskFlow(tokens, sessionId) {
  // Step 1: church lookup (always happens on kiosk load)
  churchLookup();
  sleep(randomBetween(0.1, 0.3));

  // Step 2: search for a person by name (simulates typing name at kiosk)
  const terms = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones'];
  staffPeopleSearch(tokens, terms[Math.floor(Math.random() * terms.length)]);
  sleep(randomBetween(0.2, 0.5));

  // Step 3: record the visit
  const pid = PERSON_IDS[Math.floor(Math.random() * PERSON_IDS.length)];
  checkinVisit(tokens, pid, sessionId);
  sleep(randomBetween(0.5, 1.5));
}

// ── Member portal flows (B1App — member self-service) ────────────────────────

/**
 * Member portal: view own profile.
 */
export function memberViewProfile(tokens) {
  const res = http.get(
    `${BASE_URL}/membership/people/${tokens.personId}`,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'member' } }
  );
  check(res, { 'member profile 200': (r) => r.status === 200 });
  return res;
}

/**
 * Member portal: update own profile (self-edit — restricted permission).
 */
export function memberUpdateProfile(tokens) {
  if (!tokens.personId) return null;
  const payload = JSON.stringify([{
    id: tokens.personId,
    churchId: tokens.churchId,
    name: { first: 'Member', last: 'SelfEdit' },
    contactInfo: {},
  }]);
  const res = http.post(
    `${BASE_URL}/membership/people`,
    payload,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'member-write' } }
  );
  check(res, { 'self edit 200 or 401': (r) => r.status === 200 || r.status === 401 });
  return res;
}

/**
 * Member portal: view available groups to join.
 */
export function memberBrowseGroups(tokens) {
  const res = http.get(
    `${BASE_URL}/membership/groups`,
    { headers: authHeaders(tokens.membershipJwt), tags: { type: 'api', flow: 'member' } }
  );
  check(res, { 'groups 200': (r) => r.status === 200 });
  return res;
}

// ── Giving flows ──────────────────────────────────────────────────────────────

/** View donation funds (public — shown on giving page). */
export function viewFunds() {
  const res = http.get(`${BASE_URL}/giving/funds`, { tags: { type: 'api', flow: 'giving' } });
  check(res, { 'funds 200': (r) => r.status === 200 });
  return res;
}

// ── Utilities ─────────────────────────────────────────────────────────────────

export function randomBetween(min, max) {
  return Math.random() * (max - min) + min;
}

export function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/**
 * Smoke check — verify API is alive before running full load test.
 * Call from setup() and throw on failure so k6 doesn't waste time.
 */
export function smokeCheck() {
  const res = http.get(`${BASE_URL}/health`, { tags: { type: 'api' } });
  if (res.status !== 200) {
    throw new Error(`API health check failed: ${res.status} — is the stack running?`);
  }
  return true;
}
