"""Nilai emas (golden values) dari artefak model asli yang ter-commit.

Kesenjangan yang ditutup di sini: 84 tes lain memeriksa `source`, ke-integer-
an, rentang 0..1, invariansi urutan, dan rumus confidence -- tidak satu pun
mengunci angka sungguhan dari bobot terlatih. Model dengan bentuk I/O benar
tapi bobot salah, atau dengan KEDUA KEPALA TERTUKAR (`demand`/`surplus`),
akan tetap lolos seluruh suite itu.

Input tetap di bawah ini SENGAJA memberi dua kepala nilai yang jauh berbeda
DAN salah satunya (`demand` mentah = 1.18) berada di LUAR rentang 0..1 milik
sigmoid `surplus` -- kalau kedua output tertukar di `forecast.py:181`
(`pred_demand, pred_surplus = runtime.model.predict(...)`), tes ini gagal
dengan jelas di kedua sisi, bukan lolos secara kebetulan karena angkanya
mirip.

Nilai yang dikunci di bawah didapat dengan menjalankan
`api/model/lestar_lstm.keras` yang sungguhan pada input tetap ini
(lihat task-10-report.md untuk perintah persisnya) -- bukan ditebak.
"""
from __future__ import annotations

import os

import numpy as np
import pytest

from model_runtime import muat

# Array literal, bukan np.random.seed(0) -- supaya golden value tidak
# pernah diam-diam ikut berubah kalau versi NumPy mengganti algoritma RNG-
# nya. Bentuk (1, 14, 11) meniru satu window forecast sungguhan.
INPUT_TETAP = np.array([[
    [0.54881352186203, 0.7151893377304077, 0.6027633547782898, 0.5448831915855408, 0.42365479469299316, 0.6458941102027893, 0.4375872015953064, 0.891772985458374, 0.9636627435684204, 0.3834415078163147, 0.7917250394821167],
    [0.5288949012756348, 0.5680445432662964, 0.9255966544151306, 0.07103605568408966, 0.08712930232286453, 0.020218396559357643, 0.832619845867157, 0.7781567573547363, 0.8700121641159058, 0.978618323802948, 0.7991585731506348],
    [0.4614793658256531, 0.7805292010307312, 0.11827442795038223, 0.6399210095405579, 0.14335328340530396, 0.9446688890457153, 0.5218483209609985, 0.4146619439125061, 0.26455560326576233, 0.7742336988449097, 0.4561503231525421],
    [0.568433940410614, 0.018789799883961678, 0.6176354885101318, 0.6120957136154175, 0.6169340014457703, 0.9437480568885803, 0.681820273399353, 0.35950788855552673, 0.43703195452690125, 0.6976311802864075, 0.0602254718542099],
    [0.6667667031288147, 0.670637845993042, 0.21038256585597992, 0.12892629206180573, 0.31542834639549255, 0.36371076107025146, 0.5701967477798462, 0.4386015236377716, 0.9883738160133362, 0.10204481333494186, 0.20887675881385803],
    [0.16130951046943665, 0.6531082987785339, 0.25329160690307617, 0.4663107693195343, 0.24442559480667114, 0.15896958112716675, 0.11037514358758926, 0.6563295722007751, 0.13818295300006866, 0.1965823620557785, 0.3687251806259155],
    [0.8209932446479797, 0.09710127860307693, 0.8379449248313904, 0.0960984081029892, 0.9764594435691833, 0.4686512053012848, 0.9767611026763916, 0.6048455238342285, 0.7392635941505432, 0.03918779268860817, 0.28280696272850037],
    [0.12019655853509903, 0.296140193939209, 0.11872772127389908, 0.3179831802845001, 0.414262980222702, 0.06414749473333359, 0.6924721002578735, 0.5666014552116394, 0.26538950204849243, 0.5232480764389038, 0.09394051134586334],
    [0.5759465098381042, 0.9292961955070496, 0.3185689449310303, 0.6674103736877441, 0.13179786503314972, 0.7163271903991699, 0.28940609097480774, 0.18319135904312134, 0.5865129232406616, 0.02010754682123661, 0.8289400339126587],
    [0.004695476032793522, 0.6778165102005005, 0.2700079679489136, 0.7351940274238586, 0.9621885418891907, 0.2487531453371048, 0.5761573314666748, 0.5920419096946716, 0.5722519159317017, 0.22308163344860077, 0.9527490139007568],
    [0.4471253752708435, 0.8464086651802063, 0.6994792819023132, 0.2974369525909424, 0.8137978315353394, 0.396505743265152, 0.8811032176017761, 0.5812729001045227, 0.8817353844642639, 0.6925315856933594, 0.7252542972564697],
    [0.5013243556022644, 0.9560836553573608, 0.6439902186393738, 0.4238550364971161, 0.6063932180404663, 0.019193198531866074, 0.30157482624053955, 0.6601735353469849, 0.2900775969028473, 0.6180154085159302, 0.42876869440078735],
    [0.1354740709066391, 0.29828232526779175, 0.5699648857116699, 0.5908727645874023, 0.5743252635002136, 0.6532008051872253, 0.6521032452583313, 0.43141844868659973, 0.8965466022491455, 0.36756187677383423, 0.4358649253845215],
    [0.8919233679771423, 0.806194007396698, 0.7038885951042175, 0.10022688657045364, 0.9194825887680054, 0.7142413258552551, 0.9988470077514648, 0.14944830536842346, 0.8681260347366333, 0.16249293088912964, 0.6155595779418945],
]], dtype='float32')

# Diukur dengan menjalankan api/model/lestar_lstm.keras sungguhan pada
# INPUT_TETAP di atas (lihat task-10-report.md, ronde perbaikan #2).
DEMAND_EMAS = 1.1807365417480469
SURPLUS_EMAS = 0.711269736289978
TOLERANSI = 1e-4  # cukup ketat untuk menangkap bobot salah/tertukar, cukup
                   # longgar untuk noise floating-point antar mesin/CPU.


@pytest.fixture(scope='module')
def runtime_asli():
    path = os.getenv('MODEL_PATH', './model/lestar_lstm.keras')
    rt = muat(path)
    if not rt.loaded:
        pytest.skip(f'model tidak termuat di lingkungan ini: {rt.error}')
    return rt


def test_kepala_demand_dan_surplus_cocok_dengan_nilai_emas(runtime_asli):
    pred_demand, pred_surplus = runtime_asli.model.predict(INPUT_TETAP, verbose=0)
    demand = float(pred_demand.reshape(-1)[0])
    surplus = float(pred_surplus.reshape(-1)[0])

    # Terpisah dan bisa dibedakan -- kalau kedua kepala tertukar di
    # runtime, assert demand akan menerima ~0.71 (gagal, beda dari 1.18)
    # dan assert surplus akan menerima ~1.18 (gagal, beda dari 0.71 DAN di
    # luar rentang 0..1 milik sigmoid).
    assert demand == pytest.approx(DEMAND_EMAS, abs=TOLERANSI)
    assert surplus == pytest.approx(SURPLUS_EMAS, abs=TOLERANSI)


def test_kedua_kepala_emas_jauh_berbeda_secara_desain(runtime_asli):
    """Jaring pengaman untuk tes di atas: kalau suatu saat nilai emas
    diperbarui (retrain baru) jadi kebetulan berdekatan, tes head-swap
    kehilangan daya bedanya tanpa ada yang sadar. Ini menegaskan asumsi
    desainnya tetap berlaku."""
    assert abs(DEMAND_EMAS - SURPLUS_EMAS) > 0.1
    assert not (0.0 <= DEMAND_EMAS <= 1.0)  # di luar rentang sigmoid surplus
    assert 0.0 <= SURPLUS_EMAS <= 1.0
