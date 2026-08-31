# Lestar — Skenario Demo

**Durasi** 7 menit · **Demo** Rabu 2 September 2026 · **Perangkat** Android fisik, di-mirror ke proyektor

---

## 1. Prinsip

Yang menentukan menang bukan jumlah fitur, tapi apakah juri melihat **satu alur yang tak terputus**. Satu cerita: makanan yang tadinya akan dibuang, berpindah tangan sampai habis nilainya.

Aturan yang tidak boleh dilanggar:
- **Tidak ada layar mock di jalur demo.** Setiap layar yang muncul harus benar-benar terhubung ke Supabase.
- **Tidak ada registrasi di depan juri.** Semua akun sudah di-seed dan sudah login.
- **Tidak ada build dadakan.** APK release sudah terpasang di HP sejak Selasa malam.

## 2. Persiapan sebelum masuk ruangan

| # | Tindakan | Kapan |
|---|---|---|
| 1 | Ping `/health` Railway 15 menit sebelum tampil | H-15 menit |
| 2 | Buka app, pastikan sesi merchant aktif | H-10 menit |
| 3 | Reset data demo lewat `supabase/seed/reset_demo.sql` | H-10 menit |
| 4 | Matikan notifikasi HP, aktifkan mode jangan ganggu | H-5 menit |
| 5 | Kecerahan layar maksimum | H-5 menit |
| 6 | Cek mirroring ke proyektor | H-5 menit |
| 7 | Siapkan hotspot pribadi sebagai cadangan WiFi venue | H-5 menit |

## 3. Data yang harus di-seed

| Entitas | Nilai |
|---|---|
| Merchant demo | **Verde Kitchen**, kategori kafe, Malang, `cutoff_time = 22:00` |
| Riwayat penjualan | 90 hari di `sales_history`, pola akhir pekan terlihat jelas di chart |
| Konsumen demo | **Amira**, lokasi 0,4–1,2 km dari Verde Kitchen |
| Pengepul demo | **Pak Budi**, peternak maggot, `waste_preference = {wet}`, 1,2 km dari Verde Kitchen |
| Merchant lain | 29 merchant dengan listing aktif, supaya radar konsumen tidak terlihat sepi |
| Listing aktif | 8–12 listing live dari merchant lain, harga dan diskon bervariasi |
| Waste tersedia | 2 batch dari merchant lain dalam radius 2 km dari Pak Budi, **total tepat 16,6 kg** (mis. 9,2 kg + 7,4 kg) — supaya setelah kaskade Verde Kitchen menambah 8,4 kg, radar menampilkan **25 KG** persis seperti mockup |
| `esg_events` | ~40 baris riwayat, supaya laporan ESG punya angka yang masuk akal |

**Yang sengaja dikosongkan:** listing croissant Verde Kitchen dan waste batch hasil kaskadenya. Keduanya dibuat **langsung di depan juri**. Itu inti demonstrasinya.

## 4. Alat bantu demo yang harus dibangun

### 4.1 Ganti role instan
Logout–login antar role memakan ~20 detik. Empat kali ganti = 80 detik hilang dari 7 menit.

**Solusi:** tekan-lama logo di app bar → sheet "Ganti Role" → pilih akun → langsung masuk shell yang sesuai.

Aktif **hanya** di build demo: `flutter build apk --release --dart-define=DEMO=true`

Ini alat bantu presentasi, bukan fitur palsu. Kalau juri bertanya, sebut apa adanya: *"Ini pintasan demo supaya kami tidak menghabiskan waktu Bapak/Ibu untuk logout-login."*

### 4.2 Pemicu kaskade manual

**Job cron sengaja dimatikan.** Agent A menemukan saat pengujian: begitu jam melewati `cutoff_time`, satu putaran cron mengubah 6 dari 12 listing panggung jadi `cascaded` dan mengosongkan radar konsumen. Cron tidak menambah apa pun selain risiko panggung berubah tanpa ada yang menekan tombol.

Di build demo, tombol tersembunyi di layar Inventory merchant memanggil:

```dart
await supabase.rpc('run_auto_cascade', params: {
  'p_force': true,               // demo pagi hari, cutoff jam 22.00
  'p_merchant_id': merchant.id,  // WAJIB
});
```

**`p_merchant_id` wajib diisi.** Tanpa itu, kaskade paksa menyeret 12 listing panggung merchant lain dan mengosongkan radar konsumen tepat sebelum menit 5:00.

Logika yang dijalankan **identik** dengan yang dipanggil cron — keduanya memanggil fungsi Postgres `run_auto_cascade()` yang sama. Bukan jalur berbeda, hanya pemicu berbeda.

## 5. Skenario menit per menit

### 0:00 — 1:30 · Merchant · Buffer Intelligence
> **Pembuka:** *"Ini Verde Kitchen, kafe di Malang. Sekarang pagi hari, dan Bu Sari belum memutuskan mau produksi berapa hari ini."*

Buka **Merchant Console → Home**.

Kartu Stock Forecast menampilkan:
- **48 kg** permintaan diprediksi
- Badge `94% accuracy`
- Chart 7 hari: demand vs current plan
- Chip amber: `⚠ −12 kg vs plan`
- Narasi: *"Besok Jumat dan cuaca cerah — permintaan diprediksi naik 18%. Produksi 58 porsi aman; surplus yang terbentuk sudah punya jalur keluar."*
- Badge sumber: `AI · LSTM + Gemini`

Tekan **Apply recommended order**.

> **Pesan kunci:** *"Perhatikan — Lestar tidak menunggu makanan terbuang lalu menjualnya murah. Lestar mencegah kerugian sebelum terjadi. Dan justru karena ada jalur keluar yang pasti, Bu Sari berani produksi lebih banyak di hari ramai."*

### 1:30 — 2:30 · Merchant · Input surplus & gerbang keamanan pangan
> *"Sekarang lompat ke pukul sembilan malam. Ada 12 croissant tidak terjual."*

**Inventory → Tambah Surplus**
- Foto croissant
- Kategori: roti · Qty: 12 · Dimasak: 13.00 · Harga normal: Rp88.000

Sistem menampilkan hasil triage:
- **Skor 80 → jalur B2C**
- Alasan: *"Dimasak 8 jam lalu, kategori roti tahan 24 jam. Kondisi suhu normal."*
- Perhitungan: `100 − (8/24) × 60 = 80`

> Angka ini sengaja bulat. Jam masak 14.00 menghasilkan `82,5`, dan pembulatan setengah berbeda antara Dart dan Python — Dart membulatkan menjauhi nol (83), Python membulatkan ke genap (82). Skor bulat menghilangkan satu hal yang bisa dipersoalkan juri sekaligus satu sumber selisih antar-implementasi.

Muncul tombol **"Validasi Kondisi Fisik Aman"**.

> **Berhenti di sini. Ini poin penting.** *"AI memberi skor, tapi AI tidak memutuskan. Bu Sari harus mencium, melihat, dan menyentuh croissant ini dulu. Tanpa dia menekan tombol ini, listing tidak akan pernah tayang. Kami menegakkannya di level database, bukan sekadar di tampilan."*

Tekan tombol. Harga otomatis: ~~Rp88.000~~ → **Rp32.000 (−64%)**.

### 2:30 — 3:30 · Konsumen · Radar realtime
Tekan-lama logo → ganti ke **Amira**.

**Live Flash Radar** terbuka. Croissant Verde Kitchen **sudah ada di sana** — muncul tanpa refresh, lewat Supabase Realtime.

> *"Tidak ada tombol muat ulang. Listing itu sampai ke Amira kurang dari dua detik setelah Bu Sari menekan validasi."*

Ketuk kartu → detail → **Pesan** → bayar (simulasi) → **QR terbit**.

Tunjukkan rincian: subtotal Rp32.000 + green fee Rp1.000 = **Rp33.000**.

> *"Seribu rupiah ini adalah green fee — dialokasikan untuk mesin kalkulasi emisi dan infrastruktur realtime. Konsumen ikut membiayai ekosistemnya."*

### 3:30 — 4:30 · Merchant · Klaim QR
Ganti kembali ke **merchant**. Buka **Scan QR**, pindai QR dari layar konsumen.

Status berubah **CLAIMED**. Angka di kartu KPI naik di depan mata.

> *"Kasir tidak perlu mengetik apa pun. Tidak ada gangguan pada ritme operasional."*

### 4:30 — 5:00 · Titik kaskade
> *"Tapi tidak semuanya terjual. Lima croissant tersisa, dan ada 8 kg sisa dapur yang skornya 45 — di bawah ambang, tidak layak dijual ke manusia."*

Lewati jam cutoff (pakai pemicu manual).

Layar merchant menampilkan jejak kaskade:
```
Croissant 5 pcs (0,4 kg)  →  tidak terklaim 21.00  →  dialihkan 21.05
Sisa dapur 8 kg           →  skor 45              →  jalur B2B langsung
──────────────────────────────────────────────────────────────
Verde Kitchen malam ini: 8,4 kg
```

Radar Pak Budi menjumlahkan seluruh limbah dalam radiusnya: **8,4 kg dari Verde Kitchen + 16,6 kg dari dua merchant lain dalam radius 2 km = 25 kg.** Inilah gunanya Smart Matching — satu perjalanan, beberapa titik ambil.

> **Ini inti gagasan Lestar.** *"Tidak ada satu kilogram pun yang berakhir di TPA. Yang layak dimakan manusia pergi ke manusia. Yang tidak, pergi ke maggot dan kompos."*

### 5:00 — 6:00 · Pengepul · UI Bodoh
Ganti ke **Pak Budi**.

Layar berubah total. Putih polos. Huruf raksasa.

```
Halo, Pak Budi
[📍 Desa Sukamaju]

    ADA SAMPAH ORGANIK

       TERSEDIA
        25 KG

  Jarak 1,2 KM dari rumah

  [ 🚚 JEMPUT SEKARANG ]
```

> **Berhenti. Jelaskan.** *"Perhatikan perbedaannya. Konsumen dapat antarmuka kaca yang ringan. Merchant dapat kokpit data gelap. Pak Budi dapat ini. Pak Budi berusia lima puluh dua tahun, HP-nya entry-level, dan dia membaca layar ini di bawah matahari sambil membawa ember. Glassmorphism di tangannya bukan keindahan — itu penghalang. Kami tidak memaksakan satu design system ke tiga orang yang hidup di dunia berbeda."*

Tekan **JEMPUT SEKARANG** → status `matched`. Merchant menerima notifikasi realtime.

### 6:00 — 6:45 · Merchant · Laporan ESG
Ganti ke merchant → tab **ESG**.

Laporan tergenerate:
```
Periode 1 – 31 Agustus 2026 · Verde Kitchen

  32 kg      makanan diselamatkan
  8 kg       CO₂eq tidak dilepaskan
  Rp 384.000 nilai dipulihkan
  128 porsi  sampai ke konsumen
```

Plus narasi Gemini siap pakai untuk green branding. Tekan **Export PDF**.

> *"Setiap angka di sini bisa ditelusuri ke transaksi aslinya. Ini bukan estimasi kasar — ini buku besar."*

### 6:45 — 7:00 · Penutup · Matikan WiFi
> *"Satu hal terakhir."*

**Matikan WiFi di depan juri.** Buka Buffer Intelligence.

Angka tetap keluar. Badge berubah jadi: `Mode offline · heuristik`.

> *"Kalau internet mati di warung, Lestar tetap memberi rekomendasi. Lapisan terakhir kami adalah heuristik yang ditanam di dalam aplikasi. Dan sistem mengaku — dia memberi tahu bahwa angka ini berasal dari perhitungan lokal, bukan dari AI. Kami tidak pernah menyamarkan asal angka."*

**Selesai.**

## 6. Kenapa penutupnya begitu

Hampir semua peserta lomba bisa mendemokan aplikasi yang jalan. Hampir tidak ada yang berani mematikan internet di depan juri. Momen itu yang diingat setelah semua presentasi selesai.

Sekaligus membuktikan tiga hal dalam satu gerakan: sistem tangguh, arsitekturnya dipikirkan, dan timnya jujur.

## 7. Pertanyaan juri yang harus disiapkan

| Pertanyaan | Jawaban |
|---|---|
| "Akurasi AI-nya berapa?" | "70% di fase awal, dari data sintetis berbasis pola F&B Indonesia. Kami tidak mengklaim lebih tinggi karena belum punya data merchant sungguhan. Roadmap kami menargetkan 83% setelah tiga iterasi fine-tuning." |
| "Datanya dari mana?" | "Sintetis, dibangun dari pola musiman nyata — hari gajian, akhir pekan, libur nasional, cuaca. Dikalibrasi ke temuan riset Aksamala Foundation: 2–3 kg surplus per restoran per hari." |
| "Kalau makanannya basi dan orang sakit?" | "Karena itu ada gerbang validasi fisik. AI hanya memberi skor. Merchant wajib memeriksa langsung dan mengonfirmasi. Tanpa itu, listing tidak tayang — kami tegakkan di level database. Tanggung jawab akhir tetap di merchant, dan itu disengaja." |
| "Bedanya dengan Too Good To Go?" | "Mereka berhenti di B2C. Kami punya jalur kedua ke pengolah limbah organik, dan lapisan pencegahan di hulu lewat Buffer Intelligence. Kami tidak hanya menjual surplus — kami mengurangi terbentuknya." |
| "Ini pakai AI beneran atau tempelan?" | "LSTM yang kami latih sendiri, 180 KB, dua output head. Gemini hanya untuk kalibrasi konteks dan bahasa — dan dibatasi hanya boleh mengubah angka LSTM maksimal 20%. Triage dan pricing sengaja deterministik, karena keamanan pangan tidak boleh bergantung pada model probabilistik." |
| "Model bisnisnya?" | "Komisi transaksi B2C, langganan bulanan mitra B2B, dan green fee Rp1.000 per transaksi. SOM tahun pertama Rp480 juta di Malang Raya dan Surabaya." |
| "Kenapa UI pengepulnya beda sendiri?" | *(jawaban ada di menit 5:00)* |

## 8. Rencana kalau ada yang gagal

| Kalau | Lakukan |
|---|---|
| Railway lambat/mati | Diamkan. Fallback heuristik jalan otomatis. **Jadikan bahan cerita**, bukan permintaan maaf. |
| Realtime tidak masuk | Tarik-untuk-refresh. Sebut sebagai kondisi jaringan venue. |
| Kamera QR gagal | Ada tombol "Masukkan kode manual" sebagai cadangan. Wajib dibangun. |
| Peta tidak memuat | Tampilan daftar tetap jalan. Lanjutkan tanpa berhenti. |
| App crash | Buka ulang. Sesi tersimpan. Lanjutkan dari langkah terakhir. Jangan bahas. |
| WiFi venue mati total | Pakai hotspot pribadi. Kalau ikut mati — demo offline tetap jalan sampai bagian ESG. |

## 9. Gladi bersih

**Minimal tiga kali berturut-turut tanpa kesalahan, Selasa malam.** Pakai stopwatch. Kalau lewat 7 menit, potong bagian ESG jadi lebih singkat — jangan potong kaskade atau penutup offline.

---

## 10. Pemanasan cache Gemini — wajib, H-1

**Ditambahkan 1 September 2026** setelah kuota free tier Gemini habis saat pengujian.

Demo membutuhkan Gemini hidup **sekali saja**, bukan saat tampil. Kedua keluarannya persisten: `forecasts.narrative` + `forecasts.source`, dan `esg_reports.narrative`.

Selama kuota tersedia, lakukan dua hal ini dan **jangan diulang**:

| # | Tindakan | Mengisi | Dipakai menit |
|---|---|---|---|
| 1 | Buka Merchant Home sebagai Verde Kitchen | satu baris `forecasts` untuk tanggal demo | 0:00 |
| 2 | Buka tab ESG, biarkan laporan tergenerate | satu baris `esg_reports` | 6:00 |

Lalu verifikasi bahwa yang tersimpan memang dari Gemini:
```sql
select forecast_date, source, left(narrative, 60) from forecasts
where merchant_id = '<verde>' order by created_at desc limit 1;
-- source harus 'lstm_gemini'
```

Kalau `source` masih `lstm_only`, kuota belum pulih — ulangi setelah reset (tengah malam waktu Pasifik, sekitar 14.00 WIB).

**Setelah kedua baris terisi, jangan panggil `/forecast` atau `/esg-narrative` lagi** sampai demo selesai. Termasuk saat gladi bersih — gladi membaca cache, dan itu memang perilaku yang akan terjadi di depan juri.

`reset_demo.sql` **tidak boleh** menghapus kedua baris ini. Periksa sebelum memakainya.
