-- 0010_cron.sql
-- Auto-cascade: listing 'live' yang lewat jam cutoff dengan sisa stok turun
-- ke jalur B2B sebagai waste_batch.
--
-- Keputusan Agent A: seluruh logika kaskade tinggal di SATU fungsi SQL,
-- public.run_auto_cascade(). Edge Function auto_cascade hanya membungkusnya
-- lewat HTTP. Akibatnya:
--   * pemicu cron dan pemicu manual menjalankan kode yang benar-benar sama,
--     bukan dua salinan yang bisa menyimpang;
--   * cron memanggil fungsi ini langsung di dalam database, jadi tidak perlu
--     menaruh service role key di dalam SQL job dan tidak perlu pg_net.
--     Supabase Vault jadi tidak diperlukan sama sekali untuk jalur ini.
--
-- Dua parameter, keduanya untuk demo, bukan untuk mengubah aturan bisnis:
--   p_force        cron memakai false (jam cutoff nyata yang menentukan).
--                  Tombol demo memakai true — docs/05-demo-script.md menit 4:30
--                  memang meminta "lewati jam cutoff (pakai pemicu manual)".
--   p_merchant_id  membatasi kaskade ke satu merchant. Saat demo hanya
--                  Verde Kitchen yang boleh turun; listing merchant lain harus
--                  tetap live supaya radar konsumen tidak ikut kosong.
-- Seleksi baris, konversi berat, dan isi waste_batch identik pada kedua jalur.

create or replace function public.run_auto_cascade(
  p_force       boolean default false,
  p_merchant_id uuid    default null
)
returns json
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_hasil json;
begin
  with due as (
    select l.id, l.merchant_id, l.name, l.category, l.qty_remaining,
           m.lat, m.lng, m.store_address
      from public.listings l
      join public.merchants m on m.id = l.merchant_id
     where l.status = 'live'
       and l.qty_remaining > 0
       and (p_merchant_id is null or l.merchant_id = p_merchant_id)
       and (p_force
            or (now() at time zone 'Asia/Jakarta')::time > m.cutoff_time)
  ),
  dicascade as (
    update public.listings l
       set status = 'cascaded'
      from due d
     where l.id = d.id
    returning l.id
  ),
  batch_baru as (
    insert into public.waste_batches (
      source_merchant_id, source_listing_id, waste_type, description,
      weight_kg, pickup_address, lat, lng,
      pickup_window_start, pickup_window_end, status)
    select d.merchant_id,
           d.id,
           'wet',
           d.name || ' ' || d.qty_remaining || ' porsi, tidak terklaim sampai jam cutoff',
           round(d.qty_remaining * public.berat_porsi_kg(d.category), 2),
           d.store_address,
           d.lat,
           d.lng,
           now(),
           now() + interval '4 hours',
           'available'
      from due d
    returning weight_kg
  )
  select json_build_object(
           'cascaded',              (select count(*) from dicascade),
           'waste_batches_created', (select count(*) from batch_baru),
           'total_kg',              coalesce((select sum(weight_kg) from batch_baru), 0)
         )
    into v_hasil;

  return v_hasil;
end $fn$;

comment on function public.run_auto_cascade(boolean, uuid) is
  'Kaskade B2C -> B2B. Dipanggil cron tiap 5 menit dan Edge Function auto_cascade.';

-- Fungsi ini security definer dan menulis lintas merchant: hanya boleh dipanggil
-- dari dalam database (cron) dan dari Edge Function yang memakai service role.
revoke execute on function public.run_auto_cascade(boolean, uuid) from public, anon, authenticated;

-- Cron tiap 5 menit, memanggil fungsi di atas langsung — tanpa HTTP, tanpa kunci.
select cron.schedule(
  'lestar-auto-cascade',
  '*/5 * * * *',
  $cron$ select public.run_auto_cascade(false, null) $cron$
);

-- ...tapi dimatikan sejak awal. Ini disengaja.
--
-- Terbukti saat pengujian: begitu jam melewati cutoff merchant, cron memakan
-- listing panggung. Dalam satu putaran, 6 dari 12 listing seed berubah
-- 'cascaded' dan radar konsumen ikut kosong — persis kondisi yang tidak boleh
-- terjadi di pagi hari demo. Kaskade yang dipakai di depan juri adalah pemicu
-- manual (docs/05-demo-script.md menit 4:30), jadi cron tidak menambah apa pun
-- selain risiko data panggung berubah tanpa ada yang menekan tombol.
--
-- Job-nya tetap terdaftar supaya tinggal dinyalakan di luar masa demo:
--   select cron.alter_job((select jobid from cron.job
--                           where jobname = 'lestar-auto-cascade'), active := true);
select cron.alter_job(
  (select jobid from cron.job where jobname = 'lestar-auto-cascade'),
  active := false
);
