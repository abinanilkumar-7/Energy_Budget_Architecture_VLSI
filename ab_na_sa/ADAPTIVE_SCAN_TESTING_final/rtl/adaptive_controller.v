// ============================================================================
// Adaptive Decision Unit
//   0 = CONTINUE / normal scheduling
//   1 = HIGH_PRIORITY scheduling
//   2 = STOP
//
// Policy:
//   - <70% of budget: normal scheduling.
//   - >=70% of budget: high-priority scheduling.
//   - >=95% coverage: milestone only; continue if energy remains.
//   - 100% coverage: stop.
//   - Budget exhausted: stop.
// ============================================================================
module adaptive_controller #(
    parameter [1:0] DECISION_CONTINUE = 2'd0,
    parameter [1:0] DECISION_HIGH     = 2'd1,
    parameter [1:0] DECISION_STOP     = 2'd2
)(
    input  wire [31:0] energy_used,
    input  wire [31:0] energy_budget,
    input  wire [7:0]  fault_coverage,
    input  wire [7:0]  acceptable_coverage,
    input  wire [7:0]  stop_coverage,
    input  wire [31:0] priority_threshold,
    output reg  [1:0]  decision,
    output wire        acceptable_reached,
    output wire        budget_exhausted,
    output wire        full_coverage
);

    assign acceptable_reached = (fault_coverage >= acceptable_coverage);
    assign budget_exhausted  = (energy_used >= energy_budget);
    assign full_coverage     = (fault_coverage >= stop_coverage);

    always @(*) begin
        if (full_coverage || budget_exhausted)
            decision = DECISION_STOP;
        else if (energy_used >= priority_threshold)
            decision = DECISION_HIGH;
        else
            decision = DECISION_CONTINUE;
    end
endmodule
