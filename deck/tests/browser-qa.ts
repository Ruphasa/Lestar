import { access, mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { chromium, type Page } from 'playwright';

const deck = resolve(fileURLToPath(new URL('..', import.meta.url)));
const qaDirectory = resolve(deck, '.qa');
const url = 'http://127.0.0.1:4327';
const chromePath = process.env.CHROME_PATH ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const chromeDebugUrl = 'http://127.0.0.1:9223';
const requestTimeout = 1_000;
const viewports = [
  { width: 320, height: 568 },
  { width: 375, height: 812 },
  { width: 768, height: 1024 },
  { width: 1024, height: 768 },
  { width: 1280, height: 720 },
  { width: 1440, height: 900 },
] as const;

const fetchWithTimeout = async (input: string, timeoutMs: number) => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(input, { signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
};

const waitForHttp = async (input: string, unavailableMessage: string) => {
  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    try {
      if ((await fetchWithTimeout(input, requestTimeout)).status === 200) return;
    } catch {
      // Endpoint belum siap; lanjut polling hingga batas waktu.
    }
    await Bun.sleep(200);
  }
  throw new Error(unavailableMessage);
};

const waitForPreview = () => waitForHttp(url, 'Preview deck tidak siap dalam 20 detik');
const waitForChrome = () => waitForHttp(`${chromeDebugUrl}/json/version`, 'Chrome tidak siap dalam 20 detik');

type Rect = { left: number; right: number; top: number; bottom: number };

const intersects = (first: Rect, second: Rect) =>
  first.left < second.right && first.right > second.left && first.top < second.bottom && first.bottom > second.top;

const waitForDeck = async (page: Page) => {
  await page.waitForSelector('[data-slide][data-active]');
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(40);
};

let preview: ReturnType<typeof Bun.spawn> | undefined;
let chrome: ReturnType<typeof Bun.spawn> | undefined;
let chromeProfile: string | undefined;
const nodeRunner = process.argv.includes('--node-runner');

const runAssertions = async () => {
  await mkdir(qaDirectory, { recursive: true });
  const browser = await chromium.connectOverCDP(chromeDebugUrl);
  const results: Array<Record<string, unknown>> = [];
  try {
    const page = await browser.newPage({ viewport: viewports[0] });

    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      await page.goto(`${url}/#slide-1`);
      await waitForDeck(page);
      const metrics = await page.evaluate(() => ({
        clientWidth: document.documentElement.clientWidth,
        scrollWidth: document.documentElement.scrollWidth,
        offenders: [...document.querySelectorAll<HTMLElement>('body *')]
          .filter((node) => {
            const rect = node.getBoundingClientRect();
            return rect.left < -0.5 || rect.right > document.documentElement.clientWidth + 0.5;
          })
          .map((node) => `${node.tagName}.${node.className}`).slice(0, 10),
      }));
      if (metrics.scrollWidth > metrics.clientWidth || metrics.offenders.length) {
        throw new Error(`Overflow ${viewport.width}x${viewport.height}: ${JSON.stringify(metrics)}`);
      }

      const controls = await page.locator('.deck-controls button').evaluateAll((buttons) => buttons.map((button) => {
        const rect = button.getBoundingClientRect();
        return { width: rect.width, height: rect.height };
      }));
      if (controls.some(({ width, height }) => width < 44 || height < 44)) throw new Error(`Target kontrol kurang dari 44px pada ${viewport.width}x${viewport.height}`);

      await page.locator('[data-action="next"]').focus();
      const outlineWidth = Number.parseFloat(await page.locator('[data-action="next"]').evaluate((button) => getComputedStyle(button).outlineWidth));
      if (outlineWidth < 3) throw new Error(`Focus ring kurang dari 3px pada ${viewport.width}x${viewport.height}`);

      const overlap = await page.evaluate(() => {
        const controlsRect = document.querySelector('.deck-controls')?.getBoundingClientRect();
        const active = document.querySelector<HTMLElement>('[data-slide][data-active]');
        const copy = active?.querySelectorAll<HTMLElement>('.slide__title,.slide-content__body');
        if (!controlsRect || !copy) return false;
        return [...copy].some((node) => {
          const rect = node.getBoundingClientRect();
          return rect.left < controlsRect.right && rect.right > controlsRect.left && rect.top < controlsRect.bottom && rect.bottom > controlsRect.top;
        });
      });
      if (overlap) throw new Error(`Kontrol menutupi copy pada ${viewport.width}x${viewport.height}`);

      results.push({ viewport: `${viewport.width}x${viewport.height}`, ...metrics, controls });
      if ([320, 375, 1440].includes(viewport.width)) {
        await page.screenshot({ path: resolve(qaDirectory, `viewport-${viewport.width}x${viewport.height}.png`) });
      }
    }

    await page.setViewportSize({ width: 1280, height: 720 });
    for (let number = 1; number <= 12; number += 1) {
      await page.goto(`${url}/#slide-${number}`);
      await waitForDeck(page);
      if (!(await page.locator(`#slide-${number}`).getAttribute('data-active')) && number !== 1) throw new Error(`Slide ${number} tidak aktif sebelum screenshot`);
      await page.screenshot({ path: resolve(qaDirectory, `slide-${String(number).padStart(2, '0')}.png`) });
    }

    await page.goto(`${url}/#slide-1`);
    await waitForDeck(page);
    await page.locator('[data-deck]').dispatchEvent('pointerdown', { clientX: 200, clientY: 300, pointerId: 1, pointerType: 'touch' });
    await page.locator('[data-deck]').dispatchEvent('pointerup', { clientX: 120, clientY: 300, pointerId: 1, pointerType: 'touch' });
    if (!page.url().endsWith('#slide-2')) throw new Error('Swipe 80px tidak maju tepat satu slide');

    await page.goto(`${url}/#slide-7`);
    await waitForDeck(page);
    if (!(await page.locator('#slide-7').evaluate((element) => element.hasAttribute('data-active')))) throw new Error('Deep link #slide-7 tidak dipulihkan');
    await page.goto(`${url}/#slide-1`);
    await waitForDeck(page);
    await page.keyboard.press('ArrowRight');
    if (!page.url().endsWith('#slide-2')) throw new Error('ArrowRight tidak menuju slide 2');
    await page.waitForTimeout(20);
    await page.keyboard.press('End');
    if (!page.url().endsWith('#slide-12')) throw new Error('End tidak menuju slide 12');
    await page.waitForTimeout(20);
    await page.keyboard.press('Home');
    if ((await page.locator('[data-progress]').textContent())?.trim() !== '1 / 12') throw new Error('Progress tidak kembali ke 1 / 12');

    const fullscreen = page.locator('[data-action="fullscreen"]');
    if (await fullscreen.getAttribute('aria-pressed') !== 'false') throw new Error('Kontrol fullscreen harus mulai tidak tertekan');
    if (await fullscreen.getAttribute('aria-label') !== 'Buka layar penuh') throw new Error('Label awal fullscreen tidak sesuai');

    const reduced = await browser.newPage({ viewport: { width: 1280, height: 720 }, reducedMotion: 'reduce' });
    await reduced.goto(`${url}/#slide-1`);
    await waitForDeck(reduced);
    const transitionDuration = await reduced.locator('#slide-1').evaluate((slide) => getComputedStyle(slide).transitionDuration);
    if (Number.parseFloat(transitionDuration) > .01) throw new Error(`Reduced motion masih ${transitionDuration}`);
    await reduced.close();

    const noJavaScript = await browser.newPage({ viewport: { width: 1280, height: 720 }, javaScriptEnabled: false });
    await noJavaScript.goto(url);
    const staticSections = await noJavaScript.locator('section[data-slide]').evaluateAll((sections) => sections.map((section) => Boolean(section.getBoundingClientRect())));
    if (staticSections.length !== 12 || staticSections.some((visible) => !visible)) throw new Error('Fallback tanpa JavaScript tidak merender 12 section');
    await noJavaScript.close();

    await writeFile(resolve(qaDirectory, 'qa-results.json'), `${JSON.stringify(results, null, 2)}\n`);
    await page.close();
  } finally {
    await browser.close();
  }
};

if (nodeRunner) {
  await runAssertions();
} else try {
  await access(chromePath);
  preview = Bun.spawn(['bun', 'run', 'preview', '--', '--host', '127.0.0.1', '--port', '4327'], { cwd: deck, stdout: 'pipe', stderr: 'pipe' });
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
  const assertions = Bun.spawn(['node', '--experimental-strip-types', process.argv[1]!, '--node-runner'], { cwd: deck, stdout: 'inherit', stderr: 'inherit' });
  if ((await assertions.exited) !== 0) throw new Error('Browser QA matriks gagal');
} finally {
  chrome?.kill();
  if (chrome) await chrome.exited;
  preview?.kill();
  if (preview) await preview.exited;
  const stopPreview = Bun.spawn(['bun', 'run', 'preview', 'stop'], { cwd: deck, stdout: 'ignore', stderr: 'ignore' });
  await stopPreview.exited;
  if (chromeProfile) await rm(chromeProfile, { recursive: true, force: true });
}
