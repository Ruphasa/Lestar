# Agent B — Core & Migrasi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended) or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bangun fondasi Flutter Lestar — model, repository, klien API + fallback, tema kerangka, routing tiga shell, widget bersama — sampai D/E/F bisa mulai tanpa menebak.

**Architecture:** Fork struktur Ecobite (Riverpod + GoRouter + repository pattern), buang seluruh Firebase, ganti data layer ke `supabase_flutter`. Lapisan: `lib/shared/models` (data murni, `fromJson`/`toJson` manual) → `lib/shared/repositories` (akses Supabase) → `lib/core` (tema, routing, konstanta, klien API, fallback) → `lib/features` (milik D/E/F, di sini hanya stub agar router bisa dikompilasi).

**Tech Stack:** Flutter 3.47.1 / Dart 3.13.1 · flutter_riverpod 3.4.2 · go_router 18.0.0 · supabase_flutter 2.17.2 · flutter_map 8.3.2 + latlong2 0.10.1 · geolocator 14.0.3 · pdf 3.13.0 + printing 5.15.0 · intl 0.20.3 · qr_flutter · mobile_scanner · fl_chart · image_picker · uuid · http

## Global Constraints

- Nol impor Firebase di seluruh repo. Tidak ada `firebase_options.dart`, `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`.
- Tidak boleh `json_serializable` / `build_runner`. `fromJson`/`toJson` ditulis tangan.
- Semua kolom waktu Postgres `timestamptz` → `DateTime.parse(...).toLocal()`. Tidak ada `Timestamp`.
- Setiap enum punya parser aman: nilai tak dikenal jatuh ke default, tidak melempar.
- Konstanta bersama **hanya** hidup di `lib/core/constants.dart`. Nilainya wajib identik dengan `berat_porsi_kg()`/`faktor_co2_per_kg()` di SQL dan `api/constants.py`.
- Nilai konstanta persis: `FAKTOR_CO2_PER_KG = 0.25` · `GREEN_FEE = 1000` · `AMBANG_TRIAGE_B2C = 70` · `DISKON_MAKSIMUM = 0.70` · `DISKON_DASAR = 0.30` · `QR_MASA_BERLAKU_JAM = 2`.
- `SHELF_LIFE_JAM`: gorengan 6 · nasi_lauk 8 · roti 24 · kue 72 · seafood 4 · santan_susu 5 · minuman 12.
- `BERAT_PORSI_KG`: gorengan 0.15 · nasi_lauk 0.35 · roti 0.08 · kue 0.05 · minuman 0.30 · lainnya 0.20. Kategori di luar daftar → 0.20.
- Warna token persis: forest `#265938` · emeraldDeep `#009966` · emerald `#00BC7D` · emeraldTint `#ECFAEF` · orange `#F38222` · orangeText `#C2540E` · orangeTint `#FFF1E4` · ink `#0A0A0A` · inkSoft `#171717` · muted `#737373` · mutedSoft `#A1A1A1` · surfaceGrey `#F5F5F5` · danger `#E5484D`. **`#12C56A` dilarang.**
- Font dibundel dari `assets/fonts/`, variable font, bobot lewat `fontVariations` bukan `fontWeight`. Paket `google_fonts` tidak dipakai.
- Stream Supabase selalu difilter ulang di sisi klien, bukan hanya mengandalkan RLS.
- Klien API tidak pernah melempar exception ke UI — setiap kegagalan jatuh ke `FallbackEngine`.
- `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, `OPENWEATHER_API_KEY` tidak pernah masuk APK.
- Pesan commit Bahasa Indonesia.
- Jangan menyentuh `api/`, `ml/`, `supabase/`, `landing/`. Di `lib/features/*/presentation/` hanya boleh membuat stub yang akan ditimpa D/E/F.

---

## File Structure

```
pubspec.yaml                                  dependency + registrasi font
analysis_options.yaml                         lint
android/, ios/, dll                           hasil flutter create, tanpa Firebase
lib/main.dart                                 bootstrap Supabase + MaterialApp.router
lib/core/
  constants.dart                              konstanta bersama (satu-satunya tempat)
  supabase/supabase_client.dart               inisialisasi + provider client
  supabase/session.dart                       authStateProvider, currentProfileProvider, guard
  theme/tokens.dart                           warna + tipografi + fontVariations helper
  theme/light_glass.dart                      kerangka tema konsumen  (isi: Agent E)
  theme/dark_glass.dart                       kerangka tema merchant  (isi: Agent D)
  theme/plain.dart                            kerangka tema pengepul  (isi: Agent F)
  theme/theme_for_role.dart                   pemetaan role -> ThemeData
  api/lestar_api.dart                         4 metode + timeout + fallback
  api/api_models.dart                         ForecastResult, TriageResult, PricingResult
  fallback_engine.dart                        forecast/triage/pricing lokal
  utils/formatters.dart                       rupiah, tanggal, jarak, sisa waktu
  utils/error_handler.dart                    pesan error ramah
  routing/router.dart                         AuthGate + tiga StatefulShellRoute
  routing/routes.dart                         konstanta nama rute
  demo/demo_accounts.dart                     3 akun demo
  demo/role_switcher.dart                     tekan-lama logo -> ganti role
lib/shared/models/                            11 model + enums.dart
lib/shared/repositories/                      7 repository + providers.dart
lib/shared/widgets/                           14 widget kerangka
lib/features/auth/presentation/login_screen.dart          milik B
lib/features/{merchant,consumer,partner}/presentation/    stub, milik D/E/F
test/fallback_engine_test.dart                parity 10 input
test/constants_test.dart                      konstanta cocok dengan SQL
tool/smoke_supabase.dart                      bukti tiap repository membaca data nyata
docs/06-agent-briefs/B-HANDOFF.md             serah terima
```

---

### Task 1: Scaffold proyek Flutter tanpa Firebase

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`, `lib/main.dart`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: —
- Produces: proyek Flutter bernama `lestar`, dependency terkunci, font terdaftar.

- [ ] **Step 1: Buat scaffold**

```bash
flutter create --org id.lestar --project-name lestar --platforms android,ios,web .
```

- [ ] **Step 2: Tulis blok dependency di `pubspec.yaml`**

```yaml
environment:
  sdk: ^3.9.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.9
  flutter_riverpod: ^3.4.2
  go_router: ^18.0.0
  supabase_flutter: ^2.17.2
  flutter_map: ^8.3.2
  latlong2: ^0.10.1
  geolocator: ^14.0.3
  pdf: ^3.13.0
  printing: ^5.15.0
  intl: ^0.20.3
  qr_flutter: ^4.1.0
  mobile_scanner: ^7.4.0
  fl_chart: ^1.2.0
  image_picker: ^1.2.3
  uuid: ^4.6.0
  http: ^1.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 3: Daftarkan aset dan font**

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/logo.png
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans[wght].ttf
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter[opsz,wght].ttf
```

- [ ] **Step 4: Verifikasi resolusi dependency**

Run: `flutter pub get`
Expected: `Got dependencies!`, tanpa konflik versi.

- [ ] **Step 5: Verifikasi nol Firebase**

Run: `grep -ril firebase lib pubspec.yaml android ios | grep -v '^$'`
Expected: tidak ada keluaran.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(core): scaffold Flutter lestar, dependency Supabase, font dibundel"
```

---

### Task 2: Konstanta bersama

**Files:**
- Create: `lib/core/constants.dart`, `test/constants_test.dart`

**Interfaces:**
- Produces: `LestarConstants.faktorCo2PerKg` (double 0.25), `.greenFee` (int 1000), `.ambangTriageB2c` (int 70), `.diskonMaksimum` (0.70), `.diskonDasar` (0.30), `.qrMasaBerlakuJam` (2), `LestarConstants.shelfLifeJam` (`Map<String,int>`), `LestarConstants.beratPorsiKg` (`Map<String,double>`), `LestarConstants.beratPorsi(String kategori) -> double`, `LestarConstants.kategoriListing` (`List<String>`), `LestarConstants.supabaseUrl`, `.supabaseAnonKey`, `.apiBaseUrl`, `.demoMode` (bool dari `bool.fromEnvironment('DEMO')`).

- [ ] **Step 1: Tulis test yang gagal**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/constants.dart';

void main() {
  test('konstanta cocok dengan versi SQL dan Python', () {
    expect(LestarConstants.faktorCo2PerKg, 0.25);
    expect(LestarConstants.greenFee, 1000);
    expect(LestarConstants.ambangTriageB2c, 70);
    expect(LestarConstants.diskonMaksimum, 0.70);
    expect(LestarConstants.diskonDasar, 0.30);
    expect(LestarConstants.qrMasaBerlakuJam, 2);
  });

  test('berat porsi identik dengan berat_porsi_kg() di SQL', () {
    expect(LestarConstants.beratPorsi('gorengan'), 0.15);
    expect(LestarConstants.beratPorsi('nasi_lauk'), 0.35);
    expect(LestarConstants.beratPorsi('roti'), 0.08);
    expect(LestarConstants.beratPorsi('kue'), 0.05);
    expect(LestarConstants.beratPorsi('minuman'), 0.30);
    expect(LestarConstants.beratPorsi('lainnya'), 0.20);
    expect(LestarConstants.beratPorsi('seafood'), 0.20);
    expect(LestarConstants.beratPorsi('entah_apa'), 0.20);
  });

  test('shelf life mencakup seafood dan santan_susu', () {
    expect(LestarConstants.shelfLifeJam['gorengan'], 6);
    expect(LestarConstants.shelfLifeJam['nasi_lauk'], 8);
    expect(LestarConstants.shelfLifeJam['roti'], 24);
    expect(LestarConstants.shelfLifeJam['kue'], 72);
    expect(LestarConstants.shelfLifeJam['seafood'], 4);
    expect(LestarConstants.shelfLifeJam['santan_susu'], 5);
    expect(LestarConstants.shelfLifeJam['minuman'], 12);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/constants_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:lestar/core/constants.dart'`.

- [ ] **Step 3: Tulis `lib/core/constants.dart`**

Isi seluruh nilai dari Global Constraints. `beratPorsi` mengembalikan `beratPorsiKg[kategori] ?? 0.20`. Kunci Supabase dibaca lewat `String.fromEnvironment` dengan default anon key (aman untuk publik, dilindungi RLS).

- [ ] **Step 4: Jalankan test**

Run: `flutter test test/constants_test.dart`
Expected: PASS, 3 test.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants.dart test/constants_test.dart
git commit -m "feat(core): konstanta bersama selaras dengan SQL Agent A"
```

---

### Task 3: Enum dan sebelas model

**Files:**
- Create: `lib/shared/models/enums.dart`, `profile.dart`, `merchant.dart`, `partner.dart`, `listing.dart`, `order.dart`, `order_item.dart`, `waste_batch.dart`, `forecast.dart`, `sales_history.dart`, `esg_event.dart`, `esg_report.dart`, `models.dart` (barrel), `test/models_test.dart`

**Interfaces:**
- Consumes: `LestarConstants` (tidak wajib).
- Produces: 7 enum (`UserRole`, `ListingStatus`, `WasteType`, `WasteStatus`, `OrderStatus`, `ForecastSource`, `EsgEventType`) masing-masing dengan `wire` (String) dan parser statis `X.parse(dynamic)`; 11 kelas model dengan `fromJson(Map<String,dynamic>)`, `toJson()`, dan `copyWith`. Nama field persis mengikuti `A-HANDOFF.md` §1 dalam camelCase.

- [ ] **Step 1: Tulis test yang gagal**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/shared/models/models.dart';

void main() {
  test('enum tak dikenal jatuh ke default, bukan crash', () {
    expect(UserRole.parse('merchant'), UserRole.merchant);
    expect(UserRole.parse('alien'), UserRole.consumer);
    expect(UserRole.parse(null), UserRole.consumer);
    expect(ListingStatus.parse('cascaded'), ListingStatus.cascaded);
    expect(ListingStatus.parse('???'), ListingStatus.draft);
    expect(OrderStatus.parse('claimed'), OrderStatus.claimed);
    expect(OrderStatus.parse(42), OrderStatus.pending);
    expect(WasteStatus.parse('picked_up'), WasteStatus.pickedUp);
    expect(ForecastSource.parse('lstm_gemini'), ForecastSource.lstmGemini);
    expect(ForecastSource.parse('x'), ForecastSource.heuristic);
    expect(EsgEventType.parse('b2b_diverted'), EsgEventType.b2bDiverted);
    expect(WasteType.parse('dry'), WasteType.dry);
  });

  test('Listing.fromJson membaca timestamptz ISO 8601', () {
    final l = Listing.fromJson({
      'id': 'l1', 'merchant_id': 'm1', 'name': 'Nasi Padang',
      'description': null, 'category': 'nasi_lauk', 'image_url': null,
      'qty_total': 10, 'qty_remaining': 4,
      'original_price': 25000, 'price': 12000,
      'cooked_at': '2026-08-29T03:00:00+00:00',
      'expires_at': '2026-08-29T11:00:00+00:00',
      'triage_score': 82, 'triage_reason': 'aman',
      'physical_validated': true, 'physical_validated_at': null,
      'status': 'live', 'created_at': '2026-08-29T03:05:00+00:00',
    });
    expect(l.name, 'Nasi Padang');
    expect(l.qtyRemaining, 4);
    expect(l.price, 12000);
    expect(l.status, ListingStatus.live);
    expect(l.cookedAt.isUtc, false);
    expect(l.cookedAt.toUtc().hour, 3);
    expect(l.discountPercent, closeTo(0.52, 0.001));
  });

  test('Partner.waste_preference array enum jadi List<WasteType>', () {
    final p = Partner.fromJson({
      'id': 'p1', 'org_name': 'Maggot Jaya', 'partner_type': 'maggot',
      'waste_preference': ['wet', 'dry'], 'vehicle_type': 'pickup',
      'license_plate': 'B 1 XX', 'service_radius_km': 10,
      'base_lat': -6.9, 'base_lng': 107.6, 'total_pickups': 3,
      'subscription_expiry': null,
    });
    expect(p.wastePreference, [WasteType.wet, WasteType.dry]);
    expect(p.serviceRadiusKm, 10);
    expect(p.subscriptionExpiry, isNull);
  });

  test('toJson membuang id dan bisa dibaca balik oleh fromJson', () {
    final now = DateTime.parse('2026-08-29T10:00:00Z').toLocal();
    final w = WasteBatch(
      id: 'w1', sourceMerchantId: 'm1', sourceListingId: null,
      wasteType: WasteType.wet, description: null, weightKg: 9.2,
      price: 5000, pickupAddress: 'Jl. Mawar', lat: -6.9, lng: 107.6,
      pickupWindowStart: null, pickupWindowEnd: null, imageUrl: null,
      status: WasteStatus.available, matchedPartnerId: null,
      createdAt: now, completedAt: null,
    );
    final json = w.toJson();
    expect(json.containsKey('id'), false);
    expect(json['status'], 'available');
    expect(WasteBatch.fromJson({...json, 'id': 'w1'}).weightKg, 9.2);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/models_test.dart`
Expected: FAIL — file model belum ada.

- [ ] **Step 3: Tulis enum**

Pola untuk setiap enum, contoh `ListingStatus`:

```dart
enum ListingStatus {
  draft('draft'),
  live('live'),
  soldOut('sold_out'),
  expired('expired'),
  cascaded('cascaded');

  const ListingStatus(this.wire);
  final String wire;

  static ListingStatus parse(dynamic v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ListingStatus.draft,
      );
}
```

Default tiap enum: `UserRole.consumer` · `ListingStatus.draft` · `WasteType.wet` · `WasteStatus.available` · `OrderStatus.pending` · `ForecastSource.heuristic` · `EsgEventType.b2cRescued`.

- [ ] **Step 4: Tulis 11 model**

Aturan seragam:
- `fromJson(Map<String, dynamic> json)` membaca `json['id'] as String`.
- Angka: `(json['x'] as num?)?.toDouble() ?? 0.0` / `?.toInt() ?? 0`.
- Waktu wajib: `DateTime.parse(json['created_at'] as String).toLocal()`; waktu opsional: helper `_dt(json['paid_at'])` yang mengembalikan `null` saat null.
- `date`/`forecast_date` bertipe `date` Postgres → `DateTime.parse('2026-08-29')`, simpan sebagai `DateTime` tanpa `.toLocal()`.
- `toJson()` tidak menyertakan `id` (dibuat database) dan menulis waktu sebagai `.toUtc().toIso8601String()`.
- Field turunan yang boleh ada di model: `Listing.discountPercent`, `Listing.isExpired`, `Order.qrValid`.

Nama field camelCase yang mengikat (dipakai D/E/F) ditulis lengkap di `B-HANDOFF.md` Task 12.

- [ ] **Step 5: Jalankan test**

Run: `flutter test test/models_test.dart`
Expected: PASS, 4 test.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/models test/models_test.dart
git commit -m "feat(models): 11 model + 7 enum dengan parser aman, tanpa Timestamp"
```

---

### Task 4: Klien Supabase dan sesi

**Files:**
- Create: `lib/core/supabase/supabase_client.dart`, `lib/core/supabase/session.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `LestarConstants.supabaseUrl`, `.supabaseAnonKey`, `Profile`, `UserRole`.
- Produces: `supabase` (getter `SupabaseClient`), `supabaseProvider`, `authStateProvider` (`StreamProvider<AuthState?>`), `currentProfileProvider` (`StreamProvider<Profile?>`), `currentRoleProvider` (`Provider<UserRole?>`).

- [ ] **Step 1: Tulis `supabase_client.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: LestarConstants.supabaseUrl,
    anonKey: LestarConstants.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
```

- [ ] **Step 2: Tulis `session.dart`**

`authStateProvider` membungkus `supabase.auth.onAuthStateChange`. `currentProfileProvider` membaca `authStateProvider`, dan saat ada sesi memanggil `ProfileRepository.getProfile(uid)` (Task 5) lalu memancarkannya; saat tidak ada sesi memancarkan `null`.

- [ ] **Step 3: Perbarui `main.dart`**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: LestarApp()));
}
```

- [ ] **Step 4: Verifikasi**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/supabase lib/main.dart
git commit -m "feat(core): inisialisasi Supabase dan provider sesi"
```

---

### Task 5: Tujuh repository

**Files:**
- Create: `lib/shared/repositories/auth_repository.dart`, `profile_repository.dart`, `listing_repository.dart`, `order_repository.dart`, `waste_repository.dart`, `forecast_repository.dart`, `esg_repository.dart`, `providers.dart`, `repositories.dart` (barrel)

**Interfaces:**
- Consumes: `supabase`, seluruh model.
- Produces: tanda tangan berikut, dikunci untuk D/E/F.

```dart
class AuthRepository {
  Future<Profile?> signIn(String email, String password);
  Future<void> signOut();
  Future<Profile?> currentProfile();
  Stream<AuthState> authStateStream();
}

class ProfileRepository {
  Future<Profile?> getProfile(String id);
  Future<Merchant?> getMerchant(String id);
  Future<Partner?> getPartner(String id);
  Future<void> updateProfile(String id, Map<String, dynamic> patch);
}

class ListingRepository {
  Future<Listing> createListing(Listing listing);
  Future<void> validatePhysical(String listingId);
  Stream<List<Listing>> liveListingsStream();
  Future<List<NearbyListing>> nearbyListings({required double lat, required double lng, double radiusKm = 5});
  Stream<List<Listing>> merchantListings(String merchantId);
}

class OrderRepository {
  Future<Order> createOrder({required String merchantId, required List<OrderItem> items});
  Future<Order> pay(String orderId, {String paymentMethod = 'simulasi'});
  Future<Order> claimByQr(String qrToken);
  Stream<List<Order>> consumerOrders(String consumerId);
  Stream<List<Order>> merchantOrders(String merchantId);
  Future<List<OrderItem>> itemsOf(String orderId);
}

class WasteRepository {
  Stream<List<WasteBatch>> availableStream();
  Future<List<NearbyWaste>> nearbyWaste({required double lat, required double lng, double radiusKm = 10});
  Future<WasteBatch> matchPartner(String batchId, String partnerId);
  Future<WasteBatch> updateStatus(String batchId, WasteStatus status);
  Stream<List<WasteBatch>> merchantWaste(String merchantId);
}

class ForecastRepository {
  Future<Forecast?> getForecast(String merchantId, DateTime date);
  Future<Forecast> saveForecast(Forecast forecast);
  Future<List<SalesHistory>> recentSalesHistory(String merchantId, {int days = 14});
}

class EsgRepository {
  Future<List<EsgEvent>> eventsInPeriod(String merchantId, DateTime start, DateTime end);
  Future<EsgAggregate> aggregate(String merchantId, DateTime start, DateTime end);
  Future<EsgReport> saveReport(EsgReport report);
}
```

- [ ] **Step 1: Tulis pola stream + filter klien**

```dart
Stream<List<Listing>> liveListingsStream() => supabase
    .from('listings')
    .stream(primaryKey: ['id'])
    .map((rows) => rows
        .map(Listing.fromJson)
        .where((l) => l.status == ListingStatus.live && l.qtyRemaining > 0 && !l.isExpired)
        .toList());
```

Catatan wajib: `.stream()` Supabase tidak menyaring `expires_at > now()` di server, dan RLS hanya menyaring baris yang boleh dibaca — filter ulang di `.map()` inilah yang mencegah rebuild sia-sia. Terapkan pola sama di `merchantListings`, `availableStream`, `merchantWaste`, `consumerOrders`, `merchantOrders`.

- [ ] **Step 2: Tulis dua RPC geo**

```dart
final rows = await supabase.rpc('nearby_listings', params: {
  'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm,
}) as List<dynamic>;
return rows.map((e) => NearbyListing.fromJson(e as Map<String, dynamic>)).toList();
```

`NearbyListing` dan `NearbyWaste` adalah model tampilan hasil RPC (kolom persis dari `A-HANDOFF.md` §2, termasuk `store_name`, `jarak_km`); taruh di `lib/shared/models/nearby.dart`.

- [ ] **Step 3: Tulis `createOrder` dan `claimByQr`**

`createOrder` menghitung `subtotal` dari item, `greenFee = LestarConstants.greenFee`, `total = subtotal + greenFee`, membuat `qr_token` dengan `Uuid().v4()` dan `qr_expires_at = now + QR_MASA_BERLAKU_JAM jam`, lalu `insert` `orders` dan `order_items` berurutan. `claimByQr` melakukan `update` `orders` `status='claimed'`, `claimed_at=now()` dengan `.eq('qr_token', token)` dan menolak (`StateError`) bila `qr_expires_at` sudah lewat atau status bukan `paid`.

Catatan: `esg_events` **tidak pernah** ditulis dari aplikasi — trigger database yang mengisi.

- [ ] **Step 4: `EsgAggregate`**

```dart
class EsgAggregate {
  final double totalWeightKg;
  final double totalCo2Kg;
  final double totalRevenueRecovered;
  final int mealsRescued;
}
```

`aggregate()` menjumlahkan `eventsInPeriod` di sisi klien — tidak menambah RPC baru ke wilayah Agent A.

- [ ] **Step 5: Verifikasi**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/shared/repositories lib/shared/models/nearby.dart
git commit -m "feat(data): 7 repository Supabase, stream difilter ulang di klien"
```

---

### Task 6: FallbackEngine dan parity

**Files:**
- Create: `lib/core/fallback_engine.dart`, `lib/core/api/api_models.dart`, `test/fallback_engine_test.dart`

**Interfaces:**
- Consumes: `LestarConstants`, `SalesHistory`, `ForecastSource`.
- Produces: `ForecastResult`, `TriageResult`, `PricingResult`; `FallbackEngine.forecast({required List<SalesHistory> history, required DateTime targetDate, required int weatherCode})`, `FallbackEngine.triage({required String kategori, required double jamSejakMasak, required double ambientTemp})`, `FallbackEngine.pricing({required double originalPrice, required double jamTersisa, required double jamTotal, required int qtyRemaining, required int qtyTotal})`.

- [ ] **Step 1: Tulis test parity 10 input**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/fallback_engine.dart';

void main() {
  // 10 input uji, angka acuan dihitung tangan dari 04-ai-pipeline.md §4.
  // Bentuk: kategori, jam sejak masak, suhu, skor harapan, rute harapan.
  const kasus = [
    ['roti', 6.0, 28.0, 85, 'b2c'],
    ['gorengan', 3.0, 28.0, 70, 'b2c'],
    ['gorengan', 4.0, 28.0, 60, 'b2b'],
    ['nasi_lauk', 2.0, 28.0, 85, 'b2c'],
    ['nasi_lauk', 2.0, 33.0, 70, 'b2c'],
    ['kue', 12.0, 28.0, 90, 'b2c'],
    ['seafood', 1.0, 28.0, 65, 'b2b'],
    ['santan_susu', 1.0, 28.0, 68, 'b2b'],
    ['minuman', 6.0, 31.0, 55, 'b2b'],
    ['lainnya', 1.0, 28.0, 93, 'b2c'],   // kategori tanpa shelf_life -> default 8 jam
  ];

  test('triage identik dengan rumus Python untuk 10 input', () {
    for (final k in kasus) {
      final r = FallbackEngine.triage(
        kategori: k[0] as String,
        jamSejakMasak: k[1] as double,
        ambientTemp: k[2] as double,
      );
      expect(r.score, k[3], reason: 'kategori ${k[0]} jam ${k[1]}');
      expect(r.route, k[4]);
    }
  });

  test('skor selalu di dalam 0..100', () {
    final r = FallbackEngine.triage(kategori: 'seafood', jamSejakMasak: 48, ambientTemp: 40);
    expect(r.score, 0);
    expect(r.route, 'b2b');
  });

  test('pricing dibatasi 70% dan dibulatkan ke Rp500', () {
    final r = FallbackEngine.pricing(
      originalPrice: 25000, jamTersisa: 0, jamTotal: 8,
      qtyRemaining: 10, qtyTotal: 10,
    );
    expect(r.diskon, 0.70);
    expect(r.harga, 7500);
    expect(r.harga % 500, 0);
  });

  test('pricing pada awal masa jual memakai diskon dasar', () {
    final r = FallbackEngine.pricing(
      originalPrice: 20000, jamTersisa: 8, jamTotal: 8,
      qtyRemaining: 0, qtyTotal: 10,
    );
    expect(r.diskon, closeTo(0.30, 1e-9));
    expect(r.harga, 14000);
  });

  test('forecast heuristik jujur soal sumbernya', () {
    final history = List.generate(14, (i) => SalesHistory(
      id: 'h$i', merchantId: 'm1',
      date: DateTime(2026, 8, 28 - i),
      portionsSold: 70, revenue: 700000,
      dayOfWeek: 0, isHoliday: false, weatherCode: 0, surplusKg: 2.0,
    ));
    final f = FallbackEngine.forecast(
      history: history,
      targetDate: DateTime(2026, 8, 30),
      weatherCode: 0,
    );
    expect(f.source, ForecastSource.heuristic);
    expect(f.confidence, 0.45);
    expect(f.demandX, greaterThan(0));
    expect(f.recommendedProduction, greaterThanOrEqualTo(f.demandX));
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/fallback_engine_test.dart`
Expected: FAIL — `fallback_engine.dart` belum ada.

- [ ] **Step 3: Implementasi persis rumus §4**

```dart
static TriageResult triage({
  required String kategori,
  required double jamSejakMasak,
  required double ambientTemp,
}) {
  final shelf = LestarConstants.shelfLifeJam[kategori] ?? 8;
  var score = 100.0;
  score -= (jamSejakMasak / shelf) * 60;
  if (ambientTemp > 30) score -= 15;
  if (kategori == 'seafood' || kategori == 'santan_susu') score -= 20;
  final s = score.round().clamp(0, 100);
  return TriageResult(
    score: s,
    route: s >= LestarConstants.ambangTriageB2c ? 'b2c' : 'b2b',
    reason: _alasanTriage(kategori, jamSejakMasak, shelf, ambientTemp),
  );
}
```

`pricing` mengikuti §4 apa adanya, dengan `diskonDasar`, faktor 0.35 dan 0.15, `min(diskon, diskonMaksimum)`, dan `(harga / 500).round() * 500`.
`forecast` mengikuti blok Dart di §5 apa adanya, termasuk `dowMultiplier`, ambang hujan `weatherCode >= 60`, dan `confidence: 0.45`.

- [ ] **Step 4: Jalankan test**

Run: `flutter test test/fallback_engine_test.dart`
Expected: PASS, 5 test.

- [ ] **Step 5: Commit**

```bash
git add lib/core/fallback_engine.dart lib/core/api/api_models.dart test/fallback_engine_test.dart
git commit -m "feat(core): fallback engine dengan rumus triage dan pricing deterministik"
```

---

### Task 7: Klien API dengan timeout dan fallback

**Files:**
- Create: `lib/core/api/lestar_api.dart`, `test/lestar_api_test.dart`

**Interfaces:**
- Consumes: `FallbackEngine`, `ForecastResult`, `TriageResult`, `PricingResult`, `LestarConstants.apiBaseUrl`.
- Produces:

```dart
class LestarApi {
  LestarApi({http.Client? client, String? baseUrl});
  Future<ForecastResult> forecast({required String merchantId, required List<SalesHistory> history, required DateTime targetDate, required int weatherCode, Map<String, dynamic>? merchantContext});
  Future<TriageResult> triage({required String kategori, required double jamSejakMasak, required double ambientTemp});
  Future<PricingResult> pricing({required double originalPrice, required double jamTersisa, required double jamTotal, required int qtyRemaining, required int qtyTotal});
  Future<String> esgNarrative({required Map<String, dynamic> agregat});
}
```

Timeout: forecast 4 dtk · triage 4 dtk · pricing 3 dtk · esg 8 dtk.

- [ ] **Step 1: Tulis test yang gagal (klien HTTP palsu)**

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lestar/core/api/lestar_api.dart';

void main() {
  test('triage jatuh ke fallback saat server mati, tidak melempar', () async {
    final api = LestarApi(
      client: http.MockClient((_) async => throw const SocketException('mati')),
      baseUrl: 'http://localhost:9',
    );
    final r = await api.triage(kategori: 'roti', jamSejakMasak: 6, ambientTemp: 28);
    expect(r.score, 85);
    expect(r.route, 'b2c');
    expect(r.fromFallback, true);
  });

  test('forecast jatuh ke heuristik saat timeout terlampaui', () async {
    final api = LestarApi(
      client: http.MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 6));
        return http.Response('{}', 200);
      }),
    );
    final f = await api.forecast(
      merchantId: 'm1', history: contohHistory(), targetDate: DateTime(2026, 8, 30), weatherCode: 0,
    );
    expect(f.source, ForecastSource.heuristic);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('respons 500 juga jatuh ke fallback', () async {
    final api = LestarApi(client: http.MockClient((_) async => http.Response('boom', 500)));
    final r = await api.pricing(originalPrice: 25000, jamTersisa: 0, jamTotal: 8, qtyRemaining: 10, qtyTotal: 10);
    expect(r.harga, 7500);
    expect(r.fromFallback, true);
  });
}
```

Catatan: `http.MockClient` datang dari `package:http/testing.dart` — impor itu di test, dan tambahkan `http` ke `dev_dependencies` tidak perlu karena sudah ada di `dependencies`.

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/lestar_api_test.dart`
Expected: FAIL — kelas belum ada.

- [ ] **Step 3: Implementasi**

Setiap metode membungkus `POST` dalam `try { ... }.timeout(d)` dan `catch (_) { return <fallback>; }`. Tidak ada `rethrow`. `esgNarrative` gagal → kalimat template lokal yang menyebut angka agregat, bukan string kosong.

- [ ] **Step 4: Jalankan test**

Run: `flutter test test/lestar_api_test.dart`
Expected: PASS, 3 test.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api test/lestar_api_test.dart
git commit -m "feat(core): klien API 4 endpoint, selalu jatuh ke fallback lokal"
```

---

### Task 8: Token, tipografi, tiga kerangka tema

**Files:**
- Create: `lib/core/theme/tokens.dart`, `light_glass.dart`, `dark_glass.dart`, `plain.dart`, `theme_for_role.dart`, `test/tokens_test.dart`

**Interfaces:**
- Produces: `LestarTokens` (13 warna), `LestarType.display({double size, double wght})`, `LestarType.body({double size, double wght})`, `LightGlassTheme.data`, `DarkGlassTheme.data`, `PlainTheme.data`, `themeForRole(UserRole)`.

- [ ] **Step 1: Tulis test yang gagal**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/theme/tokens.dart';
import 'package:lestar/core/theme/theme_for_role.dart';
import 'package:lestar/shared/models/models.dart';

void main() {
  test('token warna persis dari 03-design-system §3', () {
    expect(LestarTokens.forest, const Color(0xFF265938));
    expect(LestarTokens.emeraldDeep, const Color(0xFF009966));
    expect(LestarTokens.emerald, const Color(0xFF00BC7D));
    expect(LestarTokens.orange, const Color(0xFFF38222));
    expect(LestarTokens.danger, const Color(0xFFE5484D));
  });

  test('bobot font lewat fontVariations, bukan fontWeight', () {
    final s = LestarType.display(size: 90, wght: 800);
    expect(s.fontFamily, 'PlusJakartaSans');
    expect(s.fontVariations, [const FontVariation('wght', 800)]);
    expect(LestarType.body(size: 15).fontFamily, 'Inter');
  });

  test('tema dipilih dari role', () {
    expect(themeForRole(UserRole.consumer), LightGlassTheme.data);
    expect(themeForRole(UserRole.merchant), DarkGlassTheme.data);
    expect(themeForRole(UserRole.partner), PlainTheme.data);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/tokens_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementasi**

`tokens.dart` berisi 13 konstanta warna dan `LestarType` dengan dua pabrik `TextStyle` yang selalu memakai `fontVariations: [FontVariation('wght', wght)]`. Ketiga berkas tema hanya menyediakan `static final ThemeData data` dengan `colorScheme`, `scaffoldBackgroundColor`, `textTheme` dasar dan komentar `// Agent D/E/F: perkaya di sini`. Tidak ada dekorasi kaca di sini — itu milik D/E/F.

- [ ] **Step 4: Jalankan test**

Run: `flutter test test/tokens_test.dart`
Expected: PASS, 3 test.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/tokens_test.dart
git commit -m "feat(theme): token warna, tipografi variable font, 3 kerangka tema"
```

---

### Task 9: Widget bersama — kerangka bertanda tangan stabil

**Files:**
- Create: 14 berkas di `lib/shared/widgets/` + `widgets.dart` (barrel), `test/widgets_smoke_test.dart`

**Interfaces:**
- Produces:

```dart
GlassCard({Key? key, required Widget child, EdgeInsetsGeometry padding, VoidCallback? onTap, double borderRadius})
DarkGlassCard({Key? key, required Widget child, EdgeInsetsGeometry padding, VoidCallback? onTap, double borderRadius})
PlainCard({Key? key, required Widget child, EdgeInsetsGeometry padding, VoidCallback? onTap, double borderRadius})
BigButton({Key? key, required String label, VoidCallback? onPressed, bool loading, bool expanded, IconData? icon, BigButtonTone tone})   // tone: primary | danger | neutral
StatTile({Key? key, required String label, required String value, String? unit, IconData? icon, Widget? trailing})
SourceBadge({Key? key, required ForecastSource source})
DiscountPill({Key? key, required double percent})
PriceText({Key? key, required double price, double? originalPrice, double size})
CountdownChip({Key? key, required DateTime expiresAt})
LestarMap({Key? key, required LatLng center, double zoom, List<LestarMapMarker> markers, void Function(LestarMapMarker)? onMarkerTap, bool showUser})
QrDisplay({Key? key, required String data, double size, String? caption})
QrScanner({Key? key, required void Function(String) onDetect, String? hint})
EmptyState({Key? key, required String title, String? message, IconData? icon, Widget? action})
OfflineBanner({Key? key, required bool offline, String message})
```

`LestarMapMarker({required LatLng point, required Widget child, Object? payload})` didefinisikan di `lestar_map.dart`.

- [ ] **Step 1: Tulis smoke test yang gagal**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/shared/widgets/widgets.dart';

Widget bungkus(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('DiscountPill menampilkan persen bulat', (t) async {
    await t.pumpWidget(bungkus(const DiscountPill(percent: 0.52)));
    expect(find.text('-52%'), findsOneWidget);
  });

  testWidgets('PriceText mencoret harga asli', (t) async {
    await t.pumpWidget(bungkus(const PriceText(price: 12000, originalPrice: 25000)));
    expect(find.text('Rp 12.000'), findsOneWidget);
    expect(find.text('Rp 25.000'), findsOneWidget);
  });

  testWidgets('SourceBadge jujur saat heuristik', (t) async {
    await t.pumpWidget(bungkus(const SourceBadge(source: ForecastSource.heuristic)));
    expect(find.textContaining('Perkiraan lokal'), findsOneWidget);
  });

  testWidgets('EmptyState dan OfflineBanner terpasang', (t) async {
    await t.pumpWidget(bungkus(const Column(children: [
      OfflineBanner(offline: true),
      EmptyState(title: 'Belum ada apa-apa'),
    ])));
    expect(find.text('Belum ada apa-apa'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('BigButton memanggil onPressed sekali', (t) async {
    var n = 0;
    await t.pumpWidget(bungkus(BigButton(label: 'Beli', onPressed: () => n++)));
    await t.tap(find.text('Beli'));
    expect(n, 1);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/widgets_smoke_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementasi kerangka**

Setiap widget mengambil warna dari `Theme.of(context)` — bukan dari `LestarTokens` langsung, kecuali `DiscountPill` (isian oranye + teks `ink`, aturan kontras 7,2:1) dan `SourceBadge`. Isi visual seminimum mungkin; yang dikunci adalah tanda tangannya.

- [ ] **Step 4: Jalankan test**

Run: `flutter test test/widgets_smoke_test.dart`
Expected: PASS, 5 test.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets test/widgets_smoke_test.dart
git commit -m "feat(widgets): 14 widget bersama dengan tanda tangan yang dikunci"
```

---

### Task 10: Routing, AuthGate, tiga shell

**Files:**
- Create: `lib/core/routing/routes.dart`, `lib/core/routing/router.dart`, `lib/features/auth/presentation/login_screen.dart`, `lib/features/auth/presentation/auth_gate_screen.dart`, stub layar di `lib/features/{merchant,consumer,partner}/presentation/`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `currentProfileProvider`, `themeForRole`, `AuthRepository`.
- Produces: `routerProvider`, `Routes` (konstanta path), tiga shell.

Rute persis:
```
/login
/merchant · /merchant/inventory · /merchant/esg
/radar · /feed · /orders · /profile        (+ FAB QR ke /scan)
/partner · /partner/riwayat · /partner/langganan
```

- [ ] **Step 1: Tulis stub layar**

Sembilan stub berbentuk sama, contoh:

```dart
// lib/features/merchant/presentation/merchant_home_screen.dart
// STUB milik Agent B — Agent D menimpanya. Jangan tambahkan logika di sini.
import 'package:flutter/material.dart';

class MerchantHomeScreen extends StatelessWidget {
  const MerchantHomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Merchant · Beranda'));
}
```

- [ ] **Step 2: Tulis `router.dart`**

Pertahankan pola Ecobite: `RouterNotifier extends ChangeNotifier` yang mendengarkan `currentProfileProvider`, `redirect` yang (a) menunggu selama `isLoading`, (b) melempar tamu ke `/login`, (c) memantulkan pengguna yang sudah masuk dari `/login` ke beranda role-nya, (d) menolak lintas-role. Tiga `StatefulShellRoute.indexedStack`, satu per role, masing-masing dengan `Scaffold` + `NavigationBar` sendiri (pengganti `main_layout.dart` yang dibuang).

- [ ] **Step 3: Sambungkan tema per role di `main.dart`**

```dart
final profile = ref.watch(currentProfileProvider).value;
return MaterialApp.router(
  title: 'Lestar',
  theme: themeForRole(profile?.role ?? UserRole.consumer),
  routerConfig: ref.watch(routerProvider),
  debugShowCheckedModeBanner: false,
);
```

- [ ] **Step 4: Verifikasi**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/routing lib/features lib/main.dart
git commit -m "feat(routing): AuthGate dan tiga shell per role"
```

---

### Task 11: Pintasan demo dan bukti data nyata

**Files:**
- Create: `lib/core/demo/demo_accounts.dart`, `lib/core/demo/role_switcher.dart`, `tool/smoke_supabase.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `LestarConstants.demoMode`, seluruh repository.
- Produces: `DemoAccount` (`email`, `password`, `label`, `role`), `demoAccounts` (3 entri), `showRoleSwitcher(BuildContext, WidgetRef)`, `RoleSwitcherLogo` (widget app bar dengan `onLongPress`).

- [ ] **Step 1: Tulis `demo_accounts.dart`**

```dart
const demoAccounts = <DemoAccount>[
  DemoAccount(email: 'merchant@lestar.id', password: 'lestar2026', label: 'Verde Kitchen', role: UserRole.merchant),
  DemoAccount(email: 'amira@lestar.id',    password: 'lestar2026', label: 'Amira Rahmadani', role: UserRole.consumer),
  DemoAccount(email: 'budi@lestar.id',     password: 'lestar2026', label: 'Pak Budi', role: UserRole.partner),
];
```

- [ ] **Step 2: Tulis `role_switcher.dart`**

`RoleSwitcherLogo` hanya memasang `onLongPress` bila `LestarConstants.demoMode` true; kalau tidak, ia mengembalikan logo biasa. Bottom sheet menampilkan tiga akun; pilih → `signOut()` → `signIn()` → `router` memantulkan sendiri lewat `redirect`.

- [ ] **Step 3: Tulis `tool/smoke_supabase.dart`**

Skrip Dart yang login sebagai tiga akun demo dan memanggil satu metode dari setiap repository, mencetak jumlah baris. Ini bukti "tiap repository membaca data nyata". Harapan cetak:
```
profiles ok · merchants 30 · listings live 12 · nearby_listings >0 · orders ok
waste available 2 (16.6 kg) · sales_history 14 · esg_events 40
```

- [ ] **Step 4: Jalankan**

Run: `flutter test tool/smoke_supabase.dart` (ditulis sebagai test agar punya binding)
Expected: seluruh baris tercetak tanpa exception; `listings live` = 12, `waste available` total 16.6 kg.

- [ ] **Step 5: Uji realtime**

Buka skrip, biarkan `liveListingsStream()` mendengarkan, lalu lewat MCP Supabase `insert` satu listing uji dan pastikan stream memancarkan jumlah bertambah. Hapus baris uji setelahnya.

- [ ] **Step 6: Commit**

```bash
git add lib/core/demo tool/smoke_supabase.dart
git commit -m "feat(demo): pintasan ganti role dan skrip bukti data nyata"
```

---

### Task 12: Gerbang penutup dan serah terima

**Files:**
- Create: `docs/06-agent-briefs/B-HANDOFF.md`
- Modify: `docs/06-agent-briefs/README.md` (tandai B selesai, bila ada tabel status)

- [ ] **Step 1: Jalankan seluruh gerbang**

```bash
flutter analyze
flutter test
grep -ril firebase lib pubspec.yaml android ios
flutter build apk --release --dart-define=DEMO=true
```
Expected: analyze bersih · seluruh test lulus · grep kosong · APK ter-build.

- [ ] **Step 2: Uji mode pesawat**

Pasang APK, matikan WiFi dan data, buka app: teks harus tetap Plus Jakarta Sans / Inter (bukan Roboto), dan layar forecast harus menampilkan badge sumber `Perkiraan lokal`.

- [ ] **Step 3: Ukur ganti role**

Tekan-lama logo → pilih akun → hitung sampai shell baru tampil. Target < 3 detik. Catat angka sebenarnya di handoff.

- [ ] **Step 4: Tulis `B-HANDOFF.md`**

Enam bagian wajib: (1) daftar model + nama field persis, (2) tanda tangan tiap metode repository, (3) tanda tangan widget bersama, (4) nama rute per shell, (5) contoh `TextStyle` dengan `fontVariations`, (6) keputusan yang diambil sendiri + apa yang gagal atau dilewati.

- [ ] **Step 5: Commit**

```bash
git add docs/06-agent-briefs/B-HANDOFF.md
git commit -m "docs(core): serah terima Agent B untuk D, E, dan F"
```

---

## Catatan risiko

- **`C-HANDOFF.md` belum ada.** Angka acuan di Task 6 diturunkan dari `04-ai-pipeline.md` §4 sendiri, bukan dari `api/test_parity.py`. Saat Agent C selesai, jalankan ulang 10 input yang sama di Python dan bandingkan. Catat ini di handoff.
- **`listings.image_url` masih null untuk semua baris** (`A-HANDOFF.md` §8.2). Widget yang menampilkan gambar harus punya placeholder — D dan E sudah diberi tahu.
- **go_router 18 vs 17 di Ecobite.** Pola `StatefulShellRoute.indexedStack` tetap sama; kalau ada perubahan API, ikuti versi 18.
- **flutter_map 8 vs 7 di brief.** Brief menyebut `^7.0.2`; pub.dev sudah di `8.3.2`. Pakai 8 dan sesuaikan `MapOptions(initialCenter:)`.
