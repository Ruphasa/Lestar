# Agent B — Serah Terima Core & Migrasi

**Selesai** 30 Agustus 2026 · **Flutter** 3.47.1 / Dart 3.13.1 · **Paket** `lestar`

Fondasi siap. **D, E, dan F boleh mulai.** Semua yang ada di dokumen ini sudah
berjalan melawan project Supabase sungguhan (`vhauffhtjckzmqomcgrl`), bukan
data tiruan.

> **Aturan satu kalimat:** apa pun yang ada di dokumen ini adalah kontrak.
> Kalau kamu perlu mengubahnya, bilang dulu — tiga agent memakainya sekaligus.

---

## 0. Cara mulai

```bash
flutter pub get
flutter analyze          # harus: No issues found!
flutter test             # 59 test, semuanya lulus, tanpa jaringan

# Bukti data nyata (butuh jaringan):
flutter test tool/smoke_supabase.dart
flutter test tool/smoke_realtime.dart

# Build demo — pintasan ganti role hanya hidup di sini:
flutter run --dart-define=DEMO=true
flutter build apk --release --dart-define=DEMO=true
```

Login demo: `merchant@lestar.id` · `amira@lestar.id` · `budi@lestar.id`,
kata sandi `lestar2026`.

### Yang kamu miliki

| Agent | Milikmu | Jangan sentuh |
|---|---|---|
| D | `lib/features/merchant/`, `lib/core/theme/dark_glass.dart` | sisanya di `lib/core/`, `lib/shared/` |
| E | `lib/features/consumer/`, `lib/core/theme/light_glass.dart` | idem |
| F | `lib/features/partner/`, `lib/core/theme/plain.dart` | idem |

Dua belas berkas di `lib/features/*/presentation/` adalah **stub milikku** —
setiap berkas menyebutkan agent yang menimpanya di baris pertama. Tulis ulang
seluruh isinya; stub itu hanya ada supaya router bisa dikompilasi.

`lib/features/auth/` milikku, bukan milik kalian.

---

## 1. Sebelas model + nama field persis

`import 'package:lestar/shared/models/models.dart';` — satu impor, semuanya
ikut.

Aturan yang berlaku di seluruh model:

- `fromJson(Map<String, dynamic>)` dan `toJson()` ditulis tangan. Tidak ada
  `build_runner`.
- `toJson()` **tidak menyertakan `id`** (dibuat database) dan membuang pasangan
  bernilai null.
- Kolom `timestamptz` → `DateTime` **lokal**. Kolom `date` → `DateTime` tanpa
  konversi zona waktu (menggesernya bisa memundurkan tanggal satu hari).
- `numeric` PostgREST bisa datang sebagai `num` **atau** `String`; keduanya
  sudah ditangani.

### Profile — `profiles`
```dart
String id · String name · String email · String? phone · String? address
UserRole role · int ecoPoints · String? avatarUrl · DateTime createdAt
```
`id` = `auth.uid()`. Baris dibuat trigger saat registrasi — jangan insert.

### Merchant — `merchants`
```dart
String id · String storeName · String storeAddress · double lat · double lng
String? storeImage · String? category · String? operatingHours
String cutoffTime          // kolom `time`, mis. "22:00:00" — String, bukan DateTime
double rating · double totalEarnings · double totalWasteSavedKg · int level
```
Turunan: `cutoffJam`, `cutoffMenit`.
`merchants.id` = `profiles.id` = `auth.uid()`. Tidak ada kolom `merchant_id`.

### Partner — `partners`
```dart
String id · String orgName · String? partnerType
List<WasteType> wastePreference     // array enum: {wet}, {dry}, {wet,dry}
String? vehicleType · String? licensePlate · double serviceRadiusKm
double baseLat · double baseLng · int totalPickups · DateTime? subscriptionExpiry
```
Turunan: `langgananAktif`.

### Listing — `listings`
```dart
String id · String merchantId · String name · String? description
String category · String? imageUrl
int qtyTotal · int qtyRemaining · double originalPrice · double price
DateTime cookedAt · DateTime expiresAt
int? triageScore · String? triageReason
bool physicalValidated · DateTime? physicalValidatedAt
ListingStatus status · DateTime createdAt
```
Turunan: `discountPercent` (0..1, bukan persen) · `isExpired` · `sisaWaktu`
(`Duration`) · `tampilDiRadar`.

> **`imageUrl` masih null untuk SELURUH baris seed.** Fotonya belum ada
> (`A-HANDOFF.md` §8.2). D dan E wajib punya placeholder yang rapi — ini
> kondisi sekarang, bukan keadaan darurat.

### Order — `orders`
```dart
String id · String consumerId · String merchantId
double subtotal · double greenFee · double total · OrderStatus status
String? qrToken · DateTime? qrExpiresAt · String? paymentMethod
DateTime orderedAt · DateTime? paidAt · DateTime? claimedAt
List<OrderItem> items     // tidak ikut toJson; diisi itemsOf() atau select bersarang
```
Turunan: `qrValid` (token ada **dan** status `paid` **dan** belum kedaluwarsa) ·
`totalPorsi`.

### OrderItem — `order_items`
```dart
String id · String orderId · String? listingId
String nameSnapshot · int qty · double unitPrice
```
Turunan: `lineTotal`. Pabrik `OrderItem.baru(...)` untuk item yang belum punya
order — dipakai `createOrder`.

### WasteBatch — `waste_batches`
```dart
String id · String sourceMerchantId · String? sourceListingId
WasteType wasteType · String? description · double weightKg · double price
String pickupAddress · double lat · double lng
DateTime? pickupWindowStart · DateTime? pickupWindowEnd · String? imageUrl
WasteStatus status · String? matchedPartnerId
DateTime createdAt · DateTime? completedAt
```
Turunan: `dariKaskade` (`sourceListingId != null`) · `co2DihindariKg`.

### Forecast — `forecasts`
```dart
String id · String merchantId · DateTime forecastDate    // kolom date
double demandX · double surplusProbabilityY · double? surplusVolumeEstKg
int recommendedProduction · double? confidence · String? narrative
ForecastSource source · DateTime createdAt
```
Turunan: `dariModel`.

### SalesHistory — `sales_history`
```dart
String id · String merchantId · DateTime date       // kolom date
int portionsSold · double revenue
int dayOfWeek        // 0 = SENIN, 6 = Minggu — bukan DateTime.weekday
bool isHoliday · int? weatherCode · double surplusKg
```
Statis: `SalesHistory.dayOfWeekDari(DateTime)` mengonversi ke konvensi tabel.

### EsgEvent — `esg_events` (**baca saja**)
```dart
String id · String merchantId · EsgEventType eventType · String refId
double weightKg · double co2SavedKg · double revenueRecovered · DateTime occurredAt
```
Tidak punya `toJson`, dan itu disengaja: barisnya lahir dari trigger saat
`orders.status` jadi `claimed` dan `waste_batches.status` jadi `completed`.
Menulis manual akan ditolak `unique (event_type, ref_id)`.

### EsgAggregate — hasil hitungan, bukan tabel
```dart
double totalWeightKg · double totalCo2Kg · double totalRevenueRecovered
int mealsRescued · DateTime periodStart · DateTime periodEnd
```
`EsgAggregate.kosong(start, end)` untuk periode tanpa peristiwa.

### EsgReport — `esg_reports`
```dart
String id · String merchantId · DateTime periodStart · DateTime periodEnd
double totalWeightKg · double totalCo2Kg · double totalRevenueRecovered
int mealsRescued · String? narrative · String? pdfUrl · DateTime createdAt
```
Bucket `esg-reports` **privat** — `pdfUrl` butuh signed URL.

### NearbyListing / NearbyWaste — hasil dua RPC geo

Bukan tabel: gabungan listing/batch + data toko + `jarakKm`. Kolomnya persis
seperti `A-HANDOFF.md` §2, termasuk `storeName` dan `jarakKm` (kilometer,
terurut menaik). `NearbyListing` juga punya `discountPercent` dan `sisaWaktu`;
`NearbyWaste` punya `dariKaskade`.

### Tujuh enum

Setiap enum punya `.wire` (String yang dipahami database) dan `X.parse(dynamic)`
yang **tidak pernah melempar** — nilai tak dikenal jatuh ke default.

| Enum | Nilai | Default parse |
|---|---|---|
| `UserRole` | consumer · merchant · partner | `consumer` |
| `ListingStatus` | draft · live · soldOut · expired · cascaded | `draft` |
| `WasteType` | wet · dry | `wet` |
| `WasteStatus` | available · matched · pickedUp · completed · cancelled | `available` |
| `OrderStatus` | pending · paid · ready · claimed · cancelled · expired | `pending` |
| `ForecastSource` | lstmGemini · lstmOnly · heuristic | `heuristic` |
| `EsgEventType` | b2cRescued · b2bDiverted | `b2cRescued` |

`WasteType.parseList(dynamic)` untuk kolom array `waste_preference`.

`ForecastSource` default sengaja `heuristic`: sumber yang tidak dikenali tidak
boleh menyamar sebagai hasil model.

> **Jangan `import 'shared/models/json.dart'` kecuali kamu memang perlu.**
> Helper `toDouble`/`toInt` di sana bertabrakan nama dengan yang diekspor
> `realtime_client` lewat `supabase_flutter`. `models.dart` sengaja hanya
> meneruskan `dateKeWire`.

---

## 2. Tujuh repository — tanda tangan lengkap

```dart
import 'package:lestar/shared/repositories/repositories.dart';
```

Pakai lewat provider, jangan membuat instans sendiri:

```dart
final repo = ref.watch(listingRepositoryProvider);
```

Provider yang tersedia: `authRepositoryProvider` · `profileRepositoryProvider` ·
`listingRepositoryProvider` · `orderRepositoryProvider` ·
`wasteRepositoryProvider` · `forecastRepositoryProvider` ·
`esgRepositoryProvider` · `lestarApiProvider`.

### AuthRepository
```dart
Future<Profile?> signIn(String email, String password)   // boleh melempar AuthException
Future<void>     signOut()
Future<Profile?> currentProfile()
Stream<AuthState> authStateStream()
Session?         get session
```

### ProfileRepository
```dart
Future<Profile?>  getProfile(String id)
Future<Merchant?> getMerchant(String id)
Future<Partner?>  getPartner(String id)
Future<Profile>   updateProfile(String id, Map<String, dynamic> patch)
Future<Merchant>  updateMerchant(String id, Map<String, dynamic> patch)
Future<Partner>   updatePartner(String id, Map<String, dynamic> patch)
```

### ListingRepository
```dart
Future<Listing>              createListing(Listing listing)
Future<Listing>              validatePhysical(String listingId)
Stream<List<Listing>>        liveListingsStream()
Future<List<NearbyListing>>  nearbyListings({required double lat, required double lng, double radiusKm = 5})
Stream<List<Listing>>        merchantListings(String merchantId)
Future<Listing?>             getListing(String id)
Future<List<Listing>>        merchantListingsSekali(String merchantId)
```

### OrderRepository
```dart
Future<Order>          createOrder({required String merchantId, required List<OrderItem> items})
Future<Order>          pay(String orderId, {String paymentMethod = 'simulasi'})
Future<Order>          claimByQr(String qrToken)      // melempar StateError berisi pesan siap tampil
Stream<List<Order>>    consumerOrders(String consumerId)
Stream<List<Order>>    merchantOrders(String merchantId)
Future<List<OrderItem>> itemsOf(String orderId)
Future<Order?>         getOrder(String orderId)       // ikut order_items
```

### WasteRepository
```dart
Stream<List<WasteBatch>>  availableStream()
Future<List<NearbyWaste>> nearbyWaste({required double lat, required double lng, double radiusKm = 10})
Future<WasteBatch>        matchPartner(String batchId, String partnerId)
Future<WasteBatch>        updateStatus(String batchId, WasteStatus status)
Stream<List<WasteBatch>>  merchantWaste(String merchantId)
Stream<List<WasteBatch>>  partnerWaste(String partnerId)
Future<WasteBatch>        createBatch(WasteBatch batch)
Future<WasteBatch?>       getBatch(String id)
```

### ForecastRepository
```dart
Future<Forecast?>          getForecast(String merchantId, DateTime date)
Future<Forecast>           saveForecast(Forecast forecast)   // upsert per (merchant, tanggal)
Future<List<SalesHistory>> recentSalesHistory(String merchantId, {int days = 14})
```
`recentSalesHistory` mengembalikan **terbaru dulu** — urutan yang diharapkan
`FallbackEngine.forecast`.

### EsgRepository
```dart
Future<List<EsgEvent>>  eventsInPeriod(String merchantId, DateTime start, DateTime end)
Future<EsgAggregate>    aggregate(String merchantId, DateTime start, DateTime end)
Future<EsgReport>       saveReport(EsgReport report)
Future<List<EsgReport>> reportsOf(String merchantId)
```

### Yang perlu kamu tahu tentang stream

Setiap `Stream` di atas **menyaring ulang di sisi klien**, bukan hanya
mengandalkan RLS. RLS menentukan baris mana yang boleh dibaca; ia tidak
menentukan baris mana yang menarik. Tanpa saringan kedua, setiap perubahan
listing siapa pun akan memicu rebuild radar. `expires_at > now()` juga tidak
bisa dititipkan ke kueri stream, karena nilainya bergerak sementara kuerinya
tidak.

Konsekuensinya untuk kalian: **jangan menyaring ulang hal yang sama di layar.**
`liveListingsStream()` sudah dijamin hanya berisi listing `live`, bersisa stok,
dan belum kedaluwarsa, terurut paling cepat kedaluwarsa dulu.

### Yang TIDAK boleh ditulis aplikasi

- `esg_events` — trigger yang mengisi.
- `qty_remaining` — trigger `sync_qty_remaining` yang mengurangi, saat status
  order jadi `claimed`.
- Pembatalan jemput: pakai `updateStatus(id, WasteStatus.cancelled)`,
  **jangan** mengosongkan `matched_partner_id` — policy `WITH CHECK` menolaknya
  (`A-HANDOFF.md` §8.6).

---

## 3. Widget bersama — tanda tangan yang dikunci

```dart
import 'package:lestar/shared/widgets/widgets.dart';
```

Empat belas widget. **Perkaya tampilannya lewat tema kalian masing-masing atau
isi `build`-nya; jangan menambah, menghapus, atau mengubah tipe parameter.**
Kalau tanda tangannya berubah, dua agent lain ikut rusak tanpa tahu sebabnya.

```dart
GlassCard({Key? key, required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16),
           VoidCallback? onTap, double borderRadius = 20})
DarkGlassCard({ ...identik dengan GlassCard... })
PlainCard({ ...identik dengan GlassCard... })

BigButton({Key? key, required String label, VoidCallback? onPressed,
           bool loading = false, bool expanded = true, IconData? icon,
           BigButtonTone tone = BigButtonTone.primary})       // primary | danger | neutral

StatTile({Key? key, required String label, required String value, String? unit,
          IconData? icon, Widget? trailing, double valueSize = 32})

SourceBadge({Key? key, required ForecastSource source, bool compact = false})
DiscountPill({Key? key, required double percent, bool compact = false})   // percent 0..1
PriceText({Key? key, required double price, double? originalPrice, double size = 20})
CountdownChip({Key? key, required DateTime expiresAt, bool compact = false})

LestarMap({Key? key, required LatLng center, double zoom = 14,
           List<LestarMapMarker> markers = const [],
           void Function(LestarMapMarker)? onMarkerTap,
           bool showUser = false, MapController? controller})
LestarMapMarker({required LatLng point, required Widget child, Object? payload,
                 double width = 44, double height = 44})

QrDisplay({Key? key, required String data, double size = 240, String? caption})
QrScanner({Key? key, required void Function(String kode) onDetect, String? hint})

EmptyState({Key? key, required String title, String? message, IconData? icon, Widget? action})
OfflineBanner({Key? key, required bool offline,
               String message = 'Sedang offline — data terakhir yang tersimpan.'})
```

Catatan perilaku yang sudah diputuskan:

- `BigButton` saat `loading: true` menolak tekanan sendiri — kamu tidak perlu
  ikut menonaktifkan `onPressed`.
- `DiscountPill` memakai isian oranye dengan teks `ink` (7,2:1 AAA).
  **Jangan menukarnya jadi putih** — kombinasi itu gagal kontras.
- `QrDisplay` selalu berlatar putih apa pun temanya; pemindai butuh kontras
  penuh dan tema merchant berlatar hitam.
- `QrScanner` mengunci diri setelah kode pertama supaya satu QR tidak memicu
  klaim berkali-kali dalam sedetik. Panggil `bukaKunci()` lewat `GlobalKey`
  kalau ingin memindai lagi.
- `SourceBadge` menampilkan **"Perkiraan lokal"** untuk `heuristic`. Jangan
  menyembunyikannya demi tampilan — `forecasts.source` selalu jujur adalah
  aturan proyek.
- `LestarMap` memakai OpenStreetMap lewat `flutter_map` 8: tanpa API key, jadi
  tidak ada kunci yang bisa bocor lewat APK.

### Pembantu format — pakai ini, jangan menulis sendiri

```dart
import 'package:lestar/core/utils/formatters.dart';

Fmt.rupiah(12000)          // Rp 12.000
Fmt.angka(1240)            // 1.240
Fmt.diskon(0.52)           // -52%
Fmt.kg(9.2)                // 9,2 kg
Fmt.jarak(1.06)            // 1,1 km   (< 1 km jadi meter, > 10 km dibulatkan)
Fmt.tanggal(dt) · Fmt.tanggalPanjang(dt) · Fmt.jam(dt)
Fmt.sisaWaktu(durasi)      // 2j 15m · 45m · Habis
Fmt.sejak(dt)              // 2 jam lalu · kemarin · 3 hari lalu
Fmt.kategori('nasi_lauk')  // Nasi Lauk
```

```dart
import 'package:lestar/core/utils/error_handler.dart';
pesanError(e)      // exception -> kalimat Bahasa Indonesia yang boleh dilihat pengguna
masalahJaringan(e) // true kalau ini soal koneksi, bukan kesalahan pengguna
```

---

## 4. Rute per shell

```dart
import 'package:lestar/core/routing/routes.dart';
context.go(Routes.radar);
```

| Konstanta | Path | Shell |
|---|---|---|
| `Routes.login` | `/login` | — |
| `Routes.merchantHome` | `/merchant` | MerchantShell tab 1 |
| `Routes.merchantInventory` | `/merchant/inventory` | MerchantShell tab 2 |
| `Routes.merchantEsg` | `/merchant/esg` | MerchantShell tab 3 |
| `Routes.merchantScan` | `/merchant/scan` | di luar shell, layar penuh |
| `Routes.radar` | `/radar` | ConsumerShell tab 1 |
| `Routes.feed` | `/feed` | ConsumerShell tab 2 |
| `Routes.orders` | `/orders` | ConsumerShell tab 3 |
| `Routes.profile` | `/profile` | ConsumerShell tab 4 |
| `Routes.qr` | `/qr` | FAB tengah, di luar shell |
| `Routes.partnerHome` | `/partner` | PartnerShell tab 1 |
| `Routes.partnerRiwayat` | `/partner/riwayat` | PartnerShell tab 2 |
| `Routes.partnerLangganan` | `/partner/langganan` | PartnerShell tab 3 |

Pembantu: `Routes.berandaUntuk(role)` dan `Routes.pemilikPath(path)`.

**Menambah rute baru:** tulis konstantanya di `routes.dart`, daftarkan di
`router.dart`, dan kalau path-nya di luar prefix yang sudah ada, perbarui juga
`Routes.pemilikPath` — kalau tidak, penjaga lintas-role akan membiarkannya
terbuka untuk semua role. Beri tahu aku sebelum mengubah bentuk shell.

### AuthGate

`redirect` di `router.dart` melakukan empat hal, berurutan:
1. selama profil masih dimuat, tidak memindahkan ke mana pun;
2. tamu dipaksa ke `/login`;
3. yang sudah masuk dan berada di `/login` dilempar ke beranda role-nya;
4. yang mencoba masuk wilayah role lain dikembalikan ke berandanya.

**Kamu tidak perlu memanggil `context.go` setelah login.** Router yang
memindahkan sendiri begitu sesi terbentuk.

Provider sesi yang bisa kamu pakai:

```dart
import 'package:lestar/core/supabase/session.dart';

ref.watch(currentProfileProvider)   // AsyncValue<Profile?>
ref.watch(currentRoleProvider)      // UserRole?
ref.watch(currentMerchantProvider)  // AsyncValue<Merchant?>  (null untuk role lain)
ref.watch(currentPartnerProvider)   // AsyncValue<Partner?>   (null untuk role lain)
ref.watch(authStateProvider)        // AsyncValue<AuthState>
```

---

## 5. Cara memakai `fontVariations`

Kedua font adalah **variable font**: satu berkas melayani semua bobot. Bobot
diatur lewat `fontVariations`, **bukan** `fontWeight`. Memakai `fontWeight`
pada berkas variable tampak benar di sebagian mesin dan salah di mesin lain.

Contoh satu `TextStyle` yang benar:

```dart
TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontVariations: [const FontVariation('wght', 800)],
  fontSize: 90,
)
```

Tapi **jangan menulisnya sendiri.** Pakai pabrik yang sudah ada:

```dart
import 'package:lestar/core/theme/tokens.dart';

LestarType.display(size: 32, wght: 700, color: cs.onSurface)
LestarType.body(size: 15, wght: 400)

// Skala 03-design-system.md §4, sudah jadi:
LestarType.angkaRaksasa()    // 90 / 800  — angka raksasa pengepul
LestarType.judulPengepul()   // 44 / 700
LestarType.angkaBesar()      // 48 / 700  — angka besar merchant
LestarType.judulLayar()      // 32 / 700
LestarType.judulKartu()      // 20 / 600
LestarType.isi()             // 15 / 400
LestarType.label()           // 13 / 500
LestarType.caption()         // 11 / 400
```

**Paket `google_fonts` tidak dipasang dan tidak boleh dipasang.** Paket itu
mengambil font lewat jaringan; saat WiFi dimatikan di penutup demo, teks akan
jatuh ke fallback sistem dan merusak momen yang justru ingin ditonjolkan.

### Token warna

```dart
LestarTokens.forest       // #265938  logo, teks pekat
LestarTokens.emeraldDeep  // #009966  tombol aksi
LestarTokens.emerald      // #00BC7D  ikon, garis, indikator — TIDAK PERNAH latar teks
LestarTokens.emeraldTint  // #ECFAEF
LestarTokens.orange       // #F38222  pill diskon, CTA beli, hitung mundur
LestarTokens.orangeText   // #C2540E  teks oranye di atas latar terang
LestarTokens.orangeTint   // #FFF1E4
LestarTokens.ink          // #0A0A0A
LestarTokens.inkSoft      // #171717
LestarTokens.muted        // #737373
LestarTokens.mutedSoft    // #A1A1A1
LestarTokens.surfaceGrey  // #F5F5F5
LestarTokens.danger       // #E5484D
```

`#12C56A` **dilarang** — nilai tebakan dari draf lama. Ada pengujian yang
menolaknya (`test/tokens_test.dart`).

Dua aturan kontras yang mengikat: isian oranye selalu memakai teks `ink`,
tidak pernah putih; `emerald` tidak pernah jadi latar teks.

### Tema — apa yang boleh kamu ubah

Berkas temamu (`dark_glass.dart` / `light_glass.dart` / `plain.dart`) milikmu
sepenuhnya, **kecuali empat hal** yang dipakai widget bersama:

- `colorScheme.primary` — `emeraldDeep` (konsumen, pengepul) / `emerald` (merchant)
- `colorScheme.secondary` — `orange`
- `colorScheme.onSecondary` — `ink`
- keluarga font: PlusJakartaSans untuk display, Inter untuk body

`test/tokens_test.dart` menjaga keempatnya. Kalau kamu mengubahnya, test itu
gagal — dan itu memang tujuannya.

---

## 6. Konstanta bersama

```dart
import 'package:lestar/core/constants.dart';

LestarConstants.faktorCo2PerKg     // 0.25
LestarConstants.greenFee           // 1000
LestarConstants.ambangTriageB2c    // 70
LestarConstants.diskonMaksimum     // 0.70
LestarConstants.diskonDasar        // 0.30
LestarConstants.qrMasaBerlakuJam   // 2
LestarConstants.beratPorsi('nasi_lauk')   // 0.35 — kategori asing jatuh ke 0.20
LestarConstants.shelfLife('roti')         // 24  — kategori asing jatuh ke 8
LestarConstants.kategoriListing           // 6 string yang dikenali database
LestarConstants.demoMode                  // bool.fromEnvironment('DEMO')
```

**Jangan menulis ulang angka-angka ini di berkas lain.** Nilainya sudah
diverifikasi baris demi baris terhadap `berat_porsi_kg()` dan
`faktor_co2_per_kg()` di `supabase/migrations/0005_intelligence.sql`.

---

## 7. Klien API dan fallback

```dart
final api = ref.watch(lestarApiProvider);

final f = await api.forecast(merchantId: id, history: riwayat,
                             targetDate: besok, weatherCode: 0);
final t = await api.triage(kategori: 'roti', jamSejakMasak: 6, ambientTemp: 28);
final p = await api.pricing(originalPrice: 25000, jamTersisa: 2, jamTotal: 8,
                            qtyRemaining: 4, qtyTotal: 10);
final teks = await api.esgNarrative(agregat: agregat.toJson());
```

**Tidak ada satu pun metode di `LestarApi` yang melempar exception.** Server
mati, timeout terlampaui, respons bukan JSON, atau Agent C belum menyerahkan
alamat servernya — semuanya jatuh ke `FallbackEngine` dan mengembalikan angka
yang masuk akal. Kamu tidak perlu `try/catch` di sekitarnya.

Cara membaca hasilnya:

- `ForecastResult.source` — `lstmGemini` / `lstmOnly` / `heuristic`.
  Tampilkan lewat `SourceBadge(source: f.source)`.
- `TriageResult.fromFallback` dan `PricingResult.fromFallback` — true kalau
  angkanya dihitung lokal.

Timeout: forecast 4 dtk · triage 4 dtk · pricing 3 dtk · esg 8 dtk.

Alamat server dipasang saat build:
```bash
flutter run --dart-define=API_BASE_URL=https://....railway.app --dart-define=DEMO=true
```
Kalau kosong, klien **langsung** memakai fallback tanpa menunggu timeout.

---

## 8. Pintasan demo

Hidup hanya di build `--dart-define=DEMO=true`. Di build biasa, jalurnya hilang
saat tree-shaking — tidak ada gestur tersembunyi yang bisa ditemukan pengguna
sungguhan.

Tekan-lama logo di app bar → bottom sheet tiga akun → pilih → keluar dan masuk
diam-diam → router memindahkan sendiri ke shell yang sesuai.

Kalau layarmu punya app bar sendiri, pasang logonya begini:

```dart
import 'package:lestar/core/demo/role_switcher.dart';

AppBar(title: const Row(children: [
  RoleSwitcherLogo(size: 28), SizedBox(width: 10), Text('Lestar'),
]))
```

`MerchantShell` sudah memakainya. `ConsumerShell` dan `PartnerShell` tidak
punya app bar (keputusan desain E dan F) — kalau kalian menambahkan app bar,
pasang `RoleSwitcherLogo` di sana supaya pintasan demo tetap ada di ketiga role.

---

## 9. Keadaan data sekarang — terverifikasi, bukan disalin dari dokumen A

Dijalankan `flutter test tool/smoke_supabase.dart` pada 30 Agustus 2026:

```
auth ok · merchant@lestar.id · Verde Kitchen · merchant
auth ok · amira@lestar.id · Amira Rahmadani · consumer
auth ok · budi@lestar.id · Pak Budi · partner
merchant ok · Verde Kitchen · cutoff 22:00:00
partner ok · Maggot Berkah Malang · preferensi wet · radius 10.0 km
listing live 12
nearby_listings 12 baris · terdekat 0.35 km
liveListingsStream 12 listing
orders konsumen 4
waste available 2 batch · 16.6 kg
nearby_waste 2 baris · dari kaskade 0
sales_history 14 baris · terbaru 2026-08-28
esg merchant ini · 80.4 kg · 20.1 kg CO2 · 16 porsi
esg_events terlihat oleh merchant ini 24
```

Dua catatan yang perlu kalian tahu:

1. **Data seed ada di Malang**, bukan Bandung. Pak Budi adalah "Maggot Berkah
   Malang". Kalau kalian menulis koordinat uji sendiri, ambil dari tabel
   `merchants`, jangan menebak — titik yang salah mengembalikan nol baris tanpa
   ada yang rusak di kodenya.
2. **`esg_events` terlihat 24, bukan 40.** Angka 40 di `A-HANDOFF.md` §5 adalah
   jumlah seluruh project, yang hanya terlihat oleh service role. RLS
   membatasi merchant pada peristiwanya sendiri. Ini benar, bukan bug.

Realtime, `flutter test tool/smoke_realtime.dart`:
```
sebelum insert · 12 listing live
sesudah insert · 13 listing live
urutan snapshot yang diterima · [12, 13]
baris uji dihapus
```

### Diuji di emulator dengan APK release

APK `--dart-define=DEMO=true` (67,6 MB) dipasang di emulator Android 16
(API 36) dan dijalankan sungguhan:

| Yang diuji | Hasil |
|---|---|
| `merchant@lestar.id` masuk | mendarat di MerchantShell, tema gelap, 3 tab |
| Ganti role ke Pak Budi | PartnerShell, tema polos, label HURUF BESAR |
| Ganti role ke Amira | ConsumerShell, 4 tab + FAB QR emeraldDeep |
| Waktu ganti role | di bawah 3 detik (diukur ~2,7 dtk termasuk jeda tangkap layar) |
| Font di mode pesawat | tetap Plus Jakarta Sans / Inter, tidak jatuh ke Roboto |
| Sesi setelah WiFi mati | bertahan, langsung ke shell yang benar |

**Tiga cacat ditemukan lewat pengujian ini dan sudah diperbaiki**, bukan
dicatat sebagai utang:

1. **Indikator nav tampil oranye.** Material 3 memakai
   `colorScheme.secondaryContainer` untuk indikator `NavigationBar`, dan
   `secondaryContainer` kita bernuansa oranye — padahal oranye khusus untuk
   uang dan peringatan. Ketiga tema sekarang memaksa indikatornya hijau, dan
   ada pengujiannya di `test/tokens_test.dart`. **D/E/F: jangan menghapus
   `navigationBarTheme` dari tema kalian tanpa mengganti indikatornya.**

2. **Tidak ada jalan ganti role dari shell konsumen dan pengepul.** Keduanya
   sengaja tanpa app bar, jadi tidak ada logo untuk ditekan-lama. Sekarang ada
   `DemoCornerTap` — area tak terlihat 48x48 di sudut kiri atas yang hanya
   menangkap tekan-lama, dan di build non-demo tidak menggambar maupun
   menangkap apa pun. Sudah terpasang di kedua shell; kalau kalian mengganti
   `body` shell, pertahankan `Stack` yang membungkusnya.

3. **WiFi mati melempar pengguna kembali ke layar login**, meski sesinya masih
   sah — membaca tabel `profiles` butuh jaringan. Sekarang
   `currentProfileProvider` jatuh ke metadata JWT (`name`, `role`, `phone`,
   `avatar_url` yang disalin trigger `on_auth_user_created`). Cukup untuk
   memilih shell dan tema; `ecoPoints` di jalur ini nol, jadi layar yang
   menampilkannya perlu tahan terhadap angka nol.

---

## 10. Keputusan yang aku ambil sendiri

Semuanya karena tidak tertulis di dokumen, dan semuanya memilih jalan paling
sederhana yang masih benar.

1. **Proyek dibuat `flutter create` baru, bukan menyalin repo Ecobite.**
   Yang diwarisi dari Ecobite adalah polanya — `GoRouter` +
   `StatefulShellRoute`, repository, Riverpod — bukan berkasnya. Menyalin
   16.882 baris Dart lalu membuang Firebase dari dalamnya lebih lambat dan
   menyisakan jejak. Konfigurasi signing Ecobite ternyata tidak ada yang
   istimewa: rilisnya memakai kunci debug, sama seperti hasil `flutter create`.
   Konsekuensinya nol impor Firebase dijamin secara struktural, bukan lewat
   pembersihan.

2. **Hanya platform Android yang di-scaffold.** Demo memakai APK; iOS, web,
   dan desktop hanya menambah berkas yang tidak pernah dibuka. Menambahkannya
   nanti satu perintah: `flutter create --platforms ios .`.

3. **Dua belas stub layar dibuat di `lib/features/*/presentation/`**, wilayah
   D/E/F. Tanpa itu router tidak bisa dikompilasi dan "tiga akun demo mendarat
   di shell yang benar" tidak bisa dibuktikan. Setiap stub menyebutkan agent
   pemiliknya di baris pertama dan tidak berisi logika apa pun.

4. **`lib/features/auth/` aku ambil**, karena tidak ada di daftar milik D, E,
   maupun F, dan layar login diperlukan sebelum siapa pun bisa masuk.

5. **Tiga shell dan `NavigationBar`-nya ada di `lib/core/routing/shells.dart`**,
   bukan di wilayah D/E/F, karena ketiganya pengganti `main_layout.dart` yang
   dibuang dan harus stabil untuk ketiganya. Isi tab bebas kalian ubah; bentuk
   shell jangan.

6. **Versi paket diverifikasi ke pub.dev, dan sebagian lebih baru dari brief.**
   `flutter_map` 8.3.2 (brief menyebut ^7.0.2 — API `MapOptions` berubah ke
   `initialCenter`/`initialZoom`), `go_router` 18.0.0 (Ecobite 17),
   `latlong2` 0.10.1, `geolocator` 14.0.3, `intl` 0.20.3,
   `supabase_flutter` 2.17.2, `flutter_riverpod` 3.4.2.

7. **`google_fonts` dicabut sepenuhnya**, meski `B-core.md` §1 mencantumkannya
   di daftar "dipertahankan". Bagian §5b di brief yang sama melarang memakainya
   untuk kedua font kita, dan tidak ada font ketiga. Menyimpan paket yang tidak
   dipakai hanya menambah godaan.

8. **`anonKey` diganti `publishableKey`** di `Supabase.initialize` — parameter
   lama sudah `@Deprecated` di supabase_flutter 2.17, dan kunci yang kita punya
   memang `sb_publishable_...`.

9. **Kunci Supabase dibundel sebagai default `String.fromEnvironment`.**
   Publishable key aman untuk publik dan dilindungi RLS; menaruhnya sebagai
   default berarti `flutter run` polos langsung jalan. Bisa ditimpa
   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
   Service role key tidak ada di mana pun dalam kode Dart.

10. **`json.dart` tidak di-export penuh dari `models.dart`.** Helper
    `toDouble`/`toInt` bertabrakan nama dengan yang diekspor `realtime_client`
    lewat `supabase_flutter`, dan tabrakan itu baru muncul di berkas yang
    mengimpor keduanya — persis yang akan kalian lakukan.

11. **`EsgRepository.aggregate` menjumlahkan di sisi klien**, tidak menambah
    RPC baru. `supabase/` wilayah Agent A, dan jumlah peristiwa satu merchant
    per periode kecil (24 baris untuk seluruh data seed).

12. **`OrderRepository.claimByQr` memeriksa masa berlaku dan status di
    aplikasi.** Agent A sengaja tidak membatasi transisi status di database
    (keputusan A no. 13), jadi lapisan aplikasi yang memutuskan. Melempar
    `StateError` dengan pesan siap tampil: "QR sudah kedaluwarsa.", "QR ini
    sudah pernah diklaim.", "Pesanan belum dibayar.".

13. **`Merchant.cutoffTime` disimpan sebagai `String`**, bukan `DateTime`.
    Kolomnya bertipe `time` tanpa tanggal; membungkusnya jadi `DateTime` akan
    menempelkan tanggal palsu yang cepat atau lambat dipakai orang untuk
    berhitung. Ada `cutoffJam` dan `cutoffMenit` untuk itu.

14. **Sepuluh input uji parity dihitung tangan dari rumus di
    `04-ai-pipeline.md` §4**, bukan diambil dari keluaran implementasi mana
    pun. Kalau diambil dari salah satunya, pengujian hanya membuktikan kode
    cocok dengan dirinya sendiri. Daftarnya ada di bagian 12 di bawah — Agent C
    tinggal menyalinnya.

15. **`FallbackEngine.triage` memakai shelf life default 8 jam** untuk kategori
    di luar daftar. `02-data-model.md` §10 tidak menyebutkan nilai default
    untuk shelf life (hanya untuk berat porsi), dan 8 jam adalah nilai
    `nasi_lauk`, kategori paling umum. Agent C harus memakai angka yang sama.

16. **`smoke_supabase.dart` dan `smoke_realtime.dart` ditaruh di `tool/`,
    bukan `test/`.** Keduanya butuh jaringan dan project sungguhan; kalau ikut
    `flutter test`, setiap orang tanpa koneksi akan melihat "test gagal" yang
    bukan salah kodenya.

---

## 11. Yang gagal, dilewati, atau perlu perhatian

### 11.1 Parity dengan Agent C belum bisa dibuktikan dua arah
`C-HANDOFF.md` belum ada, jadi `api/test_parity.py` belum bisa dijalankan.
Versi Dart sudah lulus 10 input uji melawan angka yang dihitung tangan dari
rumus. **Begitu Agent C selesai, jalankan sepuluh baris yang sama di Python
dan bandingkan** — kalau berbeda, yang salah hampir pasti pembulatan
(`round()` Python membulatkan setengah ke genap; Dart membulatkan menjauhi
nol — `92.5` jadi `92` di Python, `93` di Dart).

Ini bukan masalah teoretis: kasus `lainnya · 1 jam · 28°C` menghasilkan tepat
`92.5`. Kalau Agent C memakai `round()` bawaan Python, angkanya akan berbeda 1.

### 11.2 Foto listing masih null
Bukan pekerjaanku dan bukan hal baru (`A-HANDOFF.md` §8.2), tapi berdampak
langsung ke D dan E: `listing.imageUrl` null untuk **seluruh** baris seed.
Siapkan placeholder yang rapi sejak awal, jangan menundanya.

### 11.3 `flutter_map` naik dari 7 ke 8
Brief menyebut `^7.0.2`; pub.dev sudah di 8.3.2. API berubah:
`MapOptions(center:, zoom:)` jadi `MapOptions(initialCenter:, initialZoom:)`.
`LestarMap` sudah memakai versi 8. Kalau kalian mencari contoh di internet,
pastikan contohnya untuk v8.

### 11.4 Belum diuji di perangkat fisik
Emulator dan APK release sudah (lihat bagian 9), perangkat sungguhan belum —
tidak ada perangkat Android yang terhubung ke mesin ini. Yang paling mungkin
berbeda di HP entry-level Pak Budi: kecepatan blur `BackdropFilter` di
`GlassCard`/`DarkGlassCard`. Agent F sudah benar tidak memakainya.

### 11.4b Build rilis pertama gagal karena cache Kotlin
`:shared_preferences_android:compileReleaseKotlin` gagal dengan
`Could not close incremental caches`. Ini masalah penguncian berkas di
Windows, bukan kode kita. `kotlin.incremental=false` sudah ditambahkan ke
`android/gradle.properties` dan build berikutnya lolos dalam ~1 menit.
Kalau kalian bertemu error yang sama, hapus foldernya
(`build/<nama_plugin>`) lalu build ulang.

### 11.5 `partner_subscriptions` belum punya repository
Tabelnya ada, modelnya belum aku buat. Brief menyebut tujuh repository dan
sebelas model, dan langganan mitra ada di urutan pertama daftar korban kalau
waktu habis (`docs/README.md`). Agent F: kalau layar langganan jadi dibangun,
bilang — modelnya sepuluh menit.

### 11.6 `notifications` juga belum
Alasan yang sama: tidak ada di daftar sebelas model, dan tidak ada layar yang
menampilkannya di brief mana pun.

---

## 12. Sepuluh input uji parity — untuk Agent C

Salin apa adanya ke `api/test_parity.py`. Rumusnya di `04-ai-pipeline.md` §4;
angka harapannya dihitung tangan, bukan diambil dari keluaran Dart.

| # | kategori | jam sejak masak | suhu °C | skor | rute | dari mana angkanya |
|---|---|---|---|---|---|---|
| 1 | `roti` | 6 | 28 | 85 | b2c | 100 − 6/24×60 |
| 2 | `gorengan` | 3 | 28 | 70 | b2c | 100 − 3/6×60, tepat di ambang |
| 3 | `gorengan` | 4 | 28 | 60 | b2b | 100 − 40 |
| 4 | `nasi_lauk` | 2 | 28 | 85 | b2c | 100 − 2/8×60 |
| 5 | `nasi_lauk` | 2 | 33 | 70 | b2c | 85 − 15 suhu |
| 6 | `kue` | 12 | 28 | 90 | b2c | 100 − 12/72×60 |
| 7 | `seafood` | 1 | 28 | 65 | b2b | 100 − 15 − 20 kategori |
| 8 | `santan_susu` | 1 | 28 | 68 | b2b | 100 − 12 − 20 |
| 9 | `minuman` | 6 | 31 | 55 | b2b | 100 − 30 − 15 suhu |
| 10 | `lainnya` | 1 | 28 | 93 | b2c | shelf default 8 jam: 100 − 7,5 = 92,5 |

Baris 10 adalah yang paling mungkin berbeda — lihat 11.1 soal pembulatan.

Pricing, empat kasus yang sama sudah diuji di `test/fallback_engine_test.dart`:

| harga asli | jam tersisa | jam total | sisa stok | stok awal | diskon | harga |
|---|---|---|---|---|---|---|
| 25.000 | 0 | 8 | 10 | 10 | 0,70 (dijepit dari 0,80) | 7.500 |
| 20.000 | 8 | 8 | 0 | 10 | 0,30 | 14.000 |
| 30.000 | 4 | 8 | 5 | 10 | 0,55 | 13.500 |

---

## 13. Berkas yang aku buat

```
pubspec.yaml · analysis_options.yaml · android/            scaffold, font, izin
lib/main.dart                                              bootstrap + tema per role
lib/core/constants.dart                                    konstanta bersama
lib/core/supabase/supabase_client.dart · session.dart       klien + provider sesi
lib/core/theme/tokens.dart                                  13 warna + tipografi
lib/core/theme/light_glass.dart · dark_glass.dart · plain.dart   kerangka, milik E/D/F
lib/core/theme/theme_for_role.dart                          pemetaan role -> tema
lib/core/api/lestar_api.dart · api_models.dart · api_provider.dart
lib/core/fallback_engine.dart                               heuristik lapis 3
lib/core/routing/routes.dart · router.dart · shells.dart
lib/core/demo/demo_accounts.dart · role_switcher.dart
lib/core/utils/formatters.dart · error_handler.dart
lib/shared/models/                                          11 model + enums + json + nearby
lib/shared/repositories/                                    7 repository + providers
lib/shared/widgets/                                         14 widget kerangka
lib/features/auth/presentation/login_screen.dart            milikku
lib/features/{merchant,consumer,partner}/presentation/      12 stub, milik D/E/F
test/                                                       59 test, tanpa jaringan
tool/smoke_supabase.dart · smoke_realtime.dart               bukti data nyata
docs/superpowers/plans/2026-08-29-agent-b-core-migrasi.md    rencana yang dijalankan
docs/06-agent-briefs/B-HANDOFF.md                            berkas ini
```

Tidak ada berkas di `api/`, `ml/`, `supabase/`, atau `landing/` yang disentuh.
