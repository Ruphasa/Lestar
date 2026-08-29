-- 0006_notifications.sql
-- In-app notification. FCM sengaja tidak dipakai (docs/00-PRD.md §5.3),
-- jadi tabel ini + realtime pada tabel lain yang menggantikan push native.

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  title      text not null,
  body       text,
  type       text,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

-- Query utama: notifikasi milik saya, terbaru dulu.
create index idx_notifications_user on public.notifications (user_id, created_at desc);
-- Badge "belum dibaca" — partial index jauh lebih kecil.
create index idx_notifications_unread on public.notifications (user_id) where read = false;
