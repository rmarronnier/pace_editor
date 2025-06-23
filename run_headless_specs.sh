#!/bin/bash

# Simple headless spec runner

echo "Running Headless Specs"
echo "====================="
echo

# Set headless mode
export HEADLESS_SPECS=true

# Run headless specs with a count at the end
crystal spec spec --tag "~graphics" 2>&1 | grep -E "examples|failures|errors|pending|Finished"