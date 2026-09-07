import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { chromium } from 'playwright';

const outPath = resolve('landing/assets/screenshots/consumer.png');
const deckOutPath = resolve('deck/public/assets/screenshots/consumer.png');
const chromePath = process.env.CHROME_PATH ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const chromeDebugUrl = 'http://127.0.0.1:9226';

const nodeRunner = process.argv.includes('--node-runner');

async function renderScreenshot() {
  const browser = await chromium.connectOverCDP(chromeDebugUrl);
  try {
    const page = await browser.newPage({
      viewport: { width: 1080, height: 2400 },
      deviceScaleFactor: 1,
    });

    const html = `<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<style>
  @font-face {
    font-family: 'Plus Jakarta Sans';
    src: url('file://${resolve('landing/assets/fonts/PlusJakartaSans-wght.ttf').replace(/\\/g, '/')}');
  }
  @font-face {
    font-family: 'Inter';
    src: url('file://${resolve('landing/assets/fonts/Inter-opsz-wght.ttf').replace(/\\/g, '/')}');
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    width: 1080px;
    height: 2400px;
    background: linear-gradient(180deg, #EDFAF1 0%, #F8FCF9 40%, #FFFFFF 100%);
    font-family: 'Inter', sans-serif;
    color: #171717;
    position: relative;
    overflow: hidden;
  }

  /* Android Status Bar */
  .status-bar {
    height: 90px;
    padding: 24px 48px 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 32px;
    font-weight: 600;
    color: #265938;
  }
  .status-icons {
    display: flex;
    gap: 16px;
    align-items: center;
  }

  /* Content */
  .content {
    padding: 28px 48px;
  }

  /* Header Greeting */
  .header-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
  }
  .greeting {
    font-size: 34px;
    color: #009966;
    font-weight: 600;
    margin-bottom: 6px;
  }
  .screen-title {
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 60px;
    font-weight: 800;
    color: #265938;
    letter-spacing: -0.03em;
  }
  .location-badge {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 14px 28px;
    background: #FFFFFF;
    border: 2px solid #D5EFE0;
    border-radius: 999px;
    font-size: 28px;
    font-weight: 700;
    color: #265938;
    box-shadow: 0 4px 16px rgba(38,89,56,0.06);
  }

  /* Search Bar */
  .search-box {
    margin-top: 32px;
    display: flex;
    align-items: center;
    gap: 20px;
    padding: 24px 32px;
    background: #FFFFFF;
    border: 2px solid #D1EADE;
    border-radius: 28px;
    font-size: 30px;
    color: #737373;
    box-shadow: 0 6px 20px rgba(38,89,56,0.04);
  }

  /* Radar Map Card */
  .radar-map-card {
    margin-top: 32px;
    height: 520px;
    background: radial-gradient(circle at 50% 50%, #E5F6EC 0%, #D2EFE0 50%, #C0E7D0 100%);
    border: 2px solid #B4E0C7;
    border-radius: 40px;
    position: relative;
    overflow: hidden;
    box-shadow: 0 12px 36px rgba(38,89,56,0.08);
  }
  .radar-ring {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    border-radius: 50%;
    border: 2px dashed rgba(38, 89, 56, 0.25);
    pointer-events: none;
  }
  .ring-1 { width: 180px; height: 180px; }
  .ring-2 { width: 340px; height: 340px; }
  .ring-3 { width: 500px; height: 500px; }
  .center-pin {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 44px;
    height: 44px;
    background: #009966;
    border: 6px solid #FFFFFF;
    border-radius: 50%;
    box-shadow: 0 0 24px rgba(0, 153, 102, 0.6);
  }
  .radar-sweep {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 300px;
    height: 300px;
    transform-origin: 0 0;
    background: conic-gradient(from 0deg, rgba(0, 188, 125, 0.35) 0deg, transparent 60deg);
    border-radius: 50%;
  }

  .map-pin {
    position: absolute;
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 12px 22px;
    border-radius: 999px;
    background: #FFFFFF;
    border: 3px solid #265938;
    box-shadow: 0 8px 24px rgba(0,0,0,0.14);
    font-size: 25px;
    font-weight: 700;
  }
  .pin-badge {
    background: #F38222;
    color: #0A0A0A;
    font-weight: 800;
    padding: 4px 14px;
    border-radius: 999px;
    font-size: 23px;
  }
  .pin-1 { top: 100px; left: 140px; }
  .pin-2 { top: 210px; right: 120px; }
  .pin-3 { bottom: 85px; left: 320px; }

  /* Section Title */
  .section-row {
    margin-top: 40px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .section-heading {
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 40px;
    font-weight: 800;
    color: #265938;
  }
  .see-all {
    font-size: 28px;
    font-weight: 700;
    color: #C2540E;
  }

  /* Grid of Deals */
  .deals-grid {
    margin-top: 24px;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 26px;
  }
  .deal-card {
    background: #FFFFFF;
    border: 2px solid #E2EFE7;
    border-radius: 36px;
    padding: 22px;
    display: flex;
    flex-direction: column;
    box-shadow: 0 8px 24px rgba(38, 89, 56, 0.05);
    position: relative;
  }
  .card-img-placeholder {
    height: 310px;
    border-radius: 24px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
  }
  .card-img-1 { background: linear-gradient(135deg, #FFF0E2 0%, #FFE5CE 100%); }
  .card-img-2 { background: linear-gradient(135deg, #E5F6ED 0%, #D8F2E3 100%); }
  .card-img-3 { background: linear-gradient(135deg, #FFF5E8 0%, #FFE9D4 100%); }
  .card-img-4 { background: linear-gradient(135deg, #E0F4EA 0%, #CEEEDD 100%); }

  .discount-tag {
    position: absolute;
    top: 16px;
    left: 16px;
    background: #F38222;
    color: #0A0A0A;
    font-weight: 800;
    font-size: 24px;
    padding: 6px 16px;
    border-radius: 999px;
  }
  .stock-tag {
    position: absolute;
    bottom: 16px;
    left: 16px;
    background: rgba(10, 10, 10, 0.72);
    color: #FFFFFF;
    font-weight: 600;
    font-size: 21px;
    padding: 6px 16px;
    border-radius: 999px;
    backdrop-filter: blur(8px);
  }

  .deal-info {
    margin-top: 20px;
  }
  .deal-title {
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 32px;
    font-weight: 800;
    color: #171717;
    line-height: 1.25;
  }
  .deal-store {
    margin-top: 8px;
    font-size: 25px;
    color: #737373;
  }
  .price-row {
    margin-top: 14px;
    display: flex;
    align-items: baseline;
    gap: 14px;
  }
  .price-now {
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 36px;
    font-weight: 800;
    color: #265938;
  }
  .price-was {
    font-size: 25px;
    color: #A3A3A3;
    text-decoration: line-through;
  }

  /* Bottom Nav */
  .bottom-nav {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 180px;
    background: #FFFFFF;
    border-top: 2px solid #E2EFE7;
    display: flex;
    justify-content: space-around;
    align-items: center;
    padding: 0 40px 30px;
  }
  .nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    color: #737373;
    font-size: 25px;
    font-weight: 600;
  }
  .nav-item.active {
    color: #265938;
    font-weight: 800;
  }
  .nav-active-pill {
    width: 105px;
    height: 56px;
    background: #D5EFE0;
    border-radius: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .fab-qr {
    width: 96px;
    height: 96px;
    background: #009966;
    border-radius: 34px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #FFFFFF;
    box-shadow: 0 10px 28px rgba(0, 153, 102, 0.4);
    transform: translateY(-22px);
  }
  .home-bar {
    position: absolute;
    bottom: 12px;
    left: 50%;
    transform: translateX(-50%);
    width: 320px;
    height: 8px;
    background: #0A0A0A;
    border-radius: 4px;
  }
</style>
</head>
<body>

<div class="status-bar">
  <span>06:50</span>
  <div class="status-icons">
    <svg width="34" height="34" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3c-4.97 0-9 4.03-9 9 0 2.12.74 4.07 1.97 5.61L4.35 18.23C3.52 16.51 3 14.33 3 12c0-4.97 4.03-9 9-9s9 4.03 9 9c0 2.33-.52 4.51-1.35 6.23l-.62-.62C20.26 16.07 21 14.12 21 12c0-4.97-4.03-9-9-9z"/></svg>
    <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M12 4C7.31 4 3.07 5.9 0 8.98L12 21 24 8.98C20.93 5.9 16.69 4 12 4z"/></svg>
    <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M15.67 4H14V2h-4v2H8.33C7.6 4 7 4.6 7 5.33v15.33C7 21.4 7.6 22 8.33 22h7.33c.74 0 1.34-.6 1.34-1.33V5.33C17 4.6 16.4 4 15.67 4z"/></svg>
  </div>
</div>

<div class="content">
  <div class="header-row">
    <div>
      <p class="greeting">Selamat pagi, Amira</p>
      <h1 class="screen-title">Live Flash Radar</h1>
    </div>
    <div class="location-badge">
      <svg width="26" height="26" viewBox="0 0 24 24" fill="#009966"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>
      <span>Klojen, Malang</span>
    </div>
  </div>

  <div class="search-box">
    <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
    <span>Cari surplus pangan di sekitarmu...</span>
  </div>

  <div class="radar-map-card">
    <div class="radar-ring ring-1"></div>
    <div class="radar-ring ring-2"></div>
    <div class="radar-ring ring-3"></div>
    <div class="radar-sweep"></div>
    <div class="center-pin"></div>

    <div class="map-pin pin-1">
      <span class="pin-badge">-68%</span>
      <span>Verde Bakery · 450m</span>
    </div>

    <div class="map-pin pin-2">
      <span class="pin-badge">-60%</span>
      <span>Bento Express · 650m</span>
    </div>

    <div class="map-pin pin-3">
      <span class="pin-badge">-57%</span>
      <span>Dapur Bu Sri · 1,1km</span>
    </div>
  </div>

  <div class="section-row">
    <h2 class="section-heading">Flash Deals · Segera Berakhir</h2>
    <span class="see-all">Lihat semua &rarr;</span>
  </div>

  <div class="deals-grid">
    <div class="deal-card">
      <div class="card-img-placeholder card-img-1">
        <span class="discount-tag">-68%</span>
        <svg width="110" height="110" viewBox="0 0 24 24" fill="none" stroke="#C2540E" stroke-width="1.8"><path d="M3 13h18M5 13a7 7 0 0 1 14 0M7 13v4a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-4"/></svg>
        <span class="stock-tag">Sisa 2 porsi</span>
      </div>
      <div class="deal-info">
        <h3 class="deal-title">Almond Croissant & Pastry</h3>
        <p class="deal-store">Verde Bakery · 450 m</p>
        <div class="price-row">
          <span class="price-now">Rp12.000</span>
          <span class="price-was">Rp38.000</span>
        </div>
      </div>
    </div>

    <div class="deal-card">
      <div class="card-img-placeholder card-img-2">
        <span class="discount-tag">-60%</span>
        <svg width="110" height="110" viewBox="0 0 24 24" fill="none" stroke="#265938" stroke-width="1.8"><rect x="3" y="4" width="18" height="16" rx="3"/><path d="m3 10 18 0M10 4v16"/></svg>
        <span class="stock-tag">Sisa 4 porsi</span>
      </div>
      <div class="deal-info">
        <h3 class="deal-title">Chicken Katsu Bento Pack</h3>
        <p class="deal-store">Bento Express · 650 m</p>
        <div class="price-row">
          <span class="price-now">Rp18.000</span>
          <span class="price-was">Rp45.000</span>
        </div>
      </div>
    </div>

    <div class="deal-card">
      <div class="card-img-placeholder card-img-3">
        <span class="discount-tag">-57%</span>
        <svg width="110" height="110" viewBox="0 0 24 24" fill="none" stroke="#C2540E" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 0 0 16"/></svg>
        <span class="stock-tag">Sisa 3 porsi</span>
      </div>
      <div class="deal-info">
        <h3 class="deal-title">Fresh Honey Fruit Salad</h3>
        <p class="deal-store">Fresh Garden · 850 m</p>
        <div class="price-row">
          <span class="price-now">Rp15.000</span>
          <span class="price-was">Rp35.000</span>
        </div>
      </div>
    </div>

    <div class="deal-card">
      <div class="card-img-placeholder card-img-4">
        <span class="discount-tag">-60%</span>
        <svg width="110" height="110" viewBox="0 0 24 24" fill="none" stroke="#265938" stroke-width="1.8"><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/></svg>
        <span class="stock-tag">Sisa 1 pack</span>
      </div>
      <div class="deal-info">
        <h3 class="deal-title">Artisan Donut Box (Pack 4)</h3>
        <p class="deal-store">Sweet Glaze · 1,1 km</p>
        <div class="price-row">
          <span class="price-now">Rp20.000</span>
          <span class="price-was">Rp50.000</span>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="bottom-nav">
  <div class="nav-item active">
    <div class="nav-active-pill">
      <svg width="34" height="34" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="3"/><path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8z"/><path d="M12 6a6 6 0 1 0 6 6 6 6 0 0 0-6-6z"/></svg>
    </div>
    <span>Radar</span>
  </div>

  <div class="nav-item">
    <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>
    <span>Feed</span>
  </div>

  <div class="fab-qr">
    <svg width="44" height="44" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h6v6H4zm2 2v2h2V6zm8-2h6v6h-6zm2 2v2h2V6zM4 14h6v6H4zm2 2v2h2v-2zm10 0h2v2h-2zm-2-2h2v2h-2zm4 0h2v2h-2zm-2 4h2v2h-2zm4 0h2v2h-2z"/></svg>
  </div>

  <div class="nav-item">
    <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 10h18M8 14h.01M12 14h.01M16 14h.01"/></svg>
    <span>Pesanan</span>
  </div>

  <div class="nav-item">
    <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="7" r="4"/><path d="M6 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/></svg>
    <span>Profil</span>
  </div>

  <div class="home-bar"></div>
</div>

</body>
</html>`;

    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.evaluate(() => (window as any).document.fonts.ready);
    await page.waitForTimeout(200);
    await page.screenshot({ path: outPath, type: 'png' });
    await page.screenshot({ path: deckOutPath, type: 'png' });
    console.log('Consumer screen generated successfully!');
  } finally {
    await browser.close();
  }
}

if (nodeRunner) {
  await renderScreenshot();
} else {
  let chrome: any;
  let chromeProfile: string | undefined;

  try {
    chromeProfile = await mkdtemp(resolve(tmpdir(), 'lestar-consumer-'));
    chrome = (globalThis as any).Bun.spawn([
      chromePath,
      '--headless=new',
      '--no-first-run',
      '--remote-debugging-address=127.0.0.1',
      '--remote-debugging-port=9226',
      `--user-data-dir=${chromeProfile}`,
    ], { stdout: 'pipe', stderr: 'pipe' });

    // Wait for chrome
    const deadline = Date.now() + 15_000;
    while (Date.now() < deadline) {
      try {
        const r = await fetch(`${chromeDebugUrl}/json/version`);
        if (r.status === 200) break;
      } catch {}
      await new Promise((r) => setTimeout(r, 200));
    }

    const runner = (globalThis as any).Bun.spawn(['node', '--experimental-strip-types', resolve(import.meta.dir, 'generate-consumer.ts'), '--node-runner'], { cwd: resolve(import.meta.dir, '..'), stdout: 'inherit', stderr: 'inherit' });
    if ((await runner.exited) !== 0) throw new Error('Render consumer failed');
  } finally {
    chrome?.kill();
    if (chrome) await chrome.exited;
    if (chromeProfile) await rm(chromeProfile, { recursive: true, force: true });
  }
}
