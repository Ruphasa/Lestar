"""Uji rute /esg-narrative dan template lokal narasi ESG."""
from fastapi.testclient import TestClient

import esg
import gemini
import main

AGREGAT = {
    'total_weight_kg': 128.4,
    'total_co2_kg': 32.1,
    'total_revenue_recovered': 2_450_000,
    'meals_rescued': 642,
    'period_start': '2026-08-01',
    'period_end': '2026-08-31',
    'merchant_name': 'Verde Kitchen',
}


def test_tanpa_gemini_tetap_membalas_paragraf_bernomor_benar(monkeypatch):
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    r = TestClient(main.app).post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    b = r.json()
    assert b['source'] == 'template'
    assert '128,4' in b['narrative'] or '128.4' in b['narrative']
    assert '642' in b['narrative']


def test_dengan_gemini_memakai_kalimatnya(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks',
                        lambda *a, **k: '{"narasi": "Sepanjang Agustus, Verde Kitchen menyelamatkan 128,4 kg."}')
    r = TestClient(main.app).post('/esg-narrative', json=AGREGAT)
    assert r.json()['source'] == 'gemini'
    assert 'Verde Kitchen' in r.json()['narrative']


def test_gemini_gagal_jatuh_ke_template(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: None)
    r = TestClient(main.app).post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_agregat_nol_tidak_meledak(monkeypatch):
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    r = TestClient(main.app).post('/esg-narrative', json={
        'total_weight_kg': 0, 'total_co2_kg': 0,
    })
    assert r.status_code == 200
    assert r.json()['narrative']


def test_body_kosong_tetap_200_karena_semua_field_punya_default(monkeypatch):
    """Dart mengirim map bebas dan `tanpaNull()` membuang field null — tidak
    boleh ada field wajib di EsgRequest atau ini jadi 422."""
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    r = TestClient(main.app).post('/esg-narrative', json={})
    assert r.status_code == 200
    b = r.json()
    assert b['source'] == 'template'
    assert b['narrative']


def test_format_angka_konvensi_indonesia():
    assert esg._desimal(128.4) == '128,4'
    assert esg._rupiah(2_450_000) == '2.450.000'


def test_template_memakai_format_rupiah_dan_desimal_indonesia():
    from schemas import EsgRequest
    a = EsgRequest(**AGREGAT)
    teks = esg.template(a)
    assert '128,4 kg' in teks
    assert '32,1 kg' in teks
    assert 'Rp 2.450.000' in teks
    assert 'Rp 2,450,000' not in teks


def _klien_tanpa_lempar_500():
    """Klien yang melaporkan status asli, bukan yang melempar ulang exception
    seperti default TestClient — supaya kegagalan Gemini yang tidak tertangkap
    terlihat sebagai 500, bukan tersembunyi di traceback pytest."""
    return TestClient(main.app, raise_server_exceptions=False)


def test_gemini_balas_json_array_bukan_object_tidak_500(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: '[1, 2, 3]')
    r = _klien_tanpa_lempar_500().post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_gemini_balas_json_angka_polos_tidak_500(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: '42')
    r = _klien_tanpa_lempar_500().post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_gemini_balas_json_string_tidak_500(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: '"halo"')
    r = _klien_tanpa_lempar_500().post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_gemini_balas_json_true_tidak_500(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: 'true')
    r = _klien_tanpa_lempar_500().post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_gemini_minta_teks_melempar_exception_jatuh_ke_template(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')

    def _meledak(*a, **k):
        raise TimeoutError('koneksi macet')

    monkeypatch.setattr(gemini, 'minta_teks', _meledak)
    r = _klien_tanpa_lempar_500().post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_prompt_memakai_angka_yang_sudah_dibulatkan_bukan_float_mentah(monkeypatch):
    """Prompt dan template harus menyebut digit yang sama. Kalau prompt
    memakai float mentah (128.45, 32.149999999) sementara template sudah
    membulatkan lewat _desimal, paragraf Gemini dan fallback template bisa
    beda angka untuk permintaan yang sama."""
    from schemas import EsgRequest

    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    ditangkap = {}

    def _rekam(prompt, timeout=None):
        ditangkap['prompt'] = prompt
        return None  # jatuh ke template, kita hanya menguji isi prompt

    monkeypatch.setattr(gemini, 'minta_teks', _rekam)
    a = {**AGREGAT, 'total_weight_kg': 128.45, 'total_co2_kg': 32.149999999}
    r = TestClient(main.app).post('/esg-narrative', json=a)
    assert r.status_code == 200

    prompt = ditangkap['prompt']
    assert '128,5 kg' in prompt
    assert '32,1 kg' in prompt
    assert '128.45' not in prompt
    assert '32.149999999' not in prompt


def test_format_rupiah_jutaan_miliaran_dan_negatif():
    assert esg._rupiah(1_000_000) == '1.000.000'
    assert esg._rupiah(2_500_000_000) == '2.500.000.000'
    assert esg._rupiah(-15000) == '-15.000'


def test_format_desimal_negatif():
    assert esg._desimal(-4.25) == '-4,3' or esg._desimal(-4.25) == '-4,2'
    assert esg._desimal(-4.2) == '-4,2'


def test_tipe_salah_tetap_422_setelah_default_ditambahkan():
    """Default menghilangkan 422 untuk field yang HILANG, bukan untuk field
    yang ADA tapi tipenya salah — validasi pydantic tetap berlaku."""
    r = TestClient(main.app).post('/esg-narrative', json={
        'total_weight_kg': 'bukan-angka',
    })
    assert r.status_code == 422
