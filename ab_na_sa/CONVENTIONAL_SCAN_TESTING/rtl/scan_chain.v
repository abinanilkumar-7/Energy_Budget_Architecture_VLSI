// ================================================================
// 8-bit scan chain
// After WIDTH shift clocks, scan_data contains the supplied vector.
// The controller drives the test pattern MSB first.
// ================================================================
module scan_chain #(
    parameter integer WIDTH = 8
)(
    input  wire             clk,
    input  wire             reset,
    input  wire             scan_enable,
    input  wire             scan_in,
    output wire             scan_out,
    output reg  [WIDTH-1:0] scan_data
);

    assign scan_out = scan_data[WIDTH-1];

    always @(posedge clk or posedge reset) begin
        if (reset)
            scan_data <= {WIDTH{1'b0}};
        else if (scan_enable)
            scan_data <= {scan_data[WIDTH-2:0], scan_in};
    end

endmodule
