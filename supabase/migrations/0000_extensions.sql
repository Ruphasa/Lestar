-- 0000_extensions.sql
-- Ekstensi dasar Lestar.
-- Urutan penting: cube WAJIB terpasang sebelum earthdistance,
-- karena earthdistance dibangun di atas tipe cube. Terbalik = gagal.
--
-- Semua ekstensi dipasang di schema `extensions` (konvensi Supabase),
-- bukan `public`, supaya tidak memunculkan peringatan security advisor
-- "extension_in_public". Konsekuensinya: setiap pemanggilan fungsi geo
-- harus di-qualify (extensions.ll_to_earth, OPERATOR(extensions.@>)).

create extension if not exists cube          with schema extensions;
create extension if not exists earthdistance with schema extensions;

-- pg_net dipakai pg_cron untuk memanggil Edge Function auto_cascade lewat HTTP.
create extension if not exists pg_net with schema extensions;

-- pg_cron selalu membuat schema `cron` sendiri; tidak bisa dipindah.
create extension if not exists pg_cron;
