# Lestar — Dokumentasi

Platform ekonomi sirkular tiga sisi. Demo **Rabu 2 September 2026**.

## Mulai dari mana

**Pemilik proyek** → isi [`CREDENTIALS-NEEDED.md`](CREDENTIALS-NEEDED.md) dulu. Tanpa itu tidak ada yang bisa mulai.

**Agent** → baca [`00-PRD.md`](00-PRD.md) dan [`01-architecture.md`](01-architecture.md), lalu brief-mu sendiri di [`06-agent-briefs/`](06-agent-briefs/).

## Peta dokumen

| Dokumen | Isi |
|---|---|
| [`superpowers/specs/2026-08-29-lestar-design.md`](superpowers/specs/2026-08-29-lestar-design.md) | **Spec induk** — 12 keputusan dan alasannya |
| [`00-PRD.md`](00-PRD.md) | Produk, aktor, 13 fitur wajib, aturan bisnis, non-goals, risiko |
| [`01-architecture.md`](01-architecture.md) | 4 komponen, aliran data, state machine, fallback, peta migrasi |
| [`02-data-model.md`](02-data-model.md) | 13 tabel, 7 enum, RLS, trigger, index, konstanta bersama |
| [`03-design-system.md`](03-design-system.md) | Tiga sistem desain, token, komponen, gerak |
| [`04-ai-pipeline.md`](04-ai-pipeline.md) | LSTM, 4 endpoint, fallback chain, data sintetis, deploy |
| [`05-demo-script.md`](05-demo-script.md) | Skenario 7 menit, data seed, pertanyaan juri |
| [`06-agent-briefs/`](06-agent-briefs/) | Brief A–G: kepemilikan file, tugas, definisi selesai |
| [`CREDENTIALS-NEEDED.md`](CREDENTIALS-NEEDED.md) | Token yang harus diisi pemilik proyek |

## Tujuh jalur agent

| Agent | Milik | Bergantung | Jadwal |
|---|---|---|---|
| [A · Database](06-agent-briefs/A-database.md) | `supabase/` | — | Sab pagi |
| [B · Core](06-agent-briefs/B-core.md) | `lib/core/`, `lib/shared/` | A | Sab |
| [C · ML & API](06-agent-briefs/C-ml-api.md) | `ml/`, `api/` | A (kolom saja) | Sab–Sen, paralel |
| [D · UI Merchant](06-agent-briefs/D-ui-merchant.md) | `lib/features/merchant/` | B | Min |
| [E · UI Konsumen](06-agent-briefs/E-ui-consumer.md) | `lib/features/consumer/` | B | Sen |
| [F · UI Pengepul](06-agent-briefs/F-ui-partner.md) | `lib/features/partner/` | B | Sen |
| [G · Web & Deck](06-agent-briefs/G-web-deck.md) | `landing/`, `deck/` | — | Sel, paralel |

**B adalah leher botol.** Sampai B selesai, D/E/F tidak bisa mulai.
**C dan G bebas** — bisa jalan dari awal tanpa mengganggu siapa pun.

Aturan main lengkap: [`06-agent-briefs/README.md`](06-agent-briefs/README.md)

## Yang tidak boleh dilanggar

1. **Tidak ada data palsu di jalur demo.** Kalau belum bisa dihubungkan, laporkan — jangan hardcode lalu diam.
2. **Gerbang validasi fisik** ditegakkan di database, bukan hanya di UI.
3. **`forecasts.source` selalu jujur** — termasuk saat sistem jatuh ke heuristik.
4. **Konstanta bersama** hanya hidup di `lib/core/constants.dart` dan `api/constants.py`.
5. **Kunci Gemini dan OpenWeatherMap tidak pernah masuk APK.**

## Urutan korban kalau waktu habis

1. Langganan mitra B2B
2. Export PDF ESG — cukup tampil di layar
3. Animasi transisi

**Tidak pernah dikorbankan:** kaskade · QR claim · radar realtime · Buffer Intelligence · gerbang validasi fisik
