# UI Konsumen Light Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menyelesaikan UI konsumen Lestar dari radar realtime hingga pembayaran dan QR klaim dengan data Supabase nyata.

**Architecture:** Provider/controller Riverpod di feature konsumen mengorkestrasi repository bersama tanpa mengubah tanda tangannya. Seluruh layar memakai komponen Light Glass yang responsif; alur detail/pembayaran/QR berada di navigator feature sehingga shell dan route core tetap stabil.

**Tech Stack:** Flutter 3.47, Dart 3.13, Riverpod 3, Supabase Realtime/RPC, flutter_map 8, geolocator, qr_flutter, Android MethodChannel, flutter_test.

## Global Constraints

- `nearby_listings` wajib memakai parameter `p_lat`, `p_lng`, `p_radius_km`; jarak tidak dihitung di Dart.
- `liveListingsStream()` menjadi pemicu realtime dan target kemunculan listing adalah kurang dari 2 detik.
- Oranye `#F38222` selalu memakai teks `#0A0A0A`; `#00BC7D` tidak menjadi latar teks.
- Tidak ada `#12C56A`, data demo hardcode yang disamarkan, atau pengurangan stok di klien.
- Green fee memakai `LestarConstants.greenFee` dan terlihat terpisah.
- Widget/repository/rute bersama tidak berubah tanda tangan.
- Semua widget test memakai lebar HP dan menginisialisasi locale `id_ID` bila memakai formatter tanggal.

---

### Task 1: Fondasi Light Glass dan state konsumen

**Files:**
- Modify: `lib/core/theme/light_glass.dart`
- Create: `lib/features/consumer/application/consumer_providers.dart`
- Create: `lib/features/consumer/presentation/widgets/consumer_widgets.dart`
- Modify: `android/app/src/main/kotlin/id/lestar/lestar/MainActivity.kt`
- Test: `test/features/consumer/consumer_widgets_test.dart`

**Interfaces:**
- Consumes: `ListingRepository.nearbyListings`, `ListingRepository.liveListingsStream`, `OrderRepository.consumerOrders`, `ProfileRepository.getMerchant`.
- Produces: `consumerRadarProvider`, `activeConsumerOrderProvider`, `ConsumerRadarData`, placeholder/image/card widgets.

- [ ] Write failing tests for Light Glass colors, scaled discount marker, food placeholder, and 390 dp layout.
- [ ] Implement theme decoration, providers, location fallback with explicit labeling, and reusable consumer widgets.
- [ ] Add the isolated Android brightness channel without changing any shared Dart signature.
- [ ] Run `flutter test test/features/consumer/consumer_widgets_test.dart` and `flutter analyze`.
- [ ] Stage as commit message `feat(konsumen): bangun fondasi Light Glass dan state radar`.

### Task 2: Radar realtime dan Feed

**Files:**
- Modify: `lib/features/consumer/presentation/radar_screen.dart`
- Modify: `lib/features/consumer/presentation/feed_screen.dart`
- Test: `test/features/consumer/radar_screen_test.dart`
- Test: `test/features/consumer/feed_screen_test.dart`

**Interfaces:**
- Consumes: `consumerRadarProvider`, `ConsumerRadarData`, `NearbyListing`.
- Produces: radar peta/listing terpilih dengan pull-to-refresh dan feed grid nyata.

- [ ] Write failing widget tests for map composition, search, empty/error, pull-to-refresh, discount hierarchy, and 320 ms entrance animation.
- [ ] Implement Radar with OSM, RPC-backed markers, selected glass card, live deals, and responsive constraints.
- [ ] Implement Feed using the same RPC-backed data and local search/filtering.
- [ ] Run both consumer screen tests at 390×900 and confirm `tester.takeException()` is null.
- [ ] Stage Radar as `feat(konsumen): hidupkan radar realtime berbasis RPC` and Feed as `feat(konsumen): tampilkan feed flash deal nyata`.

### Task 3: Detail, booking, pembayaran, dan QR

**Files:**
- Create: `lib/features/consumer/presentation/consumer_checkout_flow.dart`
- Modify: `lib/features/consumer/presentation/qr_screen.dart`
- Create: `lib/features/consumer/application/consumer_checkout_controller.dart`
- Test: `test/features/consumer/consumer_checkout_test.dart`
- Test: `test/features/consumer/qr_screen_test.dart`

**Interfaces:**
- Consumes: `OrderItem.baru`, `OrderRepository.createOrder`, `OrderRepository.pay`, `LestarConstants.greenFee`, `QrDisplay`.
- Produces: detail listing, checkout simulation, paid QR view, and active QR FAB behavior.

- [ ] Write failing tests asserting expired listing is disabled, green fee is separate, payment waits 1.5 seconds, and QR only appears after `paid`.
- [ ] Implement detail and checkout with guarded one-shot submission and visible retry errors.
- [ ] Implement active QR loading order items + merchant and lifecycle brightness restoration.
- [ ] Run checkout/QR tests and repository fakes through the full detail → pay → QR sequence.
- [ ] Stage as `feat(konsumen): tuntaskan pesan bayar dan QR klaim`.

### Task 4: Orders dan Profil

**Files:**
- Modify: `lib/features/consumer/presentation/orders_screen.dart`
- Modify: `lib/features/consumer/presentation/profile_screen.dart`
- Test: `test/features/consumer/orders_profile_test.dart`

**Interfaces:**
- Consumes: `OrderRepository.consumerOrders`, `currentProfileProvider`, `AuthRepository.signOut`.
- Produces: riwayat status responsif, empty/error states, profil konsumen, dan logout.

- [ ] Write failing tests for empty orders, paid/claimed status, zero eco-points, long names, and logout.
- [ ] Implement minimal but complete Orders and Profil screens using real providers.
- [ ] Run the tests at 360 and 390 dp with no layout exception.
- [ ] Stage as `feat(konsumen): lengkapi pesanan dan profil`.

### Task 5: Audit, handoff, and release verification

**Files:**
- Create: `docs/06-agent-briefs/E-HANDOFF.md`
- Modify tests only if verification exposes a real regression.

**Interfaces:**
- Consumes: every requirement in `docs/prompts/E.md`.
- Produces: evidence table with command results and an honest physical-device status.

- [ ] Run `dart format lib/features/consumer lib/core/theme/light_glass.dart test/features/consumer`.
- [ ] Run `flutter analyze` and full `flutter test`.
- [ ] Run `flutter test tool/smoke_supabase.dart` and `flutter test tool/smoke_realtime.dart` when network permits.
- [ ] Run `rg -n "#12C56A|12C56A" lib/features/consumer lib/core/theme/light_glass.dart` and audit orange/emerald usage.
- [ ] Build `flutter build apk --release --dart-define=DEMO=true`.
- [ ] Write `E-HANDOFF.md` with completed screens, decisions, verification evidence, cross-boundary dependency, and physical-device gate.
- [ ] Stage as `docs(konsumen): serahkan UI Light Glass dan bukti verifikasi`.
