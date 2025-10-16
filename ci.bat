@echo off
setlocal enabledelayedexpansion

REM Create and enter build directory
if not exist build mkdir build
cd build
if errorlevel 1 (
    echo Failed to create or enter build directory.
    exit /b 1
)

REM Run CMake configuration
cmake .. -G Ninja
if errorlevel 1 (
    echo CMake configuration failed.
    exit /b 1
)

REM Build the project
cmake --build .
if errorlevel 1 (
    echo Build failed.
    exit /b 1
)

REM Run tests
ctest --output-on-failure
if errorlevel 1 (
    echo Tests failed.
    exit /b 1
)

echo All steps completed successfully.
exit /b 0
