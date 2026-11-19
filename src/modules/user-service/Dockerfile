FROM python:3.12-slim

WORKDIR /app
ENV PYTHONPATH=/app

COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

RUN useradd --system --create-home appuser && chown -R appuser /app
USER appuser

CMD ["uvicorn", "run:app", "--host", "0.0.0.0", "--port", "8000"]