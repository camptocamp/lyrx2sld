FROM tiangolo/uvicorn-gunicorn-fastapi:python3.7-2020-12-19

COPY ./bridge-style /bridge-style
RUN pip install /bridge-style
COPY ./app /app
