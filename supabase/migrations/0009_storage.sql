-- 0009_storage.sql
-- Empat bucket. Tiga publik untuk dibaca (foto muncul di radar tanpa signed URL),
-- satu privat karena berisi laporan ESG per merchant.
--
-- Konvensi path yang dipakai seluruh app: <uid>/<namafile>
-- Folder pertama = pemilik berkas. Policy menegakkan konvensi ini, jadi merchant
-- tidak bisa menimpa foto merchant lain meski tahu nama berkasnya.

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true),
       ('waste-images',   'waste-images',   true),
       ('store-logos',    'store-logos',    true),
       ('esg-reports',    'esg-reports',    false)
on conflict (id) do update set public = excluded.public;

-- Baca: tiga bucket publik terbuka untuk anon dan authenticated.
create policy "bucket publik boleh dibaca siapa saja" on storage.objects
  for select to anon, authenticated
  using (bucket_id in ('product-images', 'waste-images', 'store-logos'));

-- Tulis: hanya ke folder milik sendiri.
create policy "unggah ke folder sendiri" on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('product-images', 'waste-images', 'store-logos', 'esg-reports')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "ganti berkas sendiri" on storage.objects
  for update to authenticated
  using (
    bucket_id in ('product-images', 'waste-images', 'store-logos', 'esg-reports')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id in ('product-images', 'waste-images', 'store-logos', 'esg-reports')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "hapus berkas sendiri" on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('product-images', 'waste-images', 'store-logos', 'esg-reports')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Laporan ESG privat: hanya pemiliknya yang boleh membaca, lewat signed URL.
create policy "laporan esg hanya untuk pemiliknya" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'esg-reports'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
