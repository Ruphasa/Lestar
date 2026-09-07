import { resolve } from 'node:path';
import { readFile } from 'node:fs/promises';
import { chromium } from 'playwright';

import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../..', import.meta.url));
const merchantPath = resolve(root, 'landing/assets/screenshots/merchant.png');
const deckMerchantPath = resolve(root, 'deck/public/assets/screenshots/merchant.png');
const logoPath = resolve(root, 'assets/logo.png');

async function fixMerchant() {
  const browser = await chromium.launch({
    headless: true,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe'
  });

  const page = await browser.newPage({
    viewport: { width: 1080, height: 2400 },
    deviceScaleFactor: 1,
  });

  const merchantBase64 = (await readFile(merchantPath)).toString('base64');
  const logoBase64 = (await readFile(logoPath)).toString('base64');

  const html = `<!DOCTYPE html>
<html>
<body style="margin:0; padding:0; background:#000; overflow:hidden;">
  <canvas id="c" width="1080" height="2400"></canvas>
  <script>
    const c = document.getElementById('c');
    const ctx = c.getContext('2d');
    const merchantImg = new Image();
    const logoImg = new Image();

    merchantImg.onload = () => {
      ctx.drawImage(merchantImg, 0, 0);

      // Top bar background sample (x: 30, y: 140)
      const p = ctx.getImageData(30, 140, 1, 1).data;
      const bg = 'rgb(' + p[0] + ',' + p[1] + ',' + p[2] + ')';

      // Clear the white box area (x: 36, y: 100, width: 85, height: 85)
      ctx.fillStyle = bg;
      ctx.fillRect(36, 100, 85, 85);

      logoImg.onload = () => {
        // Draw the transparent logo cleanly
        ctx.drawImage(logoImg, 40, 105, 75, 75);
        window.done = true;
      };
      logoImg.src = "data:image/png;base64,${logoBase64}";
    };
    merchantImg.src = "data:image/png;base64,${merchantBase64}";
  </script>
</body>
</html>`;

  await page.setContent(html);
  await page.waitForFunction(() => (window as any).done === true);
  await page.waitForTimeout(100);

  await page.screenshot({ path: merchantPath, type: 'png' });
  await page.screenshot({ path: deckMerchantPath, type: 'png' });

  await browser.close();
  console.log('Fixed merchant.png logo successfully!');
}

fixMerchant().catch(console.error);
