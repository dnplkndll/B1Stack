// Shared helpers for B1Stack k6 load tests
import { check, sleep } from 'k6';
import http from 'k6/http';

export const BASE_URL = __ENV.BASE_URL || 'http://localhost:8084';

// Church slug used in most API calls — override with --env CHURCH_SLUG=yourslug
export const CHURCH_SLUG = __ENV.CHURCH_SLUG || 'demo';

// Standard thresholds for API + SSR targets
export const THRESHOLDS = {
  // API calls should be fast
  'http_req_duration{type:api}': ['p(95)<1000', 'p(99)<2000'],
  // SSR pages tolerate more (Next.js rendering)
  'http_req_duration{type:ssr}': ['p(95)<3000', 'p(99)<5000'],
  // Less than 0.5% failures
  http_req_failed: ['rate<0.005'],
};

/**
 * Ping the API health endpoint.
 * Use in setup() to bail early if the target is down.
 */
export function smokeCheck() {
  const res = http.get(`${BASE_URL}/health`, { tags: { type: 'api' } });
  check(res, { 'API health 200': (r) => r.status === 200 });
  return res.status === 200;
}

/**
 * Simulate a public visitor hitting the church homepage (B1App SSR).
 */
export function visitHomepage() {
  const appUrl = BASE_URL.replace('api-', '');   // strip api- prefix for b1app URL
  const res = http.get(appUrl, { tags: { type: 'ssr' } });
  check(res, { 'homepage 200': (r) => r.status === 200 });
  sleep(randomBetween(1, 3));
}

/**
 * Hit the church lookup endpoint — most common cold-start API call.
 * This is what triggered the "Too many connections" bug (SSR → API → MySQL).
 */
export function churchLookup() {
  const res = http.get(
    `${BASE_URL}/membership/churches/lookup?subDomain=${CHURCH_SLUG}`,
    { tags: { type: 'api' } }
  );
  check(res, {
    'church lookup 200': (r) => r.status === 200,
    'church lookup has id': (r) => {
      try { return !!JSON.parse(r.body).id; } catch { return false; }
    },
  });
  return res;
}

/** Random sleep between min and max seconds (simulate real user think time). */
export function randomBetween(min, max) {
  return Math.random() * (max - min) + min;
}
