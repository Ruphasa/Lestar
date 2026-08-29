-- 0005_intelligence.sql
-- Tabel intelijen: sales_history (bahan bakar LSTM), forecasts,
-- esg_events (buku besar dampak) dan esg_reports (agregasinya).

create table public.sales_history (
  id            uuid primary key default gen_random_uuid(),
  merchant_id   uuid not null references public.merchants (id) on delete cascade,
  date          date not null,
  portions_sold int  not null check (portions_sold >= 0),
  revenue       numeric not null check (revenue >= 0),
  day_of_week   smallint not null check (day_of_week between 0 and 6), -- 0 = Senin
  is_holiday    boolean not null default false,
  weather_code  smallint,
  surplus_kg    numeric not null default 0,
  unique (merchant_id, date)
);

-- Buffer Intelligence selalu mengambil 14 baris terakhir per merchant.
create index idx_sales_history_merchant_date on public.sales_history (merchant_id, date desc);

create table public.forecasts (
  id                    uuid primary key default gen_random_uuid(),
  merchant_id           uuid not null references public.merchants (id) on delete cascade,
  forecast_date         date not null,
  demand_x              numeric not null,
  surplus_probability_y numeric not null check (surplus_probability_y between 0 and 1),
  surplus_volume_est_kg numeric,
  recommended_production int not null,
  confidence            numeric,
  narrative             text,
  -- source harus jujur: heuristic ditulis apa adanya saat Railway mati.
  source                public.forecast_source not null,
  created_at            timestamptz not null default now(),
  unique (merchant_id, forecast_date)
);

create index idx_forecasts_merchant on public.forecasts (merchant_id, forecast_date desc);

create table public.esg_events (
  id                uuid primary key default gen_random_uuid(),
  merchant_id       uuid not null references public.merchants (id) on delete cascade,
  event_type        public.esg_event_type not null,
  ref_id            uuid not null, -- order_id atau waste_batch_id
  weight_kg         numeric not null check (weight_kg >= 0),
  co2_saved_kg      numeric not null check (co2_saved_kg >= 0),
  revenue_recovered numeric not null default 0,
  occurred_at       timestamptz not null default now(),
  -- Buku besar: satu peristiwa satu baris, tidak boleh ganda.
  unique (event_type, ref_id)
);

create index idx_esg_events_merchant on public.esg_events (merchant_id, occurred_at desc);

create table public.esg_reports (
  id                      uuid primary key default gen_random_uuid(),
  merchant_id             uuid not null references public.merchants (id) on delete cascade,
  period_start            date not null,
  period_end              date not null,
  total_weight_kg         numeric not null default 0,
  total_co2_kg            numeric not null default 0,
  total_revenue_recovered numeric not null default 0,
  meals_rescued           int not null default 0,
  narrative               text,
  pdf_url                 text,
  created_at              timestamptz not null default now()
);

create index idx_esg_reports_merchant on public.esg_reports (merchant_id, period_end desc);

-- ── Konstanta bersama, versi SQL ──────────────────────────────────────────
-- Nilai identik dengan lib/core/constants.dart dan api/constants.py.
-- Ditaruh sebagai fungsi immutable supaya trigger, RPC, dan Edge Function
-- memakai satu sumber angka yang sama.
create or replace function public.berat_porsi_kg(p_category text)
returns numeric
language sql
immutable
set search_path = ''
as $fn$
  select case lower(coalesce(p_category, ''))
           when 'gorengan'  then 0.15
           when 'nasi_lauk' then 0.35
           when 'roti'      then 0.08
           when 'kue'       then 0.05
           when 'minuman'   then 0.30
           else 0.20                       -- lainnya
         end::numeric;
$fn$;

create or replace function public.faktor_co2_per_kg()
returns numeric
language sql
immutable
set search_path = ''
as $fn$ select 0.25::numeric $fn$;   -- Tabel 2.5.1 proposal

comment on function public.faktor_co2_per_kg() is
  'kg CO2eq per kg surplus dialihkan dari TPA. Harus identik di Dart, Python, SQL.';

-- ── write_esg_event ───────────────────────────────────────────────────────
-- Ditulis tepat dua kali sepanjang hidup satu makanan:
--   order  -> claimed    = b2c_rescued
--   waste  -> completed  = b2b_diverted
create or replace function public.write_esg_event_order()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_weight numeric;
begin
  if new.status = 'claimed' and old.status is distinct from 'claimed' then
    select coalesce(sum(oi.qty * public.berat_porsi_kg(l.category)), 0)
      into v_weight
      from public.order_items oi
      left join public.listings l on l.id = oi.listing_id
     where oi.order_id = new.id;

    insert into public.esg_events
      (merchant_id, event_type, ref_id, weight_kg, co2_saved_kg, revenue_recovered, occurred_at)
    values
      (new.merchant_id, 'b2c_rescued', new.id, v_weight,
       v_weight * public.faktor_co2_per_kg(), new.subtotal, coalesce(new.claimed_at, now()))
    on conflict (event_type, ref_id) do nothing;
  end if;
  return new;
end $fn$;

create trigger trg_write_esg_event_order
  after update of status on public.orders
  for each row execute function public.write_esg_event_order();

create or replace function public.write_esg_event_waste()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    insert into public.esg_events
      (merchant_id, event_type, ref_id, weight_kg, co2_saved_kg, revenue_recovered, occurred_at)
    values
      (new.source_merchant_id, 'b2b_diverted', new.id, new.weight_kg,
       new.weight_kg * public.faktor_co2_per_kg(), new.price, coalesce(new.completed_at, now()))
    on conflict (event_type, ref_id) do nothing;
  end if;
  return new;
end $fn$;

create trigger trg_write_esg_event_waste
  after update of status on public.waste_batches
  for each row execute function public.write_esg_event_waste();
