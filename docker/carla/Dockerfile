# CARLA Simulator Docker Image
# Built for GPU support and headless operation

FROM nvidia/cuda:11.8.0-base-ubuntu22.04

# Build arguments
ARG CARLA_VERSION=0.9.15
ARG DEBIAN_FRONTEND=noninteractive

# Metadata
LABEL maintainer="DevOps Team"
LABEL description="CARLA Simulator for ADAS-CARLA synthetic data generation"
LABEL version="${CARLA_VERSION}"

# System dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    software-properties-common \
    build-essential \
    # Graphics and display libraries
    libglu1-mesa \
    libgl1-mesa-glx \
    libx11-6 \
    libxcursor1 \
    libxrandr2 \
    libxinerama1 \
    libxi6 \
    libxxf86vm1 \
    libxkbcommon0 \
    libgl1 \
    # Audio libraries (even for headless, CARLA needs them)
    libasound2 \
    libpulse0 \
    # Python and pip
    python3 \
    python3-pip \
    python3-dev \
    # Additional utilities
    unzip \
    xdg-user-dirs \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Set up Python environment
RUN python3 -m pip install --upgrade pip setuptools wheel

# Create carla user (don't run as root in production)
RUN useradd -m -s /bin/bash carla && \
    usermod -aG video carla

# Download and extract CARLA
WORKDIR /home/carla

# Using the official CARLA release
RUN wget -nv -O CARLA_${CARLA_VERSION}.tar.gz \
    "https://carla-releases.s3.eu-west-3.amazonaws.com/Linux/CARLA_${CARLA_VERSION}.tar.gz" && \
    tar -xzf CARLA_${CARLA_VERSION}.tar.gz && \
    rm CARLA_${CARLA_VERSION}.tar.gz && \
    chmod +x /home/carla/CarlaUE4.sh && \
    chmod +x /home/carla/CarlaUE4/Binaries/Linux/CarlaUE4-Linux-Shipping

# Install Python CARLA client and dependencies
COPY requirements-carla.txt /tmp/requirements-carla.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements-carla.txt && \
    rm /tmp/requirements-carla.txt

# Set up Python path for CARLA egg file
ENV PYTHONPATH=/home/carla/PythonAPI/carla/dist/carla-${CARLA_VERSION}-py3.7-linux-x86_64.egg:${PYTHONPATH}

# Copy custom scripts
COPY docker/carla/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/carla/scripts/healthcheck.py /usr/local/bin/healthcheck.py
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/healthcheck.py

# Environment variables for CARLA
ENV CARLA_ROOT=/home/carla
ENV SDL_VIDEODRIVER=offscreen
ENV DISPLAY=:0
ENV UE4_PROJECT_ROOT=/home/carla

# Expose ports
# 2000-2002: CARLA server ports
# 8000-8002: Traffic Manager ports
EXPOSE 2000 2001 2002 8000 8001 8002

# Set working directory
WORKDIR /home/carla

# Switch to carla user
USER carla

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python3 /usr/local/bin/healthcheck.py

# Entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command - can be overridden
CMD ["./CarlaUE4.sh", "-quality-level=Low", "-RenderOffScreen", "-nosound"]