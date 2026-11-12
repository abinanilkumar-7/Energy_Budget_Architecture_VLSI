module conventional_assertions(
    input logic clk,
    input logic reset,
    input logic [7:0] coverage,
    input logic [31:0] energy
);
    property p_cov_range;
        @(posedge clk) disable iff(reset) coverage <= 8'd100;
    endproperty
    property p_energy_monotonic;
        @(posedge clk) disable iff(reset) energy >= $past(energy);
    endproperty
    assert property(p_cov_range);
    assert property(p_energy_monotonic);
endmodule
