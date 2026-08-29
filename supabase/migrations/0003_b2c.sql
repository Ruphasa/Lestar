-- 0003_b2c.sql
-- Jalur B2C: listings, orders, order_items.
-- Berisi gerbang keamanan pangan — klaim utama produk, ditegakkan di database.

create table public.listings (
  id                    uuid primary key default gen_random_uuid(),
  merchant_id           uuid not null references public.merchants (id) on delete cascade,
  name                  text not null,
  description           text,
  -- category menentukan shelf_life dan berat porsi (docs/02-data-model.md §10)
  category              text not null,
  image_url             text,
  qty_total             int  not null check (qty_total > 0),
  qty_remaining         int  not null check (qty_remaining >= 0),
  original_price        numeric not null check (original_price >= 0),
  price                 numeric not null check (price >= 0),
  cooked_at             timestamptz not null,
  expires_at            timestamptz not null,
  triage_score          smallint check (triage_score between 0 and 100),
  triage_reason         text,
  physical_validated    boolean not null default false,
  physical_validated_at timestamptz,
  status                public.listing_status not null default 'draft',
  created_at            timestamptz not null default now(),
  constraint listings_qty_sisa_wajar check (qty_remaining <= qty_total)
);

-- Partial index: radar konsumen hanya pernah menanyakan listing 'live'.
create index idx_listings_live on public.listings (status, expires_at) where status = 'live';
create index idx_listings_merchant on public.listings (merchant_id, created_at desc);

-- ── GERBANG VALIDASI FISIK ────────────────────────────────────────────────
-- Aturan keamanan pangan tidak boleh hanya hidup di kode Flutter.
-- Kalau ada agent yang keliru menulis status='live' langsung, database yang menolak.
create or replace function public.enforce_physical_validation()
returns trigger
language plpgsql
set search_path = ''
as $fn$
begin
  if new.status = 'live' and new.physical_validated is not true then
    raise exception 'listing tidak boleh live tanpa validasi fisik merchant';
  end if;
  if new.status = 'live' and coalesce(new.triage_score, 0) < 70 then
    raise exception 'listing dengan skor triage < 70 harus dialihkan ke jalur B2B';
  end if;
  return new;
end $fn$;

create trigger trg_enforce_physical_validation
  before insert or update on public.listings
  for each row execute function public.enforce_physical_validation();

create table public.orders (
  id             uuid primary key default gen_random_uuid(),
  consumer_id    uuid not null references public.profiles (id) on delete cascade,
  merchant_id    uuid not null references public.merchants (id) on delete cascade,
  subtotal       numeric not null check (subtotal >= 0),
  green_fee      numeric not null default 1000,
  total          numeric not null check (total >= 0),
  status         public.order_status not null default 'pending',
  qr_token       text unique,
  qr_expires_at  timestamptz,
  payment_method text,
  ordered_at     timestamptz not null default now(),
  paid_at        timestamptz,
  claimed_at     timestamptz
);

create index idx_orders_consumer on public.orders (consumer_id, ordered_at desc);
create index idx_orders_merchant on public.orders (merchant_id, ordered_at desc);

create table public.order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references public.orders (id) on delete cascade,
  listing_id    uuid references public.listings (id) on delete set null,
  -- Nama dan harga di-snapshot: listing bisa berubah atau hilang setelah order dibuat,
  -- riwayat pesanan harus tetap terbaca benar setahun kemudian.
  name_snapshot text not null,
  qty           int not null check (qty > 0),
  unit_price    numeric not null check (unit_price >= 0)
);

create index idx_order_items_order on public.order_items (order_id);
create index idx_order_items_listing on public.order_items (listing_id);

-- ── sync_qty_remaining ────────────────────────────────────────────────────
-- Keputusan Agent A: trigger dipasang di `orders`, bukan `order_items`.
-- Alasan: peristiwa pemicunya adalah perubahan orders.status menjadi 'claimed'
-- (merchant scan QR), dan baris order_items sendiri tidak berubah saat itu.
-- Trigger membaca order_items milik order tersebut lalu mengurangi stok.
create or replace function public.sync_qty_remaining()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
begin
  if new.status = 'claimed' and old.status is distinct from 'claimed' then
    update public.listings l
       set qty_remaining = greatest(l.qty_remaining - oi.qty, 0)
      from public.order_items oi
     where oi.order_id = new.id
       and l.id = oi.listing_id;

    -- Stok habis: listing keluar dari radar konsumen.
    update public.listings l
       set status = 'sold_out'
      from public.order_items oi
     where oi.order_id = new.id
       and l.id = oi.listing_id
       and l.qty_remaining = 0
       and l.status = 'live';
  end if;
  return new;
end $fn$;

create trigger trg_sync_qty_remaining
  after update of status on public.orders
  for each row execute function public.sync_qty_remaining();
