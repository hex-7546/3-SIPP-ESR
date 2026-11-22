#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Building CoreMark for simulation (100 iterations)..."
./src/build_coremark.sh 100

if [ ! -f ../obj_dir/Vtb_three_sipp_esr ]; then
  echo "Building 3-SIPP-ESR simulator with Verilator..."
  cd ..
  verilator --binary --timing --top tb_three_sipp_esr -Wno-fatal -Irtl/common -Irtl rtl/common/three_sipp_esr_pkg.sv rtl/common/three_sipp_esr_alu.sv rtl/common/three_sipp_esr_regfile.sv rtl/common/three_sipp_esr_muldiv.sv rtl/common/three_sipp_esr_csr.sv rtl/common/three_sipp_esr_rvc.sv rtl/common/three_sipp_esr_immgen.sv rtl/common/three_sipp_esr_branch.sv rtl/common/three_sipp_esr_decode.sv rtl/common/three_sipp_esr_pmp.sv rtl/three_sipp_esr_debug.sv rtl/three_sipp_esr_core.sv rtl/three_sipp_esr_uart.sv rtl/three_sipp_esr_soc.sv tb/tb_three_sipp_esr.sv
  cd -
fi

echo "Running CoreMark on 3-SIPP-ESR simulation..."
log=$(mktemp)
../obj_dir/Vtb_three_sipp_esr +IMEM=src/coremark.hex | tee "$log"
# the run must end with the testbench's PASS verdict (tohost = 1)
if grep -qE 'FAIL|TIMEOUT' "$log" || ! grep -q '^\[TB\] PASS' "$log"; then
  rm -f "$log"; echo "CoreMark: FAIL (no [TB] PASS verdict)"; exit 1
fi
rm -f "$log"
