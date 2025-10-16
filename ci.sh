#!/usr/bin/env bash
set -e

# Clean existing build directory
rm -rf build

# Create and enter build directory
mkdir build
cd build

# Run CMake configuration
cmake ..

# Build the project
cmake --build .

# Run tests
ctest --output-on-failure
