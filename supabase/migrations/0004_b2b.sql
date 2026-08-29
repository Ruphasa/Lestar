-- 0004_b2b.sql
-- Jalur B2B: waste_batches + partner_subscriptions.
-- source_listing_id adalah kolom paling penting di seluruh schema untuk demo:
-- kalau terisi, batch ini lahir dari makanan yang gagal terjual di B2C.

create table public.waste_batches (
  id                  uuid primary key default gen_random_uuid(),
  source_merchant_id  uuid not null references public.merchants (id) on delete cascade,
  source_listing_id   uuid references public.listings (id) on delete set null,
  waste_type          public.waste_type not null,
  description         text,
  weight_kg           numeric not null check (weight_kg > 0),
  price               numeric not null default 0,
  pickup_address      text not null,
  lat                 double precision not null,
  lng                 double precision not null,
  pickup_window_start timestamptz,
  pickup_window_end   timestamptz,
  image_url           text,
  status              public.waste_status not null default 'available',
  matched_partner_id  uuid references public.partners (id) on delete set null,
  created_at          timestamptz not null default now(),
  completed_at        timestamptz
);

comment on column public.waste_batches.source_listing_id is
  'Bukti kaskade. Terisi = batch ini lahir dari listing B2C yang tidak terklaim.';

create index idx_waste_available on public.waste_batches (status, created_at desc)
  where status = 'available';
create index idx_waste_merchant on public.waste_batches (source_merchant_id, created_at desc);
create index idx_waste_partner on public.waste_batches (matched_partner_id)
  where matched_partner_id is not null;
create index idx_waste_source_listing on public.waste_batches (source_listing_id);

-- Index GiST untuk nearby_waste(). Partial: radar pengepul hanya menanyakan yang 'available'.
create index idx_waste_geo on public.waste_batches
  using gist (extensions.ll_to_earth(lat, lng)) where status = 'available';

create table public.partner_subscriptions (
  id         uuid primary key default gen_random_uuid(),
  partner_id uuid not null references public.partners (id) on delete cascade,
  plan       text not null,
  price      numeric not null default 0,
  starts_at  timestamptz not null default now(),
  expires_at timestamptz,
  status     text not null default 'active',
  paid_at    timestamptz
);

create index idx_partner_subs_partner on public.partner_subscriptions (partner_id, starts_at desc);

-- ── Dua RPC geo ───────────────────────────────────────────────────────────
-- Dipanggil Flutter lewat supabase.rpc(). Jarak dihitung di Postgres pakai
-- earthdistance, bukan haversine manual di Dart: earth_box menyaring kasar
-- lewat index GiST, earth_distance menyaring halus. Klien cukup terima jarak_km
-- yang sudah terurut menaik.
--
-- Keduanya SECURITY INVOKER (default) — RLS tetap berlaku, jadi fungsi ini
-- tidak bisa dipakai untuk mengintip baris yang tidak boleh dilihat pemanggil.
-- search_path dikosongkan, semua objek di-qualify, termasuk operator cube @>.

-- Radar pengepul (Agent F).
create or replace function public.nearby_waste(
  p_lat       double precision,
  p_lng       double precision,
  p_radius_km double precision default 10
)
returns table (
  id                  uuid,
  source_merchant_id  uuid,
  store_name          text,
  source_listing_id   uuid,
  waste_type          public.waste_type,
  description         text,
  weight_kg           numeric,
  price               numeric,
  pickup_address      text,
  lat                 double precision,
  lng                 double precision,
  pickup_window_start timestamptz,
  pickup_window_end   timestamptz,
  image_url           text,
  status              public.waste_status,
  created_at          timestamptz,
  jarak_km            double precision
)
language sql
stable
set search_path = ''
as $fn$
  select w.id,
         w.source_merchant_id,
         m.store_name,
         w.source_listing_id,
         w.waste_type,
         w.description,
         w.weight_kg,
         w.price,
         w.pickup_address,
         w.lat,
         w.lng,
         w.pickup_window_start,
         w.pickup_window_end,
         w.image_url,
         w.status,
         w.created_at,
         extensions.earth_distance(
           extensions.ll_to_earth(w.lat, w.lng),
           extensions.ll_to_earth(p_lat, p_lng)) / 1000 as jarak_km
    from public.waste_batches w
    join public.merchants m on m.id = w.source_merchant_id
   where w.status = 'available'
     and extensions.earth_box(extensions.ll_to_earth(p_lat, p_lng), p_radius_km * 1000)
         operator(extensions.@>) extensions.ll_to_earth(w.lat, w.lng)
     and extensions.earth_distance(
           extensions.ll_to_earth(w.lat, w.lng),
           extensions.ll_to_earth(p_lat, p_lng)) <= p_radius_km * 1000
   order by jarak_km;
$fn$;

comment on function public.nearby_waste(double precision, double precision, double precision) is
  'Radar pengepul. Batch limbah status available dalam radius, terurut jarak_km menaik.';

-- Radar konsumen (Agent E). Hanya listing status live.
create or replace function public.nearby_listings(
  p_lat       double precision,
  p_lng       double precision,
  p_radius_km double precision default 5
)
returns table (
  id             uuid,
  merchant_id    uuid,
  store_name     text,
  store_address  text,
  store_image    text,
  name           text,
  description    text,
  category       text,
  image_url      text,
  qty_remaining  int,
  original_price numeric,
  price          numeric,
  cooked_at      timestamptz,
  expires_at     timestamptz,
  triage_score   smallint,
  triage_reason  text,
  lat            double precision,
  lng            double precision,
  jarak_km       double precision
)
language sql
stable
set search_path = ''
as $fn$
  select l.id,
         l.merchant_id,
         m.store_name,
         m.store_address,
         m.store_image,
         l.name,
         l.description,
         l.category,
         l.image_url,
         l.qty_remaining,
         l.original_price,
         l.price,
         l.cooked_at,
         l.expires_at,
         l.triage_score,
         l.triage_reason,
         m.lat,
         m.lng,
         extensions.earth_distance(
           extensions.ll_to_earth(m.lat, m.lng),
           extensions.ll_to_earth(p_lat, p_lng)) / 1000 as jarak_km
    from public.listings l
    join public.merchants m on m.id = l.merchant_id
   where l.status = 'live'
     and l.qty_remaining > 0
     and l.expires_at > now()
     and extensions.earth_box(extensions.ll_to_earth(p_lat, p_lng), p_radius_km * 1000)
         operator(extensions.@>) extensions.ll_to_earth(m.lat, m.lng)
     and extensions.earth_distance(
           extensions.ll_to_earth(m.lat, m.lng),
           extensions.ll_to_earth(p_lat, p_lng)) <= p_radius_km * 1000
   order by jarak_km;
$fn$;

comment on function public.nearby_listings(double precision, double precision, double precision) is
  'Radar konsumen. Listing status live yang masih ada stok dan belum kedaluwarsa, terurut jarak_km menaik.';

-- Hanya pengguna yang sudah login yang boleh memanggil radar.
revoke execute on function public.nearby_waste(double precision, double precision, double precision) from public, anon;
revoke execute on function public.nearby_listings(double precision, double precision, double precision) from public, anon;
grant execute on function public.nearby_waste(double precision, double precision, double precision) to authenticated;
grant execute on function public.nearby_listings(double precision, double precision, double precision) to authenticated;
