// ================================================================
// Fault detector
// Compares actual fault-injected response with golden response.
// ================================================================
module fault_detector (
    input  wire actual_output,
    input  wire golden_output,
    input  wire response_valid,
    input  wire fault_enable,
    output wire fault_detected
);

    assign fault_detected = response_valid && fault_enable &&
        (((actual_output === 1'b0) && (golden_output === 1'b1)) ||
         ((actual_output === 1'b1) && (golden_output === 1'b0)));

endmodule
