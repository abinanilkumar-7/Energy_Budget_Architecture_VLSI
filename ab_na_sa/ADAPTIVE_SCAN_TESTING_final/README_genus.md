# Genus setup for ADAPTIVE_SCAN_TESTING

## Synthesis top

`adaptive_design_top`

## Do NOT synthesize

- `tb_adaptive.sv`
- `reference_model.v`
- `verification/adaptive_assertions.sv`
- `verification/coverage.sv`
- `atpg/adaptive_atpg.sv`

The ATPG is simulation/test-side in the current architecture.

## Before running

Set the actual Liberty standard-cell library:

### tcsh/csh
```
setenv STD_CELL_LIB /absolute/path/to/your/stdcells.lib
```

### bash
```
export STD_CELL_LIB=/absolute/path/to/your/stdcells.lib
```

## Run with GUI

```
cd genus
./run_genus.sh
```

or directly:

```
genus -gui -files genus_run.tcl
```

## Generated reports

- `reports/check_design.rpt`
- `reports/check_design_unresolved.rpt`
- `reports/check_timing.rpt`
- `reports/timing_lint.rpt`
- `reports/area.rpt`
- `reports/gates.rpt`
- `reports/timing.rpt`
- `reports/qor.rpt`
- `reports/power.rpt`
- `reports/input_to_register.rpt`
- `reports/register_to_register.rpt`
- `reports/register_to_output.rpt`

## Generated outputs

- `outputs/adaptive_design_top_netlist.v`
- `outputs/adaptive_design_top.sdc`
- `outputs/adaptive_design_top_synthesis.script`
- `outputs/adaptive_design_top.db`

The Liberty library and technology-specific files must come from the user's Cadence/technology installation; they are intentionally not included here.
