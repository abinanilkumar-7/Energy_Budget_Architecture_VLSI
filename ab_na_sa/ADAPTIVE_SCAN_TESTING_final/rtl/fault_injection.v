// ============================================================================
// Generic single-signal stuck-at fault injector.
// ============================================================================
module fault_injection (
    input  wire normal_signal,
    input  wire fault_enable,
    input  wire fault_stuck_at,
    output wire faulty_signal
);
    assign faulty_signal = fault_enable ? fault_stuck_at : normal_signal;
endmodule
