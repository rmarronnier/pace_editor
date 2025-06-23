#!/bin/bash
# Build script for PACE Editor with audio support
set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building PACE Editor...${NC}"

# Check if Crystal is installed
if ! command -v crystal &> /dev/null; then
    echo -e "${RED}❌ Error: Crystal is not installed or not in PATH${NC}"
    echo "Please install Crystal from: https://crystal-lang.org/install/"
    exit 1
fi

# Check Crystal version
CRYSTAL_VERSION=$(crystal version | head -n1 | cut -d' ' -f2)
echo "Using Crystal version: $CRYSTAL_VERSION"

# Check for required dependencies
echo "Checking dependencies..."

# Check if lib directory exists
if [ ! -d "lib" ]; then
    echo -e "${YELLOW}⚠️  Warning: lib directory not found. Running 'shards install'...${NC}"
    if ! shards install; then
        echo -e "${RED}❌ Error: Failed to install dependencies${NC}"
        exit 1
    fi
fi

# Check if miniaudiohelpers library exists
MINIAUDIO_LIB_PATH="${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"
if [ ! -d "$MINIAUDIO_LIB_PATH" ]; then
    echo -e "${RED}❌ Error: miniaudiohelpers library not found at $MINIAUDIO_LIB_PATH${NC}"
    echo "Please ensure raylib-cr dependency is properly installed"
    exit 1
fi

if [ ! -f "$MINIAUDIO_LIB_PATH/libminiaudiohelpers.a" ]; then
    echo -e "${YELLOW}⚠️  Warning: libminiaudiohelpers.a not found. This may cause linking issues.${NC}"
fi

# Set library path for miniaudiohelpers
export LIBRARY_PATH="$LIBRARY_PATH:$MINIAUDIO_LIB_PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$MINIAUDIO_LIB_PATH"

echo -e "${YELLOW}Library paths configured:${NC}"
echo "LIBRARY_PATH: $LIBRARY_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# Parse build arguments
BUILD_ARGS="$@"
if [ -z "$BUILD_ARGS" ]; then
    BUILD_ARGS="src/pace_editor.cr"
fi

echo -e "${YELLOW}Building with arguments: $BUILD_ARGS${NC}"

# Build with audio support by default
echo -e "${YELLOW}Starting Crystal build...${NC}"
if crystal build $BUILD_ARGS -Dwith_audio; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    # Show build output info
    if [ -f "pace_editor" ]; then
        BUILD_SIZE=$(ls -lah pace_editor | cut -d' ' -f5)
        echo -e "${GREEN}📦 Binary size: $BUILD_SIZE${NC}"
        echo -e "${GREEN}📁 Output: $(pwd)/pace_editor${NC}"
    fi
    
    echo -e "${GREEN}🎉 PACE Editor is ready to use!${NC}"
    echo -e "${YELLOW}Run with: ./pace_editor${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "1. Ensure all dependencies are installed with 'shards install'"
    echo "2. Check that Crystal version is 1.16.3 or higher"
    echo "3. Verify raylib system dependencies are installed"
    echo "4. Try running './run.sh' instead for automatic environment setup"
    exit 1
fi