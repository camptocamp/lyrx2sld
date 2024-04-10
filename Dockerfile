FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11

COPY ./bridge-style /tmp/bridge-style
COPY requirements.txt /tmp/
RUN pip install /tmp/bridge-style && \
    pip install --disable-pip-version-check --no-cache-dir --requirement=/tmp/requirements.txt && \
    rm --recursive --force /tmp/*
COPY ./app /app
