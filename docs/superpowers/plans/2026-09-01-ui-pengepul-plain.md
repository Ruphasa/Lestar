# UI Pengepul Plain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun tiga layar pengepul yang kontras tinggi, menampilkan radar limbah realtime, dan menuntaskan alur `available -> matched -> picked_up -> completed`.

**Architecture:** Layar tetap memakai tiga stub rute yang sudah dikunci Agent B. State dan orkestrasi data hidup di `lib/features/partner/application/`, sedangkan widget khusus Plain hidup di `lib/features/partner/presentation/widgets/`; repository bersama hanya dikonsumsi, tidak diubah. Peta merupakan keadaan layar penuh di dalam tab Beranda sehingga tidak membutuhkan rute atau modal baru.

**Tech Stack:** Flutter 3, Dart 3.9, Riverpod 3, Supabase Realtime/RPC, flutter_map 8, flutter_test.

## Global Constraints

- Isian tombol utama `#009966`; `#00BC7D` hanya ikon atau garis.
- Angka utama 90 sp dan tombol utama 140 dp (tidak pernah di bawah 120 dp).
- Tanpa blur, gradasi, animasi masuk, atau bayangan selain glow tombol utama.
- Semua label tindakan berbahasa Indonesia dan huruf besar.
- Lebar pengujian widget 390 px; tidak boleh ada `RenderFlex overflowed`.
- RPC wajib memakai parameter `p_lat`, `p_lng`, dan `p_radius_km` melalui `WasteRepository.nearbyWaste`.

---

### Task 1: Tema Plain dan komponen khusus pengepul

**Files:**
- Modify: `lib/core/theme/plain.dart`
- Create: `lib/features/partner/presentation/widgets/partner_plain_widgets.dart`
- Test: `test/features/partner/partner_plain_widgets_test.dart`

**Interfaces:**
- Consumes: `LestarTokens`, `LestarType`.
- Produces: `PartnerPrimaryButton`, `PartnerOutlineButton`, `PartnerSectionCard`, dan gaya tema Plain dengan latar putih.

- [ ] Tulis pengujian tombol 140 dp, warna `emeraldDeep`, teks besar, dan layout 390 px.
- [ ] Jalankan `flutter test test/features/partner/partner_plain_widgets_test.dart` dan pastikan gagal karena widget belum ada.
- [ ] Implementasikan komponen tanpa efek terlarang dan lengkapi `PlainTheme`.
- [ ] Jalankan pengujian sampai lulus.
- [ ] Commit dengan pesan `feat(pengepul): bangun tema polos dan tombol besar`.

### Task 2: Radar realtime, Beranda, peta, dan alur jemput

**Files:**
- Create: `lib/features/partner/application/partner_dashboard_controller.dart`
- Modify: `lib/features/partner/presentation/partner_home_screen.dart`
- Test: `test/features/partner/partner_home_screen_test.dart`

**Interfaces:**
- Consumes: `currentProfileProvider`, `currentPartnerProvider`, `WasteRepository.nearbyWaste`, `availableStream`, `matchPartner`, dan `updateStatus`.
- Produces: `partnerNearbyWasteProvider(Partner)`, `PartnerPickupController`, tampilan tersedia/kosong/peta/perjalanan.

- [ ] Tulis pengujian agregasi preferensi `wet`, angka `25 KG`, jarak terdekat, empty state, pin peta, dan transisi tombol `JEMPUT SEKARANG -> SUDAH SAMPAI -> SELESAI`.
- [ ] Jalankan test dan pastikan gagal pada stub.
- [ ] Implementasikan stream yang memuat RPC sekali lalu memuat ulang setiap snapshot realtime `waste_batches`.
- [ ] Implementasikan Beranda satu angka/satu aksi; match seluruh batch yang membentuk total perjalanan dan proses tujuan satu per satu.
- [ ] Implementasikan peta layar penuh dengan marker besar dan label berat langsung.
- [ ] Jalankan test 390x900, `flutter analyze`, lalu perbaiki semua overflow/error.
- [ ] Commit dengan pesan `feat(pengepul): hidupkan radar dan alur jemput`.

### Task 3: Riwayat dan statistik bulanan

**Files:**
- Extend: `lib/features/partner/application/partner_dashboard_controller.dart`
- Modify: `lib/features/partner/presentation/partner_riwayat_screen.dart`
- Test: `test/features/partner/partner_riwayat_screen_test.dart`

**Interfaces:**
- Consumes: `WasteRepository.partnerWaste`, `ProfileRepository.getMerchant`, `Fmt`.
- Produces: `PartnerHistoryItem` dengan batch dan nama merchant, serta tiga statistik bulan berjalan.

- [ ] Tulis test tiga statistik, filter `completed`, nama merchant, dan satu kartu per baris.
- [ ] Jalankan test dan pastikan gagal pada stub.
- [ ] Implementasikan provider riwayat realtime dan kartu polos berborder 2 px.
- [ ] Jalankan test dan analyzer sampai lulus tanpa overflow.
- [ ] Commit dengan pesan `feat(pengepul): tampilkan riwayat penjemputan`.

### Task 4: Status langganan minimal

**Files:**
- Modify: `lib/features/partner/presentation/partner_langganan_screen.dart`
- Test: `test/features/partner/partner_langganan_screen_test.dart`

**Interfaces:**
- Consumes: `currentPartnerProvider`, `ProfileRepository.updatePartner`.
- Produces: status, tanggal berakhir, dan satu aksi simulasi perpanjangan 30 hari.

- [ ] Tulis test status aktif/tidak aktif dan hanya satu tombol tindakan.
- [ ] Jalankan test dan pastikan gagal pada stub.
- [ ] Implementasikan status sederhana tanpa modal atau model subscription baru.
- [ ] Jalankan test dan analyzer sampai lulus.
- [ ] Commit dengan pesan `feat(pengepul): sederhanakan status langganan`.

### Task 5: Verifikasi penuh dan handoff

**Files:**
- Create: `docs/06-agent-briefs/F-HANDOFF.md`

**Interfaces:**
- Consumes: semua hasil Task 1-4 dan batas kepemilikan Agent A/B.
- Produces: bukti test/analyzer, keputusan teknis, kekurangan uji perangkat fisik, dan permintaan lintas-agent bila diperlukan.

- [ ] Jalankan `dart format lib/features/partner lib/core/theme/plain.dart test/features/partner`.
- [ ] Jalankan seluruh test fitur pengepul pada viewport 390x900.
- [ ] Jalankan `flutter test` dan `flutter analyze`.
- [ ] Cari efek terlarang dengan `rg "BackdropFilter|LinearGradient|RadialGradient|BoxShadow" lib/features/partner lib/core/theme/plain.dart` dan pastikan hanya glow tombol yang ada.
- [ ] Tulis `F-HANDOFF.md`, termasuk fakta bahwa verifikasi keterbacaan 1,5 meter memerlukan perangkat fisik.
- [ ] Commit dengan pesan `docs(pengepul): serahkan hasil dan bukti verifikasi`.
