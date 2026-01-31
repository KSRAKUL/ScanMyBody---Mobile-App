# Use Python 3.10 slim image (required for pytorch-grad-cam)
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies (git, libglib for opencv, libgl for OpenGL)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libglib2.0-0 \
    libgl1 \
    libglx-mesa0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ ./backend/

# Expose port
EXPOSE 8000

# Run the application
CMD ["python", "-m", "backend.main"]
