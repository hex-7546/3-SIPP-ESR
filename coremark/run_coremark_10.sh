#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Building CoreMark for simulation (10 iterations)..."
./src/build_coremark.sh 10

if [ ! -f ../sim/tb_three_sipp_esr ]; then
  echo "Building 3-SIPP-ESR simulator with Verilator..."
  (cd .. && bash build.sh sim)
fi

echo "Running CoreMark on 3-SIPP-ESR simulation..."
log=$(mktemp)
../sim/tb_three_sipp_esr +IMEM=src/coremark.hex | tee "$log"
# the run must end with the testbench's PASS verdict (tohost = 1)
if grep -qE 'FAIL|TIMEOUT' "$log" || ! grep -q '^\[TB\] PASS' "$log"; then
  rm -f "$log"; echo "CoreMark: FAIL (no [TB] PASS verdict)"; exit 1
fi
rm -f "$log"
