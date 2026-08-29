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
