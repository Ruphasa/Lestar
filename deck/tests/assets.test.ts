import { describe, expect, test } from 'bun:test';
import { resolve } from 'node:path';

const deck = resolve(import.meta.dir, '..');
const repo = resolve(deck, '..');
const pairs = [
  ['landing/assets/logo-full.png', 'deck/public/assets/logo-full.png'],
  ['landing/assets/logo-glyph.svg', 'deck/public/assets/logo-glyph.svg'],
  ['landing/assets/value-route.svg', 'deck/public/assets/value-route.svg'],
  ['landing/assets/screenshots/consumer.png', 'deck/public/assets/screenshots/consumer.png'],
  ['landing/assets/screenshots/merchant.png', 'deck/public/assets/screenshots/merchant.png'],
  ['landing/assets/screenshots/partner.png', 'deck/public/assets/screenshots/partner.png'],
  ['landing/assets/fonts/PlusJakartaSans-wght.ttf', 'deck/public/assets/fonts/PlusJakartaSans-wght.ttf'],
  ['landing/assets/fonts/Inter-opsz-wght.ttf', 'deck/public/assets/fonts/Inter-opsz-wght.ttf']
] as const;

async function sha256(path: string) {
  const bytes = await Bun.file(path).arrayBuffer();
  const hash = new Bun.CryptoHasher('sha256');
  hash.update(bytes);
  return hash.digest('hex');
}

describe('deck assets', () => {
  for (const [source, target] of pairs) {
    test(`${target} identik dengan landing`, async () => {
      const sourcePath = resolve(repo, source);
      const targetPath = resolve(repo, target);
      expect(await Bun.file(targetPath).exists()).toBe(true);
      expect(await sha256(targetPath)).toBe(await sha256(sourcePath));
    });
  }
});
