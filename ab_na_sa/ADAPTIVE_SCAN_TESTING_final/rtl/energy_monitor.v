// ============================================================================
// RTL-level energy estimator/accumulator
// Energy = transitions * ENERGY_PER_TRANSITION
// This is a switching-energy proxy for architectural simulation.
// ============================================================================
module energy_monitor #(
    parameter integer ENERGY_PER_TRANSITION = 1
)(
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] transition_count,
    output reg  [31:0] energy,
    output reg  [31:0] energy_increment
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            energy           <= 32'd0;
            energy_increment <= 32'd0;
        end
        else begin
            energy_increment <= transition_count * ENERGY_PER_TRANSITION;
            energy           <= energy + (transition_count * ENERGY_PER_TRANSITION);
        end
    end
endmodule
