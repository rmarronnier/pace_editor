#!/bin/bash

# CI-friendly spec runner that runs only headless tests

echo "Running PACE Editor CI Test Suite"
echo "================================="
echo

# Set headless mode
export HEADLESS_SPECS=true

# Find and run all non-graphics specs
spec_files=""

# Core specs
for f in spec/core/*.cr spec/core/**/*.cr; do
  [ -f "$f" ] && spec_files="$spec_files $f"
done

# Model specs
for f in spec/models/*.cr spec/models/**/*.cr; do
  [ -f "$f" ] && spec_files="$spec_files $f"
done

# Validation specs
for f in spec/validation/*.cr spec/validation/**/*.cr; do
  [ -f "$f" ] && spec_files="$spec_files $f"
done

# Export specs
for f in spec/export/*.cr spec/export/**/*.cr; do
  [ -f "$f" ] && spec_files="$spec_files $f"
done

# UI logic and headless specs
for f in spec/ui/*_logic_spec.cr spec/ui/*_fixed_spec.cr spec/ui/*_headless_spec.cr; do
  [ -f "$f" ] && spec_files="$spec_files $f"
done

# Run the specs
crystal spec $spec_files --verbose