// ============================================================================
// Golden response model.
// ============================================================================
module reference_model (
    input  wire [4:0] scan_inputs,
    output wire       golden_y
);
    cut u_cut_reference (
        .a(scan_inputs[0]),
        .b(scan_inputs[1]),
        .c(scan_inputs[2]),
        .d(scan_inputs[3]),
        .e(scan_inputs[4]),
        .y(golden_y)
    );
endmodule
