#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p logs reports outputs

if [[ -z "${STD_CELL_LIB:-}" ]]; then
    echo "ERROR: STD_CELL_LIB is not set."
    echo "Set it to your actual Liberty .lib file before running Genus."
    echo "Example (bash): export STD_CELL_LIB=/path/to/stdcells.lib"
    echo "Example (tcsh): setenv STD_CELL_LIB /path/to/stdcells.lib"
    exit 2
fi

if [[ ! -f "$STD_CELL_LIB" ]]; then
    echo "ERROR: Liberty file not found: $STD_CELL_LIB"
    exit 2
fi

echo "============================================================"
echo " GENUS ADAPTIVE SCAN SYNTHESIS"
echo "============================================================"
echo " Top      : adaptive_design_top"
echo " Library  : $STD_CELL_LIB"
echo " GUI      : 1"
echo "============================================================"

genus -gui -files genus_run.tcl 2>&1 | tee logs/genus.log
