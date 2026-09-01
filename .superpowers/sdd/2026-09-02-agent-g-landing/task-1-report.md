# Task 1 — Verification Harness dan Asset Gate

## Implementasi

- Menambahkan `landing/tests/verify.ps1` dengan pemeriksaan berkas wajib, copy wajib, anchor, dependency/aset eksternal, emoji ikon, gradient/glassmorphism, reduced-motion, `:focus-visible`, dan identitas SHA-256 APK.
- Menyalin font secara byte-preserving:
  - `assets/fonts/PlusJakartaSans[wght].ttf` → `landing/assets/fonts/PlusJakartaSans-wght.ttf`
  - `assets/fonts/Inter[opsz,wght].ttf` → `landing/assets/fonts/Inter-opsz-wght.ttf`
- Menyalin APK release ke `landing/public/lestar.apk`. Worktree ini tidak membawa output ignored `build/`; sumber yang tersedia dipakai dari `L:\Lestar\build\app\outputs\flutter-apk\app-release.apk` sesuai arahan parent.
- Baris regex emoji ditulis ASCII-safe (`\uD83D-\uD83E` dan `\uDC00-\uDFFF`) agar dapat diparse Windows PowerShell tanpa mengubah perilaku pemeriksaan.

## RED/GREEN TDD evidence

### RED — verifier pada landing yang belum lengkap

Perintah:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1
```

Output relevan:

```text
Berkas wajib tidak ditemukan: index.html
```

Exit code: `1` (sesuai ekspektasi Step 2).

### GREEN — hash APK distributable

Perintah:

```powershell
$a=(Get-FileHash -Algorithm SHA256 -LiteralPath 'L:\Lestar\build\app\outputs\flutter-apk\app-release.apk').Hash
$b=(Get-FileHash -Algorithm SHA256 -LiteralPath 'landing/public/lestar.apk').Hash
if($a -ne $b){throw 'Hash APK berbeda'}
```

Output error: tidak ada; exit code `0`.

SHA-256 sumber dan salinan: `75A664EDCDDE630A75971F858968D2A4F3C10B46A557CA1BCA7FC8998CA9ABCB`.

Verifier penuh belum dapat GREEN karena halaman landing (index, CSS, JS, konfigurasi, logo, ilustrasi, dan screenshot) memang belum dibuat oleh task lanjutan; verifier berhenti pada berkas pertama yang hilang sesuai desain gate.

## Berkas changed

- `landing/tests/verify.ps1`
- `landing/assets/fonts/PlusJakartaSans-wght.ttf`
- `landing/assets/fonts/Inter-opsz-wght.ttf`
- `landing/public/lestar.apk`

## Self-review

- Jalur file verifier dihitung relatif terhadap lokasi script sehingga dapat dipanggil dari root repo.
- Semua aset biner dicopy tanpa transformasi dan hash font/APK cocok dengan sumber.
- APK ditambahkan dengan `git add -f` karena aturan `.gitignore` mengabaikan APK distributable.
- Commit: `68379c3` — `test: siapkan gerbang verifikasi landing Lestar`.

## Concerns

- `android/.kotlin/sessions/` muncul sebagai untracked artifact dari percobaan `flutter build apk --release`; tidak dimasukkan ke commit.
- Verifikasi penuh bergantung pada berkas landing dari task berikutnya.

## Fix round 1/5

- `verify.ps1` kini memilih APK dari path worktree-relative terlebih dahulu. Jika output ignored tersebut tidak tersedia, verifier memakai `LESTAR_RELEASE_APK_SOURCE` hanya bila variabel itu menunjuk ke file yang ada; bila keduanya tidak ada, error menjelaskan cara memperbaikinya. Pemeriksaan SHA-256 tetap tidak berubah.
- Koreksi: commit Task 1 yang direview adalah `d260808`, bukan `68379c3`.

Evidence fix:

```text
# powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1
Berkas wajib tidak ditemukan: index.html
EXIT=1

# LESTAR_RELEASE_APK_SOURCE=L:\Lestar\build\app\outputs\flutter-apk\app-release.apk
ResolvedSource=L:\Lestar\build\app\outputs\flutter-apk\app-release.apk
SourceSHA256=75A664EDCDDE630A75971F858968D2A4F3C10B46A557CA1BCA7FC8998CA9ABCB
PublicSHA256=75A664EDCDDE630A75971F858968D2A4F3C10B46A557CA1BCA7FC8998CA9ABCB
Focused source-resolution/hash passed.
```

Catatan: baris `SourceSHA256` di atas memakai nilai aktual lengkap yang sama dengan `PublicSHA256` (`75A664EDCDDE630A75971F858968D2A4F3C10B46A557CA1BCA7FC8998CA9ABCB`).
