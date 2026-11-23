#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ITERATIONS="${1:-1000}"

echo "Building CoreMark for 3-SIPP-ESR on Artix-7 100T (${ITERATIONS} iterations)..."
./src/build_coremark.sh "${ITERATIONS}"

BUILD_DIR="../fpga/arty_a7/build"
mkdir -p "${BUILD_DIR}"
cp src/coremark.hex "${BUILD_DIR}/firmware.mem"

echo "Running Vivado synthesis for Arty A7-100T..."
cd ../fpga/arty_a7

VIVADO_SETTINGS="${VIVADO_SETTINGS:-/home/hex/Vivado/2023.2/settings64.sh}"
if [ -f "$VIVADO_SETTINGS" ]; then
    source "$VIVADO_SETTINGS"
fi

if ! command -v vivado &> /dev/null; then
    echo "ERROR: vivado not found in PATH."
    exit 1
fi

vivado -mode batch -source three_sipp_esr_arty_a7.tcl -tclargs build
echo "Bitstream generated at fpga/arty_a7/build/three_sipp_esr_arty_a7.bit"
