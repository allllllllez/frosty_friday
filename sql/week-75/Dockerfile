FROM python:3.11-slim

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        git && \
    python -m pip install pipx && \
    python -m pipx ensurepath && \
    pipx ensurepath --global && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pipx install snowflake-cli

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PATH="/root/.local/bin:${PATH}"

# Default command
CMD ["/bin/bash"]
