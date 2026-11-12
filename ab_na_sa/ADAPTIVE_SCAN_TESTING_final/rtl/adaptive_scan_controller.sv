// ============================================================================
// Adaptive Scan Controller
// Receives a selected pattern/fault from the testbench-side ATPG and shifts
// the pattern through the single shared scan chain.
// ============================================================================
module adaptive_scan_controller #(
    parameter integer WIDTH = 8
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             pattern_valid,
    input  logic [WIDTH-1:0] test_pattern,
    input  logic [4:0]       target_fault,
    input  logic             stop_request,
    input  logic             high_priority,

    output logic             scan_enable,
    output logic             scan_in,
    output logic             pattern_done,
    output logic             test_complete,
    output logic             adaptive_mode,
    output logic [4:0]       active_fault
);

    typedef enum logic [1:0] {ST_IDLE, ST_SHIFT, ST_WAIT, ST_COMPLETE} state_t;
    state_t state;
    logic [WIDTH-1:0] shift_reg;
    integer shift_count;

    always_comb begin
        scan_enable   = (state == ST_SHIFT);
        scan_in       = shift_reg[WIDTH-1];
        test_complete = (state == ST_COMPLETE);
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= ST_IDLE;
            shift_reg     <= '0;
            shift_count   <= 0;
            pattern_done  <= 1'b0;
            adaptive_mode <= 1'b0;
            active_fault  <= 5'd0;
        end
        else begin
            pattern_done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (stop_request) begin
                        state <= ST_COMPLETE;
                    end
                    else if (pattern_valid) begin
                        shift_reg     <= test_pattern;
                        active_fault  <= target_fault;
                        shift_count   <= 0;
                        adaptive_mode <= high_priority;
                        state         <= ST_SHIFT;
                    end
                end

                ST_SHIFT: begin
                    shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
                    if (shift_count == WIDTH-1) begin
                        shift_count  <= 0;
                        pattern_done <= 1'b1;
                        state        <= ST_WAIT;
                    end
                    else begin
                        shift_count <= shift_count + 1;
                    end
                end

                ST_WAIT: begin
                    if (stop_request) begin
                        state <= ST_COMPLETE;
                    end
                    else if (pattern_valid) begin
                        shift_reg     <= test_pattern;
                        active_fault  <= target_fault;
                        shift_count   <= 0;
                        adaptive_mode <= high_priority;
                        state         <= ST_SHIFT;
                    end
                end

                ST_COMPLETE: begin
                    state <= ST_COMPLETE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
