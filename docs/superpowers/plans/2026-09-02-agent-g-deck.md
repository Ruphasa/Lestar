# Agent G Deck and PDF Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membuat deck Botanical Art Nouveau 12 slide yang mendampingi demo live tujuh menit, dapat diedit sebagai PPTX, dan dikirim sebagai PDF yang telah dirender serta diperiksa.

**Architecture:** Deck dibangun dari data naratif tunggal dalam JavaScript ES module menggunakan `@oai/artifact-tool`, dengan helper layout yang menjaga margin, tipografi, sumber, dan motif konsisten. Output PPTX dirender untuk pemeriksaan visual, diekspor ke PDF, dirender ulang per halaman, lalu diverifikasi bersama tiga screenshot aplikasi nyata.

**Tech Stack:** JavaScript ES modules, `@oai/artifact-tool`, Codex presentation runtime, PowerPoint PPTX, LibreOffice-compatible PDF export, Poppler, PowerShell verification.

## Global Constraints

- Hanya mengubah `deck/`, rencana ini, dan bagian deck/final pada `docs/06-agent-briefs/G-HANDOFF.md`.
- Jangan menyentuh `lib/`, `api/`, `ml/`, atau `supabase/`.
- Wajib memakai `@oai/artifact-tool` dari JavaScript ES modules; jangan memakai `python-pptx` atau API Python lama.
- Deck wajib 12 slide, format 16:9, mendampingi demo dan tidak mengulang detail layar aplikasi.
- Slide 8 wajib memakai tiga tangkapan layar aplikasi nyata; `mockup.png` tidak boleh dipakai.
- Arah visual wajib Botanical Art Nouveau kontemporer sesuai `docs/superpowers/specs/2026-09-02-agent-g-art-nouveau-design.md`.
- Palet wajib `#EDE5D8`, `#FFFFFF`, `#265938`, `#009966`, `#00BC7D`, `#F38222`, `#C2540E`, `#0A0A0A`, `#171717`, `#737373`, dan `#F5F5F5`.
- Isian oranye selalu memakai teks `#0A0A0A`; `#00BC7D` tidak boleh menjadi latar teks.
- Plus Jakarta Sans untuk display dan Inter untuk body.
- Judul deck minimal 50 pt; judul slide minimal 35 pt; subjudul minimal 24 pt; body minimal 16 pt.
- Tidak ada emoji, gradient blob, glassmorphism, badge dekoratif, divider putus-putus, atau kumpulan panel UI generik.
- Diagram sederhana memakai native PowerPoint shapes; konektor dibuat sebelum node. Motif dekoratif memakai SVG/PNG, bukan gambar yang digambar dengan Python.
- Setiap klaim nontrivial dan aset eksternal memiliki blok `[Sources]` pada speaker notes.
- Angka pasar wajib TAM Rp960 miliar/tahun, SAM Rp48 miliar/tahun, SOM Rp480 juta/tahun.
- Slide 7 wajib menampilkan `lstm_gemini`, `lstm_only`, dan `heuristic`, serta menyebut `forecasts.source`.
- Slide 8 adalah slide terkuat dan memberi ruang terbesar bagi tiga screenshot.
- Semua slide PPTX dan halaman PDF wajib dirender serta diperiksa satu per satu; overlap, clipping, wrapping, dan teks penampung dilarang.
- Output final: `deck/Lestar-KMIPN-VIII.pptx` dan `deck/Lestar-KMIPN-VIII.pdf`.
- Pesan commit wajib Bahasa Indonesia.

---

## Struktur Berkas

```text
deck/
  Lestar-KMIPN-VIII.pptx        deck editable final
  Lestar-KMIPN-VIII.pdf         deck PDF final
  assets/
    logo-full.png               salinan aset brand final landing
    logo-glyph.svg              glyph transparan
    value-route.svg             motif jalur nilai
    screenshots/
      consumer.png
      merchant.png
      partner.png
    fonts/
      PlusJakartaSans-wght.ttf
      Inter-opsz-wght.ttf
  tests/
    verify.ps1                  pemeriksaan output, halaman, teks, dan aset
  .tmp/
    build.mjs                   builder artifact-tool
    deck-content.mjs            data naratif 12 slide
    source-notes.txt            provenance aset dan klaim
    renders/                    PNG hasil render PPTX
    pdf-renders/                PNG hasil render PDF
    qa-ledger.txt               hasil inspeksi per slide
```

## Kontrak Antarmuka

- `deck/.tmp/deck-content.mjs` mengekspor `SLIDES`, array tepat 12 objek dengan shape `{ number, title, kind, body, sources }`.
- `deck/.tmp/build.mjs` mengekspor `buildDeck(outputPath)` dan memakai helper `addSlideTitle`, `addFooter`, `addSourceNotes`, `addVine`, `addTextBlock`, serta `addImageContain`.
- Ukuran kanvas: 1280 x 720 px; safe margin: 72 px kiri/kanan dan 56 px atas/bawah.
- Screenshot source-of-truth: `landing/assets/screenshots/{consumer,merchant,partner}.png`; salinan di `deck/assets/screenshots/` harus mempunyai hash yang sama.
- Source notes selalu dimulai dengan `[Sources]` dan satu sumber per baris.
- `deck/tests/verify.ps1` hanya lulus bila PPTX dan PDF ada, PDF memiliki 12 halaman, tiga screenshot identik dengan landing, serta output berukuran masuk akal.

### Task 1: Runtime, Asset Gate, dan Verifier

**Files:**
- Create: `deck/tests/verify.ps1`
- Create: `deck/assets/logo-full.png`
- Create: `deck/assets/logo-glyph.svg`
- Create: `deck/assets/value-route.svg`
- Create: `deck/assets/screenshots/consumer.png`
- Create: `deck/assets/screenshots/merchant.png`
- Create: `deck/assets/screenshots/partner.png`
- Create: `deck/assets/fonts/PlusJakartaSans-wght.ttf`
- Create: `deck/assets/fonts/Inter-opsz-wght.ttf`
- Create: `deck/.tmp/source-notes.txt`

**Interfaces:**
- Consumes: final asset landing, presentation runtime paths, proposal, arsitektur, dan demo script.
- Produces: aset deck yang hash-nya terkunci, verifier final, serta catatan sumber untuk builder.

- [ ] **Step 1: Panggil `load_workspace_dependencies` dan simpan tiga path runtime untuk sesi eksekusi**

Ambil `RUNTIME_NODE`, `RUNTIME_NODE_MODULES`, dan `RUNTIME_BIN_DIR` persis dari tiga absolute path yang dikembalikan tool, lalu kirim ketiganya sebagai environment pada setiap command authoring. Jangan menurunkan satu path dari path lain, menulisnya ke repository, mencari runtime global, atau menginstal package. Jika salah satu tidak dikembalikan, tandai runtime sebagai blocker.

- [ ] **Step 2: Tulis verifier yang gagal sebelum output dan aset tersedia**

```powershell
$ErrorActionPreference = 'Stop'
$deckRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $deckRoot
$required = @(
  'Lestar-KMIPN-VIII.pptx','Lestar-KMIPN-VIII.pdf',
  'assets/logo-full.png','assets/logo-glyph.svg','assets/value-route.svg',
  'assets/screenshots/consumer.png','assets/screenshots/merchant.png','assets/screenshots/partner.png',
  'assets/fonts/PlusJakartaSans-wght.ttf','assets/fonts/Inter-opsz-wght.ttf',
  '.tmp/deck-content.mjs','.tmp/build.mjs','.tmp/source-notes.txt','.tmp/qa-ledger.txt'
)
foreach($relative in $required){
  if(-not (Test-Path -LiteralPath (Join-Path $deckRoot $relative) -PathType Leaf)){
    throw "Berkas deck wajib tidak ditemukan: $relative"
  }
}
foreach($role in @('consumer','merchant','partner')){
  $landingShot=Join-Path $repoRoot "landing/assets/screenshots/$role.png"
  $deckShot=Join-Path $deckRoot "assets/screenshots/$role.png"
  if(-not (Test-Path -LiteralPath $landingShot -PathType Leaf)){throw "Screenshot nyata landing belum tersedia: $role"}
  if((Get-FileHash -Algorithm SHA256 -LiteralPath $landingShot).Hash -ne
     (Get-FileHash -Algorithm SHA256 -LiteralPath $deckShot).Hash){throw "Screenshot deck berbeda dari landing: $role"}
}
$pptx=Get-Item -LiteralPath (Join-Path $deckRoot 'Lestar-KMIPN-VIII.pptx')
$pdf=Get-Item -LiteralPath (Join-Path $deckRoot 'Lestar-KMIPN-VIII.pdf')
if($pptx.Length -lt 100000){throw 'PPTX terlalu kecil untuk deck final'}
if($pdf.Length -lt 100000){throw 'PDF terlalu kecil untuk deck final'}
$content=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $deckRoot '.tmp/deck-content.mjs')
foreach($requiredText in @('14,73 juta ton','Rp213-551 triliun','7,29%','Rp960 miliar','Rp48 miliar','Rp480 juta','forecasts.source','lstm_gemini','lstm_only','heuristic')){
  if(-not $content.Contains($requiredText)){throw "Copy deck wajib tidak ditemukan: $requiredText"}
}
$qa=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $deckRoot '.tmp/qa-ledger.txt')
for($n=1;$n -le 12;$n++){
  if($qa -notmatch ("Slide $n: PASS")){throw "QA visual slide $n belum PASS"}
}
Write-Host 'Deck verification passed.'
```

- [ ] **Step 3: Jalankan verifier dan pastikan gagal pada output PPTX**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File deck/tests/verify.ps1`

Expected: exit code non-zero dengan `Berkas deck wajib tidak ditemukan: Lestar-KMIPN-VIII.pptx`.

- [ ] **Step 4: Salin aset final landing dan font ke deck**

```powershell
New-Item -ItemType Directory -Force -Path 'deck/assets/screenshots','deck/assets/fonts','deck/.tmp' | Out-Null
Copy-Item -LiteralPath 'landing/assets/logo-full.png' -Destination 'deck/assets/logo-full.png'
Copy-Item -LiteralPath 'landing/assets/logo-glyph.svg' -Destination 'deck/assets/logo-glyph.svg'
Copy-Item -LiteralPath 'landing/assets/value-route.svg' -Destination 'deck/assets/value-route.svg'
Copy-Item -LiteralPath 'landing/assets/screenshots/consumer.png' -Destination 'deck/assets/screenshots/consumer.png'
Copy-Item -LiteralPath 'landing/assets/screenshots/merchant.png' -Destination 'deck/assets/screenshots/merchant.png'
Copy-Item -LiteralPath 'landing/assets/screenshots/partner.png' -Destination 'deck/assets/screenshots/partner.png'
Copy-Item -LiteralPath 'landing/assets/fonts/PlusJakartaSans-wght.ttf' -Destination 'deck/assets/fonts/PlusJakartaSans-wght.ttf'
Copy-Item -LiteralPath 'landing/assets/fonts/Inter-opsz-wght.ttf' -Destination 'deck/assets/fonts/Inter-opsz-wght.ttf'
```

- [ ] **Step 5: Buat junction module runtime di build directory**

```powershell
if(-not (Test-Path -LiteralPath 'deck/.tmp/node_modules')){
  New-Item -ItemType Junction -Path 'deck/.tmp/node_modules' -Target $env:RUNTIME_NODE_MODULES | Out-Null
}
```

- [ ] **Step 6: Tulis provenance di `source-notes.txt`**

```text
LOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | slides 2,3,4,9,10,11,12 | statistics, gap analysis, market, roadmap
LOCAL SOURCE | docs/01-architecture.md | slides 6,7 | four components and fallback chain
LOCAL SOURCE | docs/03-design-system.md | all slides | brand colors, typography, three UI rationale
LOCAL SOURCE | docs/05-demo-script.md | slides 5,7,8 | demo boundary and honest fallback narrative
LOCAL ASSET | assets/logo.png -> deck/assets/logo-full.png | slides 1,12 | Lestar logo
LOCAL ASSET | landing/assets/screenshots/consumer.png | slide 8 | real consumer UI capture
LOCAL ASSET | landing/assets/screenshots/merchant.png | slide 8 | real merchant UI capture
LOCAL ASSET | landing/assets/screenshots/partner.png | slide 8 | real partner UI capture
```

- [ ] **Step 7: Commit runtime gate dan aset deck**

```bash
git add deck/tests/verify.ps1 deck/assets deck/.tmp/source-notes.txt
git commit -m "test: siapkan gerbang aset dan keluaran deck"
```

### Task 2: Narrative Data dan Source Notes per Slide

**Files:**
- Create: `deck/.tmp/deck-content.mjs`
- Modify: `deck/tests/verify.ps1`

**Interfaces:**
- Consumes: angka proposal dan alur 12 slide pada spec.
- Produces: `SLIDES`, satu-satunya sumber visible copy dan speaker-note sources bagi builder.

- [ ] **Step 1: Tambahkan assertion jumlah slide dan sumber**

```powershell
$slideCount=([regex]::Matches($content,'number:\s*\d+')).Count
if($slideCount -ne 12){throw "deck-content harus memiliki 12 slide, ditemukan $slideCount"}
$sourceCount=([regex]::Matches($content,'\[Sources\]')).Count
if($sourceCount -ne 12){throw "Setiap slide harus memiliki blok Sources; ditemukan $sourceCount"}
if($content -match 'mockup\.png|Juara 1 National Excellence Competitions 2026' -and $content -notmatch 'LOCAL SOURCE'){
  throw 'Klaim atau mockup tanpa sumber terdeteksi'
}
```

- [ ] **Step 2: Jalankan verifier dan pastikan gagal pada `deck-content.mjs`**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File deck/tests/verify.ps1`

Expected: exit code non-zero pada `.tmp/deck-content.mjs`.

- [ ] **Step 3: Tulis model data dan 12 slide dengan visible copy singkat**

```js
export const SLIDES = [
  { number:1, kind:'title', title:'Setiap kilogram punya jalur nilai', body:['Lestar','Tim Lestar · 2 September 2026'], sources:'[Sources]\nLOCAL ASSET | assets/logo.png | logo Lestar' },
  { number:2, kind:'problem', title:'Food waste Indonesia adalah kerugian ekonomi berskala nasional', body:['14,73 juta ton','sampah makanan per tahun','Rp213-551 triliun','kerugian ekonomi per tahun','7,29%','kontribusi emisi gas rumah kaca'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | Bab I §1.1' },
  { number:3, kind:'gap', title:'Solusi yang ada berhenti sebelum seluruh nilai dipulihkan', body:['Flash sale: hanya B2C','Donasi: bergantung relawan','Limbah: pickup manual dan informal','Pricing: subjektif','ESG: manual atau tidak ada','Forecasting: tidak tersedia'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | Tabel 2.1.1' },
  { number:4, kind:'cascade', title:'Lestar mencegah kerugian lalu memulihkan sisa nilainya', body:['Prediksi permintaan','Surplus','Triage AI','Validasi fisik','Flash Sale B2C','Limbah Organik B2B','Laporan ESG'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | §2.3.1\nLOCAL SOURCE | docs/00-PRD.md | §4' },
  { number:5, kind:'demo', title:'Sekarang lihat alurnya bekerja', body:['DEMO'], sources:'[Sources]\nLOCAL SOURCE | docs/05-demo-script.md | §5' },
  { number:6, kind:'architecture', title:'Empat komponen menjaga jalur data tetap sederhana', body:['Flutter APK','Supabase','FastAPI @ Railway','Landing @ Vercel'], sources:'[Sources]\nLOCAL SOURCE | docs/01-architecture.md | §1' },
  { number:7, kind:'fallback', title:'Sistem tetap memberi angka dan selalu mengaku dari mana asalnya', body:['LSTM + Gemini','lstm_gemini','LSTM saja','lstm_only','Heuristik lokal','heuristic','forecasts.source mencatat asal setiap angka'], sources:'[Sources]\nLOCAL SOURCE | docs/01-architecture.md | §6\nLOCAL SOURCE | docs/05-demo-script.md | §6' },
  { number:8, kind:'three-ui', title:'Tiga dunia kerja membutuhkan tiga antarmuka berbeda', body:['Konsumen: ringan dan menyenangkan','Merchant: kokpit data','Pengepul: terbaca di bawah terik matahari dengan satu tangan'], sources:'[Sources]\nLOCAL SOURCE | docs/03-design-system.md | §1.1\nLOCAL ASSET | landing/assets/screenshots/consumer.png\nLOCAL ASSET | landing/assets/screenshots/merchant.png\nLOCAL ASSET | landing/assets/screenshots/partner.png' },
  { number:9, kind:'business', title:'Tiga arus pendapatan membiayai ekosistem', body:['Komisi transaksi B2C','Langganan mitra B2B','Green fee Rp1.000 per transaksi'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | Tabel 2.2.1\nLOCAL SOURCE | docs/00-PRD.md | §6.3' },
  { number:10, kind:'market', title:'Pasar awal cukup fokus untuk dimenangkan dan cukup besar untuk tumbuh', body:['TAM · Rp960 miliar/tahun','SAM · Rp48 miliar/tahun','SOM · Rp480 juta/tahun'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | §2.6' },
  { number:11, kind:'roadmap', title:'Dua belas bulan membawa Lestar dari fondasi ke scaling', body:['Bulan 1-2 · Fondasi','Bulan 3-4 · MVP + Data Foundation','Bulan 5-6 · AI Integration','Bulan 7-9 · Pilot Launch','Bulan 10-12 · Scaling'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | Tabel 2.7.1' },
  { number:12, kind:'closing', title:'Dimulai dari Malang, dikembangkan menuju skala nasional.', body:['Lestar','Setiap kilogram punya jalur nilai'], sources:'[Sources]\nLOCAL SOURCE | LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md | §2.7.2\nLOCAL ASSET | assets/logo.png' }
];
```

- [ ] **Step 4: Jalankan assertion konten langsung pada module**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File deck/tests/verify.ps1
```

Expected: kegagalan berpindah ke `.tmp/build.mjs` atau output PPTX/PDF, bukan konten slide.

- [ ] **Step 5: Commit narasi deck**

```bash
git add deck/.tmp/deck-content.mjs deck/tests/verify.ps1
git commit -m "docs: kunci narasi dan sumber deck Lestar"
```

### Task 3: Authoring PPTX dengan Artifact Tool

**Files:**
- Create: `deck/.tmp/build.mjs`
- Create: `deck/Lestar-KMIPN-VIII.pptx`
- Create: `deck/.tmp/qa-ledger.txt`

**Interfaces:**
- Consumes: `SLIDES`, aset Task 1, dan runtime dependency paths.
- Produces: fungsi `buildDeck(outputPath)` dan PPTX 12 slide dengan speaker notes.

- [ ] **Step 1: Baca dokumentasi artifact-tool sebelum menulis builder**

Read completely:

```text
C:/Users/ASUS/.codex/plugins/cache/openai-primary-runtime/presentations/26.826.12353/skills/presentations/artifact_tool_docs/API_QUICK_START.md
C:/Users/ASUS/.codex/plugins/cache/openai-primary-runtime/presentations/26.826.12353/skills/presentations/artifact_tool_docs/api/API_DOCS.md
```

Catat API aktual untuk membuat presentation, menambah slide, text, image, shape, connector, notes, dan export. Jangan menebak method name dari library lain.

- [ ] **Step 2: Jalankan marker authoring PPTX tepat sekali sebagai command mandiri**

Working directory: `C:/Users/ASUS/.codex/plugins/cache/openai-primary-runtime/presentations/26.826.12353/skills/presentations`

Run:

```powershell
& $env:RUNTIME_NODE container_tools/mark_artifact_operation_started.mjs --operation-kind create --expected-output-count 1 --output-format pptx
```

Expected: exit code 0. Jangan menjalankan marker PPTX lagi pada sesi authoring ini.

- [ ] **Step 3: Tulis helper dan token builder dengan interface stabil**

```js
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Presentation, PresentationFile } from '@oai/artifact-tool';
import { SLIDES } from './deck-content.mjs';
export const PAGE = { width:1280, height:720, left:72, right:72, top:56, bottom:56 };
export const COLOR = { paper:'#EDE5D8', white:'#FFFFFF', forest:'#265938', emeraldDeep:'#009966', emerald:'#00BC7D', orange:'#F38222', orangeText:'#C2540E', ink:'#0A0A0A', inkSoft:'#171717', muted:'#737373', grey:'#F5F5F5' };
export const FONT = { display:'Plus Jakarta Sans', body:'Inter' };
const here = path.dirname(fileURLToPath(import.meta.url));
const assets = path.resolve(here, '..', 'assets');
let elementSequence = 0;

export function addTextBlock(slide, text, box, style = {}) {
  const shape = slide.shapes.add({
    geometry:'textbox', name:style.name ?? `text-${++elementSequence}`,
    position:box, fill:'none', line:{style:'solid',fill:'none',width:0}
  });
  shape.text = text;
  shape.text.style = {
    typeface:style.typeface ?? FONT.body, fontSize:style.fontSize ?? 20,
    bold:style.bold ?? false, color:style.color ?? COLOR.ink,
    alignment:style.alignment ?? 'left'
  };
  return shape;
}
export function addSlideTitle(slide, title, options = {}) {
  return addTextBlock(slide,title,{left:PAGE.left,top:PAGE.top,width:1136,height:76},{name:`slide-title-${options.number}`,typeface:FONT.display,fontSize:options.fontSize ?? 38,bold:true,color:options.color ?? COLOR.forest});
}
export function addFooter(slide, number) {
  addTextBlock(slide,'Lestar',{left:72,top:676,width:120,height:22},{name:`footer-brand-${number}`,typeface:FONT.display,fontSize:12,bold:true,color:COLOR.muted});
  addTextBlock(slide,String(number).padStart(2,'0'),{left:1136,top:676,width:72,height:22},{name:`footer-number-${number}`,fontSize:12,color:COLOR.muted,alignment:'right'});
}
export function addSourceNotes(slide, sources) {
  if (!sources.startsWith('[Sources]')) throw new Error('Speaker notes must start with [Sources]');
  slide.speakerNotes.textFrame.setText(sources);
  slide.speakerNotes.setVisible(false);
}
export function addVine(slide, placement) {
  return slide.images.add({path:path.join(assets,'value-route.svg'),alt:'',fit:'contain',position:placement});
}
export function addImageContain(slide, imagePath, box, alt) {
  return slide.images.add({path:imagePath,alt,fit:'contain',position:box,geometry:'rect'});
}
function addNode(slide, label, box, fill, line = COLOR.forest) {
  const node = slide.shapes.add({geometry:'roundRect',name:`node-${++elementSequence}`,position:box,fill,line:{style:'solid',fill:line,width:2},borderRadius:12});
  node.text = label;
  node.text.style = {typeface:FONT.display,fontSize:18,bold:true,color:fill === COLOR.orange ? COLOR.ink : COLOR.forest,alignment:'center'};
  return node;
}
function renderSlideByKind(slide, spec) {
  const titleColor = spec.kind === 'demo' ? COLOR.white : COLOR.forest;
  if (!['title','demo','closing'].includes(spec.kind)) addSlideTitle(slide,spec.title,{number:spec.number,color:titleColor});
  switch (spec.kind) {
    case 'title':
      addVine(slide,{left:520,top:40,width:720,height:300});
      addImageContain(slide,path.join(assets,'logo-full.png'),{left:760,top:96,width:430,height:430},'Logo Lestar berbentuk infinity dari sulur, daun, dan buah');
      addTextBlock(slide,'Lestar',{left:72,top:132,width:560,height:78},{typeface:FONT.display,fontSize:64,bold:true,color:COLOR.forest});
      addTextBlock(slide,spec.title,{left:72,top:232,width:600,height:150},{typeface:FONT.display,fontSize:52,bold:true,color:COLOR.ink});
      addTextBlock(slide,spec.body[1],{left:72,top:590,width:420,height:30},{fontSize:18,color:COLOR.muted});
      break;
    case 'problem':
      [[0,72,184,560,120,58],[2,704,184,504,120,46],[4,72,400,360,110,58]].forEach(([i,left,top,width,height,size])=>{
        addTextBlock(slide,spec.body[i],{left,top,width,height},{typeface:FONT.display,fontSize:size,bold:true,color:i===2?COLOR.orangeText:COLOR.forest});
        addTextBlock(slide,spec.body[i+1],{left,top:top+84,width,height:58},{fontSize:20,color:COLOR.inkSoft});
      });
      break;
    case 'gap':
      spec.body.forEach((row,i)=>{
        const [solution,gap]=row.split(': ');
        addTextBlock(slide,solution,{left:72,top:152+i*76,width:280,height:44},{typeface:FONT.display,fontSize:20,bold:true,color:COLOR.forest});
        addTextBlock(slide,gap,{left:390,top:152+i*76,width:720,height:44},{fontSize:20,color:i===0?COLOR.orangeText:COLOR.ink});
      });
      break;
    case 'cascade': {
      const boxes=[{left:72,top:230,width:150,height:76},{left:260,top:230,width:150,height:76},{left:448,top:230,width:174,height:76},{left:680,top:150,width:190,height:76},{left:680,top:324,width:190,height:76},{left:944,top:238,width:190,height:76}];
      const labels=['Surplus','Triage AI','Validasi fisik','Flash Sale B2C','Limbah Organik B2B','Laporan ESG'];
      const nodes=labels.map((label,i)=>addNode(slide,label,boxes[i],i===3?COLOR.orange:COLOR.white));
      [[0,1],[1,2],[2,3],[2,4],[3,5],[4,5]].forEach(([a,b])=>slide.shapes.connect(nodes[a],nodes[b],{kind:'curved',fromSide:'right',toSide:'left',line:{style:'solid',fill:a===2&&b===3?COLOR.orange:COLOR.forest,width:3},head:{type:'arrow',width:'sm',length:'sm'}}));
      break;
    }
    case 'demo':
      addTextBlock(slide,'DEMO',{left:72,top:210,width:1136,height:132},{typeface:FONT.display,fontSize:108,bold:true,color:COLOR.white,alignment:'center'});
      addTextBlock(slide,spec.title,{left:220,top:370,width:840,height:52},{typeface:FONT.display,fontSize:28,bold:true,color:COLOR.white,alignment:'center'});
      break;
    case 'architecture': {
      const flutter=addNode(slide,'Flutter APK\nsatu aplikasi, tiga wajah',{left:390,top:156,width:500,height:86},COLOR.paper);
      const supabase=addNode(slide,'Supabase\nPostgres · RLS · Realtime · Auth',{left:120,top:358,width:390,height:92},COLOR.white);
      const fastapi=addNode(slide,'FastAPI @ Railway\nLSTM · triage · pricing',{left:770,top:358,width:390,height:92},COLOR.white);
      addNode(slide,'Landing @ Vercel\nstatis · unduh APK',{left:390,top:536,width:500,height:74},COLOR.grey);
      slide.shapes.connect(flutter,supabase,{kind:'curved',fromSide:'bottom',toSide:'top',line:{style:'solid',fill:COLOR.forest,width:3},head:{type:'arrow',width:'sm',length:'sm'}});
      slide.shapes.connect(flutter,fastapi,{kind:'curved',fromSide:'bottom',toSide:'top',line:{style:'solid',fill:COLOR.forest,width:3},head:{type:'arrow',width:'sm',length:'sm'}});
      break;
    }
    case 'fallback':
      [['LSTM + Gemini','lstm_gemini',COLOR.paper],['LSTM saja','lstm_only',COLOR.grey],['Heuristik lokal','heuristic',COLOR.white]].forEach(([label,source,fill],i)=>{
        addTextBlock(slide,label,{left:122,top:156+i*136,width:340,height:56},{typeface:FONT.display,fontSize:28,bold:true,color:COLOR.forest});
        addTextBlock(slide,source,{left:540,top:164+i*136,width:230,height:42},{fontSize:19,color:COLOR.inkSoft});
        const line=slide.shapes.add({geometry:'rect',position:{left:830,top:178+i*136,width:280,height:4},fill:i===2?COLOR.orange:COLOR.emeraldDeep,line:{style:'solid',fill:'none',width:0}});
        line.name=`fallback-line-${i}`;
      });
      addTextBlock(slide,'forecasts.source mencatat asal setiap angka',{left:122,top:580,width:900,height:34},{fontSize:22,bold:true,color:COLOR.orangeText});
      break;
    case 'three-ui': {
      const shots=['consumer','merchant','partner'];
      const alts=['UI konsumen Lestar','UI merchant Lestar','UI pengepul Lestar'];
      shots.forEach((role,i)=>{
        addImageContain(slide,path.join(assets,'screenshots',`${role}.png`),{left:72+i*386,top:140,width:338,height:414},alts[i]);
        addTextBlock(slide,spec.body[i],{left:72+i*386,top:574,width:338,height:62},{fontSize:18,bold:true,color:i===1?COLOR.orangeText:COLOR.forest,alignment:'center'});
      });
      break;
    }
    case 'business':
      spec.body.forEach((text,i)=>{
        addTextBlock(slide,text,{left:120,top:174+i*132,width:720,height:76},{typeface:FONT.display,fontSize:32,bold:true,color:i===2?COLOR.orangeText:COLOR.forest});
        slide.shapes.add({geometry:'ellipse',position:{left:920,top:184+i*132,width:34,height:34},fill:i===2?COLOR.orange:COLOR.emeraldDeep,line:{style:'solid',fill:'none',width:0}});
      });
      break;
    case 'market': {
      const widths=[900,540,250];
      spec.body.forEach((text,i)=>{
        addTextBlock(slide,text,{left:72,top:164+i*138,width:490,height:46},{typeface:FONT.display,fontSize:27,bold:true,color:COLOR.forest});
        slide.shapes.add({geometry:'rect',position:{left:72,top:224+i*138,width:widths[i],height:18},fill:i===2?COLOR.orange:COLOR.emeraldDeep,line:{style:'solid',fill:'none',width:0}});
      });
      addTextBlock(slide,'Panjang garis memakai skala log agar tiga besaran tetap terbaca.',{left:72,top:626,width:760,height:28},{fontSize:16,color:COLOR.muted});
      break;
    }
    case 'roadmap': {
      const labels=spec.body;
      slide.shapes.add({geometry:'rect',position:{left:100,top:330,width:1080,height:5},fill:COLOR.forest,line:{style:'solid',fill:'none',width:0}});
      labels.forEach((label,i)=>{
        const left=82+i*226;
        slide.shapes.add({geometry:'ellipse',position:{left:left+54,top:308,width:48,height:48},fill:i===4?COLOR.orange:COLOR.paper,line:{style:'solid',fill:COLOR.forest,width:2}});
        addTextBlock(slide,label,{left,top:i%2===0?190:390,width:176,height:92},{fontSize:18,bold:true,color:COLOR.forest,alignment:'center'});
      });
      break;
    }
    case 'closing':
      addVine(slide,{left:260,top:70,width:760,height:260});
      addImageContain(slide,path.join(assets,'logo-full.png'),{left:495,top:72,width:290,height:290},'Logo Lestar berbentuk infinity dari sulur, daun, dan buah');
      addTextBlock(slide,spec.title,{left:130,top:410,width:1020,height:110},{typeface:FONT.display,fontSize:50,bold:true,color:COLOR.forest,alignment:'center'});
      addTextBlock(slide,spec.body[1],{left:330,top:560,width:620,height:38},{fontSize:22,color:COLOR.inkSoft,alignment:'center'});
      break;
    default:
      throw new Error(`Unknown slide kind: ${spec.kind}`);
  }
}
export async function buildDeck(outputPath) {
  const presentation = Presentation.create({slideSize:{width:PAGE.width,height:PAGE.height}});
  for (const spec of SLIDES) {
    const slide = presentation.slides.add();
    slide.background.fill = spec.kind === 'demo' ? COLOR.forest : (spec.kind === 'title' || spec.kind === 'closing' ? COLOR.paper : COLOR.white);
    await renderSlideByKind(slide,spec);
    if (spec.kind !== 'demo') addFooter(slide,spec.number);
    addSourceNotes(slide,spec.sources);
  }
  const pptx = await PresentationFile.exportPptx(presentation);
  await pptx.save(outputPath);
}
```

Gunakan implementasi helper dan `renderSlideByKind` di atas sebagai baseline. Bila render menunjukkan wrapping atau overlap, ubah posisi dan ringkas visible copy di `deck-content.mjs` tanpa mengubah angka atau klaim.

- [ ] **Step 4: Implementasikan layout slide 1-5**

- Slide 1: paper background, logo besar kanan, judul 54-64 pt kiri, sulur menyambung ke logo.
- Slide 2: tiga angka dengan baseline editorial; tidak memakai tiga kartu identik.
- Slide 3: enam baris gap analysis, solusi saat ini di kiri dan celah di kanan; highlight B2C-only dengan orange/ink.
- Slide 4: buat connector terlebih dahulu, lalu node kaskade; validasi fisik berbentuk gerbang berbeda.
- Slide 5: forest full-bleed, `DEMO` 88-110 pt, satu kalimat; tanpa screenshot app.

- [ ] **Step 5: Implementasikan layout slide 6-12**

- Slide 6: empat komponen sebagai arsitektur datar; Flutter terhubung ke Supabase dan FastAPI, landing berdiri sendiri.
- Slide 7: tiga lapis vertikal dengan panah turun; source code labels dalam body text, bukan badge dekoratif.
- Slide 8: tiga screenshot occupy minimal 65% kanvas, rasio contain, label satu baris, argumen aksesibilitas maksimum 42 kata.
- Slide 9: tiga arus pendapatan sebagai satu sungai bercabang, tanpa pricing yang tidak ada di proposal.
- Slide 10: bar horizontal berskala log atau broken-axis tidak boleh dipakai tanpa penjelasan; gunakan tiga garis panjang relatif yang diberi label nilai langsung dan catatan skala eksplisit.
- Slide 11: timeline lima fase pada satu sulur dari bulan 1 ke 12; fase 0-4 tetap sesuai proposal.
- Slide 12: paper background, closing sentence 46-54 pt, sulur kembali menjadi infinity.

- [ ] **Step 6: Tambahkan speaker notes sumber pada setiap slide**

Panggil `addSourceNotes(slide, spec.sources)` tepat sekali untuk setiap slide. Notes tidak boleh terlihat pada kanvas. Slide 8 harus mencatat ketiga file screenshot secara terpisah.

- [ ] **Step 7: Ekspor PPTX dengan runtime Node yang disediakan**

Run:

```powershell
& $env:RUNTIME_NODE 'L:\Lestar\deck\.tmp\build.mjs' 'L:\Lestar\deck\Lestar-KMIPN-VIII.pptx'
```

Expected: exit code 0 dan `deck/Lestar-KMIPN-VIII.pptx` terbentuk.

- [ ] **Step 8: Buat QA ledger awal yang seluruh slide masih belum lulus**

```text
Slide 1: REVIEW | title, logo, crop, source notes
Slide 2: REVIEW | data, hierarchy, source notes
Slide 3: REVIEW | gap rows, density, source notes
Slide 4: REVIEW | connectors, labels, source notes
Slide 5: REVIEW | title, contrast, source notes
Slide 6: REVIEW | architecture, connectors, source notes
Slide 7: REVIEW | fallback order, source labels, source notes
Slide 8: REVIEW | three real screenshots, crop, readability, source notes
Slide 9: REVIEW | revenue streams, source notes
Slide 10: REVIEW | TAM SAM SOM values and scale note, source notes
Slide 11: REVIEW | phase dates and outputs, source notes
Slide 12: REVIEW | closing copy, logo, source notes
```

- [ ] **Step 9: Commit builder dan draft PPTX**

```bash
git add deck/.tmp/build.mjs deck/.tmp/qa-ledger.txt deck/Lestar-KMIPN-VIII.pptx
git commit -m "feat: bangun draft deck Art Nouveau Lestar"
```

### Task 4: Render dan QA PPTX

**Files:**
- Modify: `deck/.tmp/build.mjs`
- Modify: `deck/Lestar-KMIPN-VIII.pptx`
- Modify: `deck/.tmp/qa-ledger.txt`
- Create: `deck/.tmp/renders/slide-1.png` sampai `slide-12.png`

**Interfaces:**
- Consumes: draft PPTX dan helper render presentation skill.
- Produces: PPTX tanpa overflow/overlap serta ledger 12 slide berstatus PASS.

- [ ] **Step 1: Render seluruh slide PPTX**

Working directory: `C:/Users/ASUS/.codex/plugins/cache/openai-primary-runtime/presentations/26.826.12353/skills/presentations`

Run:

```powershell
& (Join-Path $env:RUNTIME_BIN_DIR 'python.exe') container_tools/render_slides.py 'L:\Lestar\deck\Lestar-KMIPN-VIII.pptx'
```

Jika helper ini dijalankan melalui Python runtime internal yang ditentukan dokumentasi, gunakan executable dari `RUNTIME_BIN_DIR`; jangan mencari Python global.

- [ ] **Step 2: Jalankan overflow test**

Run:

```powershell
& (Join-Path $env:RUNTIME_BIN_DIR 'python.exe') container_tools/slides_test.py 'L:\Lestar\deck\Lestar-KMIPN-VIII.pptx'
```

Expected: tidak ada elemen di luar kanvas. Setiap warning harus dilacak ke slide dan diperbaiki atau dibuktikan sebagai dekorasi yang memang sengaja bleed.

- [ ] **Step 3: Inspeksi setiap PNG pada ukuran penuh**

Gunakan image viewer untuk `slide-1.png` sampai `slide-12.png`, satu per satu. Periksa wrapping judul, crop gambar, kontras, alignment, source footers, konektor, konsistensi margin, dan apakah ornament mengganggu data. Contact sheet hanya dipakai setelah inspeksi individual untuk menilai alur keseluruhan.

- [ ] **Step 4: Perbaiki builder, ekspor ulang, dan render ulang**

Ubah sumber `.mjs`, bukan file PPTX secara manual. Ulangi build -> render -> overflow test sampai tidak ada defect. Jangan mengecilkan body di bawah 16 pt; pendekkan copy atau ubah layout.

- [ ] **Step 5: Catat PASS per slide berdasarkan render terakhir**

Gunakan format tepat berikut setelah setiap slide lulus:

```text
Slide 1: PASS | title, logo, crop, source notes
Slide 2: PASS | data, hierarchy, source notes
Slide 3: PASS | gap rows, density, source notes
Slide 4: PASS | connectors, labels, source notes
Slide 5: PASS | title, contrast, source notes
Slide 6: PASS | architecture, connectors, source notes
Slide 7: PASS | fallback order, source labels, source notes
Slide 8: PASS | three real screenshots, crop, readability, source notes
Slide 9: PASS | revenue streams, source notes
Slide 10: PASS | TAM SAM SOM values and scale note, source notes
Slide 11: PASS | phase dates and outputs, source notes
Slide 12: PASS | closing copy, logo, source notes
```

- [ ] **Step 6: Commit PPTX yang telah lulus QA**

```bash
git add deck/.tmp/build.mjs deck/.tmp/qa-ledger.txt deck/Lestar-KMIPN-VIII.pptx
git commit -m "fix: rapikan visual dan keterbacaan deck"
```

### Task 5: Ekspor, Render, dan Verifikasi PDF

**Files:**
- Create: `deck/Lestar-KMIPN-VIII.pdf`
- Create: `deck/.tmp/pdf-renders/page-01.png` sampai `page-12.png`
- Modify: `deck/tests/verify.ps1`

**Interfaces:**
- Consumes: PPTX yang seluruh slide-nya PASS.
- Produces: PDF 12 halaman yang secara visual setara dan lolos verifier.

- [ ] **Step 1: Jalankan marker authoring PDF tepat sekali sebagai command mandiri**

Working directory: `C:/Users/ASUS/.codex/plugins/cache/openai-primary-runtime/pdf/26.826.12353/skills/pdf`

Run:

```powershell
& $env:RUNTIME_NODE container_tools/mark_artifact_operation_started.mjs --operation-kind create --expected-output-count 1 --output-format pdf
```

Expected: exit code 0. Jangan menjalankan marker PDF lagi pada sesi ekspor ini.

- [ ] **Step 2: Ekspor PPTX ke PDF**

Gunakan converter yang disediakan runtime presentation (`soffice` atau wrapper export yang dinyatakan dokumentasi), dengan direktori keluaran `L:\Lestar\deck`. Rename hasil bila converter menghasilkan nama berbeda; final harus `deck/Lestar-KMIPN-VIII.pdf`.

```powershell
& (Join-Path $env:RUNTIME_BIN_DIR 'soffice.exe') --headless --convert-to pdf --outdir 'L:\Lestar\deck' 'L:\Lestar\deck\Lestar-KMIPN-VIII.pptx'
```

- [ ] **Step 3: Tambahkan assertion jumlah halaman PDF**

```powershell
$pdfInfo=& (Join-Path $env:RUNTIME_BIN_DIR 'pdfinfo.exe') (Join-Path $deckRoot 'Lestar-KMIPN-VIII.pdf')
$pagesLine=$pdfInfo | Where-Object {$_ -match '^Pages:'}
if($pagesLine -notmatch 'Pages:\s+12$'){throw "PDF harus 12 halaman; $pagesLine"}
```

- [ ] **Step 4: Render semua halaman PDF ke PNG**

```powershell
New-Item -ItemType Directory -Force -Path 'deck/.tmp/pdf-renders' | Out-Null
& (Join-Path $env:RUNTIME_BIN_DIR 'pdftoppm.exe') -png -r 160 'deck/Lestar-KMIPN-VIII.pdf' 'deck/.tmp/pdf-renders/page'
```

Expected: 12 PNG dengan urutan halaman benar.

- [ ] **Step 5: Inspeksi setiap halaman PDF pada ukuran penuh**

Periksa page 1-12 satu per satu. Bandingkan terhadap render PPTX terakhir untuk font substitution, perubahan line break, clipping, raster blur, dan connector shift. Bila ada defect, perbaiki builder/PPTX lalu ulangi export dan render PDF.

- [ ] **Step 6: Jalankan verifier final deck**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File deck/tests/verify.ps1
git diff --check
```

Expected: `Deck verification passed.` dan tidak ada error whitespace.

- [ ] **Step 7: Commit PDF terverifikasi**

```bash
git add deck/Lestar-KMIPN-VIII.pdf deck/tests/verify.ps1
git commit -m "feat: ekspor deck Lestar ke PDF terverifikasi"
```

### Task 6: Handoff Akhir Agent G

**Files:**
- Create or Modify: `docs/06-agent-briefs/G-HANDOFF.md`
- Verify: `landing/`
- Verify: `deck/`

**Interfaces:**
- Consumes: URL landing publik, hash APK, PPTX/PDF final, screenshot provenance, dan seluruh hasil QA.
- Produces: handoff final yang jujur dan dapat ditindaklanjuti pemilik proyek.

- [ ] **Step 1: Jalankan semua verifier**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File deck/tests/verify.ps1
git diff --check
```

Expected: dua verifier lulus dan diff check bersih.

- [ ] **Step 2: Tulis ringkasan akhir tanpa klaim yang belum diuji**

Gunakan struktur berikut dan isi setiap nilai dari output tool aktual sebelum menyimpan:

```markdown
# Agent G - Handoff Landing Page dan Deck

**Tanggal:** 2 September 2026

## Landing Page
- URL publik: nilai hasil deploy Vercel
- APK: `landing/public/lestar.apk`
- SHA-256: nilai hasil `Get-FileHash`
- Viewport terverifikasi: daftar ukuran yang benar-benar diperiksa

## Deck
- PowerPoint: `deck/Lestar-KMIPN-VIII.pptx`
- PDF: `deck/Lestar-KMIPN-VIII.pdf`
- Jumlah slide/halaman: 12/12
- Slide 8: sumber tiga screenshot nyata dan tanggal capture

## Keputusan Mandiri
- HTML/CSS/JavaScript statis tanpa dependency runtime.
- Botanical Art Nouveau kontemporer dengan sulur sebagai jalur nilai.
- Phosphor hanya untuk ikon utilitas; SVG khusus untuk cerita utama.
- Target 4.500 kg CO2eq/bulan dipertahankan sesuai proposal meski faktor 0,25 kg CO2eq/kg tidak konsisten.

## Aset atau Gerbang yang Belum Lulus
- Tulis `Tidak ada` bila seluruh definisi selesai benar-benar terverifikasi; jika tidak, tulis hanya gerbang faktual yang masih gagal dan cara menutupnya.
```

- [ ] **Step 3: Periksa handoff terhadap output nyata**

Pastikan URL dapat dibuka, kedua path deck ada, hash APK cocok, QA ledger memiliki 12 PASS, dan bagian aset yang belum lulus tidak menyembunyikan masalah screenshot, deploy, PDF, atau instalasi perangkat bersih.

- [ ] **Step 4: Commit handoff final**

```bash
git add docs/06-agent-briefs/G-HANDOFF.md landing deck
git commit -m "docs: serahkan hasil akhir Agent G"
```
