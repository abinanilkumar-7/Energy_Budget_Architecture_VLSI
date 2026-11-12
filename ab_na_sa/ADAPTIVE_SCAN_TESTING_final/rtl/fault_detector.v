// ============================================================================
// Fault detector: compare the actual CUT response with the golden response.
// ============================================================================
module fault_detector (
    input  wire actual_output,
    input  wire golden_output,
    input  wire response_valid,
    input  wire fault_enable,
    output wire fault_detected
);
    assign fault_detected = response_valid && fault_enable &&
                            (actual_output !== golden_output);
endmodule
