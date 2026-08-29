> ✅ **SELESAI 29 Agustus 2026.** Semua gerbang lolos, diverifikasi ulang lewat review.
> Hasil dan sepuluh keputusan Agent A ada di [`A-HANDOFF.md`](../06-agent-briefs/A-HANDOFF.md).
> Berkas ini disimpan sebagai catatan. **Jangan dijalankan ulang** — database sudah terisi.
>
> Satu instruksi di bawah ternyata tidak diperlukan: **Supabase Vault tidak dipakai.**
> `run_auto_cascade()` hidup sebagai fungsi Postgres dan cron memanggilnya langsung
> di dalam database, jadi service role key tidak pernah masuk ke SQL.

Kamu **Agent A (Database)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

Kamu dikerjakan pertama. Lima agent lain menunggu hasilmu.

## Baca dulu, berurutan

```
docs/README.md
docs/00-PRD.md                        aturan bisnis, terutama §6
docs/01-architecture.md               §3 aliran data, §4 state machine
docs/02-data-model.md                 ini spesifikasi lengkapmu
docs/06-agent-briefs/README.md        aturan main antar agent
docs/06-agent-briefs/A-database.md    tugasmu
docs/06-agent-briefs/START-A.md       gerbang verifikasi dan jebakan
```

**Muat skill `supabase-postgres-best-practices` sebelum menulis satu baris SQL pun.**

## Lingkungan

```
Supabase MCP   tersambung, siap dipakai
project_id     vhauffhtjckzmqomcgrl
nama           Lestar
region         ap-southeast-1
Postgres       17.6
schema public  kosong
```

Ekstensi tersedia tapi belum terpasang: `cube` · `earthdistance` · `pg_cron` · `pg_net`
Sudah terpasang: `pgcrypto` · `uuid-ossp` · `supabase_vault`

## Milikmu

```
supabase/migrations/
supabase/functions/
supabase/seed/
```

Jangan menyentuh apa pun di `lib/`, `api/`, `ml/`, atau `landing/`.

## Lingkup

1. **11 migration berurutan** — daftar lengkap di `A-database.md`
2. **Empat trigger** — validasi fisik, `on_auth_user_created`, `sync_qty_remaining`, `write_esg_event`
3. **RLS di semua tabel** — tidak boleh ada satu tabel pun tanpa policy
4. **Realtime** di `listings`, `waste_batches`, `orders`
5. **4 storage bucket**
6. **Dua RPC geo** — `nearby_waste` dan `nearby_listings`, pakai `earthdistance` + index GiST
7. **Edge Function `auto_cascade`** — bisa dipanggil cron **dan** manual, logika identik
8. **Seed** — 43 akun, 30 merchant, 2700 baris `sales_history`, listing aktif, 2 waste batch
9. **`reset_demo.sql`** — kembalikan ke kondisi awal demo dalam < 5 detik

## Empat gerbang — jangan lanjut kalau gagal

**Gerbang 1** setelah `0002` — trigger `on_auth_user_created` ada dan `security definer`.

**Gerbang 2** setelah `0003` — keduanya **wajib error**:
```sql
insert into listings (..., status, physical_validated) values (..., 'live', false);
insert into listings (..., status, triage_score)      values (..., 'live', 45);
```
Ini gerbang keamanan pangan, klaim utama produk di depan juri. Kalau salah satu berhasil masuk, berhenti dan perbaiki.

**Gerbang 3** setelah `0007` — merchant A membaca listing draft merchant B harus mengembalikan **nol baris**.

**Gerbang 4** setelah seed:
```sql
select count(*) from merchants;       -- 30
select count(*) from sales_history;   -- 2700
select sum(weight_kg) from waste_batches where status = 'available';   -- tepat 16.6
```
Angka `16.6` wajib tepat. Saat demo, kaskade Verde Kitchen menambah 8,4 kg sehingga radar pengepul menampilkan **25 KG** persis seperti mockup.

## Tiga jebakan

**1. Akun tidak bisa dibuat lewat SQL biasa.** `profiles.id` mengacu ke `auth.users`. Menyisipkan langsung ke `auth.users` itu rapuh — hashing password dan tabel `auth.identities` gampang salah, gejalanya baru muncul saat login gagal.

Pakai Admin API:
```bash
curl -X POST "https://vhauffhtjckzmqomcgrl.supabase.co/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"merchant@lestar.id","password":"lestar2026",
       "email_confirm":true,"user_metadata":{"name":"Verde Kitchen","role":"merchant"}}'
```
Butuh 43 akun: 30 merchant + 5 konsumen + 8 mitra. Tulis skrip yang mengulang. `email_confirm: true` wajib.

**2. Seed akan ditolak trigger buatanmu sendiri.** Listing seed dengan `status='live'` harus punya `physical_validated=true` dan `triage_score >= 70`. Kalau gagal, **triggernya benar — datanya yang salah.** Perbaiki data, jangan lemahkan trigger.

**3. `cube` dipasang sebelum `earthdistance`.** Terbalik, gagal.

## Rahasia

Kunci ada di `docs/CREDENTIALS-NEEDED.md` (tidak ter-commit, sudah di `.gitignore`).

`pg_cron` butuh service role key di dalam SQL. Jangan tempel mentah di migration yang ter-commit — pakai `supabase_vault`. **Kalau ini makan waktu lebih dari 20 menit, lewati saja** — cron cuma kenyamanan, yang dipakai saat demo adalah pemicu manual, dan itu wajib tetap ada.

## Cara kerja

- Commit setiap migration yang lolos uji. Jangan tunggu semuanya selesai.
- Pesan commit Bahasa Indonesia, jelaskan apa yang berubah dan kenapa.
- Kalau menemui keputusan yang tidak tertulis di dokumen: **pilih yang paling sederhana, catat pilihannya**, lanjut. Berhenti dan tanya hanya kalau pilihan itu mengubah kontrak untuk agent lain.

## Selesai berarti

- 11 migration jalan berurutan di project kosong tanpa error
- Empat gerbang lolos
- 43 akun bisa login, mendarat di role yang benar
- `auto_cascade` dipanggil manual menghasilkan `waste_batch` dengan `source_listing_id` terisi
- Dua RPC geo mengembalikan `jarak_km` terurut menaik
- `reset_demo.sql` jalan < 5 detik

## Sebelum menutup sesi

Tulis `docs/06-agent-briefs/A-HANDOFF.md` berisi:

1. **Daftar tabel + nama kolom persis** — Agent B menunggu ini untuk menulis model
2. **Tanda tangan kedua RPC geo** beserta bentuk kolom yang dikembalikan — Agent E dan F menunggu
3. **Format kolom `sales_history`** — Agent C butuh untuk generator sintetis
4. **Kredensial 3 akun demo**
5. **Keputusan yang kamu ambil sendiri** karena tidak tertulis di dokumen
6. **Apa pun yang gagal atau kamu lewati**, dengan alasannya

Tanpa berkas ini, agent berikutnya akan menebak nama kolom dan salah. Ini bagian dari definisi selesai.
