import { beforeAll, describe, expect, test } from 'bun:test';
import { resolve } from 'node:path';

const deck = resolve(import.meta.dir, '..');
let html = '';
let deckCss = '';
let printCss = '';

beforeAll(async () => {
  const build = Bun.spawn(['bun', 'run', 'build'], { cwd: deck, stdout: 'pipe', stderr: 'pipe' });
  const code = await build.exited;
  if (code !== 0) throw new Error(await new Response(build.stderr).text());
  html = await Bun.file(resolve(deck, 'dist/index.html')).text();
  deckCss = await Bun.file(resolve(deck, 'src/styles/deck.css')).text();
  printCss = await Bun.file(resolve(deck, 'src/styles/print.css')).text();
}, 30_000);

const slideHtml = (number: number) => {
  const match = html.match(new RegExp(`<section class="slide" id="slide-${number}"[\\s\\S]*?</section>`));
  if (!match) throw new Error(`Slide ${number} tidak ditemukan`);
  return match[0];
};

describe('static deck document', () => {
  test('merender 12 section dan heading hierarchy', () => {
    expect((html.match(/<section class="slide"/g) ?? []).length).toBe(12);
    expect((html.match(/<h1(?:\s|>)/g) ?? []).length).toBe(1);
    expect((html.match(/<h2(?:\s|>)/g) ?? []).length).toBe(11);
  });

  test('memiliki kontrol dan live region yang aksesibel', () => {
    expect(html).toContain('aria-label="Slide sebelumnya"');
    expect(html).toContain('aria-label="Slide berikutnya"');
    expect(html).toContain('aria-live="polite"');
  });

  test('tidak memakai mockup atau marker internal', () => {
    expect(html).not.toContain('mockup.png');
    expect(html).not.toMatch(/TODO|TBD|speaker notes|planning/i);
  });

  test('mempertahankan fallback no-JS serta sumber layar/cetak', () => {
    expect((html.match(/<ul class="slide__sources"/g) ?? []).length).toBe(12);
    expect(html).toContain('<main id="deck" data-deck>');
    expect(html).not.toMatch(/<section class="slide"[^>]*(?:\shidden(?:\s|=|>)|\saria-hidden=)/);
    expect(deckCss).toContain('.slide{position:relative;min-height:100svh');
    expect(deckCss).toContain('@media screen{.slide__sources{display:none}}');
    expect(printCss).toContain('.slide__sources{display:block}');
  });

  test('menyembunyikan kontrol pada cetak tanpa menyembunyikan slide', () => {
    expect(printCss).toContain('.deck-controls{display:none!important}');
    expect(printCss).toContain('.slide{display:block!important;visibility:visible!important}');
  });

  test('menempatkan full logo hanya pada slide pembuka dan penutup', () => {
    expect((html.match(/src="\/assets\/logo-full\.png"/g) ?? []).length).toBe(2);
    expect(slideHtml(1)).toContain('src="/assets/logo-full.png"');
    expect(slideHtml(12)).toContain('src="/assets/logo-full.png"');
    for (let number = 2; number < 12; number += 1) {
      expect(slideHtml(number)).not.toContain('src="/assets/logo-full.png"');
    }
  });

  test('merender tiga screenshot slide 8 dengan struktur dan alternatif deskriptif', () => {
    const slide8 = slideHtml(8);
    expect((slide8.match(/<figure>/g) ?? []).length).toBe(3);
    expect((slide8.match(/<img src="\/assets\/screenshots\/[^\"]+" width="1080" height="2400" alt="[^\"]+">/g) ?? []).length).toBe(3);
    expect((slide8.match(/class="slide-content__body"/g) ?? []).length).toBe(3);
  });
});
