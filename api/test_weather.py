"""Pemetaan kode cuaca. Tidak ada test di sini yang menyentuh jaringan."""
import weather


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
