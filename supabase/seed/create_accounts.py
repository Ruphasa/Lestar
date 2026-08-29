#!/usr/bin/env python3
"""Membuat 43 akun demo Lestar lewat Supabase Admin API.

Kenapa tidak `insert into auth.users` saja: hashing password dan tabel
auth.identities gampang salah kalau ditulis manual, dan gejalanya baru
muncul saat login gagal di depan juri. Admin API menangani keduanya.

Jalankan:

    set SUPABASE_URL=https://vhauffhtjckzmqomcgrl.supabase.co
    set SUPABASE_SERVICE_ROLE_KEY=...        <- jangan pernah di-hardcode
    py supabase/seed/create_accounts.py

Skrip ini idempoten: akun yang sudah ada dilewati, bukan dibuat ganda.
Baris profiles dibuat otomatis oleh trigger on_auth_user_created dari
user_metadata di bawah, jadi tidak ada insert profiles di sini.

Data toko/organisasi (koordinat, kategori, jam operasional) TIDAK ada di
berkas ini — itu urusan seed.sql, yang mencocokkan baris lewat email.
"""

import json
import os
import sys
import urllib.error
import urllib.request

PASSWORD = "lestar2026"

MERCHANTS = [
    ("merchant@lestar.id",   "Verde Kitchen"),
    ("merchant02@lestar.id", "Warung Bu Tin"),
    ("merchant03@lestar.id", "Bakery Malang Manis"),
    ("merchant04@lestar.id", "Katering Sedap Rasa"),
    ("merchant05@lestar.id", "Kopi Tugu Ijen"),
    ("merchant06@lestar.id", "Warung Pecel Kawi"),
    ("merchant07@lestar.id", "Roti Bakar Soehat"),
    ("merchant08@lestar.id", "Ayam Geprek Sawojajar"),
    ("merchant09@lestar.id", "Dapur Nusantara Blimbing"),
    ("merchant10@lestar.id", "Kafe Suhat Corner"),
    ("merchant11@lestar.id", "Bakso Malang Cak Har"),
    ("merchant12@lestar.id", "Toko Kue Lestari"),
    ("merchant13@lestar.id", "Warung Lalapan Bu Yuli"),
    ("merchant14@lestar.id", "Katering Barokah Lowokwaru"),
    ("merchant15@lestar.id", "Kedai Kopi Klojen"),
    ("merchant16@lestar.id", "Martabak Manis Dieng"),
    ("merchant17@lestar.id", "Bakery Sari Ijen"),
    ("merchant18@lestar.id", "RM Padang Sederhana Kawi"),
    ("merchant19@lestar.id", "Kafe Taman Krida"),
    ("merchant20@lestar.id", "Pastry Corner Batu"),
    ("merchant21@lestar.id", "Warung Soto Ayam Lombok"),
    ("merchant22@lestar.id", "Katering Amanah Singosari"),
    ("merchant23@lestar.id", "Kopi Bulan Sabit"),
    ("merchant24@lestar.id", "Donat Kentang Mbak Sri"),
    ("merchant25@lestar.id", "Warung Rawon Nguling"),
    ("merchant26@lestar.id", "Dapur Mama Tumpang"),
    ("merchant27@lestar.id", "Kafe Buku Ijen"),
    ("merchant28@lestar.id", "Roti Gembong Blimbing"),
    ("merchant29@lestar.id", "Gorengan Pak Slamet"),
    ("merchant30@lestar.id", "Katering Sehat Griya Shanta"),
]

CONSUMERS = [
    ("amira@lestar.id",     "Amira Rahmadani"),
    ("konsumen02@lestar.id", "Bagas Prakoso"),
    ("konsumen03@lestar.id", "Citra Ayu Lestari"),
    ("konsumen04@lestar.id", "Dimas Ardiansyah"),
    ("konsumen05@lestar.id", "Elina Putri"),
]

PARTNERS = [
    ("budi@lestar.id",     "Pak Budi"),
    ("mitra02@lestar.id",  "Kompos Hijau Lestari"),
    ("mitra03@lestar.id",  "Unggas Sumber Rejeki"),
    ("mitra04@lestar.id",  "Maggot Mandiri Sawojajar"),
    ("mitra05@lestar.id",  "Kompos Tani Karangploso"),
    ("mitra06@lestar.id",  "Unggas Jaya Pakis"),
    ("mitra07@lestar.id",  "BSF Malang Raya"),
    ("mitra08@lestar.id",  "Daur Organik Batu"),
]

ROSTER = (
    [(e, n, "merchant") for e, n in MERCHANTS]
    + [(e, n, "consumer") for e, n in CONSUMERS]
    + [(e, n, "partner") for e, n in PARTNERS]
)


def api(url: str, key: str, method: str, payload: dict | None = None) -> tuple[int, dict]:
    body = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("apikey", key)
    req.add_header("Authorization", f"Bearer {key}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            return res.status, json.loads(res.read() or b"{}")
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw or b"{}")
        except json.JSONDecodeError:
            return e.code, {"raw": raw.decode(errors="replace")}


def main() -> int:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY harus ada di environment.")
        return 1

    endpoint = f"{url.rstrip('/')}/auth/v1/admin/users"
    dibuat = dilewati = gagal = 0

    for email, name, role in ROSTER:
        status, data = api(endpoint, key, "POST", {
            "email": email,
            "password": PASSWORD,
            # email_confirm wajib: tanpa ini login ditolak karena email
            # dianggap belum terverifikasi.
            "email_confirm": True,
            "user_metadata": {"name": name, "role": role},
        })

        if status in (200, 201):
            dibuat += 1
            print(f"  dibuat   {email:26} {role:9} {name}")
        elif status == 422:
            dilewati += 1
            print(f"  ada      {email:26} {role:9} {name}")
        else:
            gagal += 1
            print(f"  GAGAL    {email:26} status {status} {data}")

    print(f"\n{len(ROSTER)} akun: {dibuat} dibuat, {dilewati} sudah ada, {gagal} gagal.")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(main())
