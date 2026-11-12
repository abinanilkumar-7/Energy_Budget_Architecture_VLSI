# ============================================================================
# Genus synthesis script
# Project : ENERGY-BUDGET-CONSTRAINED ADAPTIVE SCAN TESTING
# Top     : adaptive_design_top
#
# IMPORTANT:
#   This is the SYNTHESIS/DESIGN flow only.
#   Do NOT include tb_adaptive.sv, reference_model.v, assertions.sv,
#   coverage.sv, or the adaptive ATPG testbench model here.
# ============================================================================

set TOP adaptive_design_top
set ROOT [file normalize [file dirname [info script]]]
set RTL  [file join $ROOT rtl]
set ATPG [file join $ROOT atpg]
set CONSTRAINTS [file join [file dirname [info script]] constraints]
set REPORTS [file join [file dirname [info script]] reports]
set OUTPUTS [file join [file dirname [info script]] outputs]

file mkdir $REPORTS
file mkdir $OUTPUTS

# --------------------------------------------------------------------------
# Standard-cell Liberty library
# Set this environment variable before starting Genus:
#   setenv STD_CELL_LIB /path/to/your/stdcells.lib    # csh/tcsh
#   export STD_CELL_LIB=/path/to/your/stdcells.lib    # bash
# --------------------------------------------------------------------------
if {![info exists ::env(STD_CELL_LIB)] || $::env(STD_CELL_LIB) eq ""} {
    puts "ERROR: STD_CELL_LIB is not set."
    puts "Example: setenv STD_CELL_LIB /path/to/stdcells.lib"
    exit 2
}

set LIB [file normalize $::env(STD_CELL_LIB)]
if {![file exists $LIB]} {
    puts "ERROR: Liberty file does not exist: $LIB"
    exit 2
}

puts "============================================================"
puts " GENUS ADAPTIVE SCAN SYNTHESIS"
puts "============================================================"
puts "Top      : $TOP"
puts "RTL      : $RTL"
puts "Library  : $LIB"
puts "============================================================"

# --------------------------------------------------------------------------
# Library setup
# --------------------------------------------------------------------------
set_db init_lib_search_path [file dirname $LIB] 
set_db library [file tail $LIB] 

# --------------------------------------------------------------------------
# Read ONLY synthesizable design RTL required by adaptive_design_top.
# adaptive_atpg.sv is intentionally NOT included because ATPG is simulation/
# verification-side in this architecture.
# --------------------------------------------------------------------------
read_hdl -sv [list \
    [file join $RTL cut.v] \
    [file join $RTL scan_chain.v] \
    [file join $RTL activity_monitor.v] \
    [file join $RTL energy_monitor.v] \
    [file join $RTL fault_injection.v] \
    [file join $RTL faulty_cut.sv] \
    [file join $RTL fault_detector.v] \
    [file join $RTL fault_coverage.v] \
    [file join $RTL adaptive_controller.v] \
    [file join $RTL adaptive_scan_controller.sv] \
    [file join $RTL adaptive_top.sv] \
    [file join $RTL adaptive_design_top.sv] \
]

# --------------------------------------------------------------------------
# Elaborate the actual synthesis top
# --------------------------------------------------------------------------
elaborate $TOP

# --------------------------------------------------------------------------
# Basic design checks before constraints/synthesis
# --------------------------------------------------------------------------
check_design -unresolved > [file join $REPORTS check_design_unresolved.rpt]
check_design > [file join $REPORTS check_design.rpt]

# --------------------------------------------------------------------------
# Read timing constraints
# --------------------------------------------------------------------------
read_sdc [file join $CONSTRAINTS design_top.sdc]

# --------------------------------------------------------------------------
# Timing/constraint sanity check
# --------------------------------------------------------------------------
check_timing > [file join $REPORTS check_timing.rpt]
report timing -lint > [file join $REPORTS timing_lint.rpt]

# --------------------------------------------------------------------------
# Synthesis
# --------------------------------------------------------------------------
set_db syn_generic_effort medium 
set_db syn_map_effort medium 
set_db syn_opt_effort medium 

syn_generic
syn_map
syn_opt

# --------------------------------------------------------------------------
# Reports
# --------------------------------------------------------------------------
report_area -hierarchical > [file join $REPORTS area.rpt]
report_gates > [file join $REPORTS gates.rpt]
report_timing -max_paths 20 -path_type full_clock > [file join $REPORTS timing.rpt]
report_qor > [file join $REPORTS qor.rpt]
report_power > [file join $REPORTS power.rpt]

# Useful timing breakdown reports
report_timing -from [all_inputs] -to [all_registers] > [file join $REPORTS input_to_register.rpt]
report_timing -from [all_registers] -to [all_registers] > [file join $REPORTS register_to_register.rpt]
report_timing -from [all_registers] -to [all_outputs] > [file join $REPORTS register_to_output.rpt]

# --------------------------------------------------------------------------
# Outputs for next stage (STA / Innovus)
# --------------------------------------------------------------------------
write_hdl > [file join $OUTPUTS ${TOP}_netlist.v]
write_sdc > [file join $OUTPUTS ${TOP}.sdc]
write_script > [file join $OUTPUTS ${TOP}_synthesis.script]
write_db [file join $OUTPUTS ${TOP}.db]

puts "============================================================"
puts " GENUS SYNTHESIS COMPLETED"
puts "============================================================"
puts "Reports written to: $REPORTS"
puts "Netlist written to: [file join $OUTPUTS ${TOP}_netlist.v]"
puts "SDC written to     : [file join $OUTPUTS ${TOP}.sdc]"
puts "============================================================"

# Keep GUI open because this script is launched with genus -gui.
gui_show
