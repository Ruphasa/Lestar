DAFTAR ISI
DAFTAR ISI .............................................................................................................................. ii
DAFTAR TABEL .................................................................................................................... iii
DAFTAR GAMBAR ................................................................................................................ iv
BAB I PENDAHULUAN ......................................................................................................... 1
1.1 Latar Belakang ................................................................................................................. 1
1.2 Tujuan ............................................................................................................................... 2
1.3 Manfaat............................................................................................................................. 2
BAB II GAGASAN .................................................................................................................. 4
2.1 Kondisi Aktual Objek Permasalahan................................................................................ 4
2.2 Gagasan yang Pernah Diimplementasikan Sebelumnya .................................................. 6
2.3 Bahasan Lengkap Gagasan yang Diajukan ...................................................................... 7
2.3.1 Sistem Kaskade Dua Tahap ....................................................................................... 8
2.3.2 Frictionless Claim via QR Code ................................................................................ 9
2.3.3 Sistem Radar & Real-Time Tracking ........................................................................ 9
2.3.4 Automated ESG Report ............................................................................................. 9
2.3.5 Buffer Intelligence ..................................................................................................... 9
2.4 Teknologi yang Digunakan ............................................................................................ 10
2.5 Prediksi Hasil Implementasi........................................................................................... 13
2.6 Peran & Kontribusi Pihak yang Terlibat ........................................................................ 14
2.7 Tahapan Strategis Implementasi ..................................................................................... 15
2.7.1 Roadmap Pengembangan Aplikasi .......................................................................... 15
2.7.2 Visi Jangka Panjang Lestar ...................................................................................... 17
BAB III PENUTUP ................................................................................................................ 18
3.1 Kesimpulan..................................................................................................................... 18
3.2 Saran ............................................................................................................................... 18
DAFTAR PUSTAKA ............................................................................................................... 20
SURAT PERNYATAAN .......................................................................................................... 21
ii

DAFTAR TABEL
Tabel 2.1.1 Gap Analisis — Solusi yang Ada vs. Lestar ........................................................... 5
Tabel 2.2.1 Analisis inovasi sebelum dan sesudah lestar ........................................................... 6
Tabel 2.4.1 Justifikasi Penggunaan Teknologi Sistem ............................................................. 12
Tabel 2.5.1 Target Metrik Keberhasilan Platform Lestar ........................................................ 13
Tabel 2.6.1 Peran & Kontribusi Aktor ..................................................................................... 15
Tabel 2.7.1 Detail Aktivitas dan Output Pengembangan Sistem ............................................. 15
iii

DAFTAR GAMBAR
Gambar 2.1.1 Surplus Makanan Restoran/Buffer Akhir Hari Operasional ............................... 4
Gambar 2.1.2 Alur Food waste Sektor F&B Tanpa Solusi Terintegrasi .................................... 5
Gambar 2.3.1 Arsitektur Sistem Lestar – Multi-Layer Architecture ......................................... 8
Gambar 2.4.1 Gambar Mockup Aplikasi Lestar ...................................................................... 10
Gambar 2.4.2 AI & ML Pipeline dari Lestar ........................................................................... 11
Gambar 2.5.1 Simulasi Dampak Finansial Operasional Restoran ........................................... 14
Gambar 2.6.1 Analisis Potensi Pasar (TAM, SAM, dan SOM) Lestar .................................... 15
Gambar 2.7.1 Roadmap Pengembangan Platform Lestar dalam 12 Bulan ............................. 16
Gambar 2.7.2 Blueprint global lestar dalam rentang waktu 5 tahun. ...................................... 17
iv

BAB I
PENDAHULUAN
1.1 Latar Belakang
Indonesia kini menghadapi paradoks pangan yang serius. Di satu sisi, jutaan warga
masih berjuang mengakses makanan yang layak. Indonesia berada di peringkat ke-70 dari 117
negara yang mengalami kelaparan parah. Di sisi lain, makanan terbuang dalam jumlah yang
tidak masuk akal. Berdasarkan laporan Food waste Index Report 2024 yang diterbitkan United
Nations Environment Programme (UNEP), Indonesia menghasilkan sampah makanan
sebanyak 14,73 juta ton per tahun yang menjadikan Indonesia sebagai negara penghasil food
waste terbesar di Asia Tenggara (Lutfiah Rahmadini, 2025).
Sementara itu, data KLHK mencatat total sampah Indonesia pada 2025 mencapai 25,14
juta ton, dengan 40,76% di antaranya merupakan sisa makanan. Angka ini bahkan melampaui
sampah plastik yang selama ini lebih sering jadi sorotan publik (Talita Aqila Shafidhya, 2026).
Dampaknya tidak berhenti di lingkungan. Secara ekonomi, kerugian akibat sampah makanan
diperkirakan mencapai Rp213 hingga Rp551 triliun per tahun, serta menyumbang 7,29% dari
total emisi gas rumah kaca Indonesia setiap tahunnya. Apabila tidak ada intervensi nyata,
timbulan sampah makanan diproyeksikan meningkat hingga 200% dari dua dekade lalu,
mencapai 344 kg per kapita per tahun pada 2045 (Agnes Z. Yonatan, 2024). Yang lebih
memprihatinkan, Badan Pangan Nasional menyebutkan bahwa jumlah sampah makanan yang
dihasilkan di Indonesia seharusnya mampu menghidupi 29 hingga 47% populasi rakyat
Indonesia (Lutfiah Rahmadini, 2025).
Permasalahan ini tidak hanya terjadi pada skala nasional. Di tingkat regional, Kota
Malang sebagai target percontohan implementasi Lestar mencatatkan timbulan sampah harian
mencapai 588,99 ton per hari berdasarkan data SIPSN KLHK 2023, dengan 57,75% di
antaranya merupakan sampah sisa makanan dan organik yang mayoritas berasal dari sektor
F&B dan rumah tangga (Kementerian Lingkungan Hidup, 2025). TPA Supit Urang sebagai
satu-satunya TPA aktif Kota Malang menerima beban sampah organik yang terus meningkat
setiap tahunnya sebuah kondisi yang secara langsung mencerminkan ketiadaan sistem
pengelolaan surplus F&B yang terstruktur di tingkat kota (Prasetyo dkk., 2018).
Sektor Food & Beverage (F&B) jadi salah satu titik kritis dalam rantai ini. Riset
Aksamala Foundation menunjukkan bahwa 35% restoran di Jakarta membuang kelebihan
makanan yang tidak terjual setiap harinya, dengan rata-rata dua sampai tiga kilogram per
restoran. Secara industri, restoran rata-rata membuang 4-10% dari total makanan yang
diproduksi. Artinya, dengan omzet Rp200 juta per bulan, ada Rp8-20 juta yang terbuang sia -
sia setiap bulannya. Surplus ini umumnya berakhir di tempat pembuangan akhir, padahal
sebenarnya masih layak dikonsumsi atau bernilai sebagai bahan baku industri agrikultur
(Vikrie, 2025).
1

Tantangan utamanya adalah belum adanya ekosistem digital yang menghubungkan
merchant F&B dengan konsumen akhir dan mitra pengolah limbah organik dalam satu sistem
yang sama. Platform yang ada sekarang umumnya cuma menangani satu sisi masalah saja,
entah redistribusi ke konsumen atau pengelolaan limbah, tanpa membangun alur kaskade yang
memanfaatkan setiap kilogram surplus secara maksimal.
Lestar dikembangkan untuk mengisi celah tersebut. Sebagai platform SaaS dan
marketplace berbasis ekonomi sirkular digital, Lestar membangun sistem kaskade dua tahap:
mendistribusikan makanan surplus yang masih layak konsumsi kepada pembeli B2C lewat
mekanisme flash sale, sekaligus menyalurkan sisa limbah organik yang tidak layak konsumsi
kepada mitra B2B seperti peternak maggot, peternak unggas, dan produsen kompos. Dengan
mengintegrasikan kecerdasan buatan untuk prediksi surplus dan penetapan harga dinamis,
Lestar membantu mengelola food waste sebagai peluang ekonomi yang berkelanjutan, bukan
sekadar beban operasional, sejalan dengan tema KMIPN VIII, "Inovasi Informatika Vokasional
untuk Transformasi Digital Berkelanjutan."
1.2 Tujuan
Pengembangan platform Lestar bertujuan untuk:
1. Membangun ekosistem digital terintegrasi berbasis ekonomi sirkular yang
menghubungkan merchant F&B, konsumen akhir (B2C), dan mitra pengolah limbah
organik (B2B) dalam satu platform.
2. Mereduksi volume pembuangan sisa makanan dari sektor F&B melalui mekanisme
distribusi surplus dua tahap yang cerdas dan otomatis.
3. Memaksimalkan nilai ekonomi merchant F&B melalui dua pendekatan simultan: (a)
Smart Production Advisor berbasis hybrid LSTM dan LLM yang membantu merchant
mengoptimalkan keputusan produksi harian melalui prediksi demand (X) dan surplus
probability (Y), serta (b) sistem distribusi surplus berlapis yang menjamin setiap
kilogram produksi memiliki jalur nilai baik melalui penjualan harga normal, flash sale
B2C, maupun redistribusi limbah organik ke mitra B2B.
4. Menyediakan alat ukur keberlanjutan otomatis bagi merchant F&B dalam bentuk
laporan ESG yang dapat digunakan sebagai instrumen green branding dan perencanaan
operasional.
5. SDGs 2.1 Berkontribusi secara terukur pada pencapaian tiga target SDGs:
melalui redistribusi surplus kepada masyarakat rentan; SDGs 8.3 melalui penciptaan
ekosistem ekonomi inklusif bagi UMKM F&B dan mitra agrikultur; serta SDGs 12.3
melalui pengurangan volume food waste dari sektor F&B sebesar target 50% pada
tahun 2030.
1.3 Manfaat
• Bagi Merchant F&B: Lestar berfungsi sebagai penasihat operasional pintar yang
bekerja dalam dua lapisan. Lapisan pertama adalah pencegahan kerugian Smart
2

Production Advisor merekomendasikan jumlah produksi optimal setiap hari
berdasarkan prediksi demand berbasis data, sehingga merchant dapat memaksimalkan
penjualan pada hari demand tinggi tanpa takut kelebihan stok produksi. Lapisan kedua
adalah pemulihan nilai setiap surplus yang tetap terbentuk memiliki guaranteed exit
channel melalui flash sale B2C dan redistribusi B2B, sehingga potensi kerugian bisa
berubah menjadi pemasukan tambahan dan penghematan biaya retribusi sampah.
• Bagi Konsumen B2C: Akses ke makanan layak konsumsi berkualitas dengan diskon
signifikan (50-70%), menjawab kebutuhan segmen price-sensitive seperti mahasiswa
dan pekerja muda urban.
• Bagi Mitra Pengolah Limbah (B2B): Kepastian pasokan bahan baku pakan atau
kompos dengan efisiensi biaya melalui satu model berlangganan (subscription).
• Bagi Lingkungan & Masyarakat: Pengurangan emisi metana dari pembusukan
organik di TPA dan jejak karbon operasional F&B secara keseluruhan — berkontribusi
langsung pada SDGs 12.3 (Responsible Consumption and Production). Redistribusi
makanan layak konsumsi kepada mahasiswa dan masyarakat berpenghasilan rendah
mendukung SDGs 2 (Zero Hunger). Pertumbuhan ekosistem mitra B2B membuka
lapangan kerja dan rantai nilai agrikultur baru selaras dengan SDGs 8 (Decent Work
and Economic Growth).
• Bagi Ekosistem Vokasi: Membuktikan bahwa inovasi informatika mahasiswa
politeknik mampu menjawab permasalahan nyata bangsa dengan solusi teknologi yang
implementatif dan berdampak ekonomi langsung.
3

BAB II
GAGASAN
2.1 Kondisi Aktual Objek Permasalahan
Sektor Food & Beverage (F&B) di Indonesia menghadapi permasalahan struktural
yang belum terpecahkan: tidak adanya ekosistem digital yang mengintegrasikan seluruh rantai
nilai dari surplus makanan hingga pemanfaatan limbah organik secara terintegrasi.Saat ini,
ketika merchant F&B menghasilkan surplus makanan di akhir hari operasional, mereka
dihadapkan pada dua pilihan yang sama-sama tidak ideal. Makanan yang masih layak konsumsi
sering kali dibuang begitu saja karena tidak ada kanal distribusi yang cepat dan mudah.
Sementara itu, sisa limbah organik yang tidak layak konsumsi juga tidak punya jalur
pengelolaan yang jelas. Peternak maggot, peternak unggas, maupun produsen kompos tidak
punya akses ke pasokan bahan baku yang konsisten dan bisa diprediksi.Kondisi ini diperparah
oleh absennya sistem inteligensi yang mampu membantu merchant membuat keputusan
berbasis data: kapan harus menurunkan harga, berapa volume surplus yang diperkirakan, dan
ke mana surplus tersebut harus dialirkan.
Gambar 2.1.1 Surplus Makanan Restoran/Buffer Akhir Hari Operasional
4

Gambar 2.1.2 Alur Food waste Sektor F&B Tanpa Solusi Terintegrasi
Tabel 2.1.1 Gap Analisis — Solusi yang Ada vs. Lestar
| Dimensi                                  | Solusi Saat Ini  | Gap yang Ada  |
| ---------------------------------------- | ---------------- | ------------- |
| Platform flash  Surplus.id, Too Good To  |                  |               |
Hanya B2C, tidak ada alur ke mitra B2B
| sale  Go  |     |     |
| --------- | --- | --- |
Donasi makanan  Yayasan/NGO lokal  Tidak scalable, bergantung relawan
Pengelolaan  Tidak terhubung ke merchant, tidak real-
Pickup manual, informal
limbah  time
Pricing surplus  Manual & subjektif kasir  Tidak ada dynamic pricing berbasis data
ESG reporting  Tidak ada / manual Excel  Merchant tidak punya bukti green impact
Tidak ada forecasting volume surplus
| AI prediction  Tidak tersedia  |     |     |
| ------------------------------ | --- | --- |
harian
5

2.2 Gagasan yang Pernah Diimplementasikan Sebelumnya
Gagasan Lestar bukan sesuatu yang muncul tiba-tiba. Ia merupakan evolusi terstruktur
dari Ecobite, platform manajemen food waste yang sebelumnya telah berhasil meraih Juara 1
pada  kompetisi  National  Exellence  Competitions  2026.  Ecobite  membuktikan  bahwa
pendekatan digital untuk redistribusi surplus makanan memiliki relevansi dan penerimaan
nyata di ekosistem kompetisi maupun di kalangan pemangku kepentingan F&B.
Ecobite berfokus pada sisi hulu: menghubungkan merchant F&B dengan konsumen
akhir melalui mekanisme flash sale berbasis lokasi. Platform tersebut berhasil memvalidasi
beberapa  asumsi  kritis,  antara  lain:  kesediaan  merchant  untuk  mengadopsi  teknologi
pengelolaan surplus, antusiasme konsumen terhadap makanan diskon berkualitas, serta potensi
pengurangan food waste yang signifikan apabila ada kanal distribusi yang frictionless.
Namun  dalam  perjalanannya,  Ecobite  mengidentifikasi  peluang  evolusi  yang
signifikan: sistem ekonomi sirkular yang telah dibangun dapat diperkuat secara substansial
melalui otomasi berbasis kecerdasan buatan dan perluasan ekosistem mitra pengolah limbah
organik. Alur kaskade dari surplus layak konsumsi menuju redistribusi B2C, hingga limbah
organik menuju mitra B2B, membutuhkan intelligence layer yang mampu membuat keputusan
distribusi  secara  real-time  sesuatu  yang  belum  dapat  dijawab  oleh  Ecobite  pada  iterasi
pertamanya.
Lestar dikembangkan sebagai jawaban atas persoalan tersebut. Ia mengambil fondasi
yang sudah teruji dari Ecobite, lalu memperluas dan mengotomasi ekosistemnya dengan
menambahkan kecerdasan buatan berlapis: LSTM untuk forecasting numerik, LLM untuk
enrichment kontekstual, dan Buffer Intelligence sebagai fitur proaktif yang mengubah Lestar
dari platform reaktif menjadi penasihat operasional pintar bagi merchant F&B.
Tabel 2.2.1 Analisis inovasi sebelum dan sesudah lestar
| Dimensi  | Ecobite (sebelumnya)  |     | Lestar (evolusi)  |
| -------- | --------------------- | --- | ----------------- |
Redistribusi B2C surplus layak
| Fokus  |     | B2C + B2B kaskade dua tahap  |     |
| ------ | --- | ---------------------------- | --- |
konsumsi
| AI  |     | Penetapan harga dinamis, peramalan /  |     |
| --- | --- | ------------------------------------- | --- |
Tidak ada
| Integration  |     | forecasting, auto-triage  |     |
| ------------ | --- | ------------------------- | --- |
| Limbah       |     | Diarahkan ke mitra        |     |
Tidak ditangani
| organik  |     | maggot/kompos/unggas  |     |
| -------- | --- | --------------------- | --- |
ESG
|     | Tidak ada  | Automated, export-ready  |     |
| --- | ---------- | ------------------------ | --- |
Reporting
Komisi + subscription B2B + green
| Model bisnis  | Komisi transaksi  |     |     |
| ------------- | ----------------- | --- | --- |
fee
| Pencapaian  | Juara 1 kompetisi  | Target implementasi nasional  |     |
| ----------- | ------------------ | ----------------------------- | --- |
6

2.3 Bahasan Lengkap Gagasan yang Diajukan
Lestar dirancang sebagai platform SaaS dan marketplace berbasis ekonomi sirkular
digital yang beroperasi melalui sistem kaskade dua tahap. Berbeda dari solusi yang ada, Lestar
mengintegrasikan kecerdasan buatan ke dalam setiap titik keputusan operasional, dari prediksi
surplus hingga penetapan harga dan pencocokan mitra. Dengan membangun ekosistem yang
menghubungkan tiga sisi pasar secara simultan, Lestar berkontribusi nyata pada tiga pilar
SDGs sekaligus: redistribusi surplus kepada kelompok rentan (SDGs 2 Zero Hunger),
pembukaan ekosistem ekonomi inklusif bagi UMKM F&B dan mitra agrikultur (SDGs 8
Decent Work and Economic Growth), serta reduksi terstruktur volume food waste (SDGs 12
Responsible Consumption and Production, target 12.3).
7

Gambar 2.3.1 Arsitektur Sistem Lestar – Multi-Layer Architecture
2.3.1 Sistem Kaskade Dua Tahap
Cascade Engine Lestar menggunakan pendekatan AI-Assisted Triage, bukan
otomasi buta, melainkan kolaborasi antara kecerdasan buatan dan validasi manusia yang
dirancang untuk menjaga standar keamanan pangan. AI melakukan food safety scoring
berbasis probabilitas ketahanan makanan menggunakan input timestamp, jenis produk,
suhu lingkungan dari weather API, dan historis shelf-life kategori produk serupa. Skor
ini kemudian disajikan kepada merchant sebagai rekomendasi jalur distribusi B2C atau
B2B.
Namun sebelum listing manapun tayang ke publik, merchant wajib melakukan
one-tap Physical Validation Confirmation, sebuah tombol "Validasi Kondisi Fisik
Aman" yang mengonfirmasi bahwa kondisi fisik makanan (aroma, tekstur, tampilan
visual) telah diperiksa secara langsung. Tanpa konfirmasi ini, listing tidak akan aktif.
8

Mekanisme ini memastikan Lestar tidak menjadi satu-satunya pihak yang menentukan
kelayakan konsumsi, tanggung jawab final tetap berada pada merchant.
2.3.2 Klaim Tanpa Hambatan Lewat Kode QR
Transaksi B2C diselesaikan dengan pemindaian QR code tanpa mengganggu
ritme operasional kasir. Ada kemungkinan waktu terbentuknya surplus F&B tidak
selalu cocok dengan pola aktivitas konsumen F&B dengan pola aktivitas konsumen
B2C. Solusinya ada pada fitur Buffer Intelligence: karena sistem sudah memprediksi
volume surplus harian sejak pagi melalui output Y (Surplus Probability), merchant
dapat melakukan Pre-Listing "Surplus Box" sejak pukul 16.00 – 17.00 sore. Konsumen
B2C dapat melakukan booking dan pembayaran di sore hari, lalu tinggal melakukan
pickup dan scan QR code pada malam hari saat restoran closing, tanpa harus
menunggu-nunggu notifikasi mendadak saat larut malam.
2.3.3 Sistem Radar & Real-Time Tracking
Mitra B2B memantau titik limbah terdekat dan status armada penjemputan
secara langsung melalui peta interaktif. Supabase Realtime menjadi backbone
websocket untuk update data instan. Smart Matching Engine secara otomatis
mencocokkan mitra dengan sumber limbah terdekat berdasarkan jenis kebutuhan wet
waste untuk maggot, dry waste untuk kompos. mengeliminasi proses pencarian
pasokan manual yang selama ini dilakukan secara informal.
2.3.4 Laporan ESG Otomatis
LLM secara otomatis menghasilkan laporan keberlanjutan per periode,
mencetak metrik reduksi sampah dalam kilogram, estimasi penghematan emisi CO₂,
dan narasi dampak lingkungan yang dapat digunakan merchant sebagai materi green
branding resmi. Green Fee sebesar Rp1.000 per transaksi yang dibebankan kepada
konsumen B2C dialokasikan khusus untuk pemeliharaan sistem kalkulasi emisi (ESG
engine) dan infrastruktur server real-time sebagai bentuk keterlibatan konsumen dalam
ekosistem ekonomi sirkular.
2.3.5 Buffer Intelligence
Lestar tidak hanya mengelola food waste yang sudah terjadi, ia secara proaktif
membantu merchant mengoptimalkan keputusan produksi harian. Sistem ini
menghasilkan dua output peramalan utama:
• X Demand Forecast: prediksi jumlah porsi yang akan terjual hari ini/besok
berdasarkan pola historis transaksional merchant.
• Y Surplus Probability: probabilitas dan estimasi volume surplus yang akan
terbentuk jika merchant memproduksi pada level tertentu.
9

Dari X dan Y, sistem secara otomatis merekomendasikan stok penyangga
optimal jumlah produksi tambahan di atas demand forecast yang aman untuk
diproduksi karena Lestar menjadi jalur keluar yang pasti bagi setiap surplus yang
terbentuk. Merchant yang sebelumnya takut overproduksi kini dapat dengan percaya
diri menambah kapasitas produksi pada hari prediksi demand tinggi, memaksimalkan
revenue dari harga normal sekaligus meminimalkan potensi lost sales.
2.4 Teknologi yang Digunakan
Gambar 2.4.1 Gambar Mockup Aplikasi Lestar
10

AI Pipeline Penjelasan Teknis
Gambar 2.4.2 AI & ML Pipeline dari Lestar
Pipeline AI Lestar menggunakan arsitektur hybrid LSTM × LLM dengan fallback chain
memisahkan tugas prediksi numerik dan pemahaman kontekstual ke model yang paling
optimal untuk masing-masing:
LSTM (Long Short-Term Memory) berperan sebagai engine prediksi numerik.
Model ini dilatih menggunakan data historis transaksional setiap merchant pola penjualan
harian, jam operasional, hari dalam seminggu untuk menghasilkan dua output utama: X
(Demand Forecast) dan Y (Surplus Probability). LSTM dipilih karena dirancang khusus untuk
11

time-series  sequential  data  dan  menghasilkan  akurasi  tinggi  untuk  pola  berulang  tanpa
membutuhkan komputasi berat.
Gemini 2.5 Flash berperan sebagai Context Enrichment Layer. Output numerik dari
LSTM diperkaya dengan pemahaman konteks dunia nyata cuaca dari weather API, kalender
libur  nasional,  event  lokal,  tren  demand  untuk  menghasilkan  angka  final  yang  sudah
terkalibrasi beserta narasi rekomendasi dalam Bahasa Indonesia yang langsung dapat dibaca
merchant.
Cloudflare Workers AI (Qwen) berperan sebagai secondary layer untuk inferensi
ringan di edge node yang akan menangani request volume tinggi dengan latensi sangat rendah
ketika Gemini API mengalami beban tinggi.
Rule-based heuristic fallback adalah lapisan deterministik terakhir yang menjamin
sistem tetap berjalan meski seluruh API eksternal tidak tersedia.
Tabel 2.4.1 Justifikasi Penggunaan Teknologi Sistem
| Layer  | Teknologi  |     | Justifikasi  |
| ------ | ---------- | --- | ------------ |
Satu basis kode Android & iOS, performa
| Mobile Frontend  | Flutter  |     |     |
| ---------------- | -------- | --- | --- |
mendekati aplikasi asli
| State  |     | Reaktif, mudah diuji, cocok untuk real-time  |     |
| ------ | --- | -------------------------------------------- | --- |
Riverpod
| Management  |     | data  |     |
| ----------- | --- | ----- | --- |
Primary  Supabase  Data bisnis relasional, Row Level Security,
| Database  | (PostgreSQL)  | autentikasi bawaan  |     |
| --------- | ------------- | ------------------- | --- |
WebSocket untuk pelacakan armada & status
| Realtime Engine  | Supabase Realtime  |     |     |
| ---------------- | ------------------ | --- | --- |
klaim secara langsung
| Push  | Firebase Cloud  |     |     |
| ----- | --------------- | --- | --- |
Notifikasi mobile yang andal dan gratis
| Notification  | Messaging           |                                         |     |
| ------------- | ------------------- | --------------------------------------- | --- |
| Forecasting   | LSTM                | Time-series forecasting: X=permintaan,  |     |
| Engine        | (TensorFlow/Keras)  | Y=probabilitas surplus                  |     |
Gemini 2.5 Flash  Pengayaan konteks, narasi rekomendasi dalam
AI Primary
|     | API  | Bahasa Indonesia  |     |
| --- | ---- | ----------------- | --- |
Cloudflare Workers  Inferensi di edge node, cadangan dengan latensi
AI Secondary
|     | AI (Qwen)  | rendah  |     |
| --- | ---------- | ------- | --- |
Tetap berjalan tanpa koneksi internet, bersifat
| AI Fallback  | Rule-based heuristic  |     |     |
| ------------ | --------------------- | --- | --- |
deterministik
| Backend  |     | REST API - FastAPI khusus untuk melayani  |     |
| -------- | --- | ----------------------------------------- | --- |
Node.js + FastAPI
| Services  |     | model LSTM  |     |
| --------- | --- | ----------- | --- |
ML Model  FastAPI +  Menghubungkan endpoint inferensi LSTM ke
| Serving  | TensorFlow Serving  | backend  |     |
| -------- | ------------------- | -------- | --- |
Autentikasi, pembatasan laju permintaan,
| API Gateway  | Kong / Nginx  |     |     |
| ------------ | ------------- | --- | --- |
routing
QR Generation  qr_flutter (Dart)  Pembuatan kode QR native di Flutter
12

Penyimpanan aset kode QR, foto produk,
| Cloud Storage  | Supabase Storage  |     |     |
| -------------- | ----------------- | --- | --- |
laporan ESG
| Analytics  | Firebase Analytics  | Pelacakan perilaku pengguna  |     |
| ---------- | ------------------- | ---------------------------- | --- |
Maps & Radar  Google Maps SDK  Titik pengambilan B2B, radius deteksi
OpenWeatherMap
Weather Context  Input konteks eksternal untuk pengayaan LLM
API
2.5 Prediksi Hasil Implementasi
Berdasarkan data baseline dari riset yang telah dipaparkan pada Bab I serta validasi
konsep yang diperoleh melalui Ecobite, Lestar memprediksi dampak berikut dalam kurun
waktu 12 bulan pertama pasca-peluncuran di satu kota percontohan (Malang Raya):
Tabel 2.5.1 Target Metrik Keberhasilan Platform Lestar
|     | Target 6  | Target 12  |     |
| --- | --------- | ---------- | --- |
Metrik  Basis Asumsi
Bulan  Bulan
Merchant F&B
|     | 50 merchant  | 200 merchant  | Penetrasi 1% SAM Malang  |
| --- | ------------ | ------------- | ------------------------ |
onboarded
Transaksi B2C per
|     | 500 transaksi  | 3.000 transaksi  | 10 transaksi/merchant aktif  |
| --- | -------------- | ---------------- | ---------------------------- |
bulan
Volume limbah B2B
|     | 500 kg/bulan  | 3.000 kg/bulan  | 2,5 kg surplus/merchant/hari  |
| --- | ------------- | --------------- | ----------------------------- |
tersalurkan
| Mitra B2B aktif  | 10 mitra  | 40 mitra  | 1 mitra per 5 merchant  |
| ---------------- | --------- | --------- | ----------------------- |
| Estimasi CO₂     | 750 kg    | 4.500 kg  |                         |
0,25 kg CO₂eq per kg surplus
| terselamatkan  | CO₂eq/bln  | CO₂eq/bln  |     |
| -------------- | ---------- | ---------- | --- |
Reduksi kerugian  ~65% dari  ~83% dari  LSTM akurasi baseline 70%,
surplus merchant  baseline  baseline  meningkat seiring data
Sisa kerugian yang  ~35% dari  ~17% dari  Error margin model + force
| tidak terhindarkan  | baseline  | baseline  | majeure demand  |
| ------------------- | --------- | --------- | --------------- |

Perlu ditegaskan bahwa Lestar tidak mengklaim dapat menghilangkan seluruh kerugian
akibat surplus. Model LSTM pada fase awal beroperasi pada akurasi baseline sekitar 70%
artinya terdapat error margin yang realistis dan tidak dapat dieliminasi sepenuhnya. Target
reduksi kerugian sebesar 83% pada bulan ke-12 mencerminkan kondisi model yang telah
melalui tiga iterasi fine-tuning menggunakan data aktual merchant, bukan sekedar asumsi ideal
di atas kertas. Sisa kerugian sebesar 17% dari baseline merepresentasikan batas wajar yang
secara empiris dapat dipertanggungjawabkan dan justru menjadi ruang perbaikan berkelanjutan
bagi model di fase scaling berikutnya. Penurunan dari baseline ke 17% sisa kerugian sudah
menunjukkan perubahan operasional yang besar bagi merchant F&B skala UMKM.
13

Gambar 2.5.1 Simulasi Dampak Finansial Operasional Restoran
Pada dimensi kualitatif, Lestar berkontribusi langsung pada pencapaian SDGs 2 melalui
redistribusi makanan surplus kepada kelompok rentan, SDGs 8 melalui pertumbuhan
ekosistem mitra B2B yang membuka rantai nilai agrikultur baru, dan SDGs 12.3 melalui
reduksi terstruktur volume food waste dari sektor F&B.
2.6 Peran & Kontribusi Pihak yang Terlibat
Analisis Pasar TAM SAM SOM
TAM (Total Addressable Market)
Seluruh restoran, kafe, dan bakery potensial di Indonesia yang menghasilkan surplus
makanan dan relevan untuk efisiensi digital. Diperkirakan terdapat ±400.000 unit usaha F&B
skala menengah yang masuk dalam kriteria ini. Dengan asumsi potensi monetisasi (langganan
sistem/komisi transaksi) rata-rata Rp 200.000/merchant/bulan, TAM = Rp 80 miliar/bulan atau
Rp 960 miliar/tahun.
SAM (Serviceable Addressable Market)
Merchant F&B di wilayah regional Jawa Timur (termasuk kota besar seperti Surabaya
dan Malang) yang sudah melek digital dan memiliki volume surplus harian yang memadai
untuk disalurkan atau diolah kembali. Diperkirakan terdapat ±20.000 merchant potensial di
wilayah ini. SAM = Rp 4 miliar/bulan atau Rp 48 miliar/tahun.
SOM (Serviceable Obtainable Market)
Target realistis penetrasi pasar dalam 12 bulan (1 tahun) pertama operasional. Berfokus
pada akuisisi awal di Malang Raya dan Surabaya sebagai kota percontohan, dengan target
14

mencapai 200 merchant F&B aktif yang ter-onboard ke dalam platform. SOM = Rp 40
juta/bulan atau Rp 480 juta/tahun.
Gambar 2.6.1 Analisis Potensi Pasar (TAM, SAM, dan SOM) Lestar
Platform Lestar beroperasi dalam ekosistem three-sided platform yang melibatkan tiga
aktor utama beserta pihak pendukung eksternal:
Tabel 2.6.1 Peran & Kontribusi Aktor
2.7 Tahapan Strategis Implementasi
2.7.1 Roadmap Pengembangan Aplikasi
Tabel 2.7.1 Detail Aktivitas dan Output Pengembangan Sistem
Fase Periode Aktivitas Utama Output
Menyiapkan infrastruktur Supabase + Prototype
Fase 0
Bulan 1–2 Firebase, mendesain UI/UX di Flutter, clickable +
Fondasi
integrasi awal Gemini API API connected
Membangun fitur inti: listing surplus,
klaim lewat kode QR, notifikasi B2B,
Fase 1 dasbor merchant. Ditambah strategi
MVP + LSTM
MVP + pengumpulan data: melatih LSTM dasar
Bulan 3–4 baseline
Data dengan data sintetis & dataset terbuka
model v0
Foundation penjualan restoran (Restaurant Orders
Dataset milik Kaggle) sebagai titik awal
model sebelum data aktual tersedia
Integrasi mesin penetapan harga dinamis, AI-powered
Fase 2 Bulan 5–6
penyaringan kaskade otomatis, Buffer version live +
15

| AI  |     | Intelligence (output X & Y), cadangan  | model v1  |
| --- | --- | -------------------------------------- | --------- |
Integration  Cloudflare Workers AI. LSTM dilatih  berbasis data
|     |     | ulang memakai data aktual dari merchant  | nyata  |
| --- | --- | ---------------------------------------- | ------ |
awal di Fase 1
|     |     | Mendaftarkan 50 merchant Malang Raya,  | Data real- |
| --- | --- | -------------------------------------- | ---------- |
Fase 3
|        |            | 10 mitra B2B, umpan balik aktif.    | world, model  |
| ------ | ---------- | ----------------------------------- | ------------- |
| Pilot  | Bulan 7–9  |                                     |               |
|        |            | Penyesuaian LSTM berkelanjutan per  | v2 per-       |
Launch
|     |     | merchant (model personal)  | merchant  |
| --- | --- | -------------------------- | --------- |
200 merchant,
Laporan ESG otomatis, ekspansi ke
| Fase 4  | Bulan 10– |     | product- |
| ------- | --------- | --- | -------- |
Surabaya, optimasi model AI dari data uji
| Scaling  | 12  |     | market fit,  |
| -------- | --- | --- | ------------ |
coba
model v3
Strategi akuisisi data untuk mengatasi tantangan cold start LSTM dilakukan secara
bertahap dalam tiga tahap. Tahap pertama (Fase 1): model dilatih menggunakan synthetic
data yang dibuat berdasarkan pola umum operasional F&B Indonesia dan open-source
dataset publik seperti Restaurant Orders Dataset, sebagai baseline model v0. Tahap kedua
(Fase 2): begitu MVP aktif dan early merchant mulai menggunakan platform, data transaksi
aktual  digunakan  untuk  fine-tuning  model  menghasilkan  model  v1  yang  sudah
mencerminkan pola lokal nyata. Tahap ketiga (Fase 3 dan seterusnya): setiap merchant
mendapatkan model LSTM yang dipersonalisasi berdasarkan data operasional uniknya
sendiri, semakin akurat seiring bertambahnya data historis. Pendekatan ini memastikan
Buffer Intelligence tetap memberikan rekomendasi yang berguna sejak hari pertama, dan
terus meningkat akurasinya secara otomatis.

Gambar 2.7.1 Roadmap Pengembangan Platform Lestar dalam 12 Bulan

16

2.7.2 Visi Jangka Panjang Lestar
Lestar tidak dirancang sekadar sebagai aplikasi melainkan sebagai infrastruktur layer
ekonomi sirkular digital Indonesia. Dalam kurun waktu 3–5 tahun, Lestar memproyeksikan
perkembangan platform sebagai berikut:
• Tahun 1–2 Local Champion: Dominasi pasar Jawa Timur (Malang, Surabaya, Batu)
sebagai bukti konsep yang terukur dengan data ESG yang dapat dipublikasikan.
• Tahun 2–3 National Expansion: Replikasi model ke 10 kota besar Indonesia (Jakarta,
Bandung, Yogyakarta, Semarang, Medan, Makassar). Kemitraan formal dengan
Kementerian Lingkungan Hidup dan dinas-dinas daerah untuk integrasi data sampah
nasional.
• Tahun 3–5 Ecosystem Play: Lestar bertransformasi menjadi Circular Economy Data
Platform menyediakan API terbuka bagi pemerintah, lembaga riset, dan perusahaan
FMCG untuk mengakses insight aliran limbah organik secara nasional. Pada titik ini,
Lestar bukan hanya marketplace, melainkan infrastruktur data keberlanjutan yang
menjadi rujukan kebijakan pangan dan lingkungan nasional.
Gambar 2.7.2 Blueprint global lestar dalam rentang waktu 5 tahun.
17

BAB III
PENUTUP
3.1 Kesimpulan
Indonesia menghadapi krisis food waste yang sifatnya mendasar, bukan sekadar
persoalan perilaku individu, melainkan karena belum adanya infrastruktur digital yang bisa
mengatur aliran surplus makanan secara efisien dari hulu ke hilir. Dengan kerugian ekonomi
mencapai Rp213 sampai 551 triliun per tahun dan kontribusi emisi GRK sebesar 7,29%,
persoalan ini butuh solusi yang tidak hanya reaktif, tapi juga sistemik dan berkelanjutan. Lestar
hadir sebagai jawaban konkret atas tantangan tersebut. Sebagai platform SaaS dan marketplace
berbasis ekonomi sirkular digital, Lestar membangun ekosistem three-sided platform yang
menghubungkan merchant F&B, konsumen B2C, dan mitra pengolah limbah organik dalam
satu alur kaskade yang cerdas dan terautomasi. Dengan mengintegrasikan kecerdasan buatan
berlapis: Gemini 2.5 Flash sebagai model utama, Cloudflare Workers AI sebagai edge inference
cadangan, dan rule-based heuristic sebagai fallback yang deterministik. Dengan begitu, Lestar
bisa membuat keputusan distribusi surplus secara real-time tanpa perlu intervensi manual yang
memperlambat operasional merchant.
Tiga nilai utama yang Lestar tawarkan sekaligus adalah:
• Pertama, nilai ekonomi. Merchant memperoleh revenue recovery dari surplus yang
sebelumnya terbuang, konsumen mendapat akses makanan berkualitas dengan diskon 50
sampai 70%, dan mitra B2B memperoleh kepastian pasokan bahan baku dengan efisiensi
biaya yang tinggi.
• Kedua, nilai lingkungan. Setiap kilogram surplus yang berhasil diredistribusikan adalah
satu kilogram yang tidak menghasilkan emisi metana di TPA, sehingga berkontribusi
langsung terhadap target SDGs 12.3, pengurangan food waste 50% pada tahun 2030.
• Ketiga, nilai inovasi vokasi. Lestar membuktikan bahwa mahasiswa politeknik mampu
merancang solusi teknologi yang tidak hanya canggih secara teknis, tetapi juga
berdampak ekonomi dan lingkungan yang terukur dan nyata, sejalan dengan semangat
KMIPN VIII: "Inovasi Informatika Vokasional untuk Transformasi Digital
Berkelanjutan."
Lestar bukan sekadar aplikasi. Ia adalah infrastruktur layer ekonomi sirkular digital
Indonesia. Dimulai dari Malang, dikembangkan menuju skala nasional.
3.2 Saran
Guna memaksimalkan dampak implementasi Lestar, terdapat beberapa rekomendasi
strategis yang perlu diperhatikan:
• Bagi Pemangku Kebijakan: Diperlukan regulasi insentif bagi merchant F&B yang
secara aktif mengadopsi platform pengelolaan food waste digital, seperti pengurangan
18

retribusi sampah atau sertifikasi green business yang dapat meningkatkan daya tarik
adopsi teknologi ini secara massal.
• Bagi Ekosistem Startup & Investor: Segmen circular economy tech di Indonesia masih
sangat belum tergarap (maksimal) dibandingkan potensi pasarnya yang mencapai Rp
6,66 triliun per tahun. Lestar membuka peluang investasi di sektor yang memiliki double
bottom line, yaitu return finansial sekaligus dampak ESG yang terukur.
• Bagi Pengembangan Selanjutnya: Model AI yang digunakan perlu dilatih secara
berkelanjutan menggunakan data lokal yang dikumpulkan selama fase percontohan, guna
meningkatkan akurasi prediksi volume surplus yang spesifik untuk pola konsumsi
masyarakat Indonesia. Eksplorasi integrasi dengan sistem SIPSN (Sistem Informasi
Pengelolaan Sampah Nasional) milik KLHK juga perlu dipertimbangkan untuk
memperluas dampak dan meningkatkan kredibilitas platform.
19

DAFTAR PUSTAKA
Agnes Z. Yonatan (2024) Indonesia Jadi Penghasil Sampah Makanan Terbesar di ASEAN.
Tersedia pada: https://goodstats.id/article/indonesia-jadi-penghasil-sampah-makanan-
terbesar-di-asean-7olEG (Diakses: 7 Juli 2026).
Kementerian Lingkungan Hidup (2025) Timbulan Sampah, Sistem Informasi Pengelolaan
Sampah Nasional (SIPSN). Tersedia pada: https://sampahnasional.kemenlh.go.id/portal-
indikatif/data/timbulan-sampah (Diakses: 9 Juli 2026).
Lutfiah Rahmadini (2025) Food waste: Fenomena yang Terlihat Kecil tapi Mampu Merusak
Bumi. Tersedia pada: https://inovasimuda.org/publication/FoodWaste (Diakses: 7 Juli
2026).
Prasetyo, J.B. dkk. (2018) Manajemen Pengelolaan Sampah Dinas Lingkungan Hidup Kota
Malang. Semarang.
Talita Aqila Shafidhya (2026) Sampah Indonesia Didominasi Sisa Makanan pada 2025.
Tersedia pada: https://goodstats.id/article/sampah-indonesia-didominasi-sisa-makanan-
pada-2025-Yttj3 (Diakses: 7 Juli 2026).
Vikrie (2025) Strategi Kelola Barang Waste Bisnis F&B: Panduan Lengkap Kurangi
Kerugian dan Tingkatkan Profit. Tersedia pada: https://rapihin.id/strategi-kelola-
barang-waste-bisnis-fb-panduan-lengkap-kurangi-kerugian-dan-tingkatkan-profit/
(Diakses: 7 Juli 2026).
20

SURAT PERNYATAAN
21