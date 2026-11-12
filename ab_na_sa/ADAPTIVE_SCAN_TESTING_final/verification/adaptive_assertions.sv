// ============================================================================
// Lightweight assertions.
// ============================================================================
module adaptive_assertions (
    input logic        clk,
    input logic        reset,
    input logic        scan_enable,
    input logic        test_complete,
    input logic [7:0]  coverage,
    input logic [31:0] energy,
    input logic [31:0] energy_budget,
    input logic [1:0]  decision,
    input logic [31:0] priority_threshold,
    input logic        high_priority
);

    property p_complete_implies_scan_off;
        @(posedge clk) disable iff (reset) test_complete |-> !scan_enable;
    endproperty

    property p_coverage_range;
        @(posedge clk) disable iff (reset) coverage <= 8'd100;
    endproperty

    property p_energy_monotonic;
        @(posedge clk) disable iff (reset) energy >= $past(energy);
    endproperty

    property p_high_after_threshold;
        @(posedge clk) disable iff (reset)
            (energy < priority_threshold && decision != 2'd2) |-> !high_priority;
    endproperty

    assert property (p_complete_implies_scan_off)
        else $error("ASSERTION FAILED: scan enabled after completion");
    assert property (p_coverage_range)
        else $error("ASSERTION FAILED: coverage exceeded 100%%");
    assert property (p_energy_monotonic)
        else $error("ASSERTION FAILED: energy decreased");
    assert property (p_high_after_threshold)
        else $error("ASSERTION FAILED: high-priority mode before 70%% threshold");
endmodule
