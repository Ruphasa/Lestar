import { access, mkdtemp, rm } from 'node:fs/promises';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const deck = resolve(fileURLToPath(new URL('..', import.meta.url)));
const url = 'http://127.0.0.1:4327';
const chromePath = process.env.CHROME_PATH ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const chromeDebugUrl = 'http://127.0.0.1:9223';

const waitForPreview = async () => {
  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    try {
      if ((await fetch(url)).status === 200) return;
    } catch {
      // Preview belum siap; lanjut polling hingga batas waktu.
    }
    await Bun.sleep(200);
  }
  throw new Error('Preview deck tidak siap dalam 20 detik');
};

const waitForChrome = async () => {
  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    try {
      if ((await fetch(`${chromeDebugUrl}/json/version`)).status === 200) return;
    } catch {
      // Chrome belum siap; lanjut polling hingga batas waktu.
    }
    await Bun.sleep(200);
  }
  throw new Error('Chrome tidak siap dalam 20 detik');
};

let preview: ReturnType<typeof Bun.spawn> | undefined;
let chrome: ReturnType<typeof Bun.spawn> | undefined;
let chromeProfile: string | undefined;
const nodeRunner = process.argv.includes('--node-runner');

const runAssertions = async () => {
  const browser = await chromium.connectOverCDP(chromeDebugUrl);
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    await page.goto(`${url}/#slide-7`);
    if (!(await page.locator('#slide-7').evaluate((element) => element.hasAttribute('data-active')))) throw new Error('Deep link #slide-7 tidak dipulihkan');
    await page.goto(`${url}/#slide-1`);
    await page.keyboard.press('ArrowRight');
    if (!page.url().endsWith('#slide-2')) throw new Error('ArrowRight tidak menuju slide 2');
    await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => resolve())));
    await page.keyboard.press('End');
    if (!page.url().endsWith('#slide-12')) throw new Error('End tidak menuju slide 12');
    await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => resolve())));
    await page.keyboard.press('Home');
    if ((await page.locator('[data-progress]').textContent())?.trim() !== '1 / 12') throw new Error('Progress tidak kembali ke 1 / 12');
    await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => resolve())));
    await page.locator('[data-action="next"]').focus();
    await page.keyboard.press('Space');
    if (!page.url().endsWith('#slide-2')) throw new Error('Space pada tombol Next harus maju tepat satu slide');
  } finally {
    await browser.close();
  }
};

if (nodeRunner) {
  await runAssertions();
} else try {
  await access(chromePath);
  preview = Bun.spawn(['bun', 'run', 'preview', '--', '--host', '127.0.0.1', '--port', '4327'], {
    cwd: deck,
    stdout: 'pipe',
    stderr: 'pipe',
  });
  await waitForPreview();

  chromeProfile = await mkdtemp(resolve(tmpdir(), 'lestar-deck-qa-'));
  chrome = Bun.spawn([
    chromePath,
    '--headless=new',
    '--no-first-run',
    '--remote-debugging-address=127.0.0.1',
    '--remote-debugging-port=9223',
    `--user-data-dir=${chromeProfile}`,
  ], { stdout: 'pipe', stderr: 'pipe' });
  await waitForChrome();
  const assertions = Bun.spawn(['node', '--experimental-strip-types', process.argv[1]!, '--node-runner'], {
    cwd: deck,
    stdout: 'inherit',
    stderr: 'inherit',
  });
  if ((await assertions.exited) !== 0) throw new Error('Browser smoke QA gagal');
} finally {
  chrome?.kill();
  if (chrome) await chrome.exited;
  preview?.kill();
  if (preview) await preview.exited;
  const stopPreview = Bun.spawn(['bun', 'run', 'preview', 'stop'], { cwd: deck, stdout: 'ignore', stderr: 'ignore' });
  await stopPreview.exited;
  if (chromeProfile) await rm(chromeProfile, { recursive: true, force: true });
}
