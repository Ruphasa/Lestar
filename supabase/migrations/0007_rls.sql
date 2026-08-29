-- 0007_rls.sql
-- RLS aktif di SELURUH 13 tabel. Tidak ada satu tabel pun tanpa policy.
--
-- Dua kebiasaan yang dipakai konsisten di berkas ini:
--   1. auth.uid() selalu dibungkus (select auth.uid()) - dievaluasi sekali,
--      bukan sekali per baris. Bedanya besar di sales_history (2700 baris).
--   2. Semua policy dibatasi `to authenticated`. Role anon tidak punya policy
--      sama sekali, jadi APK yang belum login tidak bisa membaca apa pun.
--
-- Keputusan Agent A: tidak ada fungsi bantu pembaca role (mis. is_partner()).
-- Kepemilikan baris sudah cukup dinyatakan lewat perbandingan id langsung,
-- karena merchants.id dan partners.id = profiles.id = auth.uid().

alter table public.profiles              enable row level security;
alter table public.merchants             enable row level security;
alter table public.partners              enable row level security;
alter table public.listings              enable row level security;
alter table public.orders                enable row level security;
alter table public.order_items           enable row level security;
alter table public.waste_batches         enable row level security;
alter table public.partner_subscriptions enable row level security;
alter table public.sales_history         enable row level security;
alter table public.forecasts             enable row level security;
alter table public.esg_events            enable row level security;
alter table public.esg_reports           enable row level security;
alter table public.notifications         enable row level security;

-- profiles ------------------------------------------------------------------
-- Semua yang login boleh melihat profil orang lain: konsumen perlu nama toko,
-- pengepul perlu nama merchant di kartu jemput.
create policy "profil terlihat semua yang login" on public.profiles
  for select to authenticated using (true);

create policy "ubah profil sendiri" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Baris profil normalnya dibuat trigger on_auth_user_created (security definer).
-- Policy insert ini hanya jalur cadangan kalau baris itu hilang.
create policy "buat profil sendiri" on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()));

-- merchants -----------------------------------------------------------------
create policy "toko terlihat semua yang login" on public.merchants
  for select to authenticated using (true);

create policy "merchant buat tokonya sendiri" on public.merchants
  for insert to authenticated with check (id = (select auth.uid()));

create policy "merchant ubah tokonya sendiri" on public.merchants
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- partners ------------------------------------------------------------------
create policy "pengepul terlihat semua yang login" on public.partners
  for select to authenticated using (true);

create policy "pengepul buat profil sendiri" on public.partners
  for insert to authenticated with check (id = (select auth.uid()));

create policy "pengepul ubah profil sendiri" on public.partners
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- listings ------------------------------------------------------------------
-- Gerbang 3: merchant A tidak boleh melihat draft merchant B.
-- Baris draft hanya lolos lewat cabang kedua (merchant_id = auth.uid()).
create policy "listing live terlihat semua" on public.listings
  for select to authenticated
  using (status = 'live' or merchant_id = (select auth.uid()));

create policy "merchant buat listing sendiri" on public.listings
  for insert to authenticated
  with check (merchant_id = (select auth.uid()));

create policy "merchant ubah listing sendiri" on public.listings
  for update to authenticated
  using (merchant_id = (select auth.uid()))
  with check (merchant_id = (select auth.uid()));

create policy "merchant hapus listing sendiri" on public.listings
  for delete to authenticated
  using (merchant_id = (select auth.uid()));

-- orders --------------------------------------------------------------------
create policy "order terlihat pembeli dan penjualnya" on public.orders
  for select to authenticated
  using (consumer_id = (select auth.uid()) or merchant_id = (select auth.uid()));

create policy "konsumen buat order sendiri" on public.orders
  for insert to authenticated
  with check (consumer_id = (select auth.uid()));

-- Konsumen mengubah pending -> paid; merchant mengubah paid -> ready -> claimed.
create policy "pembeli dan penjual ubah status order" on public.orders
  for update to authenticated
  using (consumer_id = (select auth.uid()) or merchant_id = (select auth.uid()))
  with check (consumer_id = (select auth.uid()) or merchant_id = (select auth.uid()));

-- order_items ---------------------------------------------------------------
-- Ikut kebijakan orders induknya lewat EXISTS ke baris order yang sudah tersaring RLS.
create policy "item ikut kebijakan ordernya" on public.order_items
  for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id));

create policy "konsumen isi item ordernya sendiri" on public.order_items
  for insert to authenticated
  with check (exists (
    select 1 from public.orders o
     where o.id = order_id and o.consumer_id = (select auth.uid())));

create policy "konsumen ubah item ordernya sendiri" on public.order_items
  for update to authenticated
  using (exists (
    select 1 from public.orders o
     where o.id = order_id and o.consumer_id = (select auth.uid())))
  with check (exists (
    select 1 from public.orders o
     where o.id = order_id and o.consumer_id = (select auth.uid())));

create policy "konsumen hapus item ordernya sendiri" on public.order_items
  for delete to authenticated
  using (exists (
    select 1 from public.orders o
     where o.id = order_id and o.consumer_id = (select auth.uid())));

-- waste_batches -------------------------------------------------------------
-- Batch 'available' terlihat semua yang login (radar pengepul); batch selain itu
-- hanya oleh merchant sumbernya dan pengepul yang sudah mengambilnya.
create policy "limbah tersedia terlihat, sisanya pemilik saja" on public.waste_batches
  for select to authenticated
  using (
    status = 'available'
    or source_merchant_id = (select auth.uid())
    or matched_partner_id = (select auth.uid())
  );

create policy "merchant buat batch limbah sendiri" on public.waste_batches
  for insert to authenticated
  with check (source_merchant_id = (select auth.uid()));

-- Pengepul boleh menekan JEMPUT pada batch yang masih 'available',
-- lalu meneruskan matched -> picked_up -> completed pada batch miliknya.
create policy "merchant dan pengepul ubah status batch" on public.waste_batches
  for update to authenticated
  using (
    source_merchant_id = (select auth.uid())
    or matched_partner_id = (select auth.uid())
    or (status = 'available'
        and exists (select 1 from public.partners p where p.id = (select auth.uid())))
  )
  with check (
    source_merchant_id = (select auth.uid())
    or matched_partner_id = (select auth.uid())
  );

create policy "merchant hapus batch sendiri" on public.waste_batches
  for delete to authenticated
  using (source_merchant_id = (select auth.uid()));

-- partner_subscriptions -----------------------------------------------------
create policy "langganan milik pengepulnya" on public.partner_subscriptions
  for select to authenticated using (partner_id = (select auth.uid()));

create policy "pengepul buat langganan sendiri" on public.partner_subscriptions
  for insert to authenticated with check (partner_id = (select auth.uid()));

create policy "pengepul ubah langganan sendiri" on public.partner_subscriptions
  for update to authenticated
  using (partner_id = (select auth.uid()))
  with check (partner_id = (select auth.uid()));

-- sales_history, forecasts, esg_events, esg_reports --------------------------
-- Ditulis aplikasi memakai anon key (FastAPI sengaja tidak menyentuh database,
-- lihat docs/01-architecture.md 1), jadi policy insert-nya merchant_id = auth.uid(),
-- bukan dibatasi service_role.
create policy "riwayat penjualan milik merchantnya" on public.sales_history
  for select to authenticated using (merchant_id = (select auth.uid()));

create policy "merchant tulis riwayat penjualannya" on public.sales_history
  for insert to authenticated with check (merchant_id = (select auth.uid()));

create policy "merchant ubah riwayat penjualannya" on public.sales_history
  for update to authenticated
  using (merchant_id = (select auth.uid()))
  with check (merchant_id = (select auth.uid()));

create policy "forecast milik merchantnya" on public.forecasts
  for select to authenticated using (merchant_id = (select auth.uid()));

create policy "merchant tulis forecastnya" on public.forecasts
  for insert to authenticated with check (merchant_id = (select auth.uid()));

create policy "merchant ubah forecastnya" on public.forecasts
  for update to authenticated
  using (merchant_id = (select auth.uid()))
  with check (merchant_id = (select auth.uid()));

-- esg_events adalah buku besar: boleh dibaca dan ditulis, tidak boleh diubah/dihapus.
create policy "esg event milik merchantnya" on public.esg_events
  for select to authenticated using (merchant_id = (select auth.uid()));

create policy "merchant tulis esg eventnya" on public.esg_events
  for insert to authenticated with check (merchant_id = (select auth.uid()));

create policy "laporan esg milik merchantnya" on public.esg_reports
  for select to authenticated using (merchant_id = (select auth.uid()));

create policy "merchant tulis laporan esgnya" on public.esg_reports
  for insert to authenticated with check (merchant_id = (select auth.uid()));

create policy "merchant ubah laporan esgnya" on public.esg_reports
  for update to authenticated
  using (merchant_id = (select auth.uid()))
  with check (merchant_id = (select auth.uid()));

-- notifications -------------------------------------------------------------
create policy "notifikasi milik penerimanya" on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));

create policy "notifikasi ditandai dibaca oleh penerimanya" on public.notifications
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "notifikasi ditulis untuk diri sendiri" on public.notifications
  for insert to authenticated with check (user_id = (select auth.uid()));
