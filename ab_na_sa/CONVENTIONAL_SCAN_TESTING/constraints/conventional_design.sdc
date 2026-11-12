create_clock -name CLK -period 10.0 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks CLK]
set_input_delay 0.5 -clock CLK [get_ports {reset scan_enable scan_in response_valid fault_enable fault_index golden_y}]
set_output_delay 0.5 -clock CLK [get_ports {scan_out scan_data activity activity_delta energy energy_increment actual_y fault_detected detected_faults coverage detected_map}]
