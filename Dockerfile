FROM --platform=$BUILDPLATFORM ubuntu:22.04 AS builder

WORKDIR /python-build

# Install dependencies
RUN apt update && apt install -y \
    build-essential \
    musl-dev \
    musl-tools \
    zlib1g-dev \
    libbz2-dev \
    libsqlite3-dev \
    libssl-dev \
    libffi-dev \
    libreadline-dev \
    liblzma-dev \
    wget \
    curl \
    git \
    bash

# Set Python version
ENV PYTHON_VERSION=3.13.2

# Download and extract Python source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz && \
    tar -xf Python-${PYTHON_VERSION}.tar.xz && \
    rm -f Python-${PYTHON_VERSION}.tar.xz

WORKDIR /python-build/Python-${PYTHON_VERSION}

# Configure Python for static build
RUN ./configure \
    --prefix=/opt/python-static \
    --enable-optimizations \
    --disable-ipv6 \
    --enable-loadable-sqlite-extensions \
    --disable-gil \
    --enable-experimental-jit \
    CC=musl-gcc \
    CFLAGS="-static" \
    LDFLAGS="-static"

# Compile and install
RUN make -j$(nproc) && make install

# Strip binary to reduce size
RUN strip /opt/python-static/bin/python3

# Final minimal image
FROM scratch AS final
COPY --from=builder /opt/python-static/bin/python3 /usr/bin/python3
ENTRYPOINT ["/usr/bin/python3"]