// ============================================================================
// Unique fault coverage tracker.
// Each fault is counted only once.
// ============================================================================
module fault_coverage #(
    parameter integer TOTAL_FAULTS = 20
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    fault_detected,
    input  wire [4:0]              fault_index,
    output reg  [7:0]              detected_faults,
    output reg  [7:0]              coverage,
    output wire [TOTAL_FAULTS-1:0] detected_map
);

    reg [TOTAL_FAULTS-1:0] detected_map_reg;
    integer i;
    integer count_temp;

    assign detected_map = detected_map_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            detected_map_reg <= {TOTAL_FAULTS{1'b0}};
        else if (fault_detected && (fault_index < TOTAL_FAULTS))
            detected_map_reg[fault_index] <= 1'b1;
    end

    always @(*) begin
        count_temp = 0;
        for (i = 0; i < TOTAL_FAULTS; i = i + 1)
            if (detected_map_reg[i])
                count_temp = count_temp + 1;

        detected_faults = count_temp;
        coverage = (count_temp * 100) / TOTAL_FAULTS;
    end
endmodule
