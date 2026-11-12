// ============================================================================
// Simulation-friendly functional counters.
// ============================================================================
module adaptive_coverage (
    input logic        clk,
    input logic        reset,
    input logic [1:0]  decision,
    input logic [7:0]  coverage,
    input logic [31:0] energy,
    input logic        high_priority,
    input logic        pattern_done,
    input logic        acceptable_reached,
    input logic        full_coverage
);
    integer continue_count;
    integer high_priority_count;
    integer stop_count;
    integer pattern_count;
    integer acceptable_hits;
    integer full_hits;
    integer max_coverage_seen;
    integer max_energy_seen;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            continue_count      <= 0;
            high_priority_count <= 0;
            stop_count          <= 0;
            pattern_count       <= 0;
            acceptable_hits     <= 0;
            full_hits           <= 0;
            max_coverage_seen   <= 0;
            max_energy_seen     <= 0;
        end
        else begin
            case (decision)
                2'd0: continue_count      <= continue_count + 1;
                2'd1: high_priority_count <= high_priority_count + 1;
                2'd2: stop_count          <= stop_count + 1;
                default: ;
            endcase
            if (pattern_done)         pattern_count      <= pattern_count + 1;
            if (acceptable_reached)   acceptable_hits    <= acceptable_hits + 1;
            if (full_coverage)        full_hits          <= full_hits + 1;
            if (coverage > max_coverage_seen) max_coverage_seen <= coverage;
            if (energy > max_energy_seen)     max_energy_seen   <= energy;
        end
    end
endmodule
