FROM python:3.12

COPY ./bridge-style /tmp/bridge-style
COPY requirements.txt /tmp/
RUN pip install /tmp/bridge-style && \
    pip install --disable-pip-version-check --no-cache-dir --requirement=/tmp/requirements.txt && \
    rm --recursive --force /tmp/*
COPY ./app /app

WORKDIR /app

CMD ["fastapi", "run", "main.py", "--port", "80"]
