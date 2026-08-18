import { chromium } from "/Users/videomacbookpro/.npm/_npx/e41f203b7505f1fb/node_modules/playwright/index.mjs";

const baseUrl = process.env.BKK_WEB_URL ?? "http://127.0.0.1:8092";
const results = [];

async function check(name, operation) {
  const started = Date.now();
  try {
    const details = await operation();
    results.push({ name, status: "passed", durationMs: Date.now() - started, details });
  } catch (error) {
    results.push({ name, status: "failed", durationMs: Date.now() - started, error: error.message });
    return false;
  }
  return true;
}

const browser = await chromium.launch({
  headless: true,
  executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

try {
  await check("Login is the platform entry point", async () => {
    await page.goto(`${baseUrl}/index.php`, { waitUntil: "networkidle" });
    if (!page.url().includes("login.php")) throw new Error(`Home bypassed login: ${page.url()}`);
    return { gate: "/login.php" };
  });

  await check("A member can sign in and reach the platform", async () => {
    await page.goto(`${baseUrl}/login.php`, { waitUntil: "networkidle" });
    await page.getByLabel("Email address").fill("member@bkk.demo");
    await page.getByLabel("Password", { exact: true }).fill("MemberDemo!26");
    await page.getByRole("button", { name: "Log in" }).click();
    await page.waitForLoadState("networkidle");
    if (!page.url().includes("profile.php")) throw new Error(`Unexpected destination: ${page.url()}`);
    await page.goto(`${baseUrl}/index.php`, { waitUntil: "networkidle" });
    return { postLogin: "/profile.php", homeAccessible: true, credentials: "redacted" };
  });

  await check("Home keeps the four primary tasks", async () => {
    for (const label of ["Events", "Discounts", "Local Info", "Contact"]) {
      await page.getByRole("link", { name: new RegExp(label, "i") }).first().waitFor({ state: "visible" });
    }
    return { primaryTasks: 4 };
  });

  await check("Touch menu has no more than five destinations", async () => {
    const toggle = page.getByRole("button", { name: /navigation menu/i });
    await toggle.click();
    const links = page.locator("#primary-navigation a");
    const count = await links.count();
    if (count > 5) throw new Error(`Primary navigation exposes ${count} destinations`);
    return { destinations: count };
  });

  await check("Page scroll works at 200% zoom", async () => {
    await page.evaluate(() => { document.documentElement.style.zoom = "2"; window.scrollTo(0, document.body.scrollHeight); });
    await page.waitForTimeout(250);
    const state = await page.evaluate(() => ({ y: window.scrollY, max: document.documentElement.scrollHeight - innerHeight }));
    if (state.max > 0 && state.y === 0) throw new Error("Page did not scroll");
    return state;
  });

  await check("Every primary page is reachable", async () => {
    const pages = ["events.php", "discounts.php", "info.php", "contact.php"];
    for (const path of pages) {
      const response = await page.goto(`${baseUrl}/${path}`, { waitUntil: "domcontentloaded" });
      if (!response?.ok()) throw new Error(`${path} returned ${response?.status()}`);
      if (!(await page.locator("main").count())) throw new Error(`${path} has no main landmark`);
    }
    return { pages };
  });

  await page.goto(`${baseUrl}/index.php`, { waitUntil: "networkidle" });
  await page.screenshot({ path: "/tmp/bkk-web-mobile-home.png", fullPage: true });
} finally {
  await browser.close();
}

const status = results.some((result) => result.status === "failed") ? "failed" : "passed";
console.log(JSON.stringify({ platform: "web", status, results }, null, 2));
if (status === "failed") process.exitCode = 1;
