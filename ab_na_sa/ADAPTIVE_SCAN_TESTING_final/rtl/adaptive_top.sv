// ============================================================================
// Adaptive scan design-side top
// One shared scan chain + CUT + fault monitor + energy monitor.
// ATPG itself is testbench/simulation-side.
// ============================================================================
module adaptive_top #(
    parameter integer WIDTH = 8,
    parameter integer TOTAL_FAULTS = 20,
    parameter integer ENERGY_PER_TRANSITION = 1,
    parameter [7:0] ACCEPTABLE_COVERAGE = 8'd95,
    parameter [7:0] STOP_COVERAGE       = 8'd100,
    parameter [7:0] PRIORITY_PERCENT    = 8'd70
)(
    input  logic                         clk,
    input  logic                         reset,
    input  logic                         pattern_valid,
    input  logic [WIDTH-1:0]             test_pattern,
    input  logic [4:0]                   target_fault,
    input  logic                         atpg_done,
    input  logic                         fault_enable,
    input  logic                         golden_y,
    input  logic [31:0]                  energy_budget,

    output logic                         scan_out,
    output logic                         scan_in,
    output logic                         scan_enable,
    output logic [WIDTH-1:0]             scan_data,
    output logic [31:0]                  activity,
    output logic [31:0]                  activity_delta,
    output logic [31:0]                  energy,
    output logic [31:0]                  energy_increment,
    output logic                         actual_y,
    output logic                         fault_detected,
    output logic [7:0]                   detected_faults,
    output logic [7:0]                   coverage,
    output logic [TOTAL_FAULTS-1:0]      detected_map,
    output logic [1:0]                   decision,
    output logic                         high_priority,
    output logic                         adaptive_mode,
    output logic                         acceptable_reached,
    output logic                         full_coverage,
    output logic                         budget_exhausted,
    output logic                         test_complete,
    output logic                         pattern_done,
    output logic                         atpg_done_seen,
    output logic [31:0]                  priority_threshold,
    output logic [4:0]                   active_fault
);

    logic stop_request;
    logic response_valid_d1, response_valid_d2;

    assign priority_threshold = (energy_budget * PRIORITY_PERCENT) / 100;
    assign high_priority      = (decision == 2'd1);
    assign stop_request       = (decision == 2'd2) || atpg_done;

    // Delay response checking enough to allow the final scan shift to settle.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            response_valid_d1 <= 1'b0;
            response_valid_d2 <= 1'b0;
        end
        else begin
            response_valid_d1 <= pattern_done;
            response_valid_d2 <= response_valid_d1;
        end
    end

    assign atpg_done_seen = atpg_done;

    adaptive_controller u_decision (
        .energy_used         (energy),
        .energy_budget       (energy_budget),
        .fault_coverage      (coverage),
        .acceptable_coverage (ACCEPTABLE_COVERAGE),
        .stop_coverage       (STOP_COVERAGE),
        .priority_threshold  (priority_threshold),
        .decision            (decision),
        .acceptable_reached  (acceptable_reached),
        .budget_exhausted    (budget_exhausted),
        .full_coverage       (full_coverage)
    );

    adaptive_scan_controller #(.WIDTH(WIDTH)) u_scan_controller (
        .clk            (clk),
        .reset          (reset),
        .pattern_valid  (pattern_valid),
        .test_pattern   (test_pattern),
        .target_fault   (target_fault),
        .stop_request   (stop_request),
        .high_priority  (high_priority),
        .scan_enable    (scan_enable),
        .scan_in        (scan_in),
        .pattern_done   (pattern_done),
        .test_complete  (test_complete),
        .adaptive_mode  (adaptive_mode),
        .active_fault   (active_fault)
    );

    scan_chain #(.WIDTH(WIDTH)) u_scan_chain (
        .clk         (clk),
        .reset       (reset),
        .scan_enable (scan_enable),
        .scan_in     (scan_in),
        .scan_out    (scan_out),
        .scan_data   (scan_data)
    );

    activity_monitor #(.WIDTH(WIDTH)) u_activity (
        .clk              (clk),
        .reset            (reset),
        .data_in          (scan_data),
        .transition_count (activity_delta),
        .activity_count   (activity)
    );

    energy_monitor #(.ENERGY_PER_TRANSITION(ENERGY_PER_TRANSITION)) u_energy (
        .clk              (clk),
        .reset            (reset),
        .transition_count (activity_delta),
        .energy           (energy),
        .energy_increment (energy_increment)
    );

    faulty_cut u_faulty_cut (
        .a            (scan_data[0]),
        .b            (scan_data[1]),
        .c            (scan_data[2]),
        .d            (scan_data[3]),
        .e            (scan_data[4]),
        .fault_enable (fault_enable),
        .fault_index  (active_fault),
        .y            (actual_y)
    );

    fault_detector u_detector (
        .actual_output  (actual_y),
        .golden_output  (golden_y),
        .response_valid (response_valid_d2),
        .fault_enable   (fault_enable),
        .fault_detected (fault_detected)
    );

    fault_coverage #(.TOTAL_FAULTS(TOTAL_FAULTS)) u_coverage (
        .clk             (clk),
        .reset           (reset),
        .fault_detected  (fault_detected),
        .fault_index     (active_fault),
        .detected_faults (detected_faults),
        .coverage        (coverage),
        .detected_map    (detected_map)
    );
endmodule
