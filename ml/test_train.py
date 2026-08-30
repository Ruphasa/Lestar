"""Uji perakitan data latih. Melatih model sungguhan tidak diuji di sini —
itu terlalu lambat untuk test; buktinya ada di metrics.json.
"""
import numpy as np

from generate_synthetic import generate
from train_lstm import FITUR, WINDOW, bangun_model, bangun_window, hitung_scalers


def test_bentuk_window_dan_jumlah_fitur():
    df = generate()
    scalers = hitung_scalers(df)
    X, yd, ys = bangun_window(df, scalers)
    assert X.shape[1:] == (WINDOW, FITUR)
    assert X.shape[0] == yd.shape[0] == ys.shape[0]
    # 120 hari, window 14, target hari ke-15 -> 106 sampel per merchant
    assert X.shape[0] == 30 * (120 - WINDOW)


def test_one_hot_hari_tepat_satu_yang_menyala():
    df = generate()
    X, _, _ = bangun_window(df, hitung_scalers(df))
    onehot = X[:, :, 1:8]
    assert np.allclose(onehot.sum(axis=2), 1.0)


def test_fitur_ternormalisasi_tidak_meledak():
    df = generate()
    X, yd, ys = bangun_window(df, hitung_scalers(df))
    assert np.isfinite(X).all()
    assert X[:, :, 0].max() < 5.0        # porsi ternormalisasi
    assert X[:, :, 9].max() <= 1.0       # cuaca 0..1
    assert set(np.unique(ys)) <= {0.0, 1.0}
    assert np.isfinite(yd).all()


def test_scalers_punya_setiap_merchant_dan_entri_global():
    df = generate()
    s = hitung_scalers(df)
    assert len(s['per_merchant']) == 30
    assert s['global']['porsi'] > 0
    assert s['global']['surplus'] > 0
    for v in s['per_merchant'].values():
        assert v['porsi'] > 0 and v['surplus'] > 0


def test_model_punya_dua_kepala_bernama():
    m = bangun_model()
    assert m.input_shape == (None, WINDOW, FITUR)
    nama = [o.node.layer.name if hasattr(o, 'node') else o.name for o in m.outputs]
    assert any('demand' in str(n) for n in nama)
    assert any('surplus' in str(n) for n in nama)
    assert len(m.outputs) == 2
