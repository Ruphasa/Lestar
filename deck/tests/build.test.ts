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
}, 60_000);

const slideHtml = (number: number) => {
  const match = html.match(new RegExp(`<section class="slide" id="slide-${number}"[\\s\\S]*?</section>`));
  if (!match) throw new Error(`Slide ${number} tidak ditemukan`);
  return match[0];
};

interface CssRule {
  selector: string;
  declarations: Map<string, string>;
  context: readonly string[];
}

const cssDeclarations = (body: string) => new Map(
  body.split(';').flatMap((declaration) => {
    const separator = declaration.indexOf(':');
    if (separator === -1) return [];
    return [[declaration.slice(0, separator).trim().toLowerCase(), declaration.slice(separator + 1).trim().toLowerCase()]];
  }),
);

const closingBrace = (css: string, openingBrace: number) => {
  let depth = 1;
  for (let index = openingBrace + 1; index < css.length; index += 1) {
    if (css[index] === '{') depth += 1;
    if (css[index] === '}') depth -= 1;
    if (depth === 0) return index;
  }
  throw new Error('CSS memiliki blok tanpa penutup');
};

const cssRules = (css: string, context: readonly string[] = []): CssRule[] => {
  const rules: CssRule[] = [];
  let cursor = 0;
  while (cursor < css.length) {
    const openingBrace = css.indexOf('{', cursor);
    if (openingBrace === -1) break;
    const selector = css.slice(cursor, openingBrace).trim();
    const closing = closingBrace(css, openingBrace);
    const body = css.slice(openingBrace + 1, closing);
    if (selector.startsWith('@')) {
      rules.push(...cssRules(body, [...context, selector]));
    } else {
      rules.push({ selector, declarations: cssDeclarations(body), context });
    }
    cursor = closing + 1;
  }
  return rules;
};

const splitSelectors = (rule: CssRule) => rule.selector.split(',').map((selector) => ({ ...rule, selector: selector.trim() }));
const targetsSlide = (selector: string) => /\.slide(?![-_a-zA-Z0-9])/.test(selector);
const isDeckEnhanced = (selector: string) => /\.deck-enhanced(?![-_a-zA-Z0-9])/.test(selector);
const normalizedValue = (value: string | undefined) => value?.replace(/\s*!important\s*$/, '').replace(/\s+/g, '') ?? '';
const isZero = (value: string | undefined) => /^(?:0(?:\.0+)?|0%)$/.test(normalizedValue(value));

const hidesSlide = (rule: CssRule) => {
  const value = (property: string) => normalizedValue(rule.declarations.get(property));
  const clipped = value('clip').replaceAll(',', '') === 'rect(0000)' || value('clip-path') === 'inset(50%)';
  const collapsedWithOverflow = value('overflow') === 'hidden' && ['height', 'max-height', 'block-size', 'max-block-size'].some((property) => isZero(rule.declarations.get(property)));
  return value('display') === 'none'
    || ['hidden', 'collapse'].includes(value('visibility'))
    || isZero(rule.declarations.get('opacity'))
    || value('content-visibility') === 'hidden'
    || clipped
    || value('transform').includes('scale(0)')
    || value('filter').includes('opacity(0)')
    || collapsedWithOverflow;
};

const hiddenBaselineSlideRules = (css: string) => cssRules(css).flatMap(splitSelectors).filter((rule) =>
  targetsSlide(rule.selector)
  && !isDeckEnhanced(rule.selector)
  && !rule.context.some((context) => /^@media\s+print\b/.test(context))
  && hidesSlide(rule),
);

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
    expect(hiddenBaselineSlideRules(deckCss)).toEqual([]);
    expect(deckCss).toContain('@media screen{.slide__sources{display:none}}');
    expect(printCss).toContain('.slide__sources{display:block}');
  });

  test('menyembunyikan kontrol pada cetak tanpa menyembunyikan slide', () => {
    expect(printCss).toContain('.deck-controls{display:none!important}');
    expect(printCss).toContain('.slide{display:block!important;visibility:visible!important}');
  });

  test('mendeteksi selector majemuk dan at-rule layar yang menyembunyikan slide', () => {
    const fixture = `
      section.slide{display:none}
      .deck.slide{visibility:hidden}
      @supports (display:grid){.slide{opacity:0}}
      @container deck (width > 1px){.slide{content-visibility:hidden}}
      @layer presentation{.slide{transform:scale(0)}}
      .deck-enhanced .slide{display:none}
      .slide__title{display:none}
      @media print{.slide{display:none}}
    `;
    const detectedSelectors = hiddenBaselineSlideRules(fixture).map((rule) => rule.selector);
    expect(detectedSelectors).toEqual([
      'section.slide',
      '.deck.slide',
      '.slide',
      '.slide',
      '.slide',
    ]);
    expect(detectedSelectors).not.toContain('.deck-enhanced .slide');
    expect(detectedSelectors).not.toContain('.slide__title');
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
