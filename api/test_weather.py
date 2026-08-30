"""Pemetaan kode cuaca. Tidak ada test di sini yang menyentuh jaringan."""
import weather


class _RespPalsu:
    """Pengganti httpx.Response -- cuma `status_code` dan `.json()`."""

    def __init__(self, status_code=200, payload=None):
        self.status_code = status_code
        self._payload = {} if payload is None else payload

    def json(self):
        return self._payload


def test_pemetaan_id_owm_ke_skala_agent_a():
    assert weather.kode_dari_owm(800) == 0       # cerah
    assert weather.kode_dari_owm(801) == 1       # sedikit berawan
    assert weather.kode_dari_owm(802) == 1
    assert weather.kode_dari_owm(803) == 2       # mendung
    assert weather.kode_dari_owm(804) == 2
    assert weather.kode_dari_owm(500) == 3       # hujan
    assert weather.kode_dari_owm(202) == 3       # badai petir
    assert weather.kode_dari_owm(301) == 3       # gerimis
    assert weather.kode_dari_owm(741) == 2       # kabut


def test_id_asing_dianggap_cerah():
    assert weather.kode_dari_owm(0) == 0
    assert weather.kode_dari_owm(99999) == 0


def test_tanpa_kunci_mengembalikan_none(monkeypatch):
    monkeypatch.delenv('OPENWEATHER_API_KEY', raising=False)
    assert weather.ramalan_besok(-7.98, 112.63) is None


def test_jaringan_gagal_mengembalikan_none_bukan_lempar(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')

    def meledak(*a, **k):
        raise RuntimeError('putus')

    monkeypatch.setattr(weather.httpx, 'get', meledak)
    assert weather.ramalan_besok(-7.98, 112.63) is None


# ─── Tugas 12 item 3: jalur kegagalan `ramalan_besok` yang cuma dilindungi
# `except Exception` lebar -- tidak ada test sebelumnya yang mengunci bahwa
# masing-masing berakhir sebagai None, bukan exception yang lolos.


def test_status_bukan_200_mengembalikan_none(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')
    monkeypatch.setattr(weather.httpx, 'get', lambda *a, **k: _RespPalsu(status_code=500))
    assert weather.ramalan_besok(-7.98, 112.63) is None


def test_body_tanpa_kunci_list_mengembalikan_none(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')
    monkeypatch.setattr(weather.httpx, 'get', lambda *a, **k: _RespPalsu(payload={}))
    assert weather.ramalan_besok(-7.98, 112.63) is None


def test_list_kosong_mengembalikan_none(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')
    monkeypatch.setattr(weather.httpx, 'get', lambda *a, **k: _RespPalsu(payload={'list': []}))
    assert weather.ramalan_besok(-7.98, 112.63) is None


def test_entri_tanpa_weather_mengembalikan_none(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')
    monkeypatch.setattr(
        weather.httpx, 'get',
        lambda *a, **k: _RespPalsu(payload={'list': [{'main': {}}]}),
    )
    assert weather.ramalan_besok(-7.98, 112.63) is None


def test_weather_tanpa_id_mengembalikan_none(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')
    monkeypatch.setattr(
        weather.httpx, 'get',
        lambda *a, **k: _RespPalsu(payload={'list': [{'weather': [{'main': 'Clear'}]}]}),
    )
    assert weather.ramalan_besok(-7.98, 112.63) is None


# ─── Tugas 12 item 3: batas-batas persis `kode_dari_owm`, diprobe manual
# sebelumnya (benar) tapi tidak pernah dikunci lewat test.


def test_kode_dari_owm_batas_batas_persis():
    assert weather.kode_dari_owm(199) == 0        # tepat di luar rentang basah
    assert weather.kode_dari_owm(200) == 3        # awal badai/gerimis/hujan
    assert weather.kode_dari_owm(599) == 3        # akhir rentang itu
    assert weather.kode_dari_owm(600) == 3        # awal salju
    assert weather.kode_dari_owm(699) == 3        # akhir rentang salju
    assert weather.kode_dari_owm(700) == 2        # awal kabut/asap/debu
    assert weather.kode_dari_owm(800) == 0        # cerah
    assert weather.kode_dari_owm(801) == 1        # sedikit berawan
    assert weather.kode_dari_owm(802) == 1
    assert weather.kode_dari_owm(803) == 2        # mendung
    assert weather.kode_dari_owm(804) == 2
    assert weather.kode_dari_owm(805) == 0        # tidak dikenal -> jatuh ke cerah
    assert weather.kode_dari_owm(900) == 0        # di luar semua rentang dikenal
    assert weather.kode_dari_owm(-1) == 0         # id negatif -> cerah, bukan exception


# ─── Tugas 12 item 3: `tersedia()` langsung, dengan dan tanpa kunci.


def test_tersedia_true_saat_kunci_di_set(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')
    assert weather.tersedia() is True


def test_tersedia_false_tanpa_kunci(monkeypatch):
    monkeypatch.delenv('OPENWEATHER_API_KEY', raising=False)
    assert weather.tersedia() is False
