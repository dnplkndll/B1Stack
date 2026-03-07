import { defineConfig, devices } from "@playwright/test";

const BASE_DOMAIN = process.env.BASE_DOMAIN || "church.hz.ledoweb.com";
const PROTO = process.env.BASE_PROTO || "https";

export default defineConfig({
  testDir: "./tests",
  timeout: 30_000,
  expect: { timeout: 10_000 },
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    ignoreHTTPSErrors: true, // cert-manager may still be issuing during test run
    extraHTTPHeaders: { Accept: "application/json, text/html" },
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  // Env vars injected into all tests
  globalSetup: undefined,
  metadata: {
    BASE_DOMAIN,
    API_URL: `${PROTO}://api-${BASE_DOMAIN}`,
    ADMIN_URL: `${PROTO}://admin-${BASE_DOMAIN}`,
    APP_URL: `${PROTO}://${BASE_DOMAIN}`,
  },
});
