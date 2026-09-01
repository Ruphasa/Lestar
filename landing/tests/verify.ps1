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
if (-not (Test-Path -LiteralPath $sourceApk -PathType Leaf)) {
  $configuredSource = $env:LESTAR_RELEASE_APK_SOURCE
  if ([string]::IsNullOrWhiteSpace($configuredSource) -or
      -not (Test-Path -LiteralPath $configuredSource -PathType Leaf)) {
    throw 'APK release sumber tidak ditemukan; set LESTAR_RELEASE_APK_SOURCE ke file APK yang ada'
  }
  $sourceApk = $configuredSource
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourceApk).Hash -ne
    (Get-FileHash -Algorithm SHA256 -LiteralPath $publicApk).Hash) {
  throw 'APK publik tidak identik dengan APK release sumber'
}
Write-Host 'Landing verification passed.'
