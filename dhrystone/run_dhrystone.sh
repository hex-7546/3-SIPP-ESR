#!/usr/bin/env bash
# run_dhrystone.sh — build Dhrystone and run it on 3-SIPP-ESR simulation.
# Usage: ./run_dhrystone.sh [NUMBER_OF_RUNS]
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${1:-1000}"

echo "Building Dhrystone for simulation (${RUNS} runs)..."
./src/build_dhrystone.sh "${RUNS}"

if [ ! -f ../sim/tb_three_sipp_esr ]; then
  echo "Building 3-SIPP-ESR simulator with Verilator..."
  (cd .. && bash build.sh sim)
fi

echo "Running Dhrystone on 3-SIPP-ESR simulation..."
# cycle budget scales with the run count (about 330 cycles per run, plus setup)
MAXCYC=$(( RUNS * 500 + 20000000 ))
log=$(mktemp)
../sim/tb_three_sipp_esr +IMEM=src/dhrystone.hex +MAXCYCLES="$MAXCYC" | tee "$log"
# the run must end with the testbench's PASS verdict (tohost = 1)
if grep -qE 'FAIL|TIMEOUT' "$log" || ! grep -q '^\[TB\] PASS' "$log"; then
  rm -f "$log"; echo "Dhrystone: FAIL (no [TB] PASS verdict)"; exit 1
fi
rm -f "$log"
