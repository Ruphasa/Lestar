# Agent G Handoff

## Landing Page

- URL publik: https://landing-46ek2z2oq-ruphasas-projects.vercel.app
- Inspect Vercel: `dpl_7ip94KjA5Q2CD1vKHBpj7FE45x9f`, target `preview`, status `Ready`, dibuat 2 September 2026 09:46:23 WIB.
- Sumber APK: `build/app/outputs/flutter-apk/app-release.apk`
- APK publik lokal: `landing/public/lestar.apk`
- APK publik URL: `https://landing-46ek2z2oq-ruphasas-projects.vercel.app/public/lestar.apk`
- SHA-256: `75A664EDCDDE630A75971F858968D2A4F3C10B46A557CA1BCA7FC8998CA9ABCB`
- Ukuran APK: 78.813.064 bytes.
- Verifikasi endpoint publik: halaman `200` dengan `text/html; charset=utf-8` dan hero `Setiap kilogram punya jalur nilai`; APK `200`, `Content-Type: application/vnd.android.package-archive`, `Content-Disposition: attachment; filename=lestar.apk`, `Content-Length: 78813064`; hasil unduh publik byte-identical dengan APK lokal.
- Viewport terverifikasi: 320x800, 375x812, 768x1024, 1024x768, dan 1440x900 px. Tidak ada forced horizontal scroll, tidak ada offender DOM keluar viewport, CTA header tetap dalam viewport, dan tiga screenshot 1080x2400 tidak terpotong.
- Keyboard: urutan Tab desktop 1024x768 dari skip link, wordmark, `Cara kerja`, `Dampak`, CTA header, CTA hero, tautan `Lihat cara kerjanya`, CTA section unduh, tautan privasi, lalu footer. Focus ring terukur minimal 3 px pada semua stop.
- Reduced motion: `prefers-reduced-motion: reduce` aktif, semua elemen `[data-reveal]` langsung terlihat dengan opacity `1` dan transform `none`.
- Kontras: ink/white 19,8:1; forest/white 8,18:1; ink/orange 7,57:1; orange-text/white 4,6:1; white/emerald-deep 3,65:1 sesuai design system untuk teks besar saja. Landing memakai CTA forest/white untuk teks tombol normal.
- Screenshot aplikasi: `consumer.png`, `merchant.png`, dan `partner.png` berasal dari Android Emulator `Medium_Phone_API_36.0` (`emulator-5554`), aplikasi release asli `id.lestar.lestar`, capture 2 September 2026 06:48--06:51 WIB. Koreksi merchant dilakukan 2 September 2026 07:20 WIB; capture final adalah dashboard Verde Kitchen, SHA-256 `8C9FF46F7E4E3C91BACFAE4B77D4A7EC5F4C6FB73D14A08A0F0B897EC5D698B0`.
- Impeccable: 9,3/10 setelah P1 contrast fix. Deferred nonblocking P2/P3: optimasi font/subsetting dan hardening kecil `app.js`; keduanya tidak memblokir demo atau deploy.
- Catatan angka proposal: target 4.500 kg CO2eq/bulan dipertahankan; faktor 0,25 kg CO2eq/kg di proposal tidak konsisten dengan target tersebut.

## Catatan Deploy

- Deploy dilakukan lewat Vercel CLI 59.1.4, akun `ruphasa`, scope `ruphasas-projects`, tanpa git push.
- Deploy pertama tanpa `--prod` otomatis dijadikan production oleh Vercel karena proyek baru. Deliverable Task 5 adalah deploy kedua/ketiga dengan `--target preview`, URL di atas.
- Project Vercel baru `landing` dibuat oleh CLI. Output Directory diubah dari automatic menjadi `.` agar route `/public/lestar.apk` berisi APK sesuai kontrak. SSO deployment protection dinonaktifkan pada project `landing` supaya URL benar-benar publik dan endpoint dapat diverifikasi tanpa bypass token.
- Metadata lokal `.vercel` dan scratch QA tidak ditambahkan ke git.

## Verifikasi Final

- `LESTAR_RELEASE_APK_SOURCE=L:\Lestar\build\app\outputs\flutter-apk\app-release.apk powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1` -> `Landing verification passed.`
- `git diff --check` -> lulus tanpa output.
- Browser QA lokal: Chrome headless Playwright Chromium 1234 via CDP pada lima viewport wajib; screenshot dan JSON bukti berada di direktori ignored `.superpowers/sdd/2026-09-02-agent-g-landing/qa-task-5/`.
- Browser QA publik: URL publik dibuka pada mobile 375x812 dan desktop 1440x900; h1 cocok, CTA dalam viewport, dan forced horizontal scroll `0`.

