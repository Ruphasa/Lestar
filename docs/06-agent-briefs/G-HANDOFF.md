# Agent G Handoff — Landing Page & Web Deck

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
- Screenshot aplikasi: `consumer.png`, `merchant.png`, dan `partner.png` berasal dari Android Emulator `Medium_Phone_API_36.0` (`emulator-5554`), aplikasi release asli `id.lestar.lestar`, capture 2 September 2026 06:48–06:51 WIB. Koreksi merchant dilakukan 2 September 2026 07:20 WIB; capture final adalah dashboard Verde Kitchen, SHA-256 `8C9FF46F7E4E3C91BACFAE4B77D4A7EC5F4C6FB73D14A08A0F0B897EC5D698B0`.
- Impeccable: 9,3/10 setelah P1 contrast fix.

## Web Deck

- Stack: Astro 7.2.10 + Bun 1.3.14
- Lokasi proyek: `deck/`
- Slide: 12 section web-native (Botanical Art Nouveau contemporer)
- PDF: `deck/Lestar-KMIPN-VIII.pdf` (12 halaman, 930.2 KB) dan `deck/public/Lestar-KMIPN-VIII.pdf` (SHA-256 identik)
- Local preview: `http://localhost:4321` (berjalan via serve)
- Navigasi terverifikasi: keyboard (ArrowRight, ArrowLeft, PageDown, PageUp, Home, End, Spasi), tombol kontrol, swipe sentuh (threshold 48px), hash deep-linking (`#slide-1` s/d `#slide-12`), live region (`aria-live="polite"`), reduced motion, fallback no-JS
- Viewport terverifikasi Playwright: 320x568, 375x812, 768x1024, 1024x768, 1280x720, 1440x900 (0 horizontal overflow, 0 DOM offenders)
- Slide 8: consumer/merchant/partner screenshot asli release app
- Audit UI & Test Suite:
  - 25 pass, 0 fail across 6 test files (`tests/assets.test.ts`, `tests/build.test.ts`, `tests/controller.test.ts`, `tests/pdf.test.ts`, `tests/slides.test.ts`, `tests/visual-contract.test.ts`)
  - Astro check 0 errors
  - Browser QA Playwright lulus seluruh assertion
  - Verifier final `bun run verify` lulus
- Catatan: PPTX sengaja tidak dibuat; web deck menggantikannya sesuai keputusan pengguna.

## Verifikasi Final

- Deck verification: `bun --cwd deck run verify` -> `Web deck verification passed.`
- PDF test: `bun --cwd deck test tests/pdf.test.ts` -> 12 halaman terverifikasi
- Landing verification: `$env:LESTAR_RELEASE_APK_SOURCE='L:\Lestar\build\app\outputs\flutter-apk\app-release.apk'; powershell -NoProfile -ExecutionPolicy Bypass -File landing/tests/verify.ps1` -> `Landing verification passed.`
