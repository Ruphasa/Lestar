-- 0001_enums.sql
-- Tujuh enum domain Lestar. Sumber: docs/02-data-model.md §1.
-- Enum dipakai (bukan text + check) supaya nilai tidak sah ditolak
-- di level tipe dan klien Dart bisa memetakan 1:1 ke enum Dart.

create type public.user_role       as enum ('consumer','merchant','partner');
create type public.listing_status  as enum ('draft','live','sold_out','expired','cascaded');
create type public.waste_type      as enum ('wet','dry');
create type public.waste_status    as enum ('available','matched','picked_up','completed','cancelled');
create type public.order_status    as enum ('pending','paid','ready','claimed','cancelled','expired');
create type public.forecast_source as enum ('lstm_gemini','lstm_only','heuristic');
create type public.esg_event_type  as enum ('b2c_rescued','b2b_diverted');
