#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
GUI="${GUI:-1}"
mkdir -p logs ../results
rm -rf xcelium.d INCA_libs *.shm *.dsn *.trn
ARGS=(-64bit -sv -access +rwc -linedebug -f filelist.f -top tb_conventional -l logs/xrun.log)
[[ "$GUI" == "1" ]] && ARGS+=( -gui )
echo "============================================================"
echo " CONVENTIONAL SCAN TESTING ONLY"
echo "============================================================"
xrun "${ARGS[@]}" "$@"
