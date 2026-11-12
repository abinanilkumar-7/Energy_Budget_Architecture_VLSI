// ================================================================
// Activity Monitor
// Counts transitions on the scan-chain parallel data.
//
// transition_count : transitions associated with the current cycle
// activity_count   : cumulative transition count
// ================================================================
module activity_monitor #(
    parameter integer WIDTH = 8
)(
    input  wire              clk,
    input  wire              reset,
    input  wire [WIDTH-1:0]  data_in,
    output reg  [31:0]       transition_count,
    output reg  [31:0]       activity_count
);

    reg [WIDTH-1:0] previous_data;
    integer i;
    reg [31:0] transition_count_comb;

    always @(*) begin
        transition_count_comb = 32'd0;
        for (i = 0; i < WIDTH; i = i + 1)
            transition_count_comb = transition_count_comb +
                                    (data_in[i] ^ previous_data[i]);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            previous_data   <= {WIDTH{1'b0}};
            transition_count <= 32'd0;
            activity_count  <= 32'd0;
        end
        else begin
            transition_count <= transition_count_comb;
            activity_count   <= activity_count + transition_count_comb;
            previous_data    <= data_in;
        end
    end

endmodule
