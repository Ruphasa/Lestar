# Lestar — Product Requirements Document

**Versi** 1.0 · **Tanggal** 29 Agustus 2026 · **Deadline demo** Rabu 2 September 2026

---

## 1. Ringkasan

Lestar adalah platform ekonomi sirkular digital yang menghubungkan tiga aktor dalam satu alur kaskade: **merchant F&B** yang menghasilkan surplus makanan, **konsumen B2C** yang membeli makanan layak konsumsi dengan diskon, dan **mitra pengepul B2B** (peternak maggot, produsen kompos, peternak unggas) yang mengambil limbah organik tidak layak konsumsi.

Nilai inti bukan sekadar marketplace surplus. Nilai intinya adalah **Buffer Intelligence**: sistem memprediksi permintaan besok, sehingga merchant berani memproduksi lebih banyak pada hari permintaan tinggi — karena setiap surplus yang terbentuk punya jalur keluar yang pasti.

> Lestar mencegah kerugian sebelum terjadi, lalu memulihkan nilai dari sisa yang tetap terbentuk.

Lestar adalah evolusi dari **Ecobite** (Juara 1 National Excellence Competitions 2026), yang memvalidasi bahwa merchant mau mengadopsi teknologi pengelolaan surplus dan konsumen antusias pada makanan diskon berkualitas. Yang ditambahkan Lestar: lapisan kecerdasan (LSTM + LLM), jalur B2B, dan pelaporan ESG otomatis.

## 2. Konteks eksekusi

| Aspek | Nilai |
|---|---|
| Tujuan | Menang lomba internal kantor, presentasi Rabu 2 September 2026 |
| Tim | Solo developer + agent |
| Waktu | 4 hari kerja (Sab 29 Ags – Sel 1 Sep), Rabu pagi buffer |
| Deliverable | APK Flutter (3 role), demo live 7 menit, deck, landing page |
| Basis kode | Fork dari Ecobite (16.882 baris Dart, Flutter + Riverpod + GoRouter) |

**Implikasi penting:** ini dinilai lewat demo live, bukan produksi. Setiap fitur yang tampil di jalur demo harus benar-benar berfungsi. Fitur di luar jalur demo boleh disederhanakan, tapi tidak boleh dipalsukan dengan tampilan yang mengesankan lebih dari yang sebenarnya ada.

## 3. Aktor

### 3.1 Merchant F&B (`role = merchant`)
Pemilik warung, kafe, bakery, atau katering skala UMKM. Memakai app beberapa kali sehari, sering sambil melayani pelanggan. Butuh keputusan cepat dan angka yang jelas.

**Pekerjaan yang ingin diselesaikan:**
- Tahu berapa harus produksi besok tanpa menebak
- Mengubah surplus jadi uang, bukan biaya retribusi sampah
- Punya bukti dampak lingkungan untuk green branding

### 3.2 Konsumen B2C (`role = consumer`)
Mahasiswa dan pekerja muda urban, sensitif harga, aktif di sore–malam hari.

**Pekerjaan yang ingin diselesaikan:**
- Dapat makanan berkualitas dengan harga jauh lebih murah
- Tahu apa yang tersedia di dekatnya, sekarang
- Klaim tanpa ribet, tanpa antre, tanpa penjelasan panjang ke kasir

### 3.3 Mitra pengepul B2B (`role = partner`)
Peternak maggot, produsen kompos, peternak unggas. Rata-rata usia 40+, HP entry-level, dipakai di luar ruangan, kadang sambil menyetir atau bersarung tangan.

**Pekerjaan yang ingin diselesaikan:**
- Tahu di mana ada limbah organik hari ini
- Pasokan yang bisa diprediksi, bukan berburu informal
- Satu tombol untuk mengambil pekerjaan

## 4. Alur kaskade — mekanisme inti produk

```
[1] Merchant input batch surplus (foto, kategori, qty, jam masak)
        ↓
[2] POST /triage — skor keamanan pangan 0–100 per item
        ↓
    skor ≥ 70 ──→ jalur B2C            skor < 70 ──→ jalur B2B
        ↓                                      ↓
[3] Merchant tekan "Validasi Kondisi Fisik Aman"   ← GERBANG WAJIB
        ↓
[4] POST /pricing — harga flash sale dinamis (diskon 30–70%)
        ↓
[5] Listing live → konsumen booking + bayar → QR token terbit
        ↓
[6] Konsumen datang → merchant scan QR → status CLAIMED
        ↓
[7] Sisa tidak terklaim lewat jam cutoff → auto-cascade ke waste_batches
        ↓
[8] Radar mitra menyala (realtime) → mitra tekan JEMPUT → picked_up → completed
        ↓
[9] Setiap peristiwa dicatat ke esg_events → laporan ESG tergenerate
```

Jejak `waste_batches.source_listing_id` adalah bukti kaskade. Kalau terisi, artinya makanan itu gagal terjual di B2C lalu turun ke B2B — bukan cerita, tapi data.

## 5. Fitur

### 5.1 Wajib — ada di jalur demo, harus berfungsi penuh

| # | Fitur | Aktor | Definisi selesai |
|---|---|---|---|
| F1 | Autentikasi 3 role | semua | Login mengarah ke shell yang benar, RLS menegakkan batas data |
| F2 | Buffer Intelligence | merchant | Menampilkan X (permintaan), Y (probabilitas surplus), rekomendasi produksi, narasi Bahasa Indonesia, dan label sumber (`lstm_gemini`/`lstm_only`/`heuristic`) |
| F3 | Input surplus + triage | merchant | Foto, kategori, qty, jam masak → skor + jalur B2C/B2B |
| F4 | Gerbang validasi fisik | merchant | Tanpa tekan tombol, `status` tidak pernah jadi `live` |
| F5 | Dynamic pricing | sistem | Harga turun otomatis mengikuti sisa waktu dan sisa stok, maksimum diskon 70% |
| F6 | Radar konsumen | konsumen | Peta + pill diskon + daftar terdekat, update realtime tanpa refresh |
| F7 | Booking + pembayaran | konsumen | Pembayaran simulasi, green fee Rp1.000, order tercatat |
| F8 | QR claim | konsumen + merchant | Token terbit, merchant scan, status → `claimed` |
| F9 | Auto-cascade | sistem | Listing lewat cutoff berubah `cascaded` dan melahirkan `waste_batch` |
| F10 | Radar pengepul | partner | Peta + kartu raksasa + satu tombol JEMPUT |
| F11 | Pickup flow | partner | `available` → `matched` → `picked_up` → `completed`, merchant dapat notifikasi realtime |
| F12 | Laporan ESG | merchant | Agregasi `esg_events` + narasi Gemini, export PDF |
| F13 | Fallback offline | sistem | Internet mati, Buffer Intelligence tetap keluar angka dengan label jujur |

### 5.2 Sekunder — dibangun kalau waktu cukup

| # | Fitur | Urutan korban |
|---|---|---|
| F14 | Langganan mitra B2B | dikorbankan pertama |
| F15 | Export PDF ESG (cukup tampil di layar) | dikorbankan kedua |
| F16 | Animasi transisi halus | dikorbankan ketiga |
| F17 | Riwayat & profil lengkap 3 role | dipertahankan, versi minimal |

### 5.3 Bukan bagian dari lingkup (non-goals)

Ditulis eksplisit supaya tidak ada agent yang membangunnya:

- **Payment gateway sungguhan** — pakai layar simulasi. Midtrans/Xendit butuh verifikasi bisnis berhari-hari.
- **Push notification native (FCM)** — pakai in-app realtime + toast. FCM butuh setup Firebase yang sudah kita buang.
- **Cloudflare Workers AI (Qwen)** — lapisan ini dilewati. Fallback chain tetap tiga lapis dan tetap jujur: `lstm_gemini` → `lstm_only` → `heuristic`.
- **Model LSTM per-merchant** — satu model global. Personalisasi per merchant adalah Fase 3 di roadmap, bukan sekarang.
- **iOS build** — Android saja.
- **Multi-bahasa** — Bahasa Indonesia saja.
- **Onboarding merchant mandiri** — akun di-seed. Registrasi tetap ada tapi tidak ada di jalur demo.

## 6. Aturan bisnis

### 6.1 Keamanan pangan
- Skor triage adalah **rekomendasi**, bukan keputusan. Keputusan akhir ada pada merchant.
- `physical_validated = false` → `listings.status` tidak boleh `live`. Ditegakkan di level database, bukan hanya UI.
- Skor `< 70` diarahkan ke B2B dan **tidak boleh** dijual ke konsumen, meski merchant memaksa.
- `shelf_life` per kategori: gorengan 6 jam · nasi/lauk 8 jam · roti 24 jam · kue kering 72 jam · seafood 4 jam · santan/susu 5 jam.

### 6.2 Harga
```
diskon = 30% + (35% × (1 − jam_tersisa / jam_total)) + (15% × rasio_sisa_stok)
diskon maksimum 70%
harga = original_price × (1 − diskon), dibulatkan ke Rp500 terdekat
```
Batas 70% menepati janji "diskon 50–70%" di proposal.

### 6.3 Green fee
Rp1.000 per transaksi B2C, dibebankan ke konsumen, di luar subtotal. Dialokasikan untuk pemeliharaan mesin ESG dan infrastruktur realtime.

### 6.4 Kaskade
- Jam cutoff default per merchant: **22.00**, bisa diubah merchant.
- Listing `live` yang lewat cutoff dengan `qty_remaining > 0` → `status = cascaded`, lahir `waste_batch` dengan `waste_type = 'wet'` dan `source_listing_id` terisi.
- Konversi berat: `qty_remaining × berat_porsi_kategori` (gorengan 0,15 kg · nasi/lauk 0,35 kg · roti 0,08 kg · kue 0,05 kg).

### 6.5 ESG
- Faktor emisi: **0,25 kg CO₂eq per kg** surplus yang dialihkan dari TPA. Angka ini diambil dari Tabel 2.5.1 proposal dan harus konsisten di seluruh sistem.
- `esg_events` ditulis tepat dua kali: saat order → `claimed` (`b2c_rescued`) dan saat waste batch → `completed` (`b2b_diverted`).
- Laporan tidak boleh memuat angka yang tidak bisa ditelusuri ke baris `esg_events`.

### 6.6 Kejujuran sistem
- `forecasts.source` harus mencerminkan asal angka yang sebenarnya. Kalau jatuh ke heuristik, tulis `heuristic` dan tampilkan labelnya di UI.
- Tidak boleh ada angka hardcode yang disamarkan sebagai output AI.

## 7. Metrik keberhasilan demo

Bukan metrik bisnis — metrik apakah demo berhasil.

| Kriteria | Ambang |
|---|---|
| Alur kaskade 7 menit selesai tanpa crash | 3 kali gladi berturut-turut |
| Waktu muat layar mana pun | < 1,5 detik |
| Listing baru muncul di radar konsumen | < 2 detik setelah merchant validasi |
| Buffer Intelligence saat internet mati | tetap keluar angka < 1 detik |
| Ganti role saat demo | < 3 detik |

## 8. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Migrasi Firebase → Supabase molor | Hari 2–4 ikut molor | Blok waktu penuh Hari 1, tidak ada UI dikerjakan hari itu |
| Railway cold start saat demo | Buffer Intelligence lambat | Ping `/health` tiap 10 menit + fallback lokal 4 detik |
| WiFi venue buruk | Realtime mati | Fallback heuristik + demo offline dijadikan bagian skenario |
| LSTM keluar angka tidak masuk akal | Kredibilitas jatuh | Clamp output ke rentang wajar per merchant, uji dengan 30 merchant seed |
| Tiga UI tidak selesai | Kehilangan pembeda utama | UI pengepul dikerjakan pertama — paling cepat dan paling berkesan |
| Bentrok file antar agent | Kode rusak | Kepemilikan folder eksklusif per agent, lihat `06-agent-briefs/` |

## 9. Referensi

- Proposal asli: `LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md`
- Mockup 3 UI: `mockup.png`
- Basis kode: https://github.com/Third-Connectors/EcoBite
