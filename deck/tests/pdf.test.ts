import { expect, test } from 'bun:test';
import { PDFDocument } from 'pdf-lib';

test('PDF final memiliki 12 halaman dan ukuran masuk akal', async () => {
  const file = Bun.file(new URL('../Lestar-KMIPN-VIII.pdf', import.meta.url));
  const publicFile = Bun.file(new URL('../public/Lestar-KMIPN-VIII.pdf', import.meta.url));
  expect(await file.exists()).toBe(true);
  expect(await publicFile.exists()).toBe(true);
  expect(file.size).toBeGreaterThan(500_000);
  const document = await PDFDocument.load(await file.arrayBuffer());
  expect(document.getPageCount()).toBe(12);
  const rootHash = new Bun.CryptoHasher('sha256').update(await file.arrayBuffer()).digest('hex');
  const publicHash = new Bun.CryptoHasher('sha256').update(await publicFile.arrayBuffer()).digest('hex');
  expect(publicHash).toBe(rootHash);
});
