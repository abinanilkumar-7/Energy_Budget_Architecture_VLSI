
# XM-Sim Command File
# TOOL:	xmsim(64)	22.09-s003
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
set vcd_compact_mode 0
alias . run
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves tb_conventional.activity tb_conventional.activity_delta tb_conventional.actual_y tb_conventional.b tb_conventional.clk tb_conventional.coverage tb_conventional.csv_fd tb_conventional.detected_faults tb_conventional.detected_map tb_conventional.energy tb_conventional.energy_increment tb_conventional.f tb_conventional.fault_detected tb_conventional.fault_enable tb_conventional.fault_index tb_conventional.golden_y tb_conventional.p tb_conventional.patterns_run tb_conventional.reset tb_conventional.response_valid tb_conventional.result_fd tb_conventional.scan_data tb_conventional.scan_enable tb_conventional.scan_in tb_conventional.scan_out

simvision -input /home/user/ab_na_sa/CONVENTIONAL_SCAN_TESTING/sim/.simvision/56526_user_cadence_autosave.tcl.svcf
