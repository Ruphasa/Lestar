# Agent B — Core & Migrasi

**Jadwal** Sabtu 29 Agustus, sepanjang hari · **Bergantung pada** A · **Memblokir** D, E, F

**Ini leher botol proyek.** Sampai kamu selesai, tiga agent UI tidak bisa mulai. Kerjakan tanpa menyentuh satu pun layar cantik hari ini — itu wajar, dan itu benar.

---

## Milik kamu

```
lib/core/
lib/shared/models/
lib/shared/repositories/
lib/shared/widgets/          (kerangka saja; D/E/F menambah varian tema)
lib/main.dart
pubspec.yaml
```

## Baca dulu

1. `docs/01-architecture.md` §2, §8 — struktur folder dan peta migrasi
2. `docs/02-data-model.md` — schema yang harus dipetakan ke model
3. Skill `flutter-apply-architecture-best-practices`, `flutter-implement-json-serialization`, `supabase`

## Titik mulai

Fork dari **Ecobite**: https://github.com/Third-Connectors/EcoBite (16.882 baris Dart, Flutter + Riverpod + GoRouter).

Yang **diwarisi**: struktur folder, pola `GoRouter` + `StatefulShellRoute`, pola repository, pola Riverpod, konfigurasi build dan signing APK.

Yang **dibuang total**: seluruh Firebase, seluruh `EcoBiteTheme`, `main_layout.dart`.

## Tugas

### 1. Bersih-bersih dependency

**Cabut:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
Hapus juga `lib/firebase_options.dart`, `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`

**Tambah:**
```yaml
supabase_flutter: ^2.8.0
flutter_map: ^7.0.2
latlong2: ^0.9.1
geolocator: ^13.0.1
pdf: ^3.11.1
printing: ^5.13.2
intl: ^0.19.0
```

**Pertahankan:** `flutter_riverpod`, `go_router`, `google_fonts`, `qr_flutter`, `mobile_scanner`, `fl_chart`, `image_picker`, `uuid`, `http`

Versi di atas adalah titik awal — **verifikasi versi terbaru lewat context7** sebelum mengunci.

### 2. Tujuh model

`lib/shared/models/` — tulis ulang dari model Ecobite. Buang `Timestamp`, pakai `DateTime.parse` untuk ISO 8601 dari Postgres.

| Model | Dari | Catatan |
|---|---|---|
| `Profile` | `UserModel` (pecah) | + enum `UserRole {consumer, merchant, partner}` |
| `Merchant` | `UserModel` (pecah) | + `lat`, `lng`, `cutoffTime` |
| `Partner` | `UserModel` (pecah) | + `baseLat`, `baseLng`, `wastePreference` |
| `Listing` | `FoodModel` | + `triageScore`, `triageReason`, `physicalValidated`, `qtyRemaining`, `cookedAt`, enum status |
| `Order` + `OrderItem` | `OrderModel` | pecah dua, + `qrToken`, `qrExpiresAt`, `greenFee` |
| `WasteBatch` | `WasteModel` | + `lat`, `lng`, `sourceListingId`, enum status |
| `Forecast` | baru | + enum `ForecastSource` |
| `SalesHistory`, `EsgEvent`, `EsgReport` | baru | |

Pakai `fromJson` / `toJson` manual seperti Ecobite. **Jangan** pakai `json_serializable` — build_runner memakan waktu yang tidak kita punya.

Semua enum butuh parser yang aman: nilai tidak dikenal → nilai default, bukan crash.

### 3. Tujuh repository

`lib/shared/repositories/` — pola sama seperti Ecobite, klien diganti.

| Repository | Metode kunci |
|---|---|
| `auth_repository` | `signIn`, `signOut`, `currentProfile`, `authStateStream` |
| `profile_repository` | `getProfile`, `getMerchant`, `getPartner`, `updateProfile` |
| `listing_repository` | `createListing`, `validatePhysical`, `liveListingsStream`, `nearbyListings`, `merchantListings` |
| `order_repository` | `createOrder`, `pay`, `claimByQr`, `consumerOrders`, `merchantOrders` |
| `waste_repository` | `availableStream`, `nearbyWaste`, `matchPartner`, `updateStatus`, `merchantWaste` |
| `forecast_repository` | `getForecast(merchantId, date)`, `saveForecast`, `recentSalesHistory` |
| `esg_repository` | `eventsInPeriod`, `aggregate`, `saveReport` |

Terjemahan pola Firestore → Supabase:
```dart
// Ecobite
collection('foods').snapshots()
// Lestar
supabase.from('listings').stream(primaryKey: ['id']).eq('status', 'live')
```

**Penting:** selalu filter stream di sisi klien juga, bukan hanya mengandalkan RLS. RLS menyaring baris, tapi klien tetap menerima event dan memicu rebuild yang tidak perlu.

### 4. Klien API + fallback

`lib/core/api/lestar_api.dart` — empat metode: `forecast`, `triage`, `pricing`, `esgNarrative`.

Timeout: forecast 4 dtk · triage 4 dtk · pricing 3 dtk · esg 8 dtk.
Setiap kegagalan **harus** jatuh ke fallback lokal, tidak pernah melempar exception ke UI.

`lib/core/fallback_engine.dart` — implementasi ada di `04-ai-pipeline.md` §5. Tiga fungsi: `forecast()`, `triage()`, `pricing()`.

**Rumus `triage` dan `pricing` harus identik dengan versi Python milik Agent C.** Koordinasikan. Uji dengan 10 input yang sama, hasil harus persis sama.

### 5. Konstanta

`lib/core/constants.dart` — semua nilai dari `02-data-model.md` §10. Satu tempat, tidak boleh ditulis ulang di file lain.

### 5b. Font — bundel, jangan unduh runtime

Unduh dari fonts.google.com ke `assets/fonts/`:
- Plus Jakarta Sans — Regular, Medium (500), Bold (700), ExtraBold (800)
- Inter — Regular, Medium (500), SemiBold (600)

Daftarkan di `pubspec.yaml` (blok lengkap ada di `03-design-system.md` §4).

**Ini bukan detail kosmetik.** `google_fonts` mengambil font lewat jaringan. Saat WiFi dimatikan di penutup demo, teks akan jatuh ke fallback sistem dan merusak momen yang justru ingin ditonjolkan. Uji dengan mode pesawat sebelum menyatakan selesai.

### 6. Tema — kerangka saja

`lib/core/theme/tokens.dart` — token bersama dari `03-design-system.md` §3. Nilai diambil dari ekstraksi piksel `mockup.png`, cocok dengan palet Tailwind v4. Emerald utama `#00BC7D`, emerald dalam `#009966`. **Jangan pakai `#12C56A`** — itu nilai tebakan dari draf lama.

Buat **berkas kosong dengan struktur kelas** untuk `light_glass.dart`, `dark_glass.dart`, `plain.dart`. Isinya diserahkan ke D/E/F. Kamu hanya menyediakan kerangka dan mendaftarkannya ke `MaterialApp`.

Pemilihan tema berdasarkan role:
```dart
ThemeData themeForRole(UserRole role) => switch (role) {
  UserRole.consumer => LightGlassTheme.data,
  UserRole.merchant => DarkGlassTheme.data,
  UserRole.partner  => PlainTheme.data,
};
```

### 7. Routing & shell

`lib/core/routing/router.dart` — pertahankan struktur Ecobite, ganti guard.

```
AuthGate → baca profiles.role
  ├── MerchantShell  StatefulShellRoute: /merchant · /merchant/inventory · /merchant/esg
  ├── ConsumerShell  StatefulShellRoute: /radar · /feed · /orders · /profile  (+ FAB QR)
  └── PartnerShell   StatefulShellRoute: /partner · /partner/riwayat · /partner/langganan
```

Ecobite sudah punya `StatefulShellRoute.indexedStack` untuk konsumen dan partner. Warisi polanya, tambahkan shell merchant.

### 8. Widget bersama — kerangka

`lib/shared/widgets/` — buat kerangka yang mengambil gaya dari `Theme.of(context)`:
`GlassCard` · `DarkGlassCard` · `PlainCard` · `BigButton` · `StatTile` · `SourceBadge` · `DiscountPill` · `LestarMap` · `QrDisplay` · `QrScanner` · `EmptyState` · `OfflineBanner`

D/E/F akan menyempurnakan varian tema masing-masing. Kamu memastikan API widget-nya stabil supaya mereka tidak saling mengubah tanda tangan fungsi.

### 9. Pintasan demo

`lib/core/demo/role_switcher.dart` — aktif hanya kalau `const bool.fromEnvironment('DEMO')`.

Tekan-lama logo di app bar → bottom sheet berisi 3 akun demo → pilih → login ulang diam-diam → masuk shell yang sesuai. Target: **< 3 detik**.

## Definisi selesai

- [ ] `flutter analyze` bersih, nol error
- [ ] Tidak ada satu pun impor Firebase yang tersisa
- [ ] Login 3 akun demo, masing-masing mendarat di shell yang benar
- [ ] Setiap repository punya minimal satu pemanggilan yang terbukti membaca data nyata dari Supabase
- [ ] `listing_repository.liveListingsStream()` menerima event realtime saat baris baru masuk
- [ ] Klien API jatuh ke fallback saat Railway dimatikan — diuji dengan mematikan koneksi
- [ ] `fallback_engine.triage()` dan versi Python Agent C memberi hasil identik untuk 10 input uji
- [ ] Ganti role di build demo < 3 detik
- [ ] APK release ter-build

## Serah terima ke D/E/F

Setelah selesai, kirim ke mereka:
- Daftar model beserta nama field-nya
- Daftar metode repository beserta tanda tangan fungsinya
- Tanda tangan widget bersama
- Nama rute per shell
