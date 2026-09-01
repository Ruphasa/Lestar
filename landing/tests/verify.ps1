$ErrorActionPreference = 'Stop'
$landingRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $landingRoot

$required = @(
  'assets/logo-full.png', 'assets/logo-glyph.svg',
  'assets/value-route.svg', 'assets/cascade.svg', 'assets/cascade-mobile.svg',
  'assets/screenshots/consumer.png', 'assets/screenshots/merchant.png',
  'assets/screenshots/partner.png',
  'index.html', 'styles.css', 'app.js', 'vercel.json',
  'assets/fonts/PlusJakartaSans-wght.ttf', 'assets/fonts/Inter-opsz-wght.ttf',
  'public/lestar.apk'
)
foreach ($relative in $required) {
  $path = Join-Path $landingRoot $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Berkas wajib tidak ditemukan: $relative"
  }
}

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
if ($html -match 'mockup\.png|https://fonts\.googleapis\.com|<script[^>]+src="https?://') {
  throw 'Ditemukan aset terlarang atau dependency eksternal'
}
# Unicode surrogate-pair range for emoji, kept ASCII-safe for Windows PowerShell.
if ($html -match '[\uD83D-\uD83E][\uDC00-\uDFFF]' ) { throw 'Emoji tidak boleh dipakai sebagai ikon' }
if ($css -match 'linear-gradient|radial-gradient|backdrop-filter') {
  throw 'Gradient atau glassmorphism terlarang ditemukan'
}
if ($css -notmatch 'prefers-reduced-motion' -or $css -notmatch ':focus-visible') {
  throw 'Reduced motion atau focus-visible belum diterapkan'
}

$sourceApk = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk'
$publicApk = Join-Path $landingRoot 'public/lestar.apk'
function Test-ValidApkSource {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
  return (Get-Item -LiteralPath $Path).Length -gt 0
}

if (-not (Test-ValidApkSource $sourceApk)) {
  $configuredSource = $env:LESTAR_RELEASE_APK_SOURCE
  if ([string]::IsNullOrWhiteSpace($configuredSource) -or
      -not (Test-ValidApkSource $configuredSource)) {
    throw 'APK release sumber tidak ditemukan; set LESTAR_RELEASE_APK_SOURCE ke file APK yang ada'
  }
  $sourceApk = $configuredSource
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourceApk).Hash -ne
    (Get-FileHash -Algorithm SHA256 -LiteralPath $publicApk).Hash) {
  throw 'APK publik tidak identik dengan APK release sumber'
}
Write-Host 'Landing verification passed.'
