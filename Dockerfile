FROM tiangolo/uvicorn-gunicorn-fastapi:python3.7

COPY ./bridge-style /bridge-style
RUN pip install /bridge-style
COPY ./app /app
