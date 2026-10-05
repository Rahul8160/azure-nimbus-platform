# ============ Stage 1: install Python dependencies into a virtual environment ============
FROM python:3.12-slim-bookworm AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install -r requirements.txt


# ============ Stage 2: download Microsoft's package signing key (curl/gnupg stay here) ============
FROM debian:bookworm-slim AS msrepo

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl gnupg ca-certificates \
 && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /microsoft-prod.gpg \
 && curl -fsSL https://packages.microsoft.com/config/debian/12/prod.list -o /mssql-release.list


# ============ Stage 3: final runtime image ============
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Only the key and repo file come across. No curl, no gnupg in this image.
COPY --from=msrepo /microsoft-prod.gpg /usr/share/keyrings/microsoft-prod.gpg
COPY --from=msrepo /mssql-release.list /etc/apt/sources.list.d/mssql-release.list

# ODBC driver: required at runtime by pyodbc
RUN apt-get update \
 && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 unixodbc \
 && rm -rf /var/lib/apt/lists/*

# Finished Python packages from stage 1
COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY app ./app

RUN useradd --system --uid 10001 --no-create-home appuser
USER 10001

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]