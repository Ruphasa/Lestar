# Agent G Astro Web Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun web deck Lestar 12 slide dengan Astro+Bun, visual Botanical Art Nouveau yang tenang, ekspor PDF 12 halaman, preview Vercel, dan tanpa membuat PPTX atau mengubah landing yang sudah selesai.

**Architecture:** `deck/` adalah project Astro statis mandiri. `src/data/slides.ts` menjadi satu-satunya sumber narasi; komponen Astro merender seluruh slide sebagai HTML berurutan, lalu controller TypeScript menambahkan mode presentasi sebagai progressive enhancement. Bun menjalankan instalasi, test, build, browser QA, dan ekspor PDF melalui Playwright.

**Tech Stack:** Bun 1.3.14+, Astro 7.2.10, TypeScript 6.0.3, Playwright 1.58.2, PDF-Lib 1.17.1, CSS native, Vercel static deployment.

## Global Constraints

- Spec sumber: `docs/superpowers/specs/2026-09-02-agent-g-astro-web-deck-design.md`.
- Plan ini menggantikan `docs/superpowers/plans/2026-09-02-agent-g-deck.md`; jangan melanjutkan builder PPTX lama.
- Landing statis, deployment landing, dan APK tidak boleh diubah.
- Perubahan hanya pada `deck/`, plan/spec Agent G, dan bagian deck di `docs/06-agent-briefs/G-HANDOFF.md`.
- Jangan menyentuh `lib/`, `api/`, `ml/`, atau `supabase/`.
- Output wajib: web deck statis 12 slide dan `deck/Lestar-KMIPN-VIII.pdf` 12 halaman; PPTX tidak dibuat.
- Bun wajib tersedia; jangan mengganti package manager ke npm/pnpm/yarn.
- Tidak memakai React, Tailwind, SSR, database, API baru, emoji, library ikon, gradient blob, glassmorphism, badge/pill dekoratif, generic card grid, accent stripe, divider `---`, atau phone mockup.
- Visual wajib Botanical Art Nouveau kontemporer dengan 60–70% negative space; maksimal satu sulur utama dan dua aksen botani kecil per slide.
- Palet wajib: `#EDE5D8`, `#FFFFFF`, `#265938`, `#009966`, `#00BC7D`, `#F38222`, `#C2540E`, `#0A0A0A`, `#171717`, `#737373`, `#F5F5F5`.
- Isian oranye selalu memakai teks `#0A0A0A`; `#00BC7D` tidak menjadi latar teks.
- Plus Jakarta Sans untuk display dan Inter untuk body, keduanya lokal.
- Ukuran minimum pada mode presentasi: judul utama 64 px, judul slide 44 px, subjudul 26 px, body 18 px, sumber 13 px.
- Slide 8 memakai `consumer.png`, `merchant.png`, dan `partner.png` yang hash-nya identik dengan landing; `mockup.png` dilarang.
- Angka wajib: `14,73 juta ton`, `Rp213–551 triliun`, `7,29%`, TAM `Rp960 miliar/tahun`, SAM `Rp48 miliar/tahun`, SOM `Rp480 juta/tahun`, green fee `Rp1.000`.
- Slide 7 wajib memuat `forecasts.source`, `lstm_gemini`, `lstm_only`, dan `heuristic`.
- Semua visible copy harus audience-facing; source/provenance tidak tampil sebagai catatan proses.
- Tanpa JavaScript, semua slide tetap terbaca vertikal. Dengan JavaScript, keyboard, tombol, swipe, hash, live region, dan fullscreen menjadi aktif.
- Motion 180–240 ms; sequence sulur/kaskade selesai maksimal 400 ms; reduced motion menampilkan state akhir tanpa transisi.
- Viewport QA: 320×568, 375×812, 768×1024, 1024×768, 1280×720, dan 1440×900.
- Tidak ada horizontal overflow, kontrol menutupi konten, ornament melintasi isi, atau target sentuh di bawah 44×44 px.
- Pesan commit wajib Bahasa Indonesia.

---

## Struktur Berkas

```text
deck/
  .gitignore                         node_modules, dist, .qa, .vercel
  astro.config.mjs                   build statis Astro
  package.json                       script Bun dan versi dependency terkunci
  bun.lock                           lockfile Bun
  tsconfig.json                      strict TypeScript + Bun types
  public/assets/                     salinan aset landing yang hash-nya terkunci
  scripts/sync-assets.ts             satu pintu salin dan verifikasi aset
  scripts/export-pdf.ts              build, serve, dan ekspor PDF 12 halaman
  src/components/DeckShell.astro     landmark, live region, dan wrapper deck
  src/components/DeckControls.astro  previous/next/fullscreen/progress
  src/components/SlideFrame.astro    kontrak section, judul, sumber, nomor
  src/components/SlideContent.astro  markup semantik per kind slide
  src/components/VineOrnament.astro  satu SVG botani reusable
  src/data/slides.ts                 sumber narasi tunggal 12 slide
  src/pages/index.astro              dokumen Astro dan asset metadata
  src/scripts/deck-controller.ts     state activeIndex dan semua input
  src/styles/deck.css                layout layar dan visual system
  src/styles/print.css               satu slide per halaman PDF
  tests/assets.test.ts               hash dan dimensi aset
  tests/slides.test.ts               kontrak/copy/sumber 12 slide
  tests/controller.test.ts           fungsi state/key/swipe murni
  tests/build.test.ts                HTML hasil build dan no-JS contract
  tests/browser-qa.ts                viewport, keyboard, hash, motion, screenshots
  tests/pdf.test.ts                  halaman/ukuran PDF
  tests/verify.ts                    orchestrator final
  Lestar-KMIPN-VIII.pdf              deliverable arsip final
```

---

### Task 1: Scaffold Astro+Bun dan Asset Gate

**Files:**
- Delete: `deck/tests/verify.ps1` (sisa untracked plan PPTX lama)
- Delete: `deck/.tmp/source-notes.txt` (sisa untracked plan PPTX lama)
- Create: `deck/.gitignore`
- Create: `deck/package.json`
- Create: `deck/astro.config.mjs`
- Create: `deck/tsconfig.json`
- Create: `deck/scripts/sync-assets.ts`
- Create: `deck/tests/assets.test.ts`
- Create: `deck/public/assets/**`
- Create: `deck/bun.lock`

**Interfaces:**
- Consumes: `landing/assets/logo-full.png`, `logo-glyph.svg`, `value-route.svg`, tiga screenshot asli, dan dua font lokal.
- Produces: `syncAssets(): Promise<AssetDigest[]>`, project Bun terkunci, serta asset tree yang dipakai semua task berikutnya.

- [ ] **Step 1: Verifikasi dan hapus hanya sisa untracked plan PPTX**

Run:

```powershell
git ls-files --error-unmatch deck/tests/verify.ps1
git ls-files --error-unmatch deck/.tmp/source-notes.txt
```

Expected: kedua command exit non-zero, membuktikan berkas tidak pernah menjadi milik pengguna yang tracked. Hapus kedua file melalui `apply_patch`; hapus direktori kosong `deck/.tmp`, `deck/assets`, dan `deck/tests` hanya setelah `Get-ChildItem -Recurse` membuktikan tidak ada isi lain.

- [ ] **Step 2: Tulis manifest dan konfigurasi project**

`deck/package.json`:

```json
{
  "name": "lestar-web-deck",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "astro dev",
    "check": "astro check",
    "test": "bun test",
    "build": "astro check && astro build",
    "preview": "astro preview",
    "sync:assets": "bun scripts/sync-assets.ts",
    "qa": "bun tests/browser-qa.ts",
    "export:pdf": "bun scripts/export-pdf.ts",
    "verify": "bun tests/verify.ts"
  },
  "dependencies": {
    "astro": "7.2.10"
  },
  "devDependencies": {
    "@astrojs/check": "0.9.10",
    "@types/bun": "1.3.14",
    "pdf-lib": "1.17.1",
    "playwright": "1.58.2",
    "typescript": "6.0.3"
  }
}
```

`deck/astro.config.mjs`:

```js
import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  build: { format: 'file' },
  vite: { build: { cssMinify: 'lightningcss' } }
});
```

`deck/tsconfig.json`:

```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "types": ["bun"],
    "noUncheckedIndexedAccess": true
  },
  "include": [".astro/types.d.ts", "**/*"],
  "exclude": ["dist"]
}
```

`deck/.gitignore`:

```gitignore
node_modules/
dist/
.astro/
.qa/
.vercel/
```

- [ ] **Step 3: Instal dependency melalui Bun dan kunci lockfile**

Run: `bun install --cwd deck`

Expected: `deck/bun.lock` terbentuk; `bun --cwd deck run check` mencapai Astro tanpa error dependency. Jangan menjalankan npm/pnpm/yarn.

- [ ] **Step 4: Tulis asset test yang gagal sebelum sinkronisasi**

`deck/tests/assets.test.ts`:

```ts
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
```

- [ ] **Step 5: Jalankan test dan pastikan RED pada aset pertama**

Run: `bun --cwd deck test tests/assets.test.ts`

Expected: FAIL karena `deck/public/assets/logo-full.png` belum tersedia.

- [ ] **Step 6: Implementasikan satu pintu sinkronisasi aset**

`deck/scripts/sync-assets.ts`:

```ts
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
```

- [ ] **Step 7: Sinkronkan aset dan pastikan GREEN**

Run:

```powershell
bun --cwd deck run sync:assets
bun --cwd deck test tests/assets.test.ts
git diff --check
```

Expected: delapan test PASS dan tidak ada whitespace error.

- [ ] **Step 8: Commit scaffold dan asset gate**

```powershell
git add deck/.gitignore deck/package.json deck/bun.lock deck/astro.config.mjs deck/tsconfig.json deck/scripts/sync-assets.ts deck/tests/assets.test.ts deck/public/assets
git commit -m "feat: siapkan fondasi Astro dan aset web deck"
```

---

### Task 2: Kontrak Narasi dan Sumber 12 Slide

**Files:**
- Create: `deck/src/data/slides.ts`
- Create: `deck/tests/slides.test.ts`

**Interfaces:**
- Consumes: proposal, PRD, arsitektur, design system, demo script, dan aset Task 1.
- Produces: `slides: readonly SlideSpec[]`, satu-satunya sumber visible copy dan provenance bagi seluruh komponen.

- [ ] **Step 1: Tulis failing test untuk kontrak slide**

`deck/tests/slides.test.ts`:

```ts
import { describe, expect, test } from 'bun:test';
import { slides } from '../src/data/slides';

describe('slide narrative', () => {
  test('tepat 12 slide bernomor urut', () => {
    expect(slides).toHaveLength(12);
    expect(slides.map((slide) => slide.number)).toEqual([1,2,3,4,5,6,7,8,9,10,11,12]);
  });

  test('setiap slide punya sumber lokal yang eksplisit', () => {
    for (const slide of slides) {
      expect(slide.sources.length).toBeGreaterThan(0);
      expect(slide.sources.every((source) => source.path.length > 0 && source.detail.length > 0)).toBe(true);
    }
  });

  test('angka proposal dan fallback chain tidak berubah', () => {
    const copy = JSON.stringify(slides);
    for (const required of ['14,73 juta ton','Rp213–551 triliun','7,29%','Rp960 miliar/tahun','Rp48 miliar/tahun','Rp480 juta/tahun','Rp1.000','forecasts.source','lstm_gemini','lstm_only','heuristic']) {
      expect(copy).toContain(required);
    }
  });

  test('slide 8 memakai tiga screenshot asli', () => {
    const slide = slides[7];
    expect(slide.kind).toBe('three-ui');
    expect(slide.images).toEqual([
      '/assets/screenshots/consumer.png',
      '/assets/screenshots/merchant.png',
      '/assets/screenshots/partner.png'
    ]);
    expect(JSON.stringify(slide)).not.toContain('mockup.png');
  });
});
```

- [ ] **Step 2: Jalankan test dan pastikan RED**

Run: `bun --cwd deck test tests/slides.test.ts`

Expected: FAIL karena `src/data/slides.ts` belum ada.

- [ ] **Step 3: Implementasikan type dan seluruh visible copy**

`deck/src/data/slides.ts`:

```ts
export type SlideKind = 'title' | 'problem' | 'gap' | 'cascade' | 'demo' | 'architecture' | 'fallback' | 'three-ui' | 'business' | 'market' | 'roadmap' | 'closing';

export interface SlideSource { path: string; detail: string }
export interface SlideItem { value?: string; label: string; detail?: string }
export interface SlideSpec {
  number: number;
  kind: SlideKind;
  title: string;
  kicker?: string;
  body: readonly string[];
  items?: readonly SlideItem[];
  images?: readonly string[];
  sources: readonly SlideSource[];
}

export const slides = [
  { number: 1, kind: 'title', title: 'Setiap kilogram punya jalur nilai', kicker: 'Lestar', body: ['Tim Lestar · 2 September 2026'], sources: [{ path: 'assets/logo.png', detail: 'Logo Lestar' }] },
  { number: 2, kind: 'problem', title: 'Food waste Indonesia adalah kerugian ekonomi berskala nasional', body: [], items: [
    { value: '14,73 juta ton', label: 'sampah makanan per tahun' },
    { value: 'Rp213–551 triliun', label: 'kerugian ekonomi per tahun' },
    { value: '7,29%', label: 'kontribusi emisi gas rumah kaca' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Bab I §1.1' }] },
  { number: 3, kind: 'gap', title: 'Solusi yang ada berhenti sebelum seluruh nilai dipulihkan', body: [], items: [
    { label: 'Flash sale', detail: 'hanya B2C' },
    { label: 'Donasi', detail: 'bergantung relawan' },
    { label: 'Limbah', detail: 'pickup manual dan informal' },
    { label: 'Pricing', detail: 'subjektif' },
    { label: 'ESG', detail: 'manual atau tidak ada' },
    { label: 'Forecasting', detail: 'tidak tersedia' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Tabel 2.1.1' }] },
  { number: 4, kind: 'cascade', title: 'Lestar mencegah kerugian lalu memulihkan sisa nilainya', body: ['Prediksi permintaan','Surplus','Triage AI','Validasi fisik','Flash Sale B2C','Limbah Organik B2B','Laporan ESG'], sources: [
    { path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: '§2.3.1' },
    { path: 'docs/00-PRD.md', detail: '§4' }
  ] },
  { number: 5, kind: 'demo', title: 'Sekarang lihat alurnya bekerja', body: ['DEMO', 'Pindah ke aplikasi Lestar di HP.'], sources: [{ path: 'docs/05-demo-script.md', detail: '§5' }] },
  { number: 6, kind: 'architecture', title: 'Empat komponen menjaga jalur data tetap sederhana', body: [], items: [
    { label: 'Flutter APK', detail: 'tiga antarmuka aktor' },
    { label: 'Supabase', detail: 'data, auth, dan realtime' },
    { label: 'FastAPI @ Railway', detail: 'forecast dan triage' },
    { label: 'Landing @ Vercel', detail: 'unduh APK dan cerita produk' }
  ], sources: [{ path: 'docs/01-architecture.md', detail: '§1' }] },
  { number: 7, kind: 'fallback', title: 'Sistem selalu mengaku dari mana angkanya berasal', body: ['forecasts.source mencatat asal setiap angka'], items: [
    { label: 'LSTM + Gemini', detail: 'lstm_gemini' },
    { label: 'LSTM saja', detail: 'lstm_only' },
    { label: 'Heuristik lokal', detail: 'heuristic' }
  ], sources: [
    { path: 'docs/01-architecture.md', detail: '§6' },
    { path: 'docs/05-demo-script.md', detail: '§6' }
  ] },
  { number: 8, kind: 'three-ui', title: 'Tiga dunia kerja membutuhkan tiga antarmuka berbeda', body: [
    'Konsumen mendapat pengalaman ringan dan menyenangkan.',
    'Merchant mendapat kokpit data.',
    'Pengepul mendapat antarmuka yang terbaca di bawah terik matahari dengan satu tangan.'
  ], images: ['/assets/screenshots/consumer.png','/assets/screenshots/merchant.png','/assets/screenshots/partner.png'], sources: [
    { path: 'docs/03-design-system.md', detail: '§1.1' },
    { path: 'landing/assets/screenshots/consumer.png', detail: 'capture aplikasi asli' },
    { path: 'landing/assets/screenshots/merchant.png', detail: 'capture aplikasi asli' },
    { path: 'landing/assets/screenshots/partner.png', detail: 'capture aplikasi asli' }
  ] },
  { number: 9, kind: 'business', title: 'Tiga arus pendapatan membiayai ekosistem', body: [], items: [
    { label: 'Komisi transaksi B2C' },
    { label: 'Langganan mitra B2B' },
    { value: 'Rp1.000', label: 'green fee per transaksi' }
  ], sources: [
    { path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Tabel 2.2.1' },
    { path: 'docs/00-PRD.md', detail: '§6.3' }
  ] },
  { number: 10, kind: 'market', title: 'Pasar awal cukup fokus untuk dimenangkan dan cukup besar untuk tumbuh', body: ['Panjang garis memakai skala log agar tiga besaran tetap terbaca.'], items: [
    { value: 'Rp960 miliar/tahun', label: 'TAM' },
    { value: 'Rp48 miliar/tahun', label: 'SAM' },
    { value: 'Rp480 juta/tahun', label: 'SOM' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: '§2.6' }] },
  { number: 11, kind: 'roadmap', title: 'Dua belas bulan membawa Lestar dari fondasi ke scaling', body: [], items: [
    { label: 'Fase 0 · Bulan 1–2', detail: 'Fondasi' },
    { label: 'Fase 1 · Bulan 3–4', detail: 'MVP + Data Foundation' },
    { label: 'Fase 2 · Bulan 5–6', detail: 'AI Integration' },
    { label: 'Fase 3 · Bulan 7–9', detail: 'Pilot Launch' },
    { label: 'Fase 4 · Bulan 10–12', detail: 'Scaling' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Tabel 2.7.1' }] },
  { number: 12, kind: 'closing', title: 'Dimulai dari Malang, dikembangkan menuju skala nasional.', kicker: 'Lestar', body: ['Setiap kilogram punya jalur nilai'], sources: [
    { path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: '§2.7.2' },
    { path: 'assets/logo.png', detail: 'Logo Lestar' }
  ] }
] as const satisfies readonly SlideSpec[];
```

- [ ] **Step 4: Jalankan test dan pastikan GREEN**

Run: `bun --cwd deck test tests/slides.test.ts`

Expected: empat test PASS.

- [ ] **Step 5: Commit narasi**

```powershell
git add deck/src/data/slides.ts deck/tests/slides.test.ts
git commit -m "docs: kunci narasi web deck Lestar"
```

---

### Task 3: HTML Semantik dan Fallback Tanpa JavaScript

**Files:**
- Create: `deck/src/components/DeckShell.astro`
- Create: `deck/src/components/DeckControls.astro`
- Create: `deck/src/components/SlideFrame.astro`
- Create: `deck/src/components/SlideContent.astro`
- Create: `deck/src/components/VineOrnament.astro`
- Create: `deck/src/pages/index.astro`
- Create: `deck/src/styles/deck.css`
- Create: `deck/src/styles/print.css`
- Create: `deck/tests/build.test.ts`

**Interfaces:**
- Consumes: `slides` dari Task 2 dan asset URL Task 1.
- Produces: 12 `<section class="slide">` berurutan, satu `h1`, sebelas `h2`, controls semantik, dan HTML yang seluruh isinya terlihat tanpa JS.

- [ ] **Step 1: Tulis build test yang gagal sebelum halaman ada**

`deck/tests/build.test.ts`:

```ts
import { beforeAll, describe, expect, test } from 'bun:test';
import { resolve } from 'node:path';

const deck = resolve(import.meta.dir, '..');
let html = '';

beforeAll(async () => {
  const build = Bun.spawn(['bun', 'run', 'build'], { cwd: deck, stdout: 'pipe', stderr: 'pipe' });
  const code = await build.exited;
  if (code !== 0) throw new Error(await new Response(build.stderr).text());
  html = await Bun.file(resolve(deck, 'dist/index.html')).text();
});

describe('static deck document', () => {
  test('merender 12 section dan heading hierarchy', () => {
    expect((html.match(/class="slide/g) ?? []).length).toBe(12);
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
```

- [ ] **Step 2: Jalankan test dan pastikan RED**

Run: `bun --cwd deck test tests/build.test.ts`

Expected: FAIL karena `src/pages/index.astro` belum ada.

- [ ] **Step 3: Implementasikan frame, shell, dan controls**

`SlideFrame.astro` harus menerima `{ slide, isTitle?: boolean }`, merender `section#slide-N[data-kind]`, heading dengan id `slide-N-title`, slot konten, daftar sumber tersembunyi dari mode layar tetapi tercetak pada footer PDF, dan nomor `N / 12`.

```astro
---
import type { SlideSpec } from '../data/slides';
interface Props { slide: SlideSpec; isTitle?: boolean }
const { slide, isTitle = false } = Astro.props;
const Heading = isTitle ? 'h1' : 'h2';
---
<section class="slide" id={`slide-${slide.number}`} data-slide={slide.number} data-kind={slide.kind} aria-labelledby={`slide-${slide.number}-title`}>
  <div class="slide__inner">
    {slide.kicker && <p class="slide__kicker">{slide.kicker}</p>}
    <Heading id={`slide-${slide.number}-title`} class="slide__title">{slide.title}</Heading>
    <slot />
  </div>
  <footer class="slide__footer">
    <span aria-hidden="true">{slide.number} / 12</span>
    <ul class="slide__sources" aria-label="Sumber slide">
      {slide.sources.map((source) => <li>{source.path} · {source.detail}</li>)}
    </ul>
  </footer>
</section>
```

`DeckControls.astro`:

```astro
<nav class="deck-controls" aria-label="Kontrol presentasi">
  <button type="button" data-action="previous" aria-label="Slide sebelumnya"><span aria-hidden="true">←</span><span>Sebelumnya</span></button>
  <output data-progress aria-live="off">1 / 12</output>
  <button type="button" data-action="fullscreen" aria-label="Buka layar penuh"><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M8 3H3v5M16 3h5v5M8 21H3v-5M16 21h5v-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg><span>Layar penuh</span></button>
  <button type="button" data-action="next" aria-label="Slide berikutnya"><span>Berikutnya</span><span aria-hidden="true">→</span></button>
</nav>
```

`DeckShell.astro` merender skip link, `<main id="deck" data-deck>`, slot, controls, dan `<p class="sr-only" data-announcer aria-live="polite"></p>`. Jangan menambahkan kelas enhancement pada server render.

- [ ] **Step 4: Implementasikan SVG sulur dan markup setiap kind**

`VineOrnament.astro` memakai satu SVG dengan `viewBox="0 0 1200 420"`, satu path sulur forest, maksimal dua daun, satu buah orange, `aria-hidden="true"`, tanpa `<text>`, filter, gradient, atau dash dekoratif.

`SlideContent.astro` memakai switch `slide.kind` dan kontrak berikut:

- `title`/`closing`: logo + body satu baris + sulur;
- `problem`: `<dl>` tiga fakta;
- `gap`: `<ol>` enam baris solusi/celah;
- `cascade`: `<ol>` tujuh node; Validasi Fisik memakai class `is-gate`; tiga output memiliki label teks berbeda;
- `demo`: kata `DEMO` dan instruksi HP;
- `architecture`: `<ol>` empat komponen dengan connector SVG di belakang;
- `fallback`: `<ol>` tiga level dan `<code>forecasts.source</code>`;
- `three-ui`: `<figure>` tiga screenshot dengan width `1080`, height `2400`, alt deskriptif, dan tiga kalimat body;
- `business`: `<ol>` tiga aliran;
- `market`: `<dl>` TAM/SAM/SOM dan catatan skala;
- `roadmap`: `<ol>` lima fase;
- tidak ada fallback/default yang menampilkan placeholder; kind yang tidak dikenal melempar error pada frontmatter.

- [ ] **Step 5: Implementasikan halaman dan baseline CSS no-JS**

`index.astro` mengimpor `slides`, `DeckShell`, `SlideFrame`, `SlideContent`, `deck.css`, dan `print.css`, lalu memetakan 12 slide. Head wajib berisi title, description, viewport, theme-color, favicon, dan preload dua font lokal.

Baseline `deck.css`:

```css
@font-face{font-family:"Plus Jakarta Sans";src:url('/assets/fonts/PlusJakartaSans-wght.ttf') format('truetype');font-weight:200 800;font-display:swap}
@font-face{font-family:Inter;src:url('/assets/fonts/Inter-opsz-wght.ttf') format('truetype');font-weight:100 900;font-display:swap}
:root{--paper:#EDE5D8;--white:#FFFFFF;--forest:#265938;--emerald-deep:#009966;--emerald:#00BC7D;--orange:#F38222;--orange-text:#C2540E;--ink:#0A0A0A;--ink-soft:#171717;--muted:#737373;--surface:#F5F5F5;--duration:220ms;--ease:cubic-bezier(.2,.8,.2,1)}
*{box-sizing:border-box}
html{background:var(--paper);color:var(--ink);font-family:Inter,system-ui,sans-serif}
body{margin:0}
button{font:inherit}
.slide{position:relative;min-height:100svh;padding:clamp(2rem,6vw,5rem);background:var(--white)}
.slide__inner{width:min(100%,80rem);margin:auto}
.slide__title{max-width:18ch;margin:0;color:var(--forest);font:750 clamp(2.4rem,5vw,4rem)/1.04 "Plus Jakarta Sans",system-ui,sans-serif}
.slide__footer{display:flex;justify-content:space-between;gap:1rem;margin-top:2rem;color:var(--muted);font-size:.8125rem}
.slide__sources{margin:0;padding:0;list-style:none;text-align:right}
.deck-controls{position:sticky;z-index:10;bottom:.75rem;display:flex;justify-content:center;gap:.5rem;width:max-content;max-width:calc(100% - 1.5rem);margin:0 auto .75rem;padding:.25rem;background:var(--white);border:1px solid var(--forest)}
.deck-controls button{min-width:44px;min-height:44px;border:0;background:transparent;color:var(--forest)}
:focus-visible{outline:3px solid var(--orange);outline-offset:3px}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}
```

`print.css` pada task ini hanya boleh memastikan controls hidden dan seluruh slide visible; kontrak page 16:9 diselesaikan pada Task 6.

- [ ] **Step 6: Jalankan build test sampai GREEN**

Run:

```powershell
bun --cwd deck test tests/build.test.ts
bun --cwd deck run check
git diff --check
```

Expected: tiga build test PASS dan Astro check 0 error.

- [ ] **Step 7: Commit semantic shell**

```powershell
git add deck/src deck/tests/build.test.ts
git commit -m "feat: susun dokumen semantik web deck"
```

---

### Task 4: Controller Presentasi dan Input Terpadu

**Files:**
- Create: `deck/src/scripts/deck-controller.ts`
- Create: `deck/tests/controller.test.ts`
- Modify: `deck/src/components/DeckShell.astro`
- Modify: `deck/src/styles/deck.css`
- Create: `deck/tests/browser-qa.ts`

**Interfaces:**
- Consumes: `[data-deck]`, `[data-slide]`, controls, progress, dan announcer Task 3.
- Produces: `resolveTarget()`, `resolveSwipe()`, `createDeckController()`, state `activeIndex`, hash sync, keyboard/pointer/fullscreen handling.

- [ ] **Step 1: Tulis unit test untuk state murni**

```ts
import { describe, expect, test } from 'bun:test';
import { resolveSwipe, resolveTarget } from '../src/scripts/deck-controller';

describe('deck navigation', () => {
  test('key navigation terikat pada bounds', () => {
    expect(resolveTarget('ArrowRight', 0, 12)).toBe(1);
    expect(resolveTarget('ArrowLeft', 0, 12)).toBe(0);
    expect(resolveTarget('End', 2, 12)).toBe(11);
    expect(resolveTarget('Home', 9, 12)).toBe(0);
    expect(resolveTarget('x', 4, 12)).toBeNull();
  });

  test('swipe butuh threshold 48px', () => {
    expect(resolveSwipe(200, 130)).toBe(1);
    expect(resolveSwipe(130, 200)).toBe(-1);
    expect(resolveSwipe(130, 160)).toBe(0);
  });
});
```

- [ ] **Step 2: Jalankan test dan pastikan RED**

Run: `bun --cwd deck test tests/controller.test.ts`

Expected: FAIL karena module belum ada.

- [ ] **Step 3: Implementasikan controller dengan satu jalur state**

`deck-controller.ts` wajib mengekspor:

```ts
const NEXT_KEYS = new Set(['ArrowRight','ArrowDown','PageDown',' ']);
const PREVIOUS_KEYS = new Set(['ArrowLeft','ArrowUp','PageUp']);

export function resolveTarget(key: string, current: number, total: number): number | null {
  if (NEXT_KEYS.has(key)) return Math.min(total - 1, current + 1);
  if (PREVIOUS_KEYS.has(key)) return Math.max(0, current - 1);
  if (key === 'Home') return 0;
  if (key === 'End') return total - 1;
  return null;
}

export function resolveSwipe(startX: number, endX: number, threshold = 48): -1 | 0 | 1 {
  const delta = endX - startX;
  return Math.abs(delta) < threshold ? 0 : delta < 0 ? 1 : -1;
}

export function createDeckController(root: HTMLElement) {
  const slides = [...root.querySelectorAll<HTMLElement>('[data-slide]')];
  const progress = document.querySelector<HTMLOutputElement>('[data-progress]');
  const announcer = document.querySelector<HTMLElement>('[data-announcer]');
  let activeIndex = Math.max(0, slides.findIndex((slide) => `#${slide.id}` === location.hash));
  let pointerStartX: number | null = null;
  let initialized = false;
  let frameLocked = false;

  const goTo = (target: number, updateHash = true) => {
    const nextIndex = Math.max(0, Math.min(slides.length - 1, target));
    if (initialized && (nextIndex === activeIndex || frameLocked)) return;
    activeIndex = nextIndex;
    initialized = true;
    frameLocked = true;
    requestAnimationFrame(() => { frameLocked = false; });
    slides.forEach((slide, index) => slide.toggleAttribute('data-active', index === activeIndex));
    const active = slides[activeIndex];
    if (!active) return;
    progress && (progress.value = `${activeIndex + 1} / ${slides.length}`);
    const title = active.querySelector('h1,h2')?.textContent?.trim() ?? '';
    announcer && (announcer.textContent = `Slide ${activeIndex + 1}: ${title}`);
    if (updateHash) history.replaceState(null, '', `#${active.id}`);
  };

  const onKey = (event: KeyboardEvent) => {
    const targetElement = event.target as HTMLElement | null;
    if (targetElement?.matches('a[href],button,input,textarea,select,[contenteditable="true"]')) return;
    const target = resolveTarget(event.key, activeIndex, slides.length);
    if (target === null) return;
    event.preventDefault();
    goTo(target);
  };

  document.documentElement.classList.add('deck-enhanced');
  document.addEventListener('keydown', onKey);
  root.addEventListener('pointerdown', (event) => { pointerStartX = event.clientX; });
  root.addEventListener('pointerup', (event) => {
    if (pointerStartX === null) return;
    const direction = resolveSwipe(pointerStartX, event.clientX);
    pointerStartX = null;
    if (direction) goTo(activeIndex + direction);
  });
  document.querySelector('[data-action="previous"]')?.addEventListener('click', () => goTo(activeIndex - 1));
  document.querySelector('[data-action="next"]')?.addEventListener('click', () => goTo(activeIndex + 1));
  document.querySelector('[data-action="fullscreen"]')?.addEventListener('click', async () => {
    if (!document.fullscreenElement) await document.documentElement.requestFullscreen?.();
    else await document.exitFullscreen?.();
  });
  window.addEventListener('hashchange', () => {
    const index = slides.findIndex((slide) => `#${slide.id}` === location.hash);
    if (index >= 0) goTo(index, false);
  });
  goTo(activeIndex, false);
  return { goTo, get activeIndex() { return activeIndex; } };
}

if (typeof document !== 'undefined') {
  const root = document.querySelector<HTMLElement>('[data-deck]');
  if (root) createDeckController(root);
}
```

`DeckShell.astro` memuat script lokal tersebut melalui mekanisme bundling script Astro, bukan inline copy kedua.

- [ ] **Step 4: Buat browser smoke QA untuk interaksi**

`browser-qa.ts` harus memakai `Bun.spawn` untuk `bun run preview -- --host 127.0.0.1 --port 4327`, poll `fetch('http://127.0.0.1:4327')` sampai 200 dengan timeout 20 detik, lalu menjalankan Chromium. Gunakan `CHROME_PATH` bila tersedia, fallback Windows `C:\Program Files\Google\Chrome\Application\chrome.exe`.

Pada 1280×720 assert:

```ts
await page.goto('http://127.0.0.1:4327/#slide-7');
if (!(await page.locator('#slide-7').evaluate((element) => element.hasAttribute('data-active')))) throw new Error('Deep link #slide-7 tidak dipulihkan');
await page.goto('http://127.0.0.1:4327/#slide-1');
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
```

Browser dan preview process selalu ditutup di `finally`.

- [ ] **Step 5: Tambahkan CSS enhancement tanpa merusak no-JS**

Hanya `.deck-enhanced` boleh menyembunyikan slide tidak aktif. Gunakan:

```css
@media (min-width: 64rem){
  .deck-enhanced body{overflow:hidden}
  .deck-enhanced .slide{position:absolute;inset:0;min-height:100svh;opacity:0;visibility:hidden;transform:translateX(1.5rem);transition:opacity var(--duration) var(--ease),transform var(--duration) var(--ease)}
  .deck-enhanced .slide[data-active]{opacity:1;visibility:visible;transform:none}
  .deck-enhanced .deck-controls{position:fixed;left:50%;transform:translateX(-50%)}
}
@media (prefers-reduced-motion:reduce){.deck-enhanced .slide{transition:none!important;transform:none!important}}
```

Pada lebar di bawah 1024 px, deck tetap scroll vertikal; controller boleh memperbarui hash tetapi tidak menyembunyikan section.

- [ ] **Step 6: Jalankan test dan smoke QA**

```powershell
bun --cwd deck test tests/controller.test.ts
bun --cwd deck run build
bun --cwd deck run qa
git diff --check
```

Expected: unit test dan browser smoke PASS.

- [ ] **Step 7: Commit controller**

```powershell
git add deck/src/scripts/deck-controller.ts deck/src/components/DeckShell.astro deck/src/styles/deck.css deck/tests/controller.test.ts deck/tests/browser-qa.ts
git commit -m "feat: tambahkan mode presentasi web deck"
```

---

### Task 5: Visual Botanical Art Nouveau dan Enam Viewport

**Files:**
- Modify: `deck/src/components/SlideContent.astro`
- Modify: `deck/src/components/VineOrnament.astro`
- Modify: `deck/src/styles/deck.css`
- Modify: `deck/tests/browser-qa.ts`
- Create: `deck/tests/visual-contract.test.ts`
- Create ignored: `deck/.qa/slide-01.png` sampai `slide-12.png`, viewport screenshots, `qa-results.json`

**Interfaces:**
- Consumes: semantic markup Task 3 dan mode presentasi Task 4.
- Produces: 12 siluet slide final, responsive strategy, dan bukti visual per slide.

- [ ] **Step 1: Tulis visual-contract test yang gagal**

Test harus membaca `deck.css`, `SlideContent.astro`, dan `slides.ts`, lalu assert seluruh token hex, media query `64rem`, `prefers-reduced-motion`, `@font-face`, tepat 12 kind unik dari data, tidak ada `linear-gradient`, `border-radius:999`, `box-shadow` berulang, `mockup.png`, emoji, `stroke-dasharray` dekoratif, atau `---`.

```ts
import { expect, test } from 'bun:test';
const css = await Bun.file(new URL('../src/styles/deck.css', import.meta.url)).text();
const markup = await Bun.file(new URL('../src/components/SlideContent.astro', import.meta.url)).text();
const data = await Bun.file(new URL('../src/data/slides.ts', import.meta.url)).text();

test('visual contract Art Nouveau', () => {
  for (const color of ['#EDE5D8','#FFFFFF','#265938','#009966','#00BC7D','#F38222','#C2540E','#0A0A0A','#171717','#737373','#F5F5F5']) expect(css).toContain(color);
  expect(css).toContain('@media (min-width: 64rem)');
  expect(css).toContain('prefers-reduced-motion:reduce');
  expect((data.match(/kind:\s*'/g) ?? []).length).toBe(12);
  expect(`${css}\n${markup}`).not.toMatch(/linear-gradient|border-radius:\s*999|mockup\.png|---/i);
});
```

- [ ] **Step 2: Jalankan test dan pastikan RED pada token/layout yang belum lengkap**

Run: `bun --cwd deck test tests/visual-contract.test.ts`

Expected: FAIL sampai seluruh visual contract tersedia.

- [ ] **Step 3: Implementasikan visual system dan negative space**

Tambahkan aturan global berikut:

- `.slide__inner` memakai grid 12 kolom pada desktop, gap 24 px, safe inset minimal 64 px;
- area copy tidak lebih dari 5–6 kolom kecuali slide 3/8/11;
- judul maksimal 18ch, body maksimal 56ch;
- `data-kind=title|closing` paper, `demo` forest, content lain white/surface bergantian secukupnya;
- ornament `position:absolute; pointer-events:none;` dan selalu terikat ke container dengan transform-origin yang tidak membuat overflow;
- tidak ada rounded card; screenshot hanya frame garis 1–2 px dengan satu corner flourish kecil;
- source footer tidak lebih dari dua baris pada layar; pada mobile boleh wrap alami.

Siluet wajib:

- slide 1: copy grid kolom 1–6, logo kolom 8–12, sulur diagonal rendah;
- slide 2: tiga `<dl>` pada satu baseline, angka 64–88 px, tidak dibungkus card;
- slide 3: enam row dengan label kiri dan celah kanan, separator tipis netral;
- slide 4: jalur kaskade horizontal desktop/vertikal mobile, gate fisik berbentuk diamond/square, cabang dilabeli;
- slide 5: forest full-bleed, `DEMO` minimal 104 px, body putih;
- slide 6: connector SVG dibuat visual di belakang empat node datar;
- slide 7: tiga fallback level vertikal; source string sebagai monospace inline text, bukan badge;
- slide 8: screenshot mengisi minimal 65% area pada 1280×720, rasio contain, copy total maksimum 42 kata;
- slide 9: satu sulur bercabang ke tiga label pendapatan;
- slide 10: tiga garis relatif dengan nilai langsung dan teks skala log eksplisit;
- slide 11: satu timeline sulur lima fase dengan label bergantian atas/bawah;
- slide 12: copy centered-left, logo/infinity di ruang kanan, tanpa CTA tambahan.

- [ ] **Step 4: Perluas browser QA menjadi matriks final**

Untuk setiap viewport `[320,568]`, `[375,812]`, `[768,1024]`, `[1024,768]`, `[1280,720]`, `[1440,900]`, assert:

```ts
const metrics = await page.evaluate(() => ({
  clientWidth: document.documentElement.clientWidth,
  scrollWidth: document.documentElement.scrollWidth,
  offenders: [...document.querySelectorAll<HTMLElement>('body *')]
    .filter((node) => { const rect = node.getBoundingClientRect(); return rect.left < -0.5 || rect.right > document.documentElement.clientWidth + 0.5; })
    .map((node) => `${node.tagName}.${node.className}`).slice(0, 10)
}));
if (metrics.scrollWidth > metrics.clientWidth || metrics.offenders.length) throw new Error(JSON.stringify(metrics));
```

Tambahkan checks:

- focus ring computed outline minimal 3 px pada tombol controls;
- target button minimal 44×44;
- reduced motion menghasilkan `transition-duration: 0s` atau ≤0.01s;
- context `javaScriptEnabled:false` menampilkan 12 section dengan bounding box non-null;
- pointer swipe 80 px mengubah hash tepat satu slide;
- tombol tidak menutupi judul/body aktif.

Pada 1280×720, simpan satu screenshot per slide ke `.qa/slide-01.png`–`.qa/slide-12.png`. Simpan viewport 320, 375, dan 1440 serta JSON metrik. `.qa` tetap ignored.

- [ ] **Step 5: Jalankan seluruh QA dan inspeksi visual individual**

```powershell
bun --cwd deck test
bun --cwd deck run build
bun --cwd deck run qa
```

Inspeksi `slide-01.png` sampai `slide-12.png` satu per satu dengan image viewer. Periksa title wrapping, negative space, crop screenshot, source footer, contrast, connector, dan apakah ornament menyentuh isi. Contact sheet hanya boleh digunakan setelah inspeksi individual.

- [ ] **Step 6: Perbaiki CSS/markup dari sumber dan ulangi seluruh render**

Setiap defect diperbaiki di `SlideContent.astro`, `VineOrnament.astro`, atau `deck.css`, lalu seluruh 12 screenshot dibuat ulang. Jangan mengecilkan body di bawah 18 px; pendekkan visible copy atau ubah grid.

- [ ] **Step 7: Pastikan GREEN dan commit visual**

```powershell
bun --cwd deck test tests/visual-contract.test.ts
bun --cwd deck run qa
git diff --check
git add deck/src/components/SlideContent.astro deck/src/components/VineOrnament.astro deck/src/styles/deck.css deck/tests/browser-qa.ts deck/tests/visual-contract.test.ts
git commit -m "feat: selesaikan visual Art Nouveau web deck"
```

---

### Task 6: Print CSS, PDF 12 Halaman, dan Audit Final

**Files:**
- Modify: `deck/src/styles/print.css`
- Create: `deck/scripts/export-pdf.ts`
- Create: `deck/tests/pdf.test.ts`
- Create: `deck/tests/verify.ts`
- Create: `deck/Lestar-KMIPN-VIII.pdf`
- Create: `deck/public/Lestar-KMIPN-VIII.pdf`
- Modify as needed: `deck/src/**` only for audited P0/P1 fixes

**Interfaces:**
- Consumes: build dan 12 slide visual final Task 5.
- Produces: PDF 12 halaman, verifier final, audit UI tanpa P0/P1.

- [ ] **Step 1: Tulis PDF test yang gagal sebelum output ada**

```ts
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
```

- [ ] **Step 2: Jalankan test dan pastikan RED**

Run: `bun --cwd deck test tests/pdf.test.ts`

Expected: FAIL karena PDF belum ada.

- [ ] **Step 3: Implementasikan print contract 16:9**

`print.css`:

```css
@page{size:13.333in 7.5in;margin:0}
@media print{
  html,body{width:13.333in;margin:0;background:#FFFFFF;print-color-adjust:exact;-webkit-print-color-adjust:exact}
  .skip-link,.deck-controls,[data-announcer]{display:none!important}
  main{display:block!important}
  .slide{position:relative!important;inset:auto!important;display:block!important;width:13.333in;height:7.5in;min-height:0!important;overflow:hidden;break-after:page;page-break-after:always;opacity:1!important;visibility:visible!important;transform:none!important;transition:none!important}
  .slide:last-child{break-after:auto;page-break-after:auto}
  .slide__sources{display:block;font-size:9pt}
}
```

- [ ] **Step 4: Implementasikan exporter yang menunggu build/font**

`export-pdf.ts` harus:

1. menjalankan `bun run build` dengan `Bun.spawn` dan gagal bila exit non-zero;
2. menjalankan `bun run preview -- --host 127.0.0.1 --port 4328`;
3. poll HTTP sampai 200 dengan timeout 20 detik;
4. membuka Chromium, `page.goto(..., { waitUntil:'networkidle' })`, lalu `await page.evaluate(() => document.fonts.ready)`;
5. mengekspor dengan `printBackground:true`, `preferCSSPageSize:true`, path absolut `Lestar-KMIPN-VIII.pdf`;
6. menyalin byte final yang sama ke `public/Lestar-KMIPN-VIII.pdf` dan memverifikasi SHA-256 keduanya identik;
7. membaca PDF memakai `PDFDocument.load()` dan melempar bila jumlah halaman bukan 12;
8. menutup browser dan preview process di `finally`.

- [ ] **Step 5: Tulis verifier final**

`tests/verify.ts` menjalankan secara berurutan menggunakan `Bun.spawn`:

```ts
import { fileURLToPath } from 'node:url';

const deck = fileURLToPath(new URL('..', import.meta.url));
const commands = [
  ['bun','test'],
  ['bun','run','check'],
  ['bun','run','build'],
  ['bun','run','qa']
];
for (const command of commands) {
  const process = Bun.spawn(command, { cwd: deck, stdout: 'inherit', stderr: 'inherit' });
  if (await process.exited !== 0) throw new Error(`Gagal: ${command.join(' ')}`);
}
console.log('Web deck verification passed.');
```

Tambahkan final assertions: PDF 12 halaman, asset hashes identik, tepat 12 slide, tidak ada `mockup.png`, dan `dist/index.html` memuat semua required copy.

- [ ] **Step 6: Ekspor PDF dan render ulang untuk inspeksi**

Run:

```powershell
bun --cwd deck run export:pdf
bun --cwd deck test tests/pdf.test.ts
```

Gunakan browser/PDF renderer yang tersedia untuk meraster halaman 1–12 ke `.qa/pdf/page-01.png`–`page-12.png`. Inspeksi individual terhadap render web terakhir: line break, font, background, crop, footer sumber, dan urutan harus setara.

- [ ] **Step 7: Jalankan Impeccable detector tepat sekali dan audit manual**

Run detector sekali pada target final `deck/src/pages/index.astro`, `deck/src/styles/deck.css`, `deck/src/styles/print.css`, dan `deck/src/scripts/deck-controller.ts`. Interpretasikan warning secara kontekstual; jangan mengubah sulur/connector bermakna hanya karena regex side-border. Audit hierarchy, negative space, AI-slop, accessibility, interaction, print, dan screenshot authenticity. Hanya P0/P1 yang memblokir; fix melalui fresh implementer + re-review.

- [ ] **Step 8: Jalankan verifier final dan commit PDF**

```powershell
bun --cwd deck run verify
git diff --check
git add deck/src/styles/print.css deck/scripts/export-pdf.ts deck/tests/pdf.test.ts deck/tests/verify.ts deck/Lestar-KMIPN-VIII.pdf deck/public/Lestar-KMIPN-VIII.pdf
git commit -m "feat: ekspor PDF web deck terverifikasi"
```

---

### Task 7: Preview Vercel dan Handoff Akhir Agent G

**Files:**
- Create: `deck/vercel.json`
- Modify: `docs/06-agent-briefs/G-HANDOFF.md`
- Verify: `landing/` tanpa perubahan
- Verify: `deck/`

**Interfaces:**
- Consumes: web deck/PDF yang lolos Task 6, landing URL existing, Vercel CLI authenticated.
- Produces: URL preview web deck publik dan handoff final faktual.

- [ ] **Step 1: Tulis konfigurasi static deploy**

`deck/vercel.json`:

```json
{
  "buildCommand": "bun run build",
  "outputDirectory": "dist",
  "framework": "astro",
  "cleanUrls": true,
  "headers": [
    {
      "source": "/Lestar-KMIPN-VIII.pdf",
      "headers": [
        { "key": "Content-Type", "value": "application/pdf" },
        { "key": "Content-Disposition", "value": "attachment; filename=Lestar-KMIPN-VIII.pdf" }
      ]
    }
  ]
}
```

Pastikan PDF disalin ke `public/Lestar-KMIPN-VIII.pdf` oleh exporter atau prebuild script dan hash-nya sama dengan root PDF; tambahkan asset test untuk pasangan ini.

- [ ] **Step 2: Jalankan gate lokal lengkap**

```powershell
bun --cwd deck install --frozen-lockfile
bun --cwd deck run verify
$env:LESTAR_RELEASE_APK_SOURCE='L:\Lestar\build\app\outputs\flutter-apk\app-release.apk'; powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1
git diff --check
```

Expected: `Web deck verification passed.`, `Landing verification passed.`, dan diff check bersih.

- [ ] **Step 3: Deploy preview langsung tanpa git push**

Preflight:

```powershell
vercel whoami
vercel teams list --format json
```

Dengan satu scope existing `ruphasas-projects`, jalankan preview, bukan production:

```powershell
vercel deploy deck -y --no-wait --scope ruphasas-projects
```

Poll `vercel inspect <deployment-url> --scope ruphasas-projects` sampai `Ready` atau terminal failure. Jangan memakai `--prod`, jangan melakukan git push, dan jangan meminta/menyimpan token.

- [ ] **Step 4: Verifikasi URL publik**

Periksa desktop 1440×900 dan mobile 375×812. Pastikan page 200, 12 slide tersedia, keyboard/hash bekerja, no overflow, dan link PDF mengembalikan 200, `application/pdf`, filename benar, size/hash sama dengan `deck/Lestar-KMIPN-VIII.pdf`.

- [ ] **Step 5: Update handoff dengan data aktual**

Tambahkan bagian `## Web Deck` menggunakan nilai langsung dari tool pada langkah yang sama. URL harus disalin persis dari output deploy; skor harus disalin persis dari laporan audit. Isi statis bagian tersebut adalah:

```markdown
## Web Deck

- Stack: Astro 7.2.10 + Bun 1.3.14
- Slide: 12 section web-native
- PDF: `deck/Lestar-KMIPN-VIII.pdf` (12 halaman)
- Navigasi terverifikasi: keyboard, tombol, swipe, hash, reduced motion, no-JS
- Viewport terverifikasi: 320×568, 375×812, 768×1024, 1024×768, 1280×720, 1440×900
- Slide 8: consumer/merchant/partner dari Android Emulator `Medium_Phone_API_36.0`, 2 September 2026 WIB
- Catatan: PPTX sengaja tidak dibuat; web deck menggantikannya sesuai keputusan pengguna.
```

Tepat setelah heading, tulis bullet `URL preview` dengan nilai deployment URL yang dikembalikan Vercel. Tepat sebelum catatan, tulis bullet `Audit UI` dengan skor yang dikembalikan audit dan status P0/P1 faktual. Kedua nilai dibaca dan ditulis dalam langkah yang sama; jangan menulis nilai contoh.

Pertahankan seluruh bukti landing yang sudah approved. Perbarui judul handoff dari “Landing Page dan Deck” bila perlu, tetapi jangan mengubah URL/hash/QA landing.

- [ ] **Step 6: Commit metadata deploy dan handoff**

```powershell
git add deck/vercel.json deck/public/Lestar-KMIPN-VIII.pdf docs/06-agent-briefs/G-HANDOFF.md
git commit -m "docs: serahkan web deck publik Lestar"
```

- [ ] **Step 7: Whole-branch final review**

Reviewer fresh membandingkan merge-base plan baru dengan HEAD, memeriksa standards dan spec compliance, membuka URL landing existing dan URL web deck, memverifikasi APK/PDF hash, serta memastikan tidak ada perubahan pada `lib/`, `api/`, `ml/`, atau `supabase/`. Semua blocker diperbaiki sebelum handoff akhir.
