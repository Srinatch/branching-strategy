FROM python:3.9-slim

WORKDIR /app

# Copy only required files
COPY app/ ./app/
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 9091

# Run with Gunicorn (production server)
CMD ["gunicorn", "-b", "0.0.0.0:9091", "app.app:app"]