# tensorflow-cpu, BUKAN tensorflow. Paket penuh membawa dependensi CUDA ~2 GB
# dan menembus batas free tier Railway. Target image < 1,5 GB.
FROM python:3.11-slim

WORKDIR /app

# Layer dependensi dipisah supaya perubahan kode tidak memicu unduh ulang
# TensorFlow di setiap build.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV MODEL_PATH=./model/lestar_lstm.keras \
    PYTHONUNBUFFERED=1 \
    TF_CPP_MIN_LOG_LEVEL=2

EXPOSE 8000

# Railway menyuntikkan PORT. Default 8000 supaya `docker run -p 8000:8000`
# tetap jalan tanpa environment tambahan.
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
