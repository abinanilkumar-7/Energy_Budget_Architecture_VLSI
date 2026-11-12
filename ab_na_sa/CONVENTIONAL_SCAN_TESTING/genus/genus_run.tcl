set TOP conventional_design_top
set RTL [file normalize ../rtl]
set LIB $::env(STD_CELL_LIB)
set_db init_lib_search_path [file dirname $LIB] 
set_db library [file tail $LIB] 
read_hdl -sv [list \
  $RTL/scan_chain.v $RTL/activity_monitor.v $RTL/energy_monitor.v \
  $RTL/fault_injection.v $RTL/faulty_cut.sv $RTL/fault_detector.v $RTL/fault_coverage.v \
  $RTL/conventional_top.v $RTL/conventional_design_top.sv ]
elaborate $TOP
current_design $TOP
check_design > reports/check_design.rpt
check_design -unresolved > reports/unresolved.rpt
check_timing > reports/check_timing.rpt
read_sdc ../constraints/conventional_design.sdc
syn_generic
syn_map
syn_opt
report_area -hierarchical > reports/area.rpt
report_timing -max_paths 20 -path_type full_clock > reports/timing.rpt
report_qor > reports/qor.rpt
report_power > reports/power.rpt
write_hdl > outputs/conventional_design_netlist.v
write_sdc > outputs/conventional_design.sdc
write_db outputs/conventional_design.db
exit
