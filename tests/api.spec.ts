import { test, expect } from "@playwright/test";

const BASE_DOMAIN = process.env.BASE_DOMAIN || "church.hz.ledoweb.com";
const PROTO = process.env.BASE_PROTO || "https";
const API = `${PROTO}://api-${BASE_DOMAIN}`;

test.describe("API health", () => {
  test("health endpoint returns healthy", async ({ request }) => {
    const res = await request.get(`${API}/health`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.status).toBe("healthy");
  });

  test("health response includes expected modules", async ({ request }) => {
    const res = await request.get(`${API}/health`);
    const body = await res.json();
    const modules: string[] = body.modules ?? [];
    for (const mod of [
      "membership",
      "attendance",
      "giving",
      "content",
      "messaging",
    ]) {
      expect(modules, `expected module "${mod}" in health response`).toContain(
        mod
      );
    }
  });

  test("unauthenticated request to protected endpoint returns 401", async ({
    request,
  }) => {
    const res = await request.get(`${API}/membership/people`);
    expect([401, 403]).toContain(res.status());
  });
});
