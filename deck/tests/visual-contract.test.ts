import { expect, test } from 'bun:test';

const css = await Bun.file(new URL('../src/styles/deck.css', import.meta.url)).text();
const markup = await Bun.file(new URL('../src/components/SlideContent.astro', import.meta.url)).text();
const data = await Bun.file(new URL('../src/data/slides.ts', import.meta.url)).text();

test('visual contract Art Nouveau', () => {
  for (const color of ['#EDE5D8','#FFFFFF','#265938','#009966','#00BC7D','#F38222','#C2540E','#0A0A0A','#171717','#737373','#F5F5F5']) {
    expect(css).toContain(color);
  }
  expect(css).toContain('@media (min-width:64rem)');
  expect(css).toContain('prefers-reduced-motion:reduce');
  expect(css).toContain('@font-face');

  const kinds = [...data.matchAll(/kind:\s*'([^']+)'/g)].map((match) => match[1]);
  expect(kinds).toHaveLength(12);
  expect(new Set(kinds).size).toBe(12);

  const componentMarkup = markup.replace(/^---[\s\S]*?---/, '');
  const source = `${css}\n${componentMarkup}`;
  expect(source).not.toMatch(/linear-gradient|border-radius:\s*999|mockup\.png|stroke-dasharray|---/i);
  expect(source.match(/box-shadow\s*:/gi) ?? []).toHaveLength(0);
  expect(markup).not.toMatch(/[\u{1F300}-\u{1FAFF}]/u);
});
