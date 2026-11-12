// ================================================================
// Conventional scan baseline.
// Uses the same CUT/fault model/activity/energy model as the adaptive
// architecture, but applies externally supplied patterns in a fixed
// order with no adaptive decision.
// ================================================================
module conventional_top #(
    parameter integer WIDTH = 8,
    parameter integer TOTAL_FAULTS = 20,
    parameter integer ENERGY_PER_TRANSITION = 1
)(
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         scan_enable,
    input  wire                         scan_in,
    input  wire                         response_valid,
    input  wire                         fault_enable,
    input  wire [4:0]                   fault_index,
    input  wire                         golden_y,

    output wire                         scan_out,
    output wire [WIDTH-1:0]             scan_data,
    output wire [31:0]                  activity,
    output wire [31:0]                  activity_delta,
    output wire [31:0]                  energy,
    output wire [31:0]                  energy_increment,
    output wire                         actual_y,
    output wire                         fault_detected,
    output wire [7:0]                   detected_faults,
    output wire [7:0]                   coverage,
    output wire [TOTAL_FAULTS-1:0]      detected_map
);

    scan_chain #(.WIDTH(WIDTH)) u_scan_chain (
        .clk        (clk),
        .reset      (reset),
        .scan_enable(scan_enable),
        .scan_in    (scan_in),
        .scan_out   (scan_out),
        .scan_data  (scan_data)
    );

    activity_monitor #(.WIDTH(WIDTH)) u_activity (
        .clk             (clk),
        .reset           (reset),
        .data_in         (scan_data),
        .transition_count(activity_delta),
        .activity_count   (activity)
    );

    energy_monitor #(
        .ENERGY_PER_TRANSITION(ENERGY_PER_TRANSITION)
    ) u_energy (
        .clk              (clk),
        .reset            (reset),
        .transition_count (activity_delta),
        .energy           (energy),
        .energy_increment (energy_increment)
    );

    faulty_cut u_faulty_cut (
        .a           (scan_data[0]),
        .b           (scan_data[1]),
        .c           (scan_data[2]),
        .d           (scan_data[3]),
        .e           (scan_data[4]),
        .fault_enable(fault_enable),
        .fault_index (fault_index),
        .y           (actual_y)
    );

    fault_detector u_detector (
        .actual_output (actual_y),
        .golden_output (golden_y),
        .response_valid(response_valid),
        .fault_enable  (fault_enable),
        .fault_detected(fault_detected)
    );

    fault_coverage #(
        .TOTAL_FAULTS(TOTAL_FAULTS)
    ) u_coverage (
        .clk            (clk),
        .reset          (reset),
        .fault_detected (fault_detected),
        .fault_index    (fault_index),
        .detected_faults(detected_faults),
        .coverage       (coverage),
        .detected_map   (detected_map)
    );

endmodule
