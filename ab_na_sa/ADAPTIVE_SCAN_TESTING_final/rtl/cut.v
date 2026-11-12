// ============================================================================
// Circuit Under Test (CUT)
// 5-input combinational circuit.
// ============================================================================
module cut (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire d,
    input  wire e,
    output wire y
);
    wire x1, x2, x3, x4;

    assign x1 = a ^ b;
    assign x2 = x1 & c;
    assign x3 = x2 | d;
    assign x4 = x3 ^ e;
    assign y  = x4;
endmodule
