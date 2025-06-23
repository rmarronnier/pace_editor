#!/bin/bash

echo "Running PACE Editor Test Suite"
echo "=============================="
echo

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Run core and logic specs (no UI)
echo -e "${YELLOW}Running Core and Logic Specs...${NC}"
crystal spec spec/core/**/*_spec.cr spec/models/**/*_spec.cr spec/validation/**/*_spec.cr spec/export/**/*_spec.cr spec/ui/*_logic_spec.cr spec/ui/*_fixed_spec.cr --no-color

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Core and Logic specs passed${NC}"
else
    echo -e "${RED}✗ Core and Logic specs failed${NC}"
fi

echo

# Run headless UI specs
echo -e "${YELLOW}Running Headless UI Specs...${NC}"
crystal spec spec/ui/*_headless_spec.cr --no-color

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Headless UI specs passed${NC}"
else
    echo -e "${RED}✗ Headless UI specs failed${NC}"
fi

echo

# Run UI specs that require graphics (optional)
if [ "$1" == "--with-graphics" ]; then
    echo -e "${YELLOW}Running Graphics UI Specs...${NC}"
    crystal spec spec/ui/*_spec.cr --no-color | grep -v "_logic_spec.cr\|_fixed_spec.cr\|_headless_spec.cr"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Graphics UI specs passed${NC}"
    else
        echo -e "${RED}✗ Graphics UI specs failed${NC}"
    fi
else
    echo -e "${YELLOW}Skipping Graphics UI specs (use --with-graphics to run)${NC}"
fi

echo
echo "Test suite complete!"