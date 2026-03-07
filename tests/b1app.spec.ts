import { test, expect } from "@playwright/test";

const BASE_DOMAIN = process.env.BASE_DOMAIN || "church.hz.ledoweb.com";
const PROTO = process.env.BASE_PROTO || "https";
const APP = `${PROTO}://${BASE_DOMAIN}`;

test.describe("B1App (public church site)", () => {
  test("home page returns 200 and loads", async ({ page }) => {
    const res = await page.goto(APP, { waitUntil: "networkidle" });
    // B1App redirects home → /my (member portal) or /{slug}
    expect(res?.status()).toBe(200);
    const body = await page.locator("body").innerHTML();
    expect(body.length).toBeGreaterThan(200);
  });

  test("home page has a title", async ({ page }) => {
    await page.goto(APP, { waitUntil: "networkidle" });
    const title = await page.title();
    expect(title).toBeTruthy();
    expect(title.length).toBeGreaterThan(0);
  });

  test("no unhandled 500 errors on home page", async ({ page }) => {
    const errors: string[] = [];
    page.on("response", (res) => {
      if (res.status() >= 500) errors.push(`${res.status()} ${res.url()}`);
    });
    await page.goto(APP, { waitUntil: "networkidle" });
    expect(errors, `500 errors: ${errors.join(", ")}`).toHaveLength(0);
  });

  test("page renders meaningful content after JS hydration", async ({
    page,
  }) => {
    await page.goto(APP, { waitUntil: "networkidle" });

    // Next.js RSC: content is JS-rendered. Wait for any content block or login form.
    // B1App redirects to /my (member portal) or renders church page — both are valid.
    const content = await page
      .locator("body")
      .evaluate((el) => el.innerText.trim());
    expect(
      content.length,
      "Page body should have visible text after hydration"
    ).toBeGreaterThan(50);

    // Should not show a generic Next.js error skeleton
    expect(content).not.toMatch(/This page could not be found/i);
  });
});
