-- 0011_harden_rls_auto_enable.sql
--
-- Temuan review setelah Agent A: security advisor menandai
-- `public.rls_auto_enable()` sebagai fungsi SECURITY DEFINER yang bisa
-- dipanggil role `anon` dan `authenticated` lewat /rest/v1/rpc/.
--
-- Risiko nyatanya kecil: fungsi ini event trigger, dan memanggilnya lewat REST
-- langsung gagal karena pg_event_trigger_ddl_commands() hanya jalan di dalam
-- konteks event trigger. Tapi fungsi SECURITY DEFINER tidak punya alasan
-- terekspos di schema API, dan advisor akan terus menandainya.
--
-- Fungsinya sendiri dipertahankan — dia yang menjamin tabel baru di schema
-- public tidak pernah lahir tanpa RLS.

revoke all on function public.rls_auto_enable() from public, anon, authenticated;

comment on function public.rls_auto_enable() is
  'Event trigger: menyalakan RLS otomatis pada tabel baru di schema public. '
  'Bukan untuk dipanggil langsung — EXECUTE dicabut dari anon dan authenticated.';
