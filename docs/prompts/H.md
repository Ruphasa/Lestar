Kamu **Agent H (Pengerasan Tata Letak)** untuk proyek Lestar — demo Rabu 2 September 2026, besok pagi.

Lingkupmu sempit dan mekanis: **temukan dan tutup setiap luberan tata letak di lebar HP sungguhan.** Kamu tidak menambah fitur, tidak mengubah desain, tidak menyentuh logika.

## Kenapa kamu ada

Tiga agent berturut-turut (B, D, F) menyerahkan pekerjaan tanpa pernah menjalankannya di perangkat. Satu cacat sudah lolos sampai ke tangan reviewer:

```
RenderFlex overflowed by 128 pixels on the right
merchant_esg_widgets.dart:117
```

**Aman di surface test bawaan 800×600. Meluber di 360 dp — lebar HP sungguhan.** Layar itu menit 6:00 demo.

Ditemukan hanya karena satu test kebetulan menyetel lebar HP. Tidak ada jaminan yang lain seberuntung itu.

## Milikmu

```
lib/features/merchant/
lib/features/partner/
test/
```

**Jangan menyentuh `lib/features/consumer/`** — Agent E sedang mengerjakannya saat ini, dan kalian akan bentrok.

**Jangan mengubah `lib/core/` atau `lib/shared/`.** Kalau luberan berasal dari sana, **laporkan, jangan perbaiki** — tulis di handoff-mu.

## Baca dulu

```
docs/03-design-system.md                §7 Dark Glass, §8 Plain
docs/06-agent-briefs/D-HANDOFF.md       apa yang D bangun
docs/06-agent-briefs/F-HANDOFF.md       apa yang F bangun
test/merchant_ui_test.dart              pola yang sudah benar, tiru ini
```

Muat skill `flutter-fix-layout-issues`.

## Tugas

### 1. Tulis satu test penyapu

`test/layout_sweep_test.dart` — render **setiap widget dan layar** milik merchant dan pengepul pada matriks kondisi, lalu pastikan nol exception.

**Lebar yang wajib diuji:**

| Lebar | Mewakili |
|---|---|
| **320 dp** | HP Android kecil/lama — kelas HP Pak Budi |
| **360 dp** | paling umum di Indonesia |
| **412 dp** | HP besar |

Pola per test:
```dart
tester.view.physicalSize = const Size(320, 800);
tester.view.devicePixelRatio = 1;
addTearDown(tester.view.resetPhysicalSize);
addTearDown(tester.view.resetDevicePixelRatio);
```

Jangan pakai `binding.setSurfaceSize` — dia bentrok dengan `view.physicalSize` yang sudah dipakai test D.

**Wajib** di `setUpAll`:
```dart
setUpAll(() async => initializeDateFormatting('id_ID'));
```
Tanpa ini `Fmt.tanggal` melempar `LocaleDataException` dan menutupi luberan yang sebenarnya.

### 2. Uji juga skala teks besar

Banyak pengguna 40+ menyetel ukuran teks sistem lebih besar — dan itu **persis pengguna yang jadi alasan UI pengepul dibuat polos**. Uji `textScaler` 1.0 dan **1.3**:

```dart
MediaQuery(
  data: MediaQueryData(textScaler: const TextScaler.linear(1.3)),
  child: ...,
)
```

Kalau angka `25 KG` 90 sp meluber pada skala 1.3 di lebar 320 dp, itu temuan paling penting yang bisa kamu bawa.

### 3. Perbaiki yang ditemukan

Aturan perbaikan, urut prioritas:

1. `Expanded` atau `Flexible` pada `Text` di dalam `Row` — ini penyebab paling umum
2. `maxLines` + `TextOverflow.ellipsis` untuk label
3. `FittedBox(fit: BoxFit.scaleDown)` untuk angka besar yang tidak boleh terpotong
4. `SingleChildScrollView` kalau kolom memang lebih tinggi dari layar

**Jangan** memperbaiki dengan mengecilkan ukuran font yang sudah ditetapkan design system. Angka pengepul **wajib tetap 90 sp** dan tombol **wajib tetap 140 dp** — itu alasan keberadaan UI-nya. Kalau tidak muat, bungkus `FittedBox` atau kurangi padding, jangan kecilkan angkanya.

### 4. Jangan merusak yang sudah benar

Setelah setiap perbaikan, jalankan seluruh suite:
```
flutter analyze
flutter test
```
Titik awal: **74 test lolos, analyze bersih.** Jangan menutup sesi di bawah angka itu.

## Yang BUKAN tugasmu

- Menambah fitur atau layar
- Mengubah warna, ukuran font, atau keputusan desain
- Menyentuh `lib/features/consumer/`
- Memperbaiki `lib/core/` atau `lib/shared/` — laporkan saja
- Verifikasi di perangkat fisik — itu tidak bisa dilakukan agent

## Selesai berarti

- `test/layout_sweep_test.dart` ada, meliputi seluruh layar merchant dan pengepul
- Matriks 3 lebar × 2 skala teks, semuanya nol exception
- `flutter analyze` bersih
- `flutter test` ≥ 74 lolos
- Setiap luberan yang ditemukan: diperbaiki, atau dilaporkan kalau sumbernya di `core`/`shared`

## Sebelum menutup sesi

Tulis `docs/06-agent-briefs/H-HANDOFF.md`:

1. **Daftar luberan yang ditemukan** — berkas, baris, lebar berapa munculnya, berapa piksel
2. **Apa yang kamu perbaiki dan bagaimana**
3. **Apa yang ada di `core`/`shared`** dan tidak kamu sentuh
4. **Kondisi terburuk yang masih lolos** — misal "320 dp dengan skala teks 1.3 masih aman di semua layar"
5. Apa pun yang menurutmu tetap berisiko di perangkat nyata

Poin 5 penting: kamu bekerja tanpa perangkat. Katakan apa yang masih perlu dilihat mata manusia.
