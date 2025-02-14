# Dockerfile
FROM ubuntu:20.04 AS builder

# Set non-interactive frontend for apt to avoid tzdata prompt
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure tzdata
RUN echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections && \
    echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    tk-dev \
    libffi-dev \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Python source
ARG PYTHON_VERSION=3.13.2
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xzf Python-${PYTHON_VERSION}.tgz && \
    rm Python-${PYTHON_VERSION}.tgz

# Build Python with custom configurations
WORKDIR /Python-${PYTHON_VERSION}
RUN ./configure \
    --enable-optimizations \
    --enable-shared \
    --disable-gil \
    --enable-experimental-jit && \
    make -j$(nproc) && \
    make install

# Create a static binary
RUN mkdir /python-static && \
    cp -r /usr/local/bin/python3 /python-static/ && \
    cp -r /usr/local/lib/libpython3.* /python-static/

# Archive the static binary
WORKDIR /python-static
RUN tar -czf python-${PYTHON_VERSION}-static-$(uname -m).tar.gz *

# Output the archive
VOLUME /output
CMD cp python-${PYTHON_VERSION}-static-$(uname -m).tar.gz /output/