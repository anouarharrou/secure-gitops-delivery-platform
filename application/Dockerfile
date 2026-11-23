FROM python:3.13.18-alpine3.24

ARG FAIL_REQUESTS=false
ARG APP_VERSION=local
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    APP_VERSION=${APP_VERSION} \
    FAIL_REQUESTS=${FAIL_REQUESTS}

WORKDIR /app
COPY app.py /app/app.py

RUN addgroup -S -g 10001 appgroup \
    && adduser -S -D -H -u 10001 -G appgroup appuser

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=1)" || exit 1

CMD ["python", "/app/app.py"]
