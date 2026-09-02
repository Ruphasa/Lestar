$ErrorActionPreference = 'Stop'
$landingRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $landingRoot

$required = @(
  'assets/logo-full.png', 'assets/logo-glyph.svg',
  'assets/value-route.svg', 'assets/cascade.svg', 'assets/cascade-mobile.svg',
  'index.html',
  'assets/screenshots/consumer.png', 'assets/screenshots/merchant.png',
  'assets/screenshots/partner.png',
  'styles.css', 'app.js', 'vercel.json',
  'assets/fonts/PlusJakartaSans-wght.ttf', 'assets/fonts/Inter-opsz-wght.ttf',
  'public/lestar.apk'
)
foreach ($relative in $required) {
  $path = Join-Path $landingRoot $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Berkas wajib tidak ditemukan: $relative"
  }
}

foreach ($shot in @('consumer','merchant','partner')) {
  $shotPath = Join-Path $landingRoot "assets/screenshots/$shot.png"
  $bytes = [System.IO.File]::ReadAllBytes($shotPath)
  if ($bytes.Length -lt 33 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80 -or
      $bytes[2] -ne 78 -or $bytes[3] -ne 71) {
    throw "Screenshot $shot bukan PNG valid"
  }
  $width = ((([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor
    ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]))
  $height = ((([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor
    ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]))
  if ($width -ne 1080 -or $height -ne 2400) {
    throw "Screenshot $shot harus 1080x2400; ditemukan ${width}x${height}"
  }
}
$approvedMerchantSha256 = '8C9FF46F7E4E3C91BACFAE4B77D4A7EC5F4C6FB73D14A08A0F0B897EC5D698B0'
$merchantSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $landingRoot 'assets/screenshots/merchant.png')).Hash.ToUpperInvariant()
if ($merchantSha256 -ne $approvedMerchantSha256) {
  throw "Screenshot merchant harus cocok dengan capture terautentik yang disetujui; ditemukan $merchantSha256"
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
$aktorSection = [regex]::Match(
  $html,
  '<section\b[^>]*\bid\s*=\s*["'']aktor["''][^>]*>(?<content>.*?)</section>',
  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $aktorSection.Success) { throw 'Section #aktor tidak ditemukan' }
$aktorArticleCount = [regex]::Matches(
  $aktorSection.Groups['content'].Value,
  '<article\b',
  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
).Count
if ($aktorArticleCount -ne 3) {
  throw "Section #aktor harus memiliki tepat tiga article; ditemukan: $aktorArticleCount"
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
  $shotPattern = 'assets/screenshots/{0}\.png["''][^>]*width=["'']1080["''][^>]*height=["'']2400["'']' -f $shot
  $reverseShotPattern = 'width=["'']1080["''][^>]*height=["'']2400["''][^>]*assets/screenshots/{0}\.png' -f $shot
  if ($html -notmatch $shotPattern -and $html -notmatch $reverseShotPattern) {
    throw "Screenshot $shot wajib memiliki dimensi eksplisit 1080x2400"
  }
}
if ($html -notmatch 'loading="lazy"' -or $html -notmatch '<img[^>]+alt="[^"]+"') {
  throw 'Gambar screenshot wajib memiliki lazy loading dan alt text deskriptif'
}
if ($html -match 'mockup\.png') { throw 'mockup.png tidak boleh dipakai' }
if ($css -match 'body\s*\{[^}]*overflow-x\s*:\s*(hidden|clip)') {
  throw 'Body tidak boleh menyamarkan overflow horizontal'
}
if ($compactCss -match '(?:html|body)\{[^}]*min-width:') {
  throw 'Root tidak boleh memakai min-width yang menciptakan overflow saat scrollbar desktop hadir'
}
foreach ($originRule in @(
  '\.hero::before\{[^}]*transform-origin:rightbottom',
  '\.hero::after\{[^}]*transform-origin:righttop',
  '\.buffer::after\{[^}]*transform-origin:righttop',
  '\.download::before\{[^}]*transform-origin:righttop'
)) {
  if ($compactCss -notmatch $originRule) {
    throw "Anchor transform ornamen kanan hilang: $originRule"
  }
}
foreach ($responsiveRule in @('min-width:0','min-width:320px','overflow-wrap:break-word')) {
  if ($css -notmatch [regex]::Escape($responsiveRule)) {
    throw "Perlindungan min-content/wrapping responsif hilang: $responsiveRule"
  }
}
if ($html -notmatch 'data-hero-vine' -or $css -notmatch 'vine-draw' -or
    $css -notmatch 'cascade-node') {
  throw 'Motion sulur hero atau reveal node kaskade belum lengkap'
}
if ($css -notmatch '\.js \[data-reveal\]' -or $css -notmatch '\.js \.cascade\.is-visible') {
  throw 'Reveal harus menjadi progressive enhancement agar tetap terbaca tanpa JavaScript'
}
$bufferEyebrowRules = @([regex]::Matches($css, '(?<selector>[^{}]+)\{(?<body>[^{}]*)\}') |
  Where-Object {
    $_.Groups['selector'].Value -match '(?m)(?:^|,)\s*\.buffer\s+\.eyebrow\s*(?:,|$)' -and
      $_.Groups['body'].Value -match '(?m)(?:^|;)\s*color\s*:\s*var\(\s*--white\s*\)\s*(?:;|$)'
  })
if ($bufferEyebrowRules.Count -eq 0) {
  throw 'Selector .buffer .eyebrow harus mendeklarasikan color:var(--white)'
}
$bufferCodeNode = [regex]::Match(
  $html,
  '<section\b[^>]*\bid\s*=\s*["'']buffer["''][^>]*>.*?<code>\s*forecasts\.source\s*</code>.*?</section>',
  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $bufferCodeNode.Success) {
  throw 'Inline code forecasts.source harus berada di section #buffer'
}
$bufferCodeRules = @([regex]::Matches($css, '(?<selector>[^{}]+)\{(?<body>[^{}]*)\}') |
  Where-Object {
    $_.Groups['selector'].Value -match '(?m)(?:^|,)\s*\.buffer\s+code\s*(?:,|$)' -and
      $_.Groups['body'].Value -match '(?m)(?:^|;)\s*color\s*:\s*var\(\s*--ink\s*\)\s*(?:;|$)'
  })
if ($bufferCodeRules.Count -eq 0) {
  throw 'Selector .buffer code harus mendeklarasikan color:var(--ink)'
}
$codeBackgroundRules = @([regex]::Matches($css, '(?<selector>[^{}]+)\{(?<body>[^{}]*)\}') |
  Where-Object {
    $_.Groups['selector'].Value -match '(?m)(?:^|,)\s*code\s*(?:,|$)' -and
      $_.Groups['body'].Value -match '(?m)(?:^|;)\s*background\s*:\s*var\(\s*--surface-grey\s*\)\s*(?:;|$)'
  })
if ($codeBackgroundRules.Count -eq 0) {
  throw 'Selector code harus mendeklarasikan background:var(--surface-grey)'
}
$cssTokenHex = @{}
foreach ($tokenMatch in [regex]::Matches($css, '(?<![\w-])(?<token>--[a-z-]+)\s*:\s*(?<hex>#[0-9a-fA-F]{6})')) {
  $cssTokenHex[$tokenMatch.Groups['token'].Value] = $tokenMatch.Groups['hex'].Value
}
function Get-RelativeLuminance {
  param([string]$Hex)
  $channels = 1..3 | ForEach-Object {
    $channel = [Convert]::ToInt32($Hex.Substring($_ * 2 - 1, 2), 16) / 255
    if ($channel -le 0.03928) { $channel / 12.92 } else { [Math]::Pow(($channel + 0.055) / 1.055, 2.4) }
  }
  return (0.2126 * $channels[0]) + (0.7152 * $channels[1]) + (0.0722 * $channels[2])
}
function Get-ContrastRatio {
  param([string]$ForegroundToken, [string]$BackgroundToken)
  if (-not $cssTokenHex.ContainsKey($ForegroundToken) -or -not $cssTokenHex.ContainsKey($BackgroundToken)) {
    throw "Token kontras tidak ditemukan: $ForegroundToken / $BackgroundToken"
  }
  $foreground = Get-RelativeLuminance $cssTokenHex[$ForegroundToken]
  $background = Get-RelativeLuminance $cssTokenHex[$BackgroundToken]
  $lighter = [Math]::Max($foreground, $background)
  $darker = [Math]::Min($foreground, $background)
  return (($lighter + 0.05) / ($darker + 0.05))
}
foreach ($pair in @(
    @('--paper', '--forest'),
    @('--paper', '--ink'),
    @('--forest', '--white'),
    @('--ink', '--surface-grey')
  )) {
  if ((Get-ContrastRatio $pair[0] $pair[1]) -lt 4.5) {
    throw "Kontras token gagal WCAG: $($pair[0]) / $($pair[1])"
  }
}
$hoverRules = @([regex]::Matches($css, '(?<selector>[^{}]*:hover[^{}]*)\{(?<body>[^{}]*)\}') |
  Where-Object { $_.Groups['selector'].Value -match 'nav|\.text-link' -and $_.Groups['body'].Value -match 'color\s*:' })
if ($hoverRules.Count -eq 0) { throw 'Hover nav/text-link tidak ditemukan' }
foreach ($rule in $hoverRules) {
  $hoverColor = [regex]::Match($rule.Groups['body'].Value, 'color\s*:\s*var\((?<token>--[a-z-]+)\)')
  if (-not $hoverColor.Success -or (Get-ContrastRatio $hoverColor.Groups['token'].Value '--paper') -lt 4.5) {
    throw 'Hover nav/text-link harus memiliki kontras minimal 4.5:1 terhadap paper'
  }
}
$vineRules = @([regex]::Matches($css, '(?<selector>[^{}]+)\{(?<body>[^{}]*)\}') |
  Where-Object { $_.Groups['selector'].Value -match '\.hero__vine' -and $_.Groups['body'].Value -match 'animation\s*:' })
if ($vineRules.Count -eq 0) { throw 'Deklarasi animasi sulur hero tidak ditemukan' }
foreach ($rule in $vineRules) {
  foreach ($animation in [regex]::Matches($rule.Groups['body'].Value, 'animation\s*:\s*(?<value>[^;}]*)')) {
    $times = [regex]::Matches($animation.Groups['value'].Value, '(?<time>[0-9]+(?:\.[0-9]+)?)ms\b')
    if ($times.Count -lt 1) { throw 'Setiap animasi sulur hero harus memiliki durasi ms' }
    $duration = [double]$times[0].Groups['time'].Value
    $delay = if ($times.Count -gt 1) { [double]$times[1].Groups['time'].Value } else { 0 }
    if (($duration + $delay) -gt 400) {
      throw "Total delay + durasi animasi sulur hero harus <= 400ms: $($duration + $delay)ms"
    }
  }
}
$cascadeDelays = [regex]::Matches($css, '\.js \.cascade\.is-visible \.cascade__steps>li:nth-child\(\d+\)\{animation-delay:(?<delay>[0-9.]+)ms')
if ($cascadeDelays.Count -ne 5) { throw 'Lima delay node kaskade wajib didefinisikan eksplisit' }
$previousDelay = $null
foreach ($match in $cascadeDelays) {
  $delay = [double]$match.Groups['delay'].Value
  if ($null -ne $previousDelay) {
    $increment = $delay - $previousDelay
    if ($increment -lt 30 -or $increment -gt 50) { throw 'Increment delay node kaskade harus antara 30ms dan 50ms' }
  }
  $previousDelay = $delay
}
if ($css -notmatch '\.button\{[^}]*background:var\(--forest\);color:var\(--white\)' -or
    $css -match 'background:var\(--emerald-deep\);color:var\(--white\)') {
  throw 'CTA tidak memakai pasangan kontras yang dapat diakses'
}
if ($css -notmatch '\.privacy-note a,footer a\{display:inline-flex;min-height:44px') {
  throw 'Tautan privasi/footer belum memiliki target sentuh 44px'
}
$app = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $landingRoot 'app.js')
if ($app -notmatch 'IntersectionObserver' -or $app -notmatch 'prefers-reduced-motion' -or
    $app -notmatch 'data-reveal') {
  throw 'Progressive enhancement reveal belum lengkap'
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
