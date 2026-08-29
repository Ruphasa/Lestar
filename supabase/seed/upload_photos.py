#!/usr/bin/env python3
"""Unggah foto makanan ke bucket product-images, lalu pasang URL-nya ke listing.

Kenapa foto tidak diunduh otomatis oleh skrip ini
--------------------------------------------------
Sumber gratis tanpa API key yang sempat dicoba semuanya tidak layak demo:
source.unsplash.com sudah mati (HTTP 503), dan loremflickr mengembalikan foto
Flickr acak berwatermark yang sering bukan foto produk sama sekali. Menempel
foto asal-asalan di jalur demo melanggar aturan "tidak ada data palsu di jalur
demo", jadi pemilihan foto sengaja diserahkan ke manusia.

Cara pakai
----------
1. Kumpulkan ~40 foto makanan Indonesia (Unsplash/Pexels, unduh manual) ke
   folder `supabase/seed/photos/`. Nama berkas bebas, tapi kalau namanya
   mengandung kata dari nama listing, pencocokan otomatis jalan. Contoh:

       photos/croissant-butter.jpg
       photos/gorengan-campur.jpg
       photos/nasi-pecel.jpg

2. Jalankan:

       set SUPABASE_URL=https://vhauffhtjckzmqomcgrl.supabase.co
       set SUPABASE_SERVICE_ROLE_KEY=...      <- dari environment, jangan hardcode
       py supabase/seed/upload_photos.py

   Tambahkan --dry-run untuk melihat rencana pencocokan tanpa mengunggah.

Berkas diunggah ke path `<merchant_uuid>/<nama-berkas>` supaya patuh pada
konvensi kepemilikan yang ditegakkan policy storage di migration 0009.
"""

import argparse
import json
import mimetypes
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

BUCKET = "product-images"
FOLDER = Path(__file__).parent / "photos"


def rest(url: str, key: str, method: str, payload=None, content_type="application/json",
         raw: bytes | None = None, extra_headers: dict | None = None):
    data = raw if raw is not None else (json.dumps(payload).encode() if payload is not None else None)
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", key)
    req.add_header("Authorization", f"Bearer {key}")
    req.add_header("Content-Type", content_type)
    for k, v in (extra_headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=60) as res:
            body = res.read()
            return res.status, json.loads(body) if body and content_type == "application/json" else body
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")


def normalisasi(teks: str) -> set[str]:
    return {w for w in re.split(r"[^a-z0-9]+", teks.lower()) if len(w) > 2}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="tampilkan rencana, jangan unggah")
    args = ap.parse_args()

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY harus ada di environment.")
        return 1
    url = url.rstrip("/")

    if not FOLDER.is_dir():
        print(f"Folder {FOLDER} belum ada. Buat foldernya dan isi dengan foto makanan.")
        return 1

    berkas = sorted(
        p for p in FOLDER.iterdir()
        if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}
    )
    if not berkas:
        print(f"Tidak ada foto di {FOLDER}.")
        return 1

    # Ambil listing yang belum punya foto.
    status, listings = rest(
        f"{url}/rest/v1/listings?select=id,name,merchant_id&image_url=is.null", key, "GET")
    if status != 200:
        print(f"Gagal membaca listings: {status} {listings}")
        return 1

    print(f"{len(berkas)} foto, {len(listings)} listing tanpa foto.\n")

    dipakai: set[Path] = set()
    rencana: list[tuple[dict, Path]] = []

    for l in listings:
        kata = normalisasi(l["name"])
        cocok = None
        skor_terbaik = 0
        for p in berkas:
            if p in dipakai:
                continue
            skor = len(kata & normalisasi(p.stem))
            if skor > skor_terbaik:
                skor_terbaik, cocok = skor, p
        if cocok is None:                      # tidak ada yang cocok: pakai sisa
            sisa = [p for p in berkas if p not in dipakai]
            cocok = sisa[0] if sisa else None
        if cocok is None:
            print(f"  (lewat) {l['name']} — foto habis")
            continue
        dipakai.add(cocok)
        rencana.append((l, cocok))
        print(f"  {l['name']:28} <- {cocok.name}")

    if args.dry_run:
        print("\n--dry-run: tidak ada yang diunggah.")
        return 0

    berhasil = gagal = 0
    for l, p in rencana:
        objek = f"{l['merchant_id']}/{p.name}"
        tipe = mimetypes.guess_type(p.name)[0] or "application/octet-stream"
        status, hasil = rest(
            f"{url}/storage/v1/object/{BUCKET}/{urllib.parse.quote(objek)}",
            key, "POST", raw=p.read_bytes(), content_type=tipe,
            extra_headers={"x-upsert": "true"})
        if status not in (200, 201):
            print(f"  GAGAL unggah {objek}: {status} {hasil}")
            gagal += 1
            continue

        publik = f"{url}/storage/v1/object/public/{BUCKET}/{urllib.parse.quote(objek)}"
        status, hasil = rest(
            f"{url}/rest/v1/listings?id=eq.{l['id']}", key, "PATCH",
            payload={"image_url": publik})
        if status not in (200, 204):
            print(f"  GAGAL pasang URL {l['name']}: {status} {hasil}")
            gagal += 1
        else:
            berhasil += 1

    print(f"\n{berhasil} listing dapat foto, {gagal} gagal.")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(main())
