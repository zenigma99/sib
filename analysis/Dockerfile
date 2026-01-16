FROM python:3.12-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir flask flask-cors requests pyyaml gunicorn

# Copy analysis module
COPY *.py ./
COPY config.yaml ./

# Create non-root user and cache directory
RUN useradd -m -r sib && \
    mkdir -p /app/cache && \
    chown -R sib:sib /app
USER sib

EXPOSE 5000

# Health check using Python (no curl needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

# Use gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "api:app"]
