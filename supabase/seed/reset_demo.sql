-- reset_demo.sql — kembalikan database ke kondisi awal demo.
--
-- Dipakai di antara gladi bersih dan sebelum tampil. Jalankan lewat SQL Editor
-- Supabase atau MCP. Perlu hak service_role / postgres (menembus RLS).
--
-- Aturan pemisah: seluruh data seed berumur MINIMAL 2 hari (riwayat order,
-- riwayat batch, riwayat ESG semuanya ditulis mundur ke belakang). Apa pun
-- yang lebih baru dari 36 jam berarti sisa gladi bersih atau demo sebelumnya.
-- Jadi tidak perlu tabel penanda, tidak perlu tanggal yang diketik manual,
-- dan gladi bersih Selasa malam ikut tersapu saat reset Rabu pagi.
--
-- Dua pengecualian yang sengaja TIDAK ikut terhapus meski baru:
--   * 12 listing live milik merchant selain Verde Kitchen
--   * 2 waste_batch 9,2 kg dan 7,4 kg yang membentuk angka 16,6 kg
-- Keduanya bagian dari panggung, bukan hasil demo. Statusnya dipulihkan,
-- bukan dihapus.

begin;

-- 1. Buku besar ESG: buang baris yang lahir saat demo/gladi.
delete from public.esg_events
 where occurred_at > now() - interval '36 hours';

-- 2. Order demo Verde Kitchen. order_items ikut terhapus lewat cascade.
delete from public.orders o
 using public.profiles p
 where p.id = o.merchant_id
   and p.email = 'merchant@lestar.id'
   and o.ordered_at > now() - interval '36 hours';

-- 3. Batch limbah hasil kaskade Verde Kitchen. Dihapus sebelum listing-nya,
--    supaya jejak source_listing_id ikut hilang, bukan jadi null menggantung.
delete from public.waste_batches w
 using public.profiles p
 where p.id = w.source_merchant_id
   and p.email = 'merchant@lestar.id'
   and w.created_at > now() - interval '36 hours';

-- 4. Listing yang dibuat Verde Kitchen di depan juri.
delete from public.listings l
 using public.profiles p
 where p.id = l.merchant_id
   and p.email = 'merchant@lestar.id'
   and l.created_at > now() - interval '36 hours';

-- 5. Pulihkan dua batch panggung kalau sempat diambil pengepul saat gladi.
update public.waste_batches w
   set status = 'available',
       matched_partner_id = null,
       completed_at = null,
       pickup_window_start = now() - interval '30 minutes',
       pickup_window_end = now() + interval '6 hours'
  from public.profiles p
 where p.id = w.source_merchant_id
   and p.email in ('merchant06@lestar.id', 'merchant11@lestar.id')
   and w.description in ('Sisa sayur rebus dan nasi dapur siang',
                         'Sisa kuah, tulang, dan sayuran')
   and w.status <> 'available';

-- 6. Pulihkan 12 listing panggung: stok penuh, status live, jam belum lewat.
update public.listings l
   set qty_remaining = l.qty_total,
       status = 'live',
       cooked_at = now() - interval '2 hours',
       expires_at = now() - interval '2 hours'
                    + (case l.category
                         when 'gorengan'  then interval '6 hours'
                         when 'nasi_lauk' then interval '8 hours'
                         when 'roti'      then interval '24 hours'
                         when 'kue'       then interval '72 hours'
                         when 'minuman'   then interval '12 hours'
                         else interval '8 hours' end)
 where l.name in ('Roti Sobek Cokelat','Kopi Susu Gula Aren','Nasi Pecel Komplit',
                  'Roti Bakar Keju','Bakso Urat Porsi Besar','Bolu Pandan Potong',
                  'Martabak Manis Cokelat','Soto Ayam Lamongan','Donat Kentang Gula',
                  'Gorengan Campur','Croissant Butter','Cold Brew Botol')
   and l.description <> 'Surplus sore'          -- jangan sentuh riwayat penjualan
   and l.physical_validated = true;

-- 7. Jam cutoff Verde Kitchen kembali ke 22:00, kalau sempat diubah saat uji.
update public.merchants m
   set cutoff_time = '22:00'
  from public.profiles p
 where p.id = m.id and p.email = 'merchant@lestar.id' and m.cutoff_time <> '22:00';

commit;

-- Verifikasi cepat. Harus: listing_live 12, radar_kg 16.6, listing_verde_aktif 0.
select (select count(*) from public.listings where status = 'live') as listing_live,
       (select sum(weight_kg) from public.waste_batches where status = 'available') as radar_kg,
       (select count(*) from public.listings l join public.profiles p on p.id = l.merchant_id
         where p.email = 'merchant@lestar.id' and l.status = 'live') as listing_verde_aktif,
       (select count(*) from public.esg_events) as esg_events;
