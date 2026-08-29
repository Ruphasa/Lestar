# Prompt Agent — Cara Pakai

Tiap berkas di folder ini adalah **prompt utuh**. Salin seluruh isinya, tempel ke sesi Claude Code yang baru di `L:\Lestar`. Tidak perlu ditambah apa-apa.

## Urutan menjalankan

```
Sabtu   A ──┬── B ──┬── D
            │       ├── E
            └── C   └── F
                        
Selasa  G   (bebas, bisa kapan saja)
```

| # | Agent | Jalankan setelah | Perkiraan | Catatan |
|---|---|---|---|---|
| 1 | [A.md](A.md) | — | ✅ **selesai** | Semua gerbang lolos. Lihat `A-HANDOFF.md` |
| 2 | [B.md](B.md) | A selesai | 5–7 jam | Leher botol. Pakai `/writing-plans` dulu |
| 3 | [C.md](C.md) | A selesai | 4–6 jam | **Paralel dengan B.** Sesi terpisah |
| 4 | [D.md](D.md) | B selesai | 5–7 jam | UI merchant |
| 5 | [E.md](E.md) | B selesai | 5–7 jam | UI konsumen |
| 6 | [F.md](F.md) | B selesai | 3–4 jam | UI pengepul. Paling cepat, paling berkesan |
| 7 | [G.md](G.md) | kapan saja | 3–4 jam | Butuh tangkapan layar dari D/E/F untuk deck |

**B dan C bisa jalan bersamaan** di dua sesi terpisah — keduanya tidak saling menyentuh berkas.
**D, E, F bisa jalan bersamaan** setelah B selesai — masing-masing punya folder sendiri.

## Aturan sesi

- **Satu agent, satu sesi baru.** Jangan tumpuk dua agent dalam satu sesi — konteksnya bercampur dan mereka akan menyentuh berkas milik agent lain.
- **Sesi utama, bukan subagent.** Kamu perlu melihat prompt izin.
- **Commit bertahap.** Setiap potong pekerjaan yang lolos uji langsung di-commit, jangan tunggu selesai semua.

## Rantai serah terima

Tiap agent menutup sesinya dengan menulis berkas serah terima. Agent berikutnya membacanya.

```
A  →  docs/06-agent-briefs/A-HANDOFF.md   nama kolom, tanda tangan RPC, format sales_history
B  →  docs/06-agent-briefs/B-HANDOFF.md   nama model, tanda tangan repository, nama rute, widget
C  →  docs/06-agent-briefs/C-HANDOFF.md   URL Railway, metrik model, berkas uji paritas
```

Tanpa berkas ini, agent berikutnya akan menebak nama kolom dan salah. Ini bagian dari definisi selesai, bukan tambahan opsional.
