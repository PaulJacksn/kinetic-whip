const { chromium } = require('/home/hatch/workspace/goals/showcasemy-resume-to-portfolio-product/files/launch-post/node_modules/playwright-core');

const URL = 'http://127.0.0.1:8931/index.html';
const OUT = '/home/hatch/workspace/kinetic-whip/verify/';
const EXE = '/home/hatch/.cache/ms-playwright/chromium-1181/chrome-linux/chrome';
const PROXY = { server: 'http://127.0.0.1:8888', bypass: '127.0.0.1,localhost' };

async function kwState(page) {
  return await page.evaluate(() => window.__KW || null);
}

async function waitForState(page, want, secs) {
  let st = null;
  for (let i = 0; i < secs; i++) {
    await page.waitForTimeout(1000);
    st = await kwState(page);
    if (st && st.state === want) return st;
  }
  return st;
}

(async () => {
  const browser = await chromium.launch({ executablePath: EXE, args: ['--no-sandbox', '--disable-gpu'] });

  // ---------------- desktop 1280x800 ----------------
  const errors = [];
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, proxy: PROXY, ignoreHTTPSErrors: true });
  const page = await ctx.newPage();
  page.on('console', (m) => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  let st = await waitForState(page, 'menu', 90);
  console.log('DESKTOP menu:', JSON.stringify(st));
  await page.waitForTimeout(2000);
  await page.screenshot({ path: OUT + 'v1-menu-desktop.png' });

  // Tap the TAP TO START button (centered panel)
  await page.mouse.click(712, 442);
  st = await waitForState(page, 'playing', 10);
  console.log('DESKTOP after click:', JSON.stringify(st));
  await page.waitForTimeout(2000);
  await page.screenshot({ path: OUT + 'v1-play-early-desktop.png' });

  // Drag in circles around the core (screen center) to spin the whip
  await page.mouse.move(640, 400);
  await page.mouse.down();
  let maxSpin = 0;
  for (let i = 0; i < 48; i++) {
    const a = (i / 48) * Math.PI * 2 * 3; // 3 full turns
    await page.mouse.move(640 + Math.cos(a) * 130, 400 + Math.sin(a) * 130);
    await page.waitForTimeout(120);
    st = await kwState(page);
    if (st && st.spin > maxSpin) maxSpin = st.spin;
    if (i === 24) await page.screenshot({ path: OUT + 'v1-play-mid-desktop.png' });
  }
  await page.mouse.up();
  st = await kwState(page);
  console.log('DESKTOP after spin: maxSpin=' + maxSpin.toFixed(0), JSON.stringify(st));
  await page.waitForTimeout(4000);
  st = await kwState(page);
  console.log('DESKTOP settled:', JSON.stringify(st));
  await page.screenshot({ path: OUT + 'v1-play-late-desktop.png' });
  await ctx.close();
  console.log('DESKTOP errors:', JSON.stringify(errors));

  // ---------------- mobile 390x844 touch ----------------
  const merrors = [];
  const mctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, proxy: PROXY, ignoreHTTPSErrors: true });
  const mpage = await mctx.newPage();
  mpage.on('console', (m) => { if (m.type() === 'error') merrors.push('console: ' + m.text()); });
  mpage.on('pageerror', (e) => merrors.push('pageerror: ' + e.message));
  await mpage.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  st = await waitForState(mpage, 'menu', 90);
  console.log('MOBILE menu:', JSON.stringify(st));
  await mpage.waitForTimeout(2000);
  await mpage.screenshot({ path: OUT + 'v1-menu-mobile.png' });

  await mpage.touchscreen.tap(195, 462);
  st = await waitForState(mpage, 'playing', 10);
  console.log('MOBILE after tap:', JSON.stringify(st));
  await mpage.waitForTimeout(1500);
  await mpage.screenshot({ path: OUT + 'v1-play-early-mobile.png' });

  const cdp = await mctx.newCDPSession(mpage);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 195, y: 420, id: 1 }] });
  let mMaxSpin = 0;
  for (let i = 1; i <= 36; i++) {
    const a = (i / 36) * Math.PI * 2 * 3;
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 195 + Math.cos(a) * 70, y: 420 + Math.sin(a) * 70, id: 1 }] });
    await mpage.waitForTimeout(120);
    st = await kwState(mpage);
    if (st && st.spin > mMaxSpin) mMaxSpin = st.spin;
    if (i === 18) await mpage.screenshot({ path: OUT + 'v1-play-mid-mobile.png' });
  }
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  st = await kwState(mpage);
  console.log('MOBILE after spin: maxSpin=' + mMaxSpin.toFixed(0), JSON.stringify(st));
  await mctx.close();
  console.log('MOBILE errors:', JSON.stringify(merrors));

  await browser.close();
  console.log('PROBE DONE');
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
