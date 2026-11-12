module conventional_coverage(
    input logic clk,
    input logic reset,
    input logic [7:0] coverage,
    input logic [31:0] energy,
    input logic pattern_done
);
    integer pattern_count;
    integer max_coverage_seen;
    integer max_energy_seen;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            pattern_count <= 0;
            max_coverage_seen <= 0;
            max_energy_seen <= 0;
        end else begin
            if(pattern_done) pattern_count <= pattern_count + 1;
            if(coverage > max_coverage_seen) max_coverage_seen <= coverage;
            if(energy > max_energy_seen) max_energy_seen <= energy;
        end
    end
endmodule
