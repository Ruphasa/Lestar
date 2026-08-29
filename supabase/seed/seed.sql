-- seed.sql — data demo Lestar.
--
-- Prasyarat: jalankan supabase/seed/create_accounts.py lebih dulu.
-- Skrip itu membuat 43 akun auth; trigger on_auth_user_created membuat
-- baris profiles-nya. Berkas ini hanya melengkapi data bisnis, dan
-- mencocokkan baris lewat profiles.email — tidak ada UUID yang di-hardcode,
-- jadi seed tetap benar walaupun akun dibuat ulang.
--
-- Isi:
--   1. 30 merchant Malang Raya, koordinat nyata
--   2. 8 mitra pengepul, termasuk Pak Budi 1,2 km dari Verde Kitchen
--   3. 5 konsumen
--   4. 2700 baris sales_history (30 merchant x 90 hari)
--   5. 12 listing live dari merchant selain Verde Kitchen
--   6. 2 waste_batch available, totalnya tepat 16,6 kg
--   7. 40 esg_event riwayat, lahir dari trigger (bukan disisipkan mentah)
--
-- Verde Kitchen sengaja TIDAK punya listing aktif. Listing itu dibuat
-- langsung di depan juri saat demo.

begin;

-- ── 1. Merchant ───────────────────────────────────────────────────────────
insert into public.merchants
  (id, store_name, store_address, lat, lng, category, operating_hours, cutoff_time, rating, level)
select p.id, d.store_name, d.store_address, d.lat, d.lng, d.category,
       d.operating_hours, d.cutoff_time::time, d.rating, d.level
from (values
  ('merchant@lestar.id',   'Verde Kitchen',               'Jl. Soekarno-Hatta No. 12, Lowokwaru, Malang', -7.9530, 112.6150, 'kafe',    '08:00-22:00', '22:00', 4.9, 3),
  ('merchant02@lestar.id', 'Warung Bu Tin',               'Jl. Bendungan Sutami No. 8, Malang',           -7.9612, 112.6203, 'warung',  '07:00-21:00', '21:00', 4.6, 2),
  ('merchant03@lestar.id', 'Bakery Malang Manis',         'Jl. Bunga Coklat No. 21, Malang',              -7.9585, 112.6088, 'bakery',  '07:00-21:00', '21:00', 4.7, 2),
  ('merchant04@lestar.id', 'Katering Sedap Rasa',         'Jl. Bandung No. 5, Malang',                    -7.9702, 112.6055, 'katering','06:00-20:00', '20:00', 4.5, 2),
  ('merchant05@lestar.id', 'Kopi Tugu Ijen',              'Jl. Ijen No. 44, Malang',                      -7.9740, 112.6265, 'kafe',    '09:00-23:00', '22:30', 4.8, 3),
  ('merchant06@lestar.id', 'Warung Pecel Kawi',           'Jl. Kawi Atas No. 17, Malang',                 -7.9700, 112.6180, 'warung',  '06:00-20:00', '20:00', 4.7, 2),
  ('merchant07@lestar.id', 'Roti Bakar Soehat',           'Jl. Soekarno-Hatta No. 30, Malang',            -7.9498, 112.6142, 'bakery',  '16:00-23:00', '22:30', 4.4, 1),
  ('merchant08@lestar.id', 'Ayam Geprek Sawojajar',       'Jl. Danau Toba No. 3, Sawojajar, Malang',      -7.9612, 112.6672, 'warung',  '10:00-22:00', '22:00', 4.5, 2),
  ('merchant09@lestar.id', 'Dapur Nusantara Blimbing',    'Jl. Borobudur No. 9, Blimbing, Malang',        -7.9382, 112.6425, 'katering','06:00-19:00', '19:00', 4.3, 1),
  ('merchant10@lestar.id', 'Kafe Suhat Corner',           'Jl. Soekarno-Hatta Indah No. 2, Malang',       -7.9455, 112.6208, 'kafe',    '09:00-23:00', '22:30', 4.6, 2),
  ('merchant11@lestar.id', 'Bakso Malang Cak Har',        'Jl. Sudimoro No. 6, Malang',                   -7.9560, 112.6250, 'warung',  '09:00-21:00', '21:00', 4.8, 3),
  ('merchant12@lestar.id', 'Toko Kue Lestari',            'Jl. Kawi No. 28, Malang',                      -7.9668, 112.6142, 'bakery',  '07:00-20:00', '20:00', 4.6, 2),
  ('merchant13@lestar.id', 'Warung Lalapan Bu Yuli',      'Jl. Jakarta No. 11, Malang',                   -7.9645, 112.6330, 'warung',  '16:00-23:00', '22:30', 4.4, 1),
  ('merchant14@lestar.id', 'Katering Barokah Lowokwaru',  'Jl. Mayjen Panjaitan No. 40, Malang',          -7.9440, 112.6100, 'katering','06:00-19:00', '19:00', 4.5, 2),
  ('merchant15@lestar.id', 'Kedai Kopi Klojen',           'Jl. Kahuripan No. 4, Klojen, Malang',          -7.9790, 112.6290, 'kafe',    '08:00-23:00', '22:30', 4.7, 2),
  ('merchant16@lestar.id', 'Martabak Manis Dieng',        'Jl. Terusan Dieng No. 15, Malang',             -7.9830, 112.6120, 'warung',  '17:00-23:30', '23:00', 4.6, 2),
  ('merchant17@lestar.id', 'Bakery Sari Ijen',            'Jl. Guntur No. 7, Malang',                     -7.9760, 112.6210, 'bakery',  '07:00-20:00', '20:00', 4.5, 2),
  ('merchant18@lestar.id', 'RM Padang Sederhana Kawi',    'Jl. Kawi No. 55, Malang',                      -7.9722, 112.6222, 'warung',  '08:00-22:00', '22:00', 4.3, 1),
  ('merchant19@lestar.id', 'Kafe Taman Krida',            'Jl. Soekarno-Hatta No. 7, Malang',             -7.9520, 112.6180, 'kafe',    '09:00-22:00', '22:00', 4.7, 2),
  ('merchant20@lestar.id', 'Pastry Corner Batu',          'Jl. Diponegoro No. 3, Batu',                   -7.9300, 112.5700, 'bakery',  '08:00-20:00', '20:00', 4.8, 3),
  ('merchant21@lestar.id', 'Warung Soto Ayam Lombok',     'Jl. Lombok No. 2, Malang',                     -7.9682, 112.6188, 'warung',  '06:00-15:00', '15:00', 4.9, 3),
  ('merchant22@lestar.id', 'Katering Amanah Singosari',   'Jl. Raya Singosari No. 18, Malang',            -7.9100, 112.6520, 'katering','06:00-19:00', '19:00', 4.4, 1),
  ('merchant23@lestar.id', 'Kopi Bulan Sabit',            'Jl. Sigura-gura No. 9, Malang',                -7.9578, 112.6320, 'kafe',    '10:00-24:00', '23:00', 4.5, 2),
  ('merchant24@lestar.id', 'Donat Kentang Mbak Sri',      'Jl. Candi Panggung No. 12, Malang',            -7.9505, 112.6290, 'bakery',  '07:00-19:00', '19:00', 4.6, 2),
  ('merchant25@lestar.id', 'Warung Rawon Nguling',        'Jl. Zainul Arifin No. 6, Malang',              -7.9805, 112.6350, 'warung',  '07:00-20:00', '20:00', 4.7, 2),
  ('merchant26@lestar.id', 'Dapur Mama Tumpang',          'Jl. Muharto No. 21, Malang',                   -7.9885, 112.6480, 'katering','06:00-18:00', '18:00', 4.3, 1),
  ('merchant27@lestar.id', 'Kafe Buku Ijen',              'Jl. Ijen No. 2, Malang',                       -7.9718, 112.6295, 'kafe',    '09:00-22:00', '22:00', 4.8, 3),
  ('merchant28@lestar.id', 'Roti Gembong Blimbing',       'Jl. LA Sucipto No. 30, Malang',                -7.9350, 112.6480, 'bakery',  '08:00-21:00', '21:00', 4.4, 1),
  ('merchant29@lestar.id', 'Gorengan Pak Slamet',         'Jl. Bendungan Sigura-gura No. 4, Malang',      -7.9598, 112.6068, 'warung',  '15:00-22:00', '22:00', 4.5, 2),
  ('merchant30@lestar.id', 'Katering Sehat Griya Shanta', 'Jl. Griya Shanta Blok K, Malang',              -7.9468, 112.6262, 'katering','06:00-19:00', '19:00', 4.6, 2)
) as d(email, store_name, store_address, lat, lng, category, operating_hours, cutoff_time, rating, level)
join public.profiles p on p.email = d.email
on conflict (id) do nothing;

-- ── 2. Mitra pengepul ─────────────────────────────────────────────────────
-- Pak Budi sengaja ditaruh 1,2 km utara Verde Kitchen: cukup dekat untuk
-- masuk radarnya saat kaskade, cukup jauh untuk terlihat nyata di peta.
insert into public.partners
  (id, org_name, partner_type, waste_preference, vehicle_type, license_plate,
   service_radius_km, base_lat, base_lng, total_pickups)
select p.id, d.org_name, d.partner_type, d.waste_preference::public.waste_type[],
       d.vehicle_type, d.license_plate, d.service_radius_km, d.base_lat, d.base_lng, d.total_pickups
from (values
  ('budi@lestar.id',    'Maggot Berkah Malang',      'maggot', '{wet}',      'Pikap L300',   'N 1234 AB', 10, -7.9638, 112.6150, 214),
  ('mitra02@lestar.id', 'Kompos Hijau Lestari',      'kompos', '{wet,dry}',  'Pikap Carry',  'N 2210 CD', 12, -7.9750, 112.6400,  98),
  ('mitra03@lestar.id', 'Unggas Sumber Rejeki',      'unggas', '{wet}',      'Motor roda 3', 'N 5567 EF', 15, -7.9300, 112.6600, 143),
  ('mitra04@lestar.id', 'Maggot Mandiri Sawojajar',  'maggot', '{wet}',      'Pikap Grand Max', 'N 8891 GH', 8, -7.9620, 112.6690,  61),
  ('mitra05@lestar.id', 'Kompos Tani Karangploso',   'kompos', '{wet,dry}',  'Truk engkel',  'N 4432 IJ', 20, -7.9000, 112.5900, 187),
  ('mitra06@lestar.id', 'Unggas Jaya Pakis',         'unggas', '{wet}',      'Pikap L300',   'N 7710 KL', 15, -7.9900, 112.6700,  74),
  ('mitra07@lestar.id', 'BSF Malang Raya',           'maggot', '{wet}',      'Motor roda 3', 'N 3320 MN', 10, -7.9480, 112.6350, 129),
  ('mitra08@lestar.id', 'Daur Organik Batu',         'kompos', '{wet,dry}',  'Truk engkel',  'N 6654 OP', 18, -7.9250, 112.5600, 156)
) as d(email, org_name, partner_type, waste_preference, vehicle_type, license_plate,
       service_radius_km, base_lat, base_lng, total_pickups)
join public.profiles p on p.email = d.email
on conflict (id) do nothing;

-- ── 3. Konsumen ───────────────────────────────────────────────────────────
-- Amira di pusat kota; radar-nya nanti memakai GPS perangkat, alamat ini
-- hanya untuk layar profil.
update public.profiles p
   set address = d.address,
       phone = d.phone,
       eco_points = d.eco_points
from (values
  ('amira@lestar.id',     'Jl. Semeru No. 14, Klojen, Malang',      '081234567801', 1240),
  ('konsumen02@lestar.id','Jl. Veteran No. 8, Lowokwaru, Malang',   '081234567802',  380),
  ('konsumen03@lestar.id','Jl. Bandung No. 21, Malang',             '081234567803',  915),
  ('konsumen04@lestar.id','Jl. Sigura-gura No. 3, Malang',          '081234567804',  120),
  ('konsumen05@lestar.id','Jl. Sumbersari No. 45, Malang',          '081234567805',  660)
) as d(email, address, phone, eco_points)
where p.email = d.email;

-- ── 4. sales_history — 30 merchant x 90 hari = 2700 baris ─────────────────
-- Bahan bakar LSTM Agent C. Deterministik: nilai diturunkan dari hashtext
-- (merchant, tanggal), jadi menjalankan ulang seed menghasilkan angka yang
-- sama persis dan hasil forecast tidak berubah antar gladi bersih.
--
-- Bentuk yang disimulasikan: permintaan naik akhir pekan, turun saat hujan,
-- melonjak pada hari libur nasional.
with m as (
  select id, row_number() over (order by store_name) as urutan
  from public.merchants
),
hari as (
  select generate_series(current_date - 90, current_date - 1, interval '1 day')::date as tanggal
),
mentah as (
  select m.id as merchant_id,
         h.tanggal,
         (extract(isodow from h.tanggal)::int - 1) as dow,           -- 0 = Senin
         -- basis harian per merchant, 40..99 porsi
         (40 + (m.urutan * 7) % 60)::numeric as basis,
         -- derau -10%..+10%, deterministik
         ((abs(hashtext(m.id::text || h.tanggal::text)) % 21) - 10)::numeric as derau_persen,
         (abs(hashtext(m.id::text || h.tanggal::text || 'cuaca')) % 4)::smallint as weather_code,
         (12000 + (m.urutan % 5) * 3000)::numeric as harga_rata
  from m cross join hari h
),
hitung as (
  select merchant_id,
         tanggal,
         dow,
         weather_code,
         harga_rata,
         -- akhir pekan +25%, hujan (weather_code 3) -15%, 17 Agustus +40%
         greatest(1, round(
           basis
           * (1 + derau_persen / 100)
           * (case when dow in (5, 6) then 1.25 else 1.0 end)
           * (case when weather_code = 3 then 0.85 else 1.0 end)
           * (case when to_char(tanggal, 'MM-DD') = '08-17' then 1.40 else 1.0 end)
         ))::int as portions_sold,
         (to_char(tanggal, 'MM-DD') = '08-17') as is_holiday
  from mentah
)
insert into public.sales_history
  (merchant_id, date, portions_sold, revenue, day_of_week, is_holiday, weather_code, surplus_kg)
select merchant_id,
       tanggal,
       portions_sold,
       portions_sold * harga_rata,
       dow,
       is_holiday,
       weather_code,
       round((portions_sold * 0.02)::numeric, 2)
from hitung
on conflict (merchant_id, date) do nothing;

-- ── 5. Listing live ───────────────────────────────────────────────────────
-- 12 listing dari merchant selain Verde Kitchen, diskon 40-68%,
-- harga sudah dibulatkan ke Rp500 terdekat sesuai aturan bisnis 6.2.
-- Semuanya physical_validated = true dan triage_score >= 70; kalau tidak,
-- trigger gerbang keamanan pangan akan menolaknya — dan itu memang benar.
insert into public.listings
  (merchant_id, name, description, category, qty_total, qty_remaining,
   original_price, price, cooked_at, expires_at, triage_score, triage_reason,
   physical_validated, physical_validated_at, status)
select p.id, d.name, d.description, d.category, d.qty, d.qty,
       d.original_price, d.price,
       now() - interval '2 hours',
       now() - interval '2 hours' + (d.shelf_life_jam || ' hours')::interval,
       d.triage_score, d.triage_reason,
       true, now() - interval '1 hour', 'live'
from (values
  ('merchant03@lestar.id', 'Roti Sobek Cokelat',    'Panggangan pagi, tekstur masih lembut',      'roti',      8, 25000, 10000, 24, 88, 'Dipanggang 2 jam lalu, kategori roti tahan 24 jam. Kemasan tertutup.'),
  ('merchant05@lestar.id', 'Kopi Susu Gula Aren',   'Botol 250 ml, disimpan dingin',              'minuman',  12, 22000,  8500, 12, 82, 'Rantai dingin terjaga sejak diseduh.'),
  ('merchant02@lestar.id', 'Nasi Pecel Komplit',    'Nasi, sayur rebus, bumbu kacang, rempeyek',  'nasi_lauk', 6, 18000,  8000,  8, 76, 'Dimasak 2 jam lalu, bumbu terpisah dari sayur.'),
  ('merchant07@lestar.id', 'Roti Bakar Keju',       'Isi keju dan susu kental manis',             'roti',     10, 20000,  9000, 24, 90, 'Baru dipanggang, suhu ruangan stabil.'),
  ('merchant11@lestar.id', 'Bakso Urat Porsi Besar','Kuah terpisah, isi 8 butir',                 'nasi_lauk', 5, 30000, 15000,  8, 79, 'Kuah dipanaskan ulang dan dipisah dari isian.'),
  ('merchant12@lestar.id', 'Bolu Pandan Potong',    'Potongan bolu pandan, kotak isi 2',          'kue',      14, 12000,  5000, 72, 92, 'Kue kering berumur simpan panjang, kemasan rapat.'),
  ('merchant16@lestar.id', 'Martabak Manis Cokelat','Loyang penuh, potong 8',                     'kue',       4, 45000, 18000, 72, 85, 'Baru matang, belum pernah dibuka.'),
  ('merchant21@lestar.id', 'Soto Ayam Lamongan',    'Kuah bening, koya terpisah',                 'nasi_lauk', 7, 20000,  9500,  8, 74, 'Kuah masih di atas suhu aman, koya dikemas terpisah.'),
  ('merchant24@lestar.id', 'Donat Kentang Gula',    'Donat kentang taburan gula halus',           'kue',      16, 15000,  5500, 72, 87, 'Adonan kentang, tidak berisi krim, aman disimpan.'),
  ('merchant29@lestar.id', 'Gorengan Campur',       'Tempe, tahu, bakwan, pisang',                'gorengan', 20, 10000,  4000,  6, 72, 'Digoreng 2 jam lalu, minyak sekali pakai.'),
  ('merchant19@lestar.id', 'Croissant Butter',      'Croissant mentega, panggangan sore',         'roti',      6, 28000, 11000, 24, 91, 'Dipanggang sore ini, disimpan di rak tertutup.'),
  ('merchant27@lestar.id', 'Cold Brew Botol',       'Botol 500 ml, tanpa gula',                   'minuman',   9, 25000, 10000, 12, 80, 'Disimpan pada 4 derajat sejak diseduh.')
) as d(email, name, description, category, qty, original_price, price,
       shelf_life_jam, triage_score, triage_reason)
join public.profiles p on p.email = d.email;

-- ── 6. Dua waste_batch available — total tepat 16,6 kg ────────────────────
-- 9,2 + 7,4 = 16,6. Saat demo, kaskade Verde Kitchen menambah 8,4 kg
-- sehingga radar Pak Budi menampilkan 25 KG persis seperti mockup.
-- Keduanya dari merchant dalam radius 2 km dari basis Pak Budi.
-- source_listing_id sengaja NULL: ini limbah dapur langsung, bukan kaskade.
insert into public.waste_batches
  (source_merchant_id, source_listing_id, waste_type, description, weight_kg,
   price, pickup_address, lat, lng, pickup_window_start, pickup_window_end, status)
select m.id, null, 'wet', d.description, d.weight_kg, 0,
       m.store_address, m.lat, m.lng,
       now() - interval '30 minutes', now() + interval '6 hours', 'available'
from (values
  ('merchant06@lestar.id', 'Sisa sayur rebus dan nasi dapur siang', 9.2),
  ('merchant11@lestar.id', 'Sisa kuah, tulang, dan sayuran',        7.4)
) as d(email, description, weight_kg)
join public.profiles p on p.email = d.email
join public.merchants m on m.id = p.id;

commit;

-- ── 7. Riwayat ESG ────────────────────────────────────────────────────────
-- 40 baris esg_events: 24 dari jalur B2C, 16 dari jalur B2B.
--
-- Baris esg_events TIDAK disisipkan langsung. Yang disisipkan adalah order
-- dan waste_batch sungguhan, lalu statusnya dinaikkan ke 'claimed'/'completed'
-- sehingga trigger write_esg_event yang menulis buku besarnya. Konsekuensinya
-- setiap angka di laporan ESG bisa ditelusuri ke order atau batch yang nyata --
-- bukan angka riwayat yang menggantung tanpa asal (aturan PRD 6.5).
-- Sekaligus ini menguji kedua trigger sebelum hari demo.

do $seed$
declare
  r          record;
  v_listing  uuid;
  v_order    uuid;
  v_merchant uuid;
  v_consumer uuid;
  v_partner  uuid;
  v_subtotal numeric;
begin
  -- 24 order lampau yang berakhir 'claimed'
  for r in
    select i,
           case when i <= 16 then 'merchant@lestar.id'
                when i % 3 = 0 then 'merchant03@lestar.id'
                when i % 3 = 1 then 'merchant12@lestar.id'
                else 'merchant05@lestar.id' end as merchant_email,
           (array['amira@lestar.id','konsumen02@lestar.id','konsumen03@lestar.id',
                  'konsumen04@lestar.id','konsumen05@lestar.id'])[1 + (i % 5)] as consumer_email,
           (array['roti','kue','nasi_lauk'])[1 + (i % 3)] as kategori,
           (array['Croissant Butter','Bolu Pandan Potong','Nasi Ayam Bakar'])[1 + (i % 3)] as nama,
           2 + (i % 4) as qty,
           (8000 + (i % 4) * 2500)::numeric as unit_price,
           now() - ((i + 1) || ' days')::interval as waktu
      from generate_series(1, 24) as i
  loop
    select id into v_merchant from public.profiles where email = r.merchant_email;
    select id into v_consumer from public.profiles where email = r.consumer_email;
    v_subtotal := r.qty * r.unit_price;

    insert into public.listings
      (merchant_id, name, description, category, qty_total, qty_remaining,
       original_price, price, cooked_at, expires_at, triage_score, triage_reason,
       physical_validated, physical_validated_at, status, created_at)
    values
      (v_merchant, r.nama, 'Surplus sore', r.kategori, r.qty, r.qty,
       r.unit_price * 2.5, r.unit_price,
       r.waktu - interval '3 hours', r.waktu + interval '6 hours',
       78 + (r.i % 15), 'Riwayat penjualan surplus',
       true, r.waktu - interval '2 hours', 'live', r.waktu - interval '3 hours')
    returning id into v_listing;

    insert into public.orders
      (consumer_id, merchant_id, subtotal, green_fee, total, status,
       qr_token, qr_expires_at, payment_method, ordered_at, paid_at)
    values
      (v_consumer, v_merchant, v_subtotal, 1000, v_subtotal + 1000, 'paid',
       gen_random_uuid()::text, r.waktu + interval '2 hours', 'simulasi',
       r.waktu, r.waktu + interval '5 minutes')
    returning id into v_order;

    insert into public.order_items (order_id, listing_id, name_snapshot, qty, unit_price)
    values (v_order, v_listing, r.nama, r.qty, r.unit_price);

    -- Perubahan status inilah yang memicu sync_qty_remaining dan write_esg_event.
    update public.orders
       set status = 'claimed', claimed_at = r.waktu + interval '40 minutes'
     where id = v_order;
  end loop;

  -- 16 batch limbah lampau yang berakhir 'completed'
  select id into v_partner from public.profiles where email = 'budi@lestar.id';

  for r in
    select i,
           case when i <= 8 then 'merchant@lestar.id'
                when i % 2 = 0 then 'merchant06@lestar.id'
                else 'merchant11@lestar.id' end as merchant_email,
           round((4 + (i % 9) + (i % 3) * 0.4)::numeric, 2) as berat,
           now() - ((i + 1) || ' days')::interval as waktu
      from generate_series(1, 16) as i
  loop
    select id into v_merchant from public.profiles where email = r.merchant_email;

    insert into public.waste_batches
      (source_merchant_id, source_listing_id, waste_type, description, weight_kg,
       price, pickup_address, lat, lng, pickup_window_start, pickup_window_end,
       status, matched_partner_id, created_at)
    select v_merchant, null, 'wet', 'Sisa dapur harian', r.berat, 0,
           m.store_address, m.lat, m.lng,
           r.waktu, r.waktu + interval '4 hours', 'matched', v_partner, r.waktu
      from public.merchants m where m.id = v_merchant
    returning id into v_listing;

    update public.waste_batches
       set status = 'completed', completed_at = r.waktu + interval '2 hours'
     where id = v_listing;
  end loop;
end $seed$;
