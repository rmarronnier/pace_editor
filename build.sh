#!/bin/bash
# Build script for PACE Editor with audio support

# Set library path for miniaudiohelpers
export LIBRARY_PATH="$LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"

# Build with audio support by default
crystal build "$@" -Dwith_audio