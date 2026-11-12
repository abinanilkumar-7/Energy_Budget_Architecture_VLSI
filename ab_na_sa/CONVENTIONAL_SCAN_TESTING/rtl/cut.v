// ================================================================
// Circuit Under Test (CUT)
// 5 primary inputs with four internal logic nodes and one output.
// The extra internal nodes make a 20-fault stuck-at campaign
// possible without changing the external five-input CUT interface.
// ================================================================
module cut (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire d,
    input  wire e,
    output wire y
);

    wire x1;
    wire x2;
    wire x3;
    wire x4;

    assign x1 = a ^ b;
    assign x2 = x1 & c;
    assign x3 = x2 | d;
    assign x4 = x3 ^ e;
    assign y  = x4;

endmodule
