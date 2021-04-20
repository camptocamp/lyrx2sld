FROM tiangolo/uvicorn-gunicorn-fastapi:python3.7

COPY ./bridge-style /bridge-style
RUN ls bridge-style && pip install /bridge-style
COPY ./app /app
