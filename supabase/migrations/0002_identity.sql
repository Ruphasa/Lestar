-- 0002_identity.sql
-- Tiga tabel identitas: profiles (cermin auth.users) + dua tabel profil peran.
-- merchants.id dan partners.id sengaja memakai PK = FK ke profiles(id),
-- bukan id sendiri. Alasan: policy RLS jadi `id = auth.uid()` tanpa join,
-- dan listings.merchant_id bisa dibandingkan langsung dengan auth.uid().

create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  name       text        not null,
  email      text        not null,
  phone      text,
  address    text,
  role       public.user_role not null,
  eco_points int         not null default 0,
  avatar_url text,
  created_at timestamptz not null default now()
);

comment on table public.profiles is 'Cerminan 1:1 auth.users. Diisi otomatis oleh trigger on_auth_user_created.';

create index idx_profiles_role on public.profiles (role);

create table public.merchants (
  id                   uuid primary key references public.profiles (id) on delete cascade,
  store_name           text not null,
  store_address        text not null,
  -- lat/lng wajib: radar konsumen dan radar pengepul tidak bisa jalan tanpa ini.
  lat                  double precision not null,
  lng                  double precision not null,
  store_image          text,
  category             text,
  operating_hours      text,
  cutoff_time          time not null default '22:00',
  rating               numeric(2,1) not null default 5.0,
  total_earnings       numeric not null default 0,
  total_waste_saved_kg numeric not null default 0,
  level                int    not null default 1
);

-- Index GiST untuk nearby_listings(). ll_to_earth di-qualify karena
-- earthdistance dipasang di schema extensions, bukan public.
create index idx_merchants_geo on public.merchants
  using gist (extensions.ll_to_earth(lat, lng));

create table public.partners (
  id                  uuid primary key references public.profiles (id) on delete cascade,
  org_name            text not null,
  partner_type        text,
  waste_preference    public.waste_type[] not null default '{wet}',
  vehicle_type        text,
  license_plate       text,
  service_radius_km   numeric not null default 10,
  base_lat            double precision not null,
  base_lng            double precision not null,
  total_pickups       int not null default 0,
  subscription_expiry timestamptz
);

create index idx_partners_geo on public.partners
  using gist (extensions.ll_to_earth(base_lat, base_lng));

-- Trigger pembuat profil.
-- security definer: berjalan sebagai pemilik supaya bisa menulis ke public.profiles
-- meski pemanggilnya adalah role auth internal yang tidak punya hak insert.
-- search_path dikosongkan supaya tidak bisa dibajak lewat schema palsu.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_role public.user_role;
begin
  -- Role diambil dari user_metadata saat pendaftaran lewat Admin API.
  -- Nilai tidak dikenal jatuh ke 'consumer' supaya pendaftaran tidak pernah gagal diam-diam.
  begin
    v_role := (new.raw_user_meta_data ->> 'role')::public.user_role;
  exception when others then
    v_role := 'consumer';
  end;

  insert into public.profiles (id, name, email, phone, role, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data ->> 'phone',
    coalesce(v_role, 'consumer'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  return new;
end $fn$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
