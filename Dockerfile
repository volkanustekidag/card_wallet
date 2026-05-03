FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV WALLET_EXPORT_HOST=0.0.0.0

WORKDIR /app
COPY tools/wallet_export_server/server.py /app/server.py

CMD ["python", "/app/server.py"]
