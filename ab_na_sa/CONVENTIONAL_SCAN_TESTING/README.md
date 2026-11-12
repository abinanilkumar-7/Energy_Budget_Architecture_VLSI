# CONVENTIONAL_SCAN_TESTING

Standalone conventional scan baseline only. No adaptive controller, adaptive
ATPG or adaptive top is instantiated.

Baseline:
- 20 modeled faults
- 32 fixed 5-bit patterns for each fault
- 640 pattern applications
- Same transition-based energy model as the adaptive project

Simulation:
    cd sim
    ./run.sh
    GUI=0 ./run.sh

Results:
    results/conventional_results.txt
    results/conventional_results.csv

Genus:
    export STD_CELL_LIB=/path/to/your/stdcells.lib
    cd genus
    ./run_genus.sh
