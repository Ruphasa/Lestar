# tensorflow-cpu, BUKAN tensorflow. Paket penuh membawa dependensi CUDA ~2 GB
# dan menembus batas free tier Railway. Target image < 1,5 GB.
FROM python:3.11-slim

WORKDIR /app

# Layer dependensi dipisah supaya perubahan kode tidak memicu unduh ulang
# TensorFlow di setiap build.
COPY requirements.txt .
# Dibersihkan di RUN yang SAMA dengan pip install, bukan RUN terpisah --
# penghapusan di layer belakangan tidak mengecilkan image sama sekali,
# byte-nya sudah terkunci di layer sebelumnya. Hanya dua target yang
# terverifikasi aman untuk inferensi murni-Python: __pycache__ (bytecode
# yang dibuat ulang otomatis saat dibutuhkan) dan tensorflow/include
# (header C++ untuk build custom op, tidak dipakai runtime). tensorboard
# SENGAJA tidak dicopot -- ukurannya kecil dan mencabutnya memicu warning
# di setiap startup container, bukan trade-off yang bagus sebelum demo.
# libtensorflow_cc.so.2 SENGAJA tidak disentuh -- itu load-bearing untuk
# `import tensorflow`.
RUN pip install --no-cache-dir -r requirements.txt && \
    find /usr/local/lib/python3.11/site-packages -type d -name '__pycache__' -exec rm -rf {} + && \
    rm -rf /usr/local/lib/python3.11/site-packages/tensorflow/include

COPY . .

ENV MODEL_PATH=./model/lestar_lstm.keras \
    PYTHONUNBUFFERED=1 \
    TF_CPP_MIN_LOG_LEVEL=2

EXPOSE 8000

# Railway menyuntikkan PORT. Default 8000 supaya `docker run -p 8000:8000`
# tetap jalan tanpa environment tambahan.
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
