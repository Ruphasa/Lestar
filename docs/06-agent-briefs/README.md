# Brief Agent — Aturan Main

**7 jalur kerja.** Kunci supaya agent paralel tidak saling menimpa: **satu agent, satu folder.**

## Kepemilikan file

| Agent | Milik eksklusif | Bergantung pada | Jadwal |
|---|---|---|---|
| **A · Database** | `supabase/migrations/`, `supabase/functions/`, `supabase/seed/` | — | Sab pagi |
| **B · Core** | `lib/core/`, `lib/shared/models/`, `lib/shared/repositories/`, `pubspec.yaml` | A (schema) | Sab |
| **C · ML & API** | `ml/`, `api/` | A (schema saja) | Sab–Sen, **paralel penuh** |
| **D · UI Merchant** | `lib/features/merchant/`, `lib/core/theme/dark_glass.dart` | B | Min |
| **E · UI Konsumen** | `lib/features/consumer/`, `lib/core/theme/light_glass.dart` | B | Sen |
| **F · UI Pengepul** | `lib/features/partner/`, `lib/core/theme/plain.dart` | B | Sen |
| **G · Web & Deck** | `landing/`, `deck/` | — | Sel, **paralel penuh** |

**C dan G tidak bergantung apa pun** setelah schema dibekukan — bisa jalan dari awal tanpa mengganggu siapa pun.

**B adalah leher botol.** Sampai B selesai, D/E/F tidak bisa mulai. Prioritaskan B di Hari 1.

## File bersama — hanya boleh disentuh pemiliknya

| File | Pemilik | Yang lain |
|---|---|---|
| `pubspec.yaml` | B | minta B menambahkan, jangan edit sendiri |
| `lib/core/routing/router.dart` | B | minta B menambahkan rute |
| `lib/core/theme/tokens.dart` | B | baca saja |
| `lib/shared/widgets/` | B membuat kerangka; D/E/F menambah varian tema masing-masing | |
| `lib/main.dart` | B | jangan sentuh |

Kalau butuh perubahan di file milik agent lain: **tulis permintaan, jangan edit langsung.**

## Aturan yang berlaku untuk semua agent

1. **Baca `00-PRD.md` dan `01-architecture.md` sebelum menulis baris pertama.**
2. **Konstanta bersama** ada di `lib/core/constants.dart` dan `api/constants.py`. Jangan tulis ulang nilainya di tempat lain.
3. **Tidak ada data palsu di jalur demo.** Kalau belum bisa dihubungkan, laporkan — jangan hardcode lalu diam.
4. **Bahasa Indonesia** untuk seluruh teks yang dilihat pengguna. Kode, nama variabel, dan komentar boleh Inggris.
5. **Format rupiah** `Rp 32.000`, bukan `32000.0`. Pakai `intl` `NumberFormat.currency(locale: 'id_ID')`.
6. **Selesai berarti berjalan.** Layar yang dibuat harus bisa dibuka, memuat data nyata dari Supabase, dan tidak overflow.
7. Kalau menemui keputusan yang tidak tertulis di dokumen, **pilih yang paling sederhana dan catat pilihannya** di akhir laporan.

## Urutan korban kalau waktu habis

Dikorbankan berurutan dari atas:
1. Langganan mitra B2B (F14)
2. Export PDF ESG — cukup tampil di layar (F15)
3. Animasi transisi (F16)

**Tidak pernah dikorbankan:** kaskade, QR claim, radar realtime, Buffer Intelligence, gerbang validasi fisik.

## Skill yang tersedia

Sudah terpasang di `.agents/skills/`:

| Skill | Untuk agent |
|---|---|
| `supabase-postgres-best-practices` | A |
| `supabase` | A, B |
| `flutter-apply-architecture-best-practices` | B |
| `flutter-implement-json-serialization` | B |
| `flutter-fix-layout-issues` | D, E, F |
| `flutter-expert` | B, D, E, F |
| `flutter-animations` | D, E |

MCP `context7` tersedia untuk dokumentasi versi terbaru Flutter, Supabase, FastAPI.

## Laporan selesai

Setiap agent menutup pekerjaannya dengan:
- Daftar file yang dibuat/diubah
- Daftar item di "Definisi selesai" yang tercapai dan yang tidak
- Keputusan yang diambil sendiri karena tidak tertulis di dokumen
- Hal yang memblokir agent lain, kalau ada
