-- 0008_realtime.sql
-- Realtime hanya pada tiga tabel penggerak layar:
--   listings      -> kartu flash sale baru muncul di radar konsumen
--   waste_batches -> radar pengepul menyala
--   orders        -> merchant lihat pesanan masuk / terklaim
-- Tabel lain tidak perlu realtime; menambahkannya cuma menambah lalu lintas WAL.
--
-- replica identity full dipasang supaya payload event UPDATE ikut membawa
-- nilai kolom LAMA. Tanpa itu klien menerima 'old' hanya berisi primary key,
-- dan Flutter tidak bisa membedakan available -> matched dari perubahan lain.

alter table public.listings      replica identity full;
alter table public.waste_batches replica identity full;
alter table public.orders        replica identity full;

alter publication supabase_realtime add table public.listings;
alter publication supabase_realtime add table public.waste_batches;
alter publication supabase_realtime add table public.orders;
