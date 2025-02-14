# Use Alpine as the base for static linking
FROM alpine:latest AS builder

WORKDIR /python-build

# Install required dependencies
RUN apk add --no-cache \
    build-base \
    musl-dev \
    musl-utils \
    linux-headers \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    ncurses-dev \
    readline-dev \
    sqlite-dev \
    openssl-dev \
    libffi-dev \
    libressl-dev \
    tcl-dev \
    tk-dev \
    wget \
    curl \
    git \
    bash

# Define Python version
ENV PYTHON_VERSION=3.13.2

# Download and extract Python source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz && \
    tar -xf Python-${PYTHON_VERSION}.tar.xz && \
    rm -f Python-${PYTHON_VERSION}.tar.xz

WORKDIR /python-build/Python-${PYTHON_VERSION}

# Configure for static build
RUN ./configure \
    --prefix=/opt/python-static \
    --enable-optimizations \
    --enable-shared \
    --disable-ipv6 \
    --with-ensurepip=install \
    --disable-gil \
    --enable-experimental-jit \
    LDFLAGS="-static" \
    CFLAGS="-static -static-libgcc -static-libstdc++"

# Compile and install
RUN make -j$(nproc) && make install

# Install staticx and create static binary
RUN apk add --no-cache python3 py3-pip && \
    pip3 install staticx && \
    staticx /opt/python-static/bin/python3 /opt/python-static/python3-static

# Reduce binary size
RUN strip /opt/python-static/python3-static

# Copy the static binary for final use
FROM scratch AS final
COPY --from=builder /opt/python-static/python3-static /usr/bin/python3
ENTRYPOINT ["/usr/bin/python3"]