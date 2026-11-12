#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GUI="${GUI:-1}"
mkdir -p logs ../results
rm -rf xcelium.d INCA_libs *.shm *.dsn *.trn

ARGS=(
  -64bit
  -sv
  -access +rwc
  -linedebug
  -f filelist.f
  -top tb_adaptive
  -l logs/xrun.log
)

if [[ "$GUI" == "1" ]]; then
  ARGS+=( -gui )
fi

echo "============================================================"
echo " HYBRID ADAPTIVE SCAN TESTING"
echo "============================================================"
echo " Top      : tb_adaptive"
echo " Filelist : $(pwd)/filelist.f"
echo " GUI      : $GUI"
echo "============================================================"

xrun "${ARGS[@]}" "$@"
