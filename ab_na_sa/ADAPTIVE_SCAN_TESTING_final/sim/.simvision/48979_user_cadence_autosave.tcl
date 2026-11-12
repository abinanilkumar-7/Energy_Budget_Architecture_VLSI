
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
probe -create -database waves tb_adaptive.acceptable_reached tb_adaptive.active_fault tb_adaptive.activity tb_adaptive.activity_delta tb_adaptive.actual_y tb_adaptive.adaptive_energy_added tb_adaptive.adaptive_mode tb_adaptive.adaptive_patterns_used tb_adaptive.atpg_budget_blocked tb_adaptive.atpg_done tb_adaptive.atpg_done_drive tb_adaptive.atpg_done_seen tb_adaptive.atpg_pattern_valid tb_adaptive.atpg_predicted_gain tb_adaptive.atpg_request tb_adaptive.atpg_score tb_adaptive.atpg_selected_cost tb_adaptive.atpg_target_fault tb_adaptive.atpg_test_pattern tb_adaptive.budget_exhausted tb_adaptive.clk tb_adaptive.conv_fault tb_adaptive.conv_pattern tb_adaptive.conv_pattern_valid tb_adaptive.conventional_patterns_used tb_adaptive.coverage tb_adaptive.csv_fd tb_adaptive.decision tb_adaptive.detected_faults tb_adaptive.detected_map tb_adaptive.energy tb_adaptive.energy_budget tb_adaptive.energy_budget_cfg tb_adaptive.energy_increment tb_adaptive.fault_detected tb_adaptive.fault_enable tb_adaptive.full_coverage tb_adaptive.golden_y tb_adaptive.high_priority tb_adaptive.issued_cost tb_adaptive.issued_fault tb_adaptive.issued_pattern tb_adaptive.issued_score tb_adaptive.pattern_done tb_adaptive.pattern_drive tb_adaptive.pattern_valid_drive tb_adaptive.phase_adaptive tb_adaptive.priority_threshold tb_adaptive.reset tb_adaptive.result_fd tb_adaptive.scan_data tb_adaptive.scan_enable tb_adaptive.scan_in tb_adaptive.scan_inputs tb_adaptive.scan_out tb_adaptive.switch_coverage tb_adaptive.switch_energy tb_adaptive.target_fault_drive tb_adaptive.test_complete tb_adaptive.test_phase tb_adaptive.total_patterns_used tb_adaptive.wait_cycles

simvision -input /home/user/ab_na_sa/ADAPTIVE_SCAN_TESTING_final/sim/.simvision/48979_user_cadence_autosave.tcl.svcf
