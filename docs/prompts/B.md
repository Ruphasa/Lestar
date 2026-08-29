Kamu **Agent B (Core & Migrasi)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

**Kamu leher botol proyek ini.** Tiga agent UI tidak bisa mulai sampai kamu selesai. Hari ini kamu tidak akan menghasilkan satu pun layar cantik — itu wajar, dan itu benar.

## Baca dulu, berurutan

```
docs/README.md
docs/00-PRD.md                          §5 fitur, §6 aturan bisnis
docs/01-architecture.md                 §2 struktur folder, §8 peta migrasi
docs/02-data-model.md                   schema yang dipetakan ke model
docs/03-design-system.md                §3 token, §4 tipografi
docs/06-agent-briefs/README.md
docs/06-agent-briefs/B-core.md          tugasmu
docs/06-agent-briefs/A-HANDOFF.md       nama kolom persis dari Agent A
```

Muat skill: `flutter-apply-architecture-best-practices`, `flutter-implement-json-serialization`, `supabase`, `flutter-expert`.

**Jalankan `/writing-plans` dulu** sebelum menulis kode. Lingkupmu paling besar dan paling saling bergantung — plan berurutan dengan checkpoint akan menghemat waktu, bukan menambah.

## Titik mulai

Fork dari **Ecobite**: https://github.com/Third-Connectors/EcoBite — 16.882 baris Dart, Flutter + Riverpod + GoRouter, sudah berjalan.

**Diwarisi:** struktur folder, pola `GoRouter` + `StatefulShellRoute`, pola repository, pola Riverpod, konfigurasi build dan signing APK.
**Dibuang total:** seluruh Firebase, seluruh `EcoBiteTheme`, `main_layout.dart`.

## Milikmu

```
lib/core/
lib/shared/models/
lib/shared/repositories/
lib/shared/widgets/        kerangka saja — D/E/F menambah varian tema
lib/main.dart
pubspec.yaml
assets/fonts/              sudah terisi, tinggal didaftarkan
```

Jangan menyentuh `lib/features/*/presentation/`, `api/`, `ml/`, `supabase/`, `landing/`.

## Lingkup

**1. Bersih-bersih dependency**
Cabut `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`. Hapus `firebase_options.dart`, `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`.
Tambah `supabase_flutter`, `flutter_map`, `latlong2`, `geolocator`, `pdf`, `printing`, `intl`.
Pertahankan `flutter_riverpod`, `go_router`, `qr_flutter`, `mobile_scanner`, `fl_chart`, `image_picker`, `uuid`, `http`.
**Verifikasi versi terbaru lewat context7** sebelum mengunci.

**2. Sepuluh model** — `Profile`, `Merchant`, `Partner`, `Listing`, `Order`, `OrderItem`, `WasteBatch`, `Forecast`, `SalesHistory`, `EsgEvent`, `EsgReport`.
Buang `Timestamp` Firestore, pakai `DateTime.parse` untuk ISO 8601. `fromJson`/`toJson` manual seperti Ecobite — **jangan** `json_serializable`, build_runner memakan waktu yang tidak kita punya. Setiap enum butuh parser aman: nilai tak dikenal jatuh ke default, bukan crash.

**3. Tujuh repository** — daftar metode lengkap ada di `B-core.md`.
Terjemahan: `collection().snapshots()` → `supabase.from(...).stream(primaryKey: ['id'])`.
**Selalu filter stream di sisi klien juga**, bukan hanya mengandalkan RLS — RLS menyaring baris, tapi klien tetap menerima event dan memicu rebuild sia-sia.

**4. Klien API + fallback**
`lib/core/api/lestar_api.dart` — empat metode, timeout forecast 4 dtk / triage 4 dtk / pricing 3 dtk / esg 8 dtk. Setiap kegagalan **wajib** jatuh ke fallback lokal, tidak pernah melempar exception ke UI.
`lib/core/fallback_engine.dart` — implementasi ada di `04-ai-pipeline.md` §5.

**Rumus `triage` dan `pricing` harus identik dengan versi Python Agent C.** Ambil `api/test_parity.py` dari `C-HANDOFF.md` kalau sudah ada, dan buktikan 10 input uji menghasilkan angka yang sama persis. Kalau C belum selesai, tulis versimu dari `04-ai-pipeline.md` §4 dan tinggalkan catatan di handoff.

**5. Konstanta** — `lib/core/constants.dart`, semua nilai dari `02-data-model.md` §10. Satu tempat, tidak ditulis ulang di berkas lain.

Agent A sudah membuat versi SQL-nya: fungsi `berat_porsi_kg(p_category text)` dan `faktor_co2_per_kg()`. Keduanya dipakai trigger ESG dan auto-cascade. **Angka di Dart wajib sama persis dengan versi SQL.** Kalau berbeda, laporan ESG dan berat kaskade akan berselisih tanpa ada yang menyadarinya sampai demo.

**6. Font** — berkas sudah ada di `assets/fonts/` (`PlusJakartaSans[wght].ttf`, `Inter[opsz,wght].ttf`). Daftarkan di `pubspec.yaml`.
Ini **variable font**: satu berkas untuk semua bobot, diatur lewat `fontVariations`, bukan `fontWeight`. **Jangan pakai paket `google_fonts`** — paket itu mengambil font lewat jaringan, dan saat WiFi dimatikan di penutup demo teks akan jatuh ke fallback sistem. Uji dengan mode pesawat.

**7. Tema — kerangka saja**
`lib/core/theme/tokens.dart` dari `03-design-system.md` §3. Emerald `#00BC7D`, emerald dalam `#009966`, forest `#265938`, oranye `#F38222`. **Jangan pakai `#12C56A`** — nilai tebakan dari draf lama.
Buat berkas dengan struktur kelas kosong untuk `light_glass.dart`, `dark_glass.dart`, `plain.dart`. Isinya diserahkan ke D/E/F. Daftarkan ke `MaterialApp`, pilih tema berdasarkan `profiles.role`.

**8. Routing & tiga shell**
```
AuthGate → baca profiles.role
  ├── MerchantShell   /merchant · /merchant/inventory · /merchant/esg
  ├── ConsumerShell   /radar · /feed · /orders · /profile   (+ FAB QR)
  └── PartnerShell    /partner · /partner/riwayat · /partner/langganan
```
Ecobite sudah punya `StatefulShellRoute.indexedStack` untuk konsumen dan partner. Warisi polanya, tambahkan shell merchant.

**9. Widget bersama — kerangka**
`GlassCard` · `DarkGlassCard` · `PlainCard` · `BigButton` · `StatTile` · `SourceBadge` · `DiscountPill` · `PriceText` · `CountdownChip` · `LestarMap` · `QrDisplay` · `QrScanner` · `EmptyState` · `OfflineBanner`
Pastikan **tanda tangan API-nya stabil** supaya D/E/F tidak saling mengubahnya.

**10. Pintasan demo** — `lib/core/demo/role_switcher.dart`, aktif hanya kalau `const bool.fromEnvironment('DEMO')`. Tekan-lama logo di app bar → bottom sheet 3 akun demo → login ulang diam-diam → masuk shell yang sesuai. Target **< 3 detik**.

## Cara kerja

- Commit setiap potong yang lolos uji. Jangan tunggu semuanya selesai.
- Pesan commit Bahasa Indonesia.
- Keputusan yang tidak tertulis: pilih yang paling sederhana, catat, lanjut. Berhenti dan tanya hanya kalau itu mengubah kontrak untuk D/E/F.

## Selesai berarti

- `flutter analyze` bersih, nol error
- Nol impor Firebase tersisa
- Login 3 akun demo, masing-masing mendarat di shell yang benar
- Tiap repository punya minimal satu pemanggilan yang terbukti membaca data nyata dari Supabase
- `liveListingsStream()` menerima event realtime saat baris baru masuk
- Klien API jatuh ke fallback saat Railway dimatikan — diuji dengan memutus koneksi
- `fallback_engine.triage()` cocok dengan versi Python untuk 10 input uji
- Font tampil benar dalam **mode pesawat**
- Ganti role di build demo < 3 detik
- APK release ter-build

## Sebelum menutup sesi

Tulis `docs/06-agent-briefs/B-HANDOFF.md` berisi:

1. **Daftar model + nama field persis** — D/E/F menunggu ini
2. **Tanda tangan setiap metode repository**
3. **Tanda tangan widget bersama**
4. **Nama rute per shell**
5. **Cara memakai `fontVariations`** — contoh satu `TextStyle` yang benar
6. **Keputusan yang kamu ambil sendiri**, dan apa pun yang gagal atau kamu lewati

Tanpa berkas ini, tiga agent UI akan menebak dan salah. Ini bagian dari definisi selesai.
