#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs reports outputs
: "${STD_CELL_LIB:?Set STD_CELL_LIB to your Liberty .lib file}"
genus -gui -files genus_run.tcl 2>&1 | tee logs/genus.log
