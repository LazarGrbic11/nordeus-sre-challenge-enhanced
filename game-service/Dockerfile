FROM python:3.8-alpine as builder

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

FROM python:3.8-alpine

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --from=builder /app /app
EXPOSE 8000
CMD ["python", "main.py"]