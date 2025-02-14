#!/bin/bash
# build-python.sh

set -e

ARCHITECTURES=("x86_64" "aarch64")
PYTHON_VERSION="3.13.2"

for arch in "${ARCHITECTURES[@]}"; do
    echo "Building Python for $arch..."
    docker buildx build --platform linux/$arch -t python-builder-$arch .
    docker run --rm -v $(pwd)/output/$arch:/output python-builder-$arch
done

echo "Build complete. Archives are in the output directory."