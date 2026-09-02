import { beforeAll, describe, expect, test } from 'bun:test';
import { resolve } from 'node:path';

const deck = resolve(import.meta.dir, '..');
let html = '';

beforeAll(async () => {
  const build = Bun.spawn(['bun', 'run', 'build'], { cwd: deck, stdout: 'pipe', stderr: 'pipe' });
  const code = await build.exited;
  if (code !== 0) throw new Error(await new Response(build.stderr).text());
  html = await Bun.file(resolve(deck, 'dist/index.html')).text();
}, 30_000);

describe('static deck document', () => {
  test('merender 12 section dan heading hierarchy', () => {
    expect((html.match(/<section class="slide"/g) ?? []).length).toBe(12);
    expect((html.match(/<h1/g) ?? []).length).toBe(1);
    expect((html.match(/<h2/g) ?? []).length).toBe(11);
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
});
