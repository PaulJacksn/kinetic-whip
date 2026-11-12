const { chromium } = require('/home/hatch/workspace/goals/showcasemy-resume-to-portfolio-product/files/launch-post/node_modules/playwright-core');

const URL = 'http://127.0.0.1:8931/index.html';
const OUT = '/home/hatch/workspace/kinetic-whip/verify/';
const EXE = '/home/hatch/.cache/ms-playwright/chromium-1181/chrome-linux/chrome';
const PROXY = { server: 'http://127.0.0.1:8888', bypass: '127.0.0.1,localhost' };

(async () => {
  const browser = await chromium.launch({ executablePath: EXE, args: ['--no-sandbox', '--disable-gpu'] });
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, proxy: PROXY, ignoreHTTPSErrors: true });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  for (let i = 0; i < 60; i++) {
    await page.waitForTimeout(1000);
    const st = await page.evaluate(() => window.__KW || null);
    if (st && st.state === 'menu') break;
  }
  await page.waitForTimeout(2000);
  await page.screenshot({ path: OUT + 'v1-menu-desktop.png' });
  const mctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, proxy: PROXY, ignoreHTTPSErrors: true });
  const mpage = await mctx.newPage();
  mpage.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  mpage.on('pageerror', (e) => errors.push(e.message));
  await mpage.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  for (let i = 0; i < 60; i++) {
    await mpage.waitForTimeout(1000);
    const st = await mpage.evaluate(() => window.__KW || null);
    if (st && st.state === 'menu') break;
  }
  await mpage.waitForTimeout(2000);
  await mpage.screenshot({ path: OUT + 'v1-menu-mobile.png' });
  console.log('errors:', JSON.stringify(errors));
  await browser.close();
  console.log('MENU SHOTS DONE');
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
