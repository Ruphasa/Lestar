# Cara Memulai Agent A

**Waktu perkiraan** 3–5 jam · **Memblokir** B, C, D, E, F · **Kerjakan pertama**

---

## 1. Mulai sesi baru

Jangan lanjutkan sesi desain. Buka terminal di `L:\Lestar`, jalankan `claude`, lalu tempel prompt di bawah.

Jalankan sebagai **sesi utama**, bukan subagent. Alasannya: kamu perlu melihat prompt izin, dan Agent A akan menulis ke database sungguhan.

## 2. Prompt pembuka

```
Kamu Agent A (Database) untuk proyek Lestar.

Baca berurutan:
  docs/README.md
  docs/00-PRD.md            — aturan bisnis, terutama §6
  docs/01-architecture.md   — §3 aliran data, §4 state machine
  docs/02-data-model.md     — ini spesifikasi lengkapmu
  docs/06-agent-briefs/README.md
  docs/06-agent-briefs/A-database.md

Muat skill supabase-postgres-best-practices SEBELUM menulis SQL apa pun.

Supabase MCP sudah tersambung. Project: vhauffhtjckzmqomcgrl (Lestar),
schema public masih kosong.

Kerjakan seluruh lingkup Agent A sampai tuntas. Commit setiap migration
yang sudah lolos uji, jangan tunggu semuanya selesai.

Berhenti dan tanya kalau menemui keputusan yang tidak tertulis di dokumen.
```

## 3. Empat gerbang verifikasi

Jangan biarkan Agent A lanjut melewati gerbang yang gagal.

### Gerbang 1 — setelah `0002_identity.sql`
```sql
select id, role from profiles limit 5;
```
Harus ada trigger `on_auth_user_created` yang `security definer`. Tanpa itu, pendaftaran pengguna akan gagal diam-diam.

### Gerbang 2 — setelah `0003_b2c.sql`
Trigger keamanan pangan harus **menolak**:
```sql
-- keduanya WAJIB error
insert into listings (..., status, physical_validated) values (..., 'live', false);
insert into listings (..., status, triage_score)      values (..., 'live', 45);
```
Kalau salah satu berhasil masuk, gerbang keamanan pangan bocor. Ini klaim utamamu di depan juri — jangan diteruskan sampai benar.

### Gerbang 3 — setelah `0007_rls.sql`
Login sebagai merchant A, lalu:
```sql
select * from listings where merchant_id = '<merchant B>' and status = 'draft';
```
Harus mengembalikan **nol baris**. Kalau merchant bisa melihat draft merchant lain, RLS-nya salah.

### Gerbang 4 — setelah seed
```sql
select count(*) from merchants;        -- 30
select count(*) from sales_history;    -- 2700  (30 × 90 hari)
select sum(weight_kg) from waste_batches where status = 'available';  -- 16.6
```
Angka `16.6` itu wajib tepat. Saat demo, kaskade Verde Kitchen menambah 8,4 kg sehingga radar menampilkan **25 KG** persis seperti mockup.

## 4. Tiga jebakan yang akan memakan waktu

### 4.1 Akun tidak bisa dibuat lewat SQL biasa

`profiles.id` mengacu ke `auth.users(id)`. Menyisipkan langsung ke `auth.users` lewat SQL itu rapuh — hashing password dan tabel `auth.identities` gampang salah, dan gejalanya baru muncul saat login gagal.

**Pakai Admin API**, bukan `insert into auth.users`:

```bash
curl -X POST "https://vhauffhtjckzmqomcgrl.supabase.co/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"merchant@lestar.id","password":"lestar2026",
       "email_confirm":true,"user_metadata":{"name":"Verde Kitchen","role":"merchant"}}'
```

Butuh **43 akun**: 30 merchant + 5 konsumen + 8 mitra. Tulis satu skrip yang mengulang, jangan manual.

`email_confirm: true` wajib — tanpa itu login akan ditolak karena email belum terverifikasi.

### 4.2 Seed akan ditolak trigger sendiri

Trigger di Gerbang 2 juga berlaku untuk seed. Setiap listing yang di-seed dengan `status='live'` **harus** punya `physical_validated=true` dan `triage_score >= 70`.

Kalau seed gagal dengan pesan *"listing tidak boleh live tanpa validasi fisik"*, triggernya benar — data seed-nya yang salah. Perbaiki datanya, jangan lemahkan triggernya.

### 4.3 `earthdistance` butuh `cube` lebih dulu

```sql
create extension if not exists cube;          -- ini dulu
create extension if not exists earthdistance; -- baru ini
```
Terbalik urutannya, gagal.

## 5. Soal `pg_cron` dan rahasia di database

Penjadwalan `auto_cascade` butuh service role key di dalam SQL cron. Jangan tempel mentah di berkas migration yang ikut ter-commit.

**Pakai Supabase Vault** (`supabase_vault` sudah terpasang):
```sql
select vault.create_secret('<SERVICE_ROLE_KEY>', 'service_role_key');
```
lalu rujuk lewat `vault.decrypted_secrets` di dalam job cron.

Kalau ini memakan waktu lebih dari 20 menit, **lewati saja** — cron cuma kenyamanan. Yang dipakai saat demo adalah pemicu manual, dan itu wajib tetap ada.

## 6. Definisi selesai

Ambil dari `A-database.md`. Ringkasnya, Agent A selesai kalau:

- 11 migration jalan berurutan di project kosong tanpa error
- Empat gerbang di atas lolos
- 43 akun bisa login dan mendarat di role yang benar
- `auto_cascade` bisa dipanggil manual, menghasilkan `waste_batch` dengan `source_listing_id` terisi
- Dua RPC geo (`nearby_waste`, `nearby_listings`) mengembalikan `jarak_km` terurut
- `reset_demo.sql` jalan di bawah 5 detik

## 7. Yang harus diserahkan sebelum menutup sesi

Agent A menutup pekerjaannya dengan menuliskan ke `docs/06-agent-briefs/A-HANDOFF.md`:

1. Daftar tabel + nama kolom persis — **Agent B menunggu ini**
2. Tanda tangan kedua RPC geo — **Agent E dan F menunggu ini**
3. Format kolom `sales_history` — **Agent C butuh ini untuk generator sintetis**
4. Kredensial 3 akun demo
5. Keputusan yang diambil sendiri karena tidak tertulis di dokumen

Tanpa berkas ini, agent berikutnya akan menebak nama kolom dan salah.

## 8. Setelah A selesai

**B dan C bisa jalan bersamaan** — keduanya tidak saling bergantung.

- Sesi B: `/writing-plans` dulu (ini leher botol, paling rumit), baru eksekusi
- Sesi C: langsung eksekusi dari brief, ruang lingkupnya sudah sempit

D, E, F menunggu B. G bebas kapan saja.
