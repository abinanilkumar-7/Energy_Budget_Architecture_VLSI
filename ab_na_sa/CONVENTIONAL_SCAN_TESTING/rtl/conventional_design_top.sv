module conventional_design_top #(
    parameter integer WIDTH = 8,
    parameter integer TOTAL_FAULTS = 20,
    parameter integer ENERGY_PER_TRANSITION = 1
)(
    input wire clk,
    input wire reset,
    input wire scan_enable,
    input wire scan_in,
    input wire response_valid,
    input wire fault_enable,
    input wire [4:0] fault_index,
    input wire golden_y,
    output wire scan_out,
    output wire [WIDTH-1:0] scan_data,
    output wire [31:0] activity,
    output wire [31:0] activity_delta,
    output wire [31:0] energy,
    output wire [31:0] energy_increment,
    output wire actual_y,
    output wire fault_detected,
    output wire [7:0] detected_faults,
    output wire [7:0] coverage,
    output wire [TOTAL_FAULTS-1:0] detected_map
);
    conventional_top #(
        .WIDTH(WIDTH),
        .TOTAL_FAULTS(TOTAL_FAULTS),
        .ENERGY_PER_TRANSITION(ENERGY_PER_TRANSITION)
    ) u_conventional (.*);
endmodule
