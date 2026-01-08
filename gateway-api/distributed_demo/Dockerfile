FROM python:3.11-slim
RUN pip install --no-cache-dir requests numpy
WORKDIR /app
COPY . .
CMD ["python", "main.py"]
