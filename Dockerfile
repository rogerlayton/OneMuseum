# OneMuseum application image.
#
# Build:  docker build -t onemuseum:dev .
# Run:    docker run --rm -p 5000:5000 --env-file .env onemuseum:dev
#
# Configuration comes entirely from the environment (see docs/CONFIG.md). No
# secrets are baked into the image; .env is excluded by .dockerignore.

FROM python:3.12-slim

# Keeps Python from writing .pyc files, and unbuffers stdout/stderr so
# container logs appear immediately rather than being held in a buffer.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Node and the KaTeX CLI are runtime dependencies, not build-only.
#
# Lesson content containing maths is rendered by markdown_katex, which shells
# out to a `katex` binary. The binaries bundled with that package are x86_64
# only and are Node bundles that need a Node runtime present. Without this
# step, any page containing maths returns a 500 while every other page renders
# normally - a failure that is easy to miss until a user hits a maths lesson.
# Installing a native katex on PATH also makes the image architecture-neutral,
# so it works on arm64 hosts (Graviton, Ampere, Apple Silicon) as well as x86.
RUN apt-get update \
    && apt-get install -y --no-install-recommends nodejs npm \
    && npm install -g katex \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dependencies are copied and installed before the application source so that
# this layer is cached and only rebuilt when requirements.txt changes.
COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY . /app

# Run as an unprivileged user. Ownership is set after the source is copied.
RUN adduser --uid 5678 --disabled-password --gecos "" appuser \
    && chown -R appuser /app
USER appuser

EXPOSE 5000

# wsgi.py is the entrypoint (see docs/CONFIG.md). The former app.py no longer
# exists; the application is created by the factory in onemuseum/__init__.py.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "wsgi:app"]
