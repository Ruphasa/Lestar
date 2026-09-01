# Agent D UI Merchant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengganti empat stub merchant dengan alur demo Dark Glass yang terhubung ke Supabase/FastAPI, aman ketika offline, dan dapat ditelusuri ke data nyata.

**Architecture:** Setiap layar tetap menjadi entry point router, sedangkan orkestrasi async hidup dalam controller Riverpod di `lib/features/merchant/application/`. Widget besar dipecah di `presentation/widgets/`; repository dan model Agent B dipakai apa adanya, tanpa mengubah tanda tangan bersama.

**Tech Stack:** Flutter 3.47, Dart 3.13, Riverpod 3, Supabase Flutter, fl_chart, image_picker, mobile_scanner, pdf, printing.

## Global Constraints

- Wilayah utama: `lib/features/merchant/` dan `lib/core/theme/dark_glass.dart`.
- Satu-satunya perubahan `lib/core/constants.dart` adalah `modelAkurasi = 0.9227` dan `modelDasarUji = 'data sintetis'` dengan sumber metrik.
- Tanda tangan widget bersama tidak boleh berubah.
- `#00BC7D` hanya untuk ikon, garis, dan indikator; bukan latar teks.
- `#12C56A` dilarang.
- Cache forecast dan laporan ESG dibaca sebelum jaringan/API.
- Listing B2C hanya menjadi `live` setelah validasi fisik; skor di bawah 70 tidak pernah menampilkan tombol B2C.
- RPC demo selalu mengirim `p_merchant_id` yang tidak kosong.
- Semua angka ESG berasal dari `esg_events`.
- Commit menggunakan Bahasa Indonesia dan dilakukan per layar yang sudah lulus pengujian.

---

### Task 1: Fondasi Dark Glass dan Kontrak Tampilan

**Files:**
- Modify: `lib/core/constants.dart`
- Modify: `lib/core/theme/dark_glass.dart`
- Modify: `lib/shared/widgets/badges.dart`
- Modify: `lib/shared/widgets/cards.dart`
- Test: `test/merchant_dark_glass_test.dart`

**Interfaces:**
- Consumes: `LestarTokens`, `LestarType`, `ForecastSource`.
- Produces: `DarkGlassTheme.data`, label sumber yang jujur, dan konstanta badge akurasi.

- [ ] **Step 1: Tulis test token, tema, dan copy badge**

```dart
test('akurasi model mengikuti metrics Agent C', () {
  expect(LestarConstants.modelAkurasi, 0.9227);
  expect(LestarConstants.modelDasarUji, 'data sintetis');
});

testWidgets('SourceBadge memakai tiga label kontrak', (tester) async {
  for (final entry in <ForecastSource, String>{
    ForecastSource.lstmGemini: 'AI · LSTM + Gemini',
    ForecastSource.lstmOnly: 'AI · LSTM',
    ForecastSource.heuristic: 'Mode offline · heuristik',
  }.entries) {
    await tester.pumpWidget(MaterialApp(
      theme: DarkGlassTheme.data,
      home: Scaffold(body: SourceBadge(source: entry.key)),
    ));
    expect(find.text(entry.value), findsOneWidget);
  }
});
```

- [ ] **Step 2: Jalankan test dan pastikan gagal karena konstanta/copy belum ada**

Run: `flutter test test/merchant_dark_glass_test.dart`
Expected: FAIL pada `modelAkurasi` dan label badge.

- [ ] **Step 3: Implementasikan token permukaan, tema komponen, badge, dan kartu gelap**

```dart
static const double modelAkurasi = 0.9227;
static const String modelDasarUji = 'data sintetis';
```

Tema memakai scaffold `0xFF10140F`, card `0xFF151A13`, tile `0xFF1C201B`, narasi `0xFF11291B`, badge `0xFF113525`, input gelap, tombol `emeraldDeep`, dan NavigationBar hijau. `SourceBadge` memilih gaya berdasarkan `Brightness.dark` tanpa mengubah constructor.

- [ ] **Step 4: Format dan jalankan test tema**

Run: `dart format lib/core/constants.dart lib/core/theme/dark_glass.dart lib/shared/widgets/badges.dart lib/shared/widgets/cards.dart test/merchant_dark_glass_test.dart && flutter test test/merchant_dark_glass_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit fondasi**

```bash
git add lib/core/constants.dart lib/core/theme/dark_glass.dart lib/shared/widgets/badges.dart lib/shared/widgets/cards.dart test/merchant_dark_glass_test.dart
git commit -m "feat(merchant): bangun fondasi tema Dark Glass"
```

### Task 2: Home dan Buffer Intelligence

**Files:**
- Create: `lib/features/merchant/application/merchant_home_controller.dart`
- Create: `lib/features/merchant/presentation/widgets/merchant_forecast_card.dart`
- Modify: `lib/features/merchant/presentation/merchant_home_screen.dart`
- Test: `test/merchant_home_test.dart`

**Interfaces:**
- Consumes: `currentMerchantProvider`, `forecastRepositoryProvider`, `listingRepositoryProvider`, `esgRepositoryProvider`, `lestarApiProvider`, `FallbackEngine.forecast`.
- Produces: `merchantHomeProvider`, `MerchantHomeState`, `MerchantForecastCard`.

- [ ] **Step 1: Tulis test helper chart, label akurasi, dan fallback sesi**

```dart
test('tujuh titik chart diurutkan terlama ke terbaru', () {
  final points = chartPoints(historyNewestFirst.take(7).toList());
  expect(points.map((e) => e.date), orderedDatesOldestFirst);
});

test('badge akurasi membawa dasar pengukuran', () {
  expect(modelAccuracyLabel(), '92% · data sintetis');
});
```

- [ ] **Step 2: Jalankan test dan pastikan helper belum tersedia**

Run: `flutter test test/merchant_home_test.dart`
Expected: FAIL karena controller/helper belum dibuat.

- [ ] **Step 3: Implementasikan controller cache-first**

`MerchantHomeState` menyimpan merchant, forecast online, forecast aktif, 14 history, agregat ESG, listing count, status loading/error, dan `offline`. Controller melakukan urutan berikut:

```dart
final cached = await forecastRepo.getForecast(merchant.id, besok);
final history = await forecastRepo.recentSalesHistory(merchant.id);
final forecast = cached ?? await _generateAndSave(merchant, history, besok);
```

`goOffline()` menghitung `FallbackEngine.forecast(history: state.history, targetDate: besok, weatherCode: state.history.first.weatherCode ?? 0)` lalu menjadikannya forecast aktif dengan `source=heuristic`. `goOnline()` mengembalikan forecast online yang sudah ada tanpa refresh API.

- [ ] **Step 4: Implementasikan Home responsif dan lifecycle observer**

`MerchantHomeScreen` memakai `WidgetsBindingObserver`; pada `resumed` ia memeriksa koneksi lalu memanggil `goOffline` atau `goOnline`. Forecast card memakai `fl_chart`, garis demand emerald, estimasi produksi oranye putus-putus, narasi hijau gelap, tombol Apply, source badge, dan `AnimatedSwitcher` 600 ms. KPI berasal dari agregat/listing nyata.

- [ ] **Step 5: Jalankan test Home dan layout sempit**

Run: `flutter test test/merchant_home_test.dart`
Expected: PASS pada lebar 320, 390, dan textScale 1.4 tanpa exception.

- [ ] **Step 6: Commit Home**

```bash
git add lib/features/merchant/application/merchant_home_controller.dart lib/features/merchant/presentation/widgets/merchant_forecast_card.dart lib/features/merchant/presentation/merchant_home_screen.dart test/merchant_home_test.dart
git commit -m "feat(merchant): hadirkan Buffer Intelligence berbasis data nyata"
```

### Task 3: Inventory, Triage, Gerbang Fisik, dan Kaskade

**Files:**
- Create: `lib/features/merchant/application/merchant_inventory_controller.dart`
- Create: `lib/features/merchant/presentation/widgets/merchant_inventory_widgets.dart`
- Modify: `lib/features/merchant/presentation/merchant_inventory_screen.dart`
- Test: `test/merchant_inventory_test.dart`

**Interfaces:**
- Consumes: `listingRepositoryProvider`, `wasteRepositoryProvider`, `lestarApiProvider`, `supabase.storage`, `supabase.rpc`.
- Produces: `merchantInventoryProvider`, `SurplusDraft`, `InventoryFlowState`.

- [ ] **Step 1: Tulis test aturan gerbang**

```dart
test('skor 69 hanya membuka jalur B2B', () {
  final state = InventoryFlowState.hasil(triage: triage(score: 69));
  expect(state.bolehValidasiB2c, isFalse);
  expect(state.bolehAlihkanB2b, isTrue);
});

testWidgets('pernyataan tanggung jawab selalu ada di hasil B2C', (tester) async {
  await tester.pumpWidget(testInventoryResult(score: 80));
  expect(find.textContaining('aroma, tekstur, dan tampilan'), findsOneWidget);
});
```

- [ ] **Step 2: Jalankan test dan pastikan gagal**

Run: `flutter test test/merchant_inventory_test.dart`
Expected: FAIL karena flow belum dibuat.

- [ ] **Step 3: Implementasikan controller alur surplus**

Controller memvalidasi nama, qty, harga, dan waktu masak; mengunggah foto ke `product-images/<merchant>/<uuid>.<ext>`; memanggil triage; untuk B2C menghitung pricing, membuat listing `draft/physicalValidated=false`, lalu memanggil `validatePhysical`; untuk B2B membuat `WasteBatch.available`. Exception database diterjemahkan dengan `pesanError` dan draft tidak pernah dipromosikan lewat UI tanpa validasi.

- [ ] **Step 4: Implementasikan form bertahap dan daftar realtime**

Form memuat picker foto, nama, kategori, qty, waktu masak, harga, hasil skor, alasan, CTA yang sesuai jalur, dan pernyataan wajib. Daftar memakai placeholder saat `imageUrl == null`, status badge, harga, stok, serta jejak kaskade dari `waste_batches.source_listing_id`.

- [ ] **Step 5: Implementasikan pemicu demo yang aman**

```dart
if (!LestarConstants.demoMode || merchantId.isEmpty) return;
await supabase.rpc('run_auto_cascade', params: {
  'p_force': true,
  'p_merchant_id': merchantId,
});
```

Hasil JSON ditampilkan sebagai snackbar terformat dan stream dibiarkan memperbarui daftar.

- [ ] **Step 6: Jalankan test Inventory**

Run: `flutter test test/merchant_inventory_test.dart`
Expected: PASS untuk skor 69/70, deklarasi, validasi input, placeholder, dan tombol demo.

- [ ] **Step 7: Commit Inventory**

```bash
git add lib/features/merchant/application/merchant_inventory_controller.dart lib/features/merchant/presentation/widgets/merchant_inventory_widgets.dart lib/features/merchant/presentation/merchant_inventory_screen.dart test/merchant_inventory_test.dart
git commit -m "feat(merchant): tegakkan triage dan validasi fisik surplus"
```

### Task 4: Scan dan Klaim QR

**Files:**
- Modify: `lib/features/merchant/presentation/merchant_scan_screen.dart`
- Test: `test/merchant_scan_test.dart`

**Interfaces:**
- Consumes: `QrScanner`, `orderRepositoryProvider.claimByQr(String)`.
- Produces: pemindaian kamera, input manual, feedback sukses/gagal.

- [ ] **Step 1: Tulis widget test tombol manual dan status klaim**

```dart
testWidgets('scan screen selalu menyediakan kode manual', (tester) async {
  await tester.pumpWidget(const TestApp(child: MerchantScanScreen()));
  expect(find.text('Masukkan kode manual'), findsOneWidget);
});
```

- [ ] **Step 2: Implementasikan layar scanner dan dialog manual**

Satu metode `_claim(String token)` menangani kedua sumber. Saat berhasil, tampilkan ikon centang, ID singkat, total, dan tombol scan berikutnya. `StateError` ditampilkan sebagai pesan siap pakai; error lain melewati `pesanError`.

- [ ] **Step 3: Jalankan test Scan**

Run: `flutter test test/merchant_scan_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit Scan**

```bash
git add lib/features/merchant/presentation/merchant_scan_screen.dart test/merchant_scan_test.dart
git commit -m "feat(merchant): tambahkan klaim QR dengan kode manual"
```

### Task 5: Laporan ESG Cache-First dan PDF

**Files:**
- Create: `lib/features/merchant/application/merchant_esg_controller.dart`
- Create: `lib/features/merchant/presentation/widgets/merchant_esg_widgets.dart`
- Modify: `lib/features/merchant/presentation/merchant_esg_screen.dart`
- Test: `test/merchant_esg_test.dart`

**Interfaces:**
- Consumes: `esgRepositoryProvider`, `lestarApiProvider`, `printing`, `pdf`.
- Produces: `merchantEsgProvider`, `MerchantEsgState`, laporan dan PDF yang hanya memakai angka agregat.

- [ ] **Step 1: Tulis test pemilihan cache periode**

```dart
test('laporan periode yang sama dipilih tanpa regenerasi', () {
  final cached = findCachedReport(reports, start, end);
  expect(cached?.id, 'agustus-2026');
});
```

- [ ] **Step 2: Implementasikan controller cache-first**

Controller menentukan awal/akhir bulan, membaca `reportsOf`, lalu menggunakan report periode persis jika ada. Jika tidak, ia memanggil `aggregate`, mengirim agregat plus nama/periode ke `esgNarrative`, menyimpan `EsgReport`, dan menampilkan baris tersimpan.

- [ ] **Step 3: Implementasikan UI dan export**

Empat tile menampilkan berat, CO2, rupiah, dan porsi dari report. Kartu narasi tidak menambah angka. Tombol export membangun PDF dari field report yang sama dan membuka `Printing.layoutPdf`.

- [ ] **Step 4: Jalankan test ESG**

Run: `flutter test test/merchant_esg_test.dart`
Expected: PASS untuk cache, angka nol, dan render lebar sempit.

- [ ] **Step 5: Commit ESG**

```bash
git add lib/features/merchant/application/merchant_esg_controller.dart lib/features/merchant/presentation/widgets/merchant_esg_widgets.dart lib/features/merchant/presentation/merchant_esg_screen.dart test/merchant_esg_test.dart
git commit -m "feat(merchant): tampilkan laporan ESG yang dapat ditelusuri"
```

### Task 6: Verifikasi Cerita Penuh dan Serah Terima

**Files:**
- Create: `docs/06-agent-briefs/D-HANDOFF.md`
- Modify: file merchant hanya jika verifikasi menemukan cacat.

**Interfaces:**
- Consumes: seluruh layar dari Task 1–5.
- Produces: bukti analisis/test/build, daftar keterbatasan, dan permintaan perubahan Agent B.

- [ ] **Step 1: Format dan analisis berurutan**

Run: `dart format lib/features/merchant lib/core/theme/dark_glass.dart lib/core/constants.dart lib/shared/widgets/badges.dart lib/shared/widgets/cards.dart test/merchant_*_test.dart`

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 2: Jalankan seluruh test tanpa paralel command Flutter**

Run: `flutter test`
Expected: semua test lulus.

- [ ] **Step 3: Scan warna terlarang dan kontrak keselamatan**

Run: `rg -n "12C56A|#12C56A" lib/features/merchant lib/core/theme/dark_glass.dart`
Expected: tidak ada hasil.

Run: `rg -n "p_merchant_id|aroma, tekstur, dan tampilan|Mode offline · heuristik|data sintetis" lib/features/merchant lib/shared/widgets/badges.dart lib/core/constants.dart`
Expected: setiap kontrak ditemukan.

- [ ] **Step 4: Build APK demo**

Run: `flutter build apk --release --dart-define=DEMO=true`
Expected: APK release berhasil.

- [ ] **Step 5: Tulis handoff jujur**

`D-HANDOFF.md` mencatat layar selesai/belum, bukti test, keputusan offline sesi, konstanta metrik, weather contract yang masih wajib dibuat nullable oleh Agent B, keterbatasan persistence tombol Apply, dan hasil uji perangkat/mode pesawat yang benar-benar dilakukan.

- [ ] **Step 6: Commit serah terima**

```bash
git add docs/06-agent-briefs/D-HANDOFF.md
git commit -m "docs(merchant): serahkan hasil dan batasan UI merchant"
```
