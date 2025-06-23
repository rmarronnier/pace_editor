#!/bin/bash
# Run script for PACE Editor with audio support
set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running PACE Editor...${NC}"

# Check if Crystal is installed
if ! command -v crystal &> /dev/null; then
    echo -e "${RED}❌ Error: Crystal is not installed or not in PATH${NC}"
    echo "Please install Crystal from: https://crystal-lang.org/install/"
    exit 1
fi

# Check for required dependencies
if [ ! -d "lib" ]; then
    echo -e "${YELLOW}⚠️  Installing dependencies...${NC}"
    if ! shards install; then
        echo -e "${RED}❌ Error: Failed to install dependencies${NC}"
        exit 1
    fi
fi

# Check if miniaudiohelpers library exists
MINIAUDIO_LIB_PATH="${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"
if [ ! -d "$MINIAUDIO_LIB_PATH" ]; then
    echo -e "${RED}❌ Error: miniaudiohelpers library not found${NC}"
    echo "Please run 'shards install' to install dependencies"
    exit 1
fi

# Set library path for miniaudiohelpers
export LIBRARY_PATH="$LIBRARY_PATH:$MINIAUDIO_LIB_PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$MINIAUDIO_LIB_PATH"

# Parse run arguments
RUN_ARGS="$@"
if [ -z "$RUN_ARGS" ]; then
    RUN_ARGS="src/pace_editor.cr"
fi

echo -e "${YELLOW}Environment configured, starting PACE Editor...${NC}"

# Run with audio support by default
if crystal run $RUN_ARGS -Dwith_audio; then
    echo -e "${GREEN}✅ PACE Editor exited successfully${NC}"
else
    EXIT_CODE=$?
    echo -e "${RED}❌ PACE Editor exited with error code: $EXIT_CODE${NC}"
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "1. Check that all system dependencies are installed"
    echo "2. Verify raylib is properly installed on your system"
    echo "3. Try building first with './build.sh' to check for compilation errors"
    exit $EXIT_CODE
fi