FROM python:3.11-slim

WORKDIR /app

COPY docker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ src/
COPY configs/ configs/

ENTRYPOINT ["python", "src/run_experiment.py"]
