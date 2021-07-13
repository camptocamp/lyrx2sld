FROM tiangolo/uvicorn-gunicorn-fastapi

COPY ./bridge-style /bridge-style
COPY requirements.txt /tmp/
RUN pip install /bridge-style && \
    pip install --disable-pip-version-check --no-cache-dir --requirement=/tmp/requirements.txt && \
    rm --recursive --force /tmp/*
COPY ./app /app
