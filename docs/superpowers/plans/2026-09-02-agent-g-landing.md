# Agent G Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun dan menerbitkan landing page statis Botanical Art Nouveau yang menjelaskan Lestar dalam 30 detik, menyediakan APK asli, akun demo, dan panduan instalasi Android.

**Architecture:** Halaman terdiri dari satu dokumen HTML semantik, satu stylesheet, dan satu skrip progressive enhancement. Seluruh font, logo, SVG botani, tangkapan layar, dan APK disajikan sebagai aset lokal sehingga konten serta unduhan tetap bekerja tanpa JavaScript atau layanan pihak ketiga.

**Tech Stack:** HTML5, CSS3, JavaScript ES2022 tanpa dependency, SVG, PowerShell verification, Vercel static hosting.

## Global Constraints

- Hanya mengubah `landing/`, rencana ini, dan bagian landing pada `docs/06-agent-briefs/G-HANDOFF.md`.
- Jangan menyentuh `lib/`, `api/`, `ml/`, atau `supabase/`.
- Arah visual wajib Botanical Art Nouveau kontemporer sesuai `docs/superpowers/specs/2026-09-02-agent-g-art-nouveau-design.md`.
- Palet wajib `#EDE5D8`, `#FFFFFF`, `#265938`, `#009966`, `#00BC7D`, `#F38222`, `#C2540E`, `#0A0A0A`, `#171717`, `#737373`, dan `#F5F5F5`.
- Isian oranye selalu memakai teks `#0A0A0A`; `#00BC7D` tidak boleh menjadi latar teks.
- Plus Jakarta Sans dipakai untuk display dan Inter untuk body, keduanya dari aset lokal.
- Tidak ada framework, package manager, CDN font, emoji, gradient blob, glassmorphism, badge dekoratif, divider putus-putus, atau kumpulan kartu generik.
- Phosphor Outline hanya untuk ikon utilitas dan setiap ikon aksi harus disertai label.
- CTA primer halaman adalah `Unduh APK`; semua CTA lain harus lebih tenang.
- Body minimal 16 px; target sentuh minimal 44 x 44 px; focus ring 3 px; zoom browser tidak boleh dinonaktifkan.
- Halaman tidak boleh scroll horizontal pada lebar 320 px atau lebih.
- Tiga screenshot harus berupa tangkapan layar aplikasi nyata; `mockup.png` tidak boleh dipakai.
- Semua angka harus persis dari proposal; target dampak menggunakan `4.500 kg CO2eq/bulan` dan inkonsistensi faktor emisi dicatat di handoff.
- APK tujuan harus byte-identical dengan `build/app/outputs/flutter-apk/app-release.apk`.
- Pesan commit wajib Bahasa Indonesia.

---

## Struktur Berkas

```text
landing/
  index.html                    dokumen semantik dan seluruh copy
  styles.css                    token, layout, responsivitas, focus, reduced motion
  app.js                        progressive enhancement untuk reveal jalur nilai
  vercel.json                   konfigurasi static hosting dan header APK
  assets/
    logo-full.png               logo tanpa bidang kertas untuk hero
    logo-glyph.svg              glyph transparan untuk header dan favicon
    value-route.svg             sulur jalur nilai dekoratif
    cascade.svg                 diagram kaskade desktop
    cascade-mobile.svg          diagram kaskade vertikal
    fonts/
      PlusJakartaSans-wght.ttf
      Inter-opsz-wght.ttf
    screenshots/
      consumer.png
      merchant.png
      partner.png
  public/
    lestar.apk                  salinan byte-identical APK release
  tests/
    verify.ps1                  pemeriksaan struktur, copy, aset, hash, dan anti-slop
```

## Kontrak Antarmuka

- Anchor publik: `#cara-kerja`, `#aktor`, `#dampak`, dan `#unduh`.
- Jalur unduhan publik: `/public/lestar.apk`.
- Elemen progressive enhancement: `[data-reveal]`; class root setelah JavaScript aktif: `.js`.
- CSS custom properties berada pada `:root` dan tidak boleh digandakan sebagai raw hex di selector komponen.
- Screenshot memakai nama dan rasio tetap: `consumer.png`, `merchant.png`, `partner.png`.
- `landing/tests/verify.ps1` keluar dengan status 0 hanya bila seluruh aset, copy, dan hash APK benar.

### Task 1: Verification Harness dan Asset Gate

**Files:**
- Create: `landing/tests/verify.ps1`
- Create: `landing/assets/fonts/PlusJakartaSans-wght.ttf`
- Create: `landing/assets/fonts/Inter-opsz-wght.ttf`
- Create: `landing/public/lestar.apk`

**Interfaces:**
- Consumes: `assets/fonts/PlusJakartaSans[wght].ttf`, `assets/fonts/Inter[opsz,wght].ttf`, dan `build/app/outputs/flutter-apk/app-release.apk`.
- Produces: `landing/tests/verify.ps1` dan aset lokal yang dipakai semua task landing berikutnya.

- [ ] **Step 1: Tulis verifier yang gagal saat landing belum lengkap**

```powershell
$ErrorActionPreference = 'Stop'
$landingRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $landingRoot

$required = @(
  'index.html', 'styles.css', 'app.js', 'vercel.json',
  'assets/logo-full.png', 'assets/logo-glyph.svg',
  'assets/value-route.svg', 'assets/cascade.svg', 'assets/cascade-mobile.svg',
  'assets/fonts/PlusJakartaSans-wght.ttf', 'assets/fonts/Inter-opsz-wght.ttf',
  'assets/screenshots/consumer.png', 'assets/screenshots/merchant.png',
  'assets/screenshots/partner.png', 'public/lestar.apk'
)
foreach ($relative in $required) {
  $path = Join-Path $landingRoot $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Berkas wajib tidak ditemukan: $relative"
  }
}

$html = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $landingRoot 'index.html')
$css = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $landingRoot 'styles.css')
$requiredCopy = @(
  'Setiap kilogram punya jalur nilai', '14,73 juta ton',
  'Rp213-551 triliun', '7,29%', '40,76%',
  '200 merchant', '3.000 transaksi', '3.000 kg', '4.500 kg CO2eq',
  'merchant@lestar.id', 'amira@lestar.id', 'budi@lestar.id', 'lestar2026'
)
foreach ($copy in $requiredCopy) {
  if (-not $html.Contains($copy)) { throw "Copy wajib tidak ditemukan: $copy" }
}

foreach ($id in @('cara-kerja', 'aktor', 'dampak', 'unduh')) {
  if ($html -notmatch ('id="' + [regex]::Escape($id) + '"')) {
    throw "Anchor wajib tidak ditemukan: #$id"
  }
}
if ($html -match 'mockup\.png|https://fonts\.googleapis\.com|<script[^>]+src="https?://') {
  throw 'Ditemukan aset terlarang atau dependency eksternal'
}
if ($html -match '[😀-🙏]' ) { throw 'Emoji tidak boleh dipakai sebagai ikon' }
if ($css -match 'linear-gradient|radial-gradient|backdrop-filter') {
  throw 'Gradient atau glassmorphism terlarang ditemukan'
}
if ($css -notmatch 'prefers-reduced-motion' -or $css -notmatch ':focus-visible') {
  throw 'Reduced motion atau focus-visible belum diterapkan'
}

$sourceApk = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk'
$publicApk = Join-Path $landingRoot 'public/lestar.apk'
if (-not (Test-Path -LiteralPath $sourceApk -PathType Leaf)) { throw 'APK release sumber tidak ditemukan' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourceApk).Hash -ne
    (Get-FileHash -Algorithm SHA256 -LiteralPath $publicApk).Hash) {
  throw 'APK publik tidak identik dengan APK release sumber'
}
Write-Host 'Landing verification passed.'
```

- [ ] **Step 2: Jalankan verifier dan pastikan gagal pada berkas pertama yang belum ada**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: exit code non-zero dengan pesan `Berkas wajib tidak ditemukan: index.html`.

- [ ] **Step 3: Salin font dan APK tanpa mengubah byte**

```powershell
New-Item -ItemType Directory -Force -Path 'landing/assets/fonts','landing/public' | Out-Null
Copy-Item -LiteralPath 'assets/fonts/PlusJakartaSans[wght].ttf' -Destination 'landing/assets/fonts/PlusJakartaSans-wght.ttf'
Copy-Item -LiteralPath 'assets/fonts/Inter[opsz,wght].ttf' -Destination 'landing/assets/fonts/Inter-opsz-wght.ttf'
Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' -Destination 'landing/public/lestar.apk'
```

- [ ] **Step 4: Verifikasi hash APK secara terpisah**

Run:

```powershell
$a=(Get-FileHash -Algorithm SHA256 -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk').Hash
$b=(Get-FileHash -Algorithm SHA256 -LiteralPath 'landing/public/lestar.apk').Hash
if($a -ne $b){throw 'Hash APK berbeda'}
```

Expected: exit code 0 tanpa output error.

- [ ] **Step 5: Commit harness dan aset distributable**

```bash
git add landing/tests/verify.ps1 landing/assets/fonts landing/public/lestar.apk
git commit -m "test: siapkan gerbang verifikasi landing Lestar"
```

### Task 2: Logo Transparan dan SVG Jalur Nilai

**Files:**
- Create: `landing/assets/logo-full.png`
- Create: `landing/assets/logo-glyph.svg`
- Create: `landing/assets/value-route.svg`
- Create: `landing/assets/cascade.svg`
- Create: `landing/assets/cascade-mobile.svg`

**Interfaces:**
- Consumes: `assets/logo.png` dan token warna global.
- Produces: aset transparan untuk hero/header serta diagram yang direferensikan oleh `landing/index.html`.

- [ ] **Step 1: Tambahkan assertion struktur SVG ke verifier**

```powershell
foreach ($svgName in @('logo-glyph.svg','value-route.svg','cascade.svg','cascade-mobile.svg')) {
  $svgPath = Join-Path $landingRoot "assets/$svgName"
  $svg = Get-Content -Raw -Encoding UTF8 -LiteralPath $svgPath
  if ($svg -notmatch '<svg' -or $svg -match '<text') {
    throw "SVG $svgName harus berupa path tanpa text bergantung font"
  }
  if ($svg -match '#12C56A|stroke-dasharray') {
    throw "SVG $svgName memakai warna atau divider terlarang"
  }
}
```

- [ ] **Step 2: Jalankan verifier dan pastikan gagal karena aset logo/SVG belum ada**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: exit code non-zero pada `assets/logo-full.png`.

- [ ] **Step 3: Buat logo transparan dari logo sumber dengan alat raster yang tersedia**

Gunakan tool image editing untuk membuang bidang paper dan bayangan tanpa mengubah warna `#265938` serta `#F38222`. Ekspor PNG transparan minimal 1200 x 1200 ke `landing/assets/logo-full.png`. Inspeksi hasil pada latar putih dan `#EDE5D8`; tidak boleh ada kotak krem atau halo abu-abu.

- [ ] **Step 4: Buat glyph dan jalur nilai sebagai SVG khusus**

Gunakan struktur berikut untuk semua SVG: `viewBox` eksplisit, `fill="none"`, stroke rounded, `aria-hidden="true"` saat dipasang sebagai dekorasi. `logo-glyph.svg` menyederhanakan infinity menjadi dua loop dan maksimum tiga daun. `value-route.svg` berisi satu sulur kontinu dan buah oranye kecil. Tidak ada teks, filter, blur, atau library ikon.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 420" fill="none">
  <path d="M36 264C180 68 318 72 470 220C602 348 742 344 908 176C1014 68 1092 92 1164 166"
        stroke="#265938" stroke-width="8" stroke-linecap="round"/>
  <path d="M238 159C270 112 316 104 351 121C326 158 284 177 238 159Z" fill="#265938"/>
  <circle cx="470" cy="220" r="13" fill="#F38222"/>
</svg>
```

- [ ] **Step 5: Buat diagram kaskade desktop dan mobile**

`cascade.svg` memakai alur kiri-ke-kanan dengan percabangan sesudah gerbang Validasi Fisik. `cascade-mobile.svg` memakai alur atas-ke-bawah. Label diagram ditulis di HTML sebagai daftar semantik yang ditumpuk di atas SVG background; SVG sendiri hanya membawa garis dan bentuk sehingga tetap tajam dan mudah diakses.

- [ ] **Step 6: Jalankan verifier dan inspeksi seluruh aset**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: kegagalan berikutnya berpindah ke `assets/screenshots/consumer.png`, membuktikan aset logo/SVG sudah melewati gate.

- [ ] **Step 7: Commit aset brand dan diagram**

```bash
git add landing/assets/logo-full.png landing/assets/logo-glyph.svg landing/assets/value-route.svg landing/assets/cascade.svg landing/assets/cascade-mobile.svg landing/tests/verify.ps1
git commit -m "feat: buat bahasa visual Art Nouveau Lestar"
```

### Task 3: Dokumen Semantik dan Copy Proposal

**Files:**
- Create: `landing/index.html`
- Create: `landing/vercel.json`
- Modify: `landing/tests/verify.ps1`

**Interfaces:**
- Consumes: anchor contract, aset Task 1-2, dan angka proposal.
- Produces: halaman yang seluruh kontennya dapat dibaca tanpa CSS/JavaScript dan deployable sebagai static site.

- [ ] **Step 1: Tambahkan assertion semantik dan urutan section**

```powershell
$orderedMarkers = @(
  '<main id="konten-utama">', '<section class="hero"',
  'id="masalah"', 'id="cara-kerja"', 'id="aktor"',
  'id="buffer"', 'id="dampak"', 'id="unduh"'
)
$cursor = -1
foreach ($marker in $orderedMarkers) {
  $next = $html.IndexOf($marker, $cursor + 1, [System.StringComparison]::Ordinal)
  if ($next -lt 0) { throw "Marker semantik hilang atau salah urutan: $marker" }
  $cursor = $next
}
if (($html | Select-String -Pattern '<h1[ >]' -AllMatches).Matches.Count -ne 1) {
  throw 'Halaman harus memiliki tepat satu h1'
}
if ($html -notmatch 'href="#konten-utama"') { throw 'Skip link tidak ditemukan' }
if ($html -notmatch 'href="/public/lestar\.apk"[^>]*download') { throw 'Tautan APK tidak valid' }
```

- [ ] **Step 2: Jalankan verifier dan pastikan gagal karena `index.html` belum ada**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: exit code non-zero pada `index.html`.

- [ ] **Step 3: Tulis `index.html` dengan struktur dan copy final**

Gunakan kerangka berikut dan isi setiap section dengan copy persis dari spec. Setiap `<img>` memiliki `width`, `height`, dan alt text; dekorasi SVG memakai `alt=""` atau `aria-hidden="true"`.

```html
<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#EDE5D8">
  <title>Lestar - Setiap kilogram punya jalur nilai</title>
  <meta name="description" content="Lestar menghubungkan merchant F&B, konsumen, dan pengolah limbah organik dalam satu alur kaskade.">
  <link rel="icon" href="assets/logo-glyph.svg" type="image/svg+xml">
  <link rel="stylesheet" href="styles.css">
  <script>document.documentElement.classList.add('js')</script>
  <script src="app.js" defer></script>
</head>
<body>
  <a class="skip-link" href="#konten-utama">Lewati ke konten utama</a>
  <header class="site-header" aria-label="Navigasi utama">
    <a class="wordmark" href="#top" aria-label="Lestar, kembali ke awal"><img src="assets/logo-glyph.svg" width="44" height="32" alt=""><span>Lestar</span></a>
    <nav><a href="#cara-kerja">Cara kerja</a><a href="#dampak">Dampak</a><a class="button button--compact" href="/public/lestar.apk" download>Unduh APK</a></nav>
  </header>
  <main id="konten-utama">
    <section class="hero" id="top"><div class="hero__copy"><p class="eyebrow">Ekonomi sirkular tiga sisi</p><h1>Setiap kilogram punya jalur nilai</h1><p>Platform ekonomi sirkular yang menghubungkan merchant F&B, konsumen, dan pengolah limbah organik dalam satu alur kaskade.</p><div class="hero__actions"><a class="button" href="/public/lestar.apk" download>Unduh APK</a><a class="text-link" href="#cara-kerja">Lihat cara kerjanya <span aria-hidden="true">→</span></a></div></div><img class="hero__logo" src="assets/logo-full.png" width="1200" height="1200" alt="Logo Lestar berbentuk infinity dari sulur, daun, dan buah"></section>
    <section id="masalah" aria-labelledby="masalah-title"><h2 id="masalah-title">Nilai pangan hilang dalam skala nasional</h2></section>
    <section id="cara-kerja" aria-labelledby="kaskade-title"><h2 id="kaskade-title">Satu surplus, dua jalur pemulihan</h2></section>
    <section id="aktor" aria-labelledby="aktor-title"><h2 id="aktor-title">Tiga dunia kerja, tiga antarmuka</h2></section>
    <section id="buffer" aria-labelledby="buffer-title"><h2 id="buffer-title">Mencegah sebelum memulihkan</h2></section>
    <section id="dampak" aria-labelledby="dampak-title"><h2 id="dampak-title">Target 12 bulan yang dapat diukur</h2></section>
    <section id="unduh" aria-labelledby="unduh-title"><h2 id="unduh-title">Coba Lestar di Android</h2></section>
  </main>
  <footer><p>Lestar · Dimulai dari Malang, dikembangkan menuju skala nasional.</p></footer>
</body>
</html>
```

- [ ] **Step 4: Masukkan seluruh angka, kaskade, tiga aktor, dampak, instalasi, dan kredensial**

Gunakan `<dl>` untuk empat angka masalah dan target dampak; `<ol>` untuk alur kaskade serta instruksi instalasi; `<article>` hanya untuk tiga aktor. Sumber masalah ditulis `UNEP Food Waste Index 2024 · KLHK 2025`. Jangan menambah klaim selain proposal.

- [ ] **Step 5: Tulis konfigurasi Vercel dengan header APK**

```json
{
  "cleanUrls": true,
  "trailingSlash": false,
  "headers": [
    {
      "source": "/public/lestar.apk",
      "headers": [
        { "key": "Content-Type", "value": "application/vnd.android.package-archive" },
        { "key": "Content-Disposition", "value": "attachment; filename=lestar.apk" },
        { "key": "Cache-Control", "value": "public, max-age=3600" }
      ]
    }
  ]
}
```

- [ ] **Step 6: Jalankan verifier**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: hanya gagal pada screenshot atau stylesheet/script yang belum selesai; tidak ada kegagalan copy dan struktur HTML.

- [ ] **Step 7: Commit struktur dan copy landing**

```bash
git add landing/index.html landing/vercel.json landing/tests/verify.ps1
git commit -m "feat: susun cerita dan data landing Lestar"
```

### Task 4: Styling, Progressive Enhancement, dan Screenshot Nyata

**Files:**
- Create: `landing/styles.css`
- Create: `landing/app.js`
- Create: `landing/assets/screenshots/consumer.png`
- Create: `landing/assets/screenshots/merchant.png`
- Create: `landing/assets/screenshots/partner.png`
- Modify: `landing/index.html`
- Modify: `landing/tests/verify.ps1`

**Interfaces:**
- Consumes: HTML Task 3, aset visual Task 2, dan tiga screenshot aplikasi nyata.
- Produces: layout mobile-first, motion aman, serta section tiga aktor siap dipakai deck.

- [ ] **Step 1: Tambahkan assertion CSS dan metadata screenshot**

```powershell
$cssTokens = @('--paper:#EDE5D8','--forest:#265938','--emerald-deep:#009966','--orange:#F38222','--ink:#0A0A0A')
$compactCss = $css -replace '\s',''
foreach ($token in $cssTokens) {
  if (-not $compactCss.Contains($token)) { throw "Token CSS hilang: $token" }
}
foreach ($width in @('320px','768px','1024px','1440px')) {
  if (-not $css.Contains($width)) { throw "Strategi viewport tidak mencakup $width" }
}
foreach ($shot in @('consumer','merchant','partner')) {
  if ($html -notmatch ("assets/screenshots/$shot\.png")) { throw "Screenshot $shot belum dipasang" }
}
```

- [ ] **Step 2: Jalankan verifier dan pastikan gagal karena CSS/screenshot belum lengkap**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: exit code non-zero pada aset screenshot pertama atau token CSS pertama.

- [ ] **Step 3: Sediakan tiga screenshot aplikasi nyata**

Ambil layar utama konsumen, merchant, dan pengepul dari build aplikasi yang berjalan. Potong hanya status bar/perangkat bila perlu; jangan mengubah isi UI. Simpan sebagai PNG dengan tinggi seragam dan catat sumber/tanggal capture di handoff. Jika perangkat tidak tersedia, hentikan klaim selesai pada task ini; jangan memakai `mockup.png`.

- [ ] **Step 4: Tulis token dan layout mobile-first di `styles.css`**

```css
@font-face{font-family:"Plus Jakarta Sans";src:url("assets/fonts/PlusJakartaSans-wght.ttf") format("truetype");font-weight:200 800;font-display:swap}
@font-face{font-family:Inter;src:url("assets/fonts/Inter-opsz-wght.ttf") format("truetype");font-weight:100 900;font-display:swap}
:root{--paper:#EDE5D8;--white:#FFFFFF;--forest:#265938;--emerald-deep:#009966;--emerald:#00BC7D;--orange:#F38222;--orange-text:#C2540E;--ink:#0A0A0A;--ink-soft:#171717;--muted:#737373;--surface-grey:#F5F5F5;--space-1:.5rem;--space-2:1rem;--space-3:1.5rem;--space-4:2rem;--space-5:3rem;--space-6:4.5rem;--max:76rem}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--white);color:var(--ink);font:400 1rem/1.65 Inter,system-ui,sans-serif;overflow-x:hidden}
h1,h2,h3,.wordmark,.button{font-family:"Plus Jakarta Sans",system-ui,sans-serif}
a{color:inherit}.skip-link{position:fixed;left:1rem;top:1rem;z-index:1000;transform:translateY(-160%)}.skip-link:focus{transform:none}
:focus-visible{outline:3px solid var(--orange);outline-offset:4px}
.button{display:inline-flex;min-height:44px;align-items:center;justify-content:center;padding:.75rem 1.25rem;background:var(--emerald-deep);color:var(--white);font-weight:700;text-decoration:none;border:2px solid var(--emerald-deep);border-radius:.4rem;touch-action:manipulation}
.button:active{transform:scale(.98)}
.hero{min-height:100dvh;background:var(--paper);display:grid;align-items:center;padding:7rem max(1.25rem,calc((100vw - var(--max))/2)) 4rem;position:relative}
.hero__copy{max-width:42rem;position:relative;z-index:2}.hero__logo{width:min(80vw,34rem);height:auto;justify-self:center}
section{padding:var(--space-6) max(1.25rem,calc((100vw - var(--max))/2))}
@media (min-width:320px){.hero__actions{display:flex;flex-wrap:wrap;gap:1rem}}
@media (min-width:768px){.hero{grid-template-columns:1.1fr .9fr}.actors{grid-template-columns:repeat(3,minmax(0,1fr))}}
@media (min-width:1024px){section{padding-block:7rem}}
@media (min-width:1440px){:root{--max:82rem}}
@media (prefers-reduced-motion:reduce){*,*::before,*::after{scroll-behavior:auto!important;animation-duration:.01ms!important;animation-iteration-count:1!important;transition-duration:.01ms!important}}
```

- [ ] **Step 5: Selesaikan komposisi editorial dan pola Art Nouveau**

Masalah memakai `<dl>` asimetris tanpa container kartu. Diagram kaskade memakai garis SVG di belakang daftar node. Tiga aktor menjadi satu komposisi triptych dengan garis lengkung tipis, bukan tiga rounded cards. Section dampak memakai satu baseline horizontal pada desktop dan daftar vertikal pada mobile. Semua ornament memakai `pointer-events:none`.

- [ ] **Step 6: Tulis progressive enhancement di `app.js`**

```js
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
if (!reduceMotion && 'IntersectionObserver' in window) {
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    }
  }, { threshold: 0.18 });
  document.querySelectorAll('[data-reveal]').forEach((node) => observer.observe(node));
} else {
  document.querySelectorAll('[data-reveal]').forEach((node) => node.classList.add('is-visible'));
}
```

- [ ] **Step 7: Jalankan verifier sampai lulus**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1`

Expected: `Landing verification passed.`

- [ ] **Step 8: Commit halaman responsif dan screenshot**

```bash
git add landing/index.html landing/styles.css landing/app.js landing/assets/screenshots landing/tests/verify.ps1
git commit -m "feat: selesaikan landing Art Nouveau responsif"
```

### Task 5: Visual QA, Local Delivery, dan Deploy Vercel

**Files:**
- Modify: `landing/index.html`
- Modify: `landing/styles.css`
- Modify: `landing/app.js`
- Modify: `landing/tests/verify.ps1`
- Modify: `docs/06-agent-briefs/G-HANDOFF.md`

**Interfaces:**
- Consumes: landing lengkap dari Task 1-4 dan koneksi Vercel yang tersedia.
- Produces: halaman publik terverifikasi, URL deploy, dan bukti QA landing pada handoff.

- [ ] **Step 1: Jalankan pemeriksaan otomatis final**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1
git diff --check
```

Expected: verifier mencetak `Landing verification passed.` dan `git diff --check` tidak mengeluarkan error.

- [ ] **Step 2: Buka halaman dan periksa matriks viewport**

Gunakan browser untuk membuka `landing/index.html` atau server statis yang tersedia. Inspeksi pada 320 x 800, 375 x 812, 768 x 1024, 1024 x 768, dan 1440 x 900. Pada setiap ukuran, pastikan tidak ada scroll horizontal, teks bertumpuk, screenshot terpotong, ornament menutup konten, atau CTA keluar viewport.

- [ ] **Step 3: Periksa keyboard, contrast, dan reduced motion**

Navigasi seluruh link dengan Tab dari skip link hingga footer; urutan harus mengikuti visual dan focus ring terlihat. Aktifkan `prefers-reduced-motion: reduce`; semua konten harus langsung terlihat. Periksa pasangan teks: ink/white, forest/white, ink/orange, orange-text/white, dan white/emerald-deep sesuai tabel kontras design system.

- [ ] **Step 4: Deploy folder `landing/` ke Vercel**

Gunakan koneksi MCP Vercel yang tersedia dan set root deploy ke `landing/`. Jika status `Needs authentication`, berhenti pada deploy saja dan minta pemilik menjalankan `/mcp` -> `plugin:vercel:vercel` -> authenticate; jangan meminta atau menulis token.

- [ ] **Step 5: Uji URL publik dan APK**

Buka URL publik pada desktop dan mobile. Pastikan respons halaman 200, `/public/lestar.apk` dapat diunduh, nama berkas `lestar.apk`, content type `application/vnd.android.package-archive`, dan ukuran unduhan sama dengan berkas lokal.

- [ ] **Step 6: Catat hasil landing di handoff**

Tambahkan bagian berikut dengan nilai hasil aktual, tanpa mengklaim gerbang yang belum dilakukan. Ambil URL dari hasil deploy, hash dari `Get-FileHash`, dan perangkat/tanggal dari log capture pada langkah sebelumnya:

```markdown
## Landing Page

- URL publik: nilai URL yang dikembalikan Vercel
- Sumber APK: `build/app/outputs/flutter-apk/app-release.apk`
- APK publik: `landing/public/lestar.apk`
- SHA-256: nilai SHA-256 aktual
- Viewport terverifikasi: 320, 375, 768, 1024, 1440 px
- Screenshot aplikasi: consumer/merchant/partner, beserta perangkat aktual dan tanggal capture
- Catatan angka proposal: target 4.500 kg CO2eq/bulan dipertahankan; faktor 0,25 kg CO2eq/kg di proposal tidak konsisten dengan target tersebut.
```

Saat eksekusi, jangan menyalin frasa instruksional `nilai ...` ke handoff; tulis data yang dikembalikan tool pada langkah yang sama.

- [ ] **Step 7: Commit deploy metadata dan handoff landing**

```bash
git add landing docs/06-agent-briefs/G-HANDOFF.md
git commit -m "docs: serahkan landing publik Lestar"
```
