import { copyFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

export interface AssetDigest { source: string; target: string; sha256: string }

const deck = resolve(import.meta.dir, '..');
const repo = resolve(deck, '..');
const mapping = [
  ['landing/assets/logo-full.png', 'public/assets/logo-full.png'],
  ['landing/assets/logo-glyph.svg', 'public/assets/logo-glyph.svg'],
  ['landing/assets/value-route.svg', 'public/assets/value-route.svg'],
  ['landing/assets/screenshots/consumer.png', 'public/assets/screenshots/consumer.png'],
  ['landing/assets/screenshots/merchant.png', 'public/assets/screenshots/merchant.png'],
  ['landing/assets/screenshots/partner.png', 'public/assets/screenshots/partner.png'],
  ['landing/assets/fonts/PlusJakartaSans-wght.ttf', 'public/assets/fonts/PlusJakartaSans-wght.ttf'],
  ['landing/assets/fonts/Inter-opsz-wght.ttf', 'public/assets/fonts/Inter-opsz-wght.ttf']
] as const;

async function hashFile(path: string) {
  const hash = new Bun.CryptoHasher('sha256');
  hash.update(await Bun.file(path).arrayBuffer());
  return hash.digest('hex');
}

export async function syncAssets(): Promise<AssetDigest[]> {
  const results: AssetDigest[] = [];
  for (const [sourceRelative, targetRelative] of mapping) {
    const source = resolve(repo, sourceRelative);
    const target = resolve(deck, targetRelative);
    if (!(await Bun.file(source).exists())) throw new Error(`Aset sumber hilang: ${sourceRelative}`);
    await mkdir(dirname(target), { recursive: true });
    await copyFile(source, target);
    const [sourceHash, targetHash] = await Promise.all([hashFile(source), hashFile(target)]);
    if (sourceHash !== targetHash) throw new Error(`Hash aset berbeda: ${targetRelative}`);
    results.push({ source: sourceRelative, target: targetRelative, sha256: targetHash });
  }
  return results;
}

if (import.meta.main) console.table(await syncAssets());
