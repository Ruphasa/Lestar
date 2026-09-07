import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { PDFDocument } from 'pdf-lib';

const deck = fileURLToPath(new URL('..', import.meta.url));
const commands = [
  ['bun', 'test'],
  ['bun', 'run', 'check'],
  ['bun', 'run', 'build'],
  ['bun', 'run', 'qa']
];

for (const command of commands) {
  const process = (globalThis as any).Bun.spawn(command, { cwd: deck, stdout: 'inherit', stderr: 'inherit' });
  if ((await process.exited) !== 0) throw new Error(`Gagal: ${command.join(' ')}`);
}

// Final assertions
const html = await (globalThis as any).Bun.file(resolve(deck, 'dist/index.html')).text();
if (!html.includes('data-deck')) throw new Error('data-deck tidak ditemukan di dist/index.html');
if (html.includes('mockup.png')) throw new Error('mockup.png ditemukan di dist/index.html');

const requiredCopies = [
  '14,73 juta ton',
  'Rp213–551 triliun',
  '7,29%',
  'Rp960 miliar/tahun',
  'Rp48 miliar/tahun',
  'Rp480 juta/tahun',
  'Rp1.000',
  'forecasts.source',
  'lstm_gemini',
  'lstm_only',
  'heuristic'
];

for (const copy of requiredCopies) {
  if (!html.includes(copy)) throw new Error(`Required copy tidak ditemukan: ${copy}`);
}

const pdfFile = (globalThis as any).Bun.file(resolve(deck, 'Lestar-KMIPN-VIII.pdf'));
const publicPdfFile = (globalThis as any).Bun.file(resolve(deck, 'public/Lestar-KMIPN-VIII.pdf'));
if (!(await pdfFile.exists()) || !(await publicPdfFile.exists())) throw new Error('PDF tidak ditemukan');

const pdfBytes = await pdfFile.arrayBuffer();
const publicPdfBytes = await publicPdfFile.arrayBuffer();
const rootHash = new (globalThis as any).Bun.CryptoHasher('sha256').update(pdfBytes).digest('hex');
const publicHash = new (globalThis as any).Bun.CryptoHasher('sha256').update(publicPdfBytes).digest('hex');
if (rootHash !== publicHash) throw new Error('Hash mismatch antara root dan public PDF');

const document = await PDFDocument.load(pdfBytes);
if (document.getPageCount() !== 12) throw new Error(`PDF memiliki ${document.getPageCount()} halaman, bukan 12`);

console.log('Web deck verification passed.');
