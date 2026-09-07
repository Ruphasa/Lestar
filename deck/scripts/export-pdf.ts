import { mkdir, mkdtemp, rm, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { PDFDocument } from 'pdf-lib';

const deck = resolve(fileURLToPath(new URL('..', import.meta.url)));
const url = 'http://127.0.0.1:4328';
const chromePath = process.env.CHROME_PATH ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const chromeDebugUrl = 'http://127.0.0.1:9224';
const pdfPath = resolve(deck, 'Lestar-KMIPN-VIII.pdf');
const publicPdfPath = resolve(deck, 'public/Lestar-KMIPN-VIII.pdf');

const nodeRunner = process.argv.includes('--node-runner');

const fetchWithTimeout = async (input: string, timeoutMs: number) => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(input, { signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
};

const waitForHttp = async (input: string, timeoutMs = 20_000) => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      if ((await fetchWithTimeout(input, 1_000)).status === 200) return;
    } catch {
      // Tunggu hingga siap
    }
    await new Promise((r) => setTimeout(r, 200));
  }
  throw new Error(`Timeout waiting for ${input}`);
};

const exportViaBrowser = async () => {
  const browser = await chromium.connectOverCDP(chromeDebugUrl);
  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.evaluate(() => (window as any).document.fonts.ready);
    await page.waitForTimeout(200);

    await page.pdf({
      path: pdfPath,
      printBackground: true,
      preferCSSPageSize: true,
    });

    const pdfBuffer = await readFile(pdfPath);
    await mkdir(resolve(deck, 'public'), { recursive: true });
    await writeFile(publicPdfPath, pdfBuffer);

    const rootHash = createHash('sha256').update(pdfBuffer).digest('hex');
    const publicBuffer = await readFile(publicPdfPath);
    const publicHash = createHash('sha256').update(publicBuffer).digest('hex');
    if (rootHash !== publicHash) throw new Error('Hash mismatch between root and public PDF');

    const document = await PDFDocument.load(pdfBuffer);
    const count = document.getPageCount();
    if (count !== 12) throw new Error(`PDF memiliki ${count} halaman, diharapkan tepat 12`);
    console.log(`PDF exported successfully: 12 pages, ${(pdfBuffer.byteLength / 1024).toFixed(1)} KB`);
  } finally {
    await browser.close();
  }
};

if (nodeRunner) {
  await exportViaBrowser();
} else {
  let preview: any;
  let chrome: any;
  let chromeProfile: string | undefined;

  try {
    const build = (globalThis as any).Bun.spawn(['bun', 'run', 'build'], { cwd: deck, stdout: 'inherit', stderr: 'inherit' });
    if ((await build.exited) !== 0) throw new Error('Build failed');

    preview = (globalThis as any).Bun.spawn(['bun', 'run', 'preview', '--', '--host', '127.0.0.1', '--port', '4328'], { cwd: deck, stdout: 'pipe', stderr: 'pipe' });
    await waitForHttp(url);

    chromeProfile = await mkdtemp(resolve(tmpdir(), 'lestar-deck-export-'));
    chrome = (globalThis as any).Bun.spawn([
      chromePath,
      '--headless=new',
      '--no-first-run',
      '--remote-debugging-address=127.0.0.1',
      '--remote-debugging-port=9224',
      `--user-data-dir=${chromeProfile}`,
    ], { stdout: 'pipe', stderr: 'pipe' });
    await waitForHttp(`${chromeDebugUrl}/json/version`);

    const runner = (globalThis as any).Bun.spawn(['node', '--experimental-strip-types', process.argv[1]!, '--node-runner'], { cwd: deck, stdout: 'inherit', stderr: 'inherit' });
    if ((await runner.exited) !== 0) throw new Error('PDF export runner gagal');
  } finally {
    chrome?.kill();
    if (chrome) await chrome.exited;
    preview?.kill();
    if (preview) await preview.exited;
    const stopPreview = (globalThis as any).Bun.spawn(['bun', 'run', 'preview', 'stop'], { cwd: deck, stdout: 'ignore', stderr: 'ignore' });
    await stopPreview.exited;
    if (chromeProfile) await rm(chromeProfile, { recursive: true, force: true });
  }
}
