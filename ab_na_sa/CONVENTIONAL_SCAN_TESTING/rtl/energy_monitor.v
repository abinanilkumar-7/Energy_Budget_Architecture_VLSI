// ================================================================
// Energy Monitor
// Contains the RTL-level energy estimator and accumulator.
//
// Energy = Number of transitions * ENERGY_PER_TRANSITION
//
// This is an RTL switching-energy proxy, not physical power in joules.
// ================================================================
module energy_monitor #(
    parameter integer ENERGY_PER_TRANSITION = 1
)(
    input  wire          clk,
    input  wire          reset,
    input  wire [31:0]   transition_count,
    output reg  [31:0]   energy,
    output reg  [31:0]   energy_increment
);

    reg [31:0] transition_energy;

    always @(*) begin
        transition_energy = transition_count * ENERGY_PER_TRANSITION;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            energy           <= 32'd0;
            energy_increment <= 32'd0;
        end
        else begin
            energy_increment <= transition_energy;
            energy           <= energy + transition_energy;
        end
    end

endmodule
