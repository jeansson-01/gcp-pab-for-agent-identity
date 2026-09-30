FROM python:3.11-slim

# Install system dependencies, Node.js and npm for @google-cloud/storage-mcp
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    build-essential \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @google-cloud/storage-mcp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

# Expose container port for Agent Runtime / Reasoning Engine serving
ENV PORT=8080
EXPOSE 8080

# Start FastAPI application
CMD ["uvicorn", "fast_api_app:app", "--host", "0.0.0.0", "--port", "8080"]
