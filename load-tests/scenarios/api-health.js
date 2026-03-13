/**
 * Smoke test — run before any load test.
 * 1 VU, 30 seconds, exercises every major endpoint.
 *
 * Run:
 *   k6 run --env BASE_URL=http://localhost:8084 load-tests/scenarios/api-health.js
 */
import { sleep } from 'k6';
import {
  smokeCheck, login, churchLookup, publicPages,
  staffPeopleList, staffPeopleSearch, staffPersonDetail,
  staffGroupList, staffAttendanceReport,
  memberViewProfile, viewFunds, PERSON_IDS,
} from '../lib/common.js';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{type:api}': ['p(95)<2000'],
  },
};

export function setup() {
  smokeCheck();
  return login();
}

export default function (tokens) {
  churchLookup();        sleep(0.5);
  publicPages(tokens);   sleep(0.5);
  viewFunds();           sleep(0.5);
  staffPeopleList(tokens); sleep(0.5);
  staffPeopleSearch(tokens, 'Smith'); sleep(0.5);
  staffPersonDetail(tokens, PERSON_IDS[0]); sleep(0.5);
  staffGroupList(tokens); sleep(0.5);
  staffAttendanceReport(tokens); sleep(0.5);
  memberViewProfile(tokens); sleep(1);
}
