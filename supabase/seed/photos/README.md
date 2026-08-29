# photos/

Taruh ~40 foto makanan Indonesia di folder ini (`.jpg`, `.jpeg`, `.png`, `.webp`),
lalu jalankan `py supabase/seed/upload_photos.py`.

Nama berkas sebaiknya memuat kata dari nama listing supaya pencocokan otomatis
mengena, misalnya `croissant-butter.jpg`, `gorengan-campur.jpg`, `nasi-pecel.jpg`.
Foto yang tidak cocok tetap terpakai untuk listing yang tersisa.

Foto sengaja tidak diunduh otomatis: sumber gratis tanpa API key yang ada
(source.unsplash.com sudah mati, loremflickr mengembalikan foto acak
berwatermark) tidak layak dipakai di jalur demo.
