// ================================================================
// Fault-injected version of the CUT.
//
// 20 stuck-at faults:
//   0  a-SA0       1  a-SA1
//   2  b-SA0       3  b-SA1
//   4  c-SA0       5  c-SA1
//   6  d-SA0       7  d-SA1
//   8  e-SA0       9  e-SA1
//   10 x1-SA0     11 x1-SA1
//   12 x2-SA0     13 x2-SA1
//   14 x3-SA0     15 x3-SA1
//   16 x4-SA0     17 x4-SA1
//   18 y-SA0      19 y-SA1
// ================================================================
module faulty_cut (
    input  logic       a,
    input  logic       b,
    input  logic       c,
    input  logic       d,
    input  logic       e,
    input  logic       fault_enable,
    input  logic [4:0] fault_index,
    output logic       y
);

    logic fault_value;
    logic [3:0] fault_node;

    logic a_f, b_f, c_f, d_f, e_f;
    logic x1_f, x2_f, x3_f, x4_f, y_f;

    logic x1_normal, x2_normal, x3_normal, x4_normal, y_normal;

    assign fault_node  = fault_index[4:1];
    assign fault_value = fault_index[0];

    // Primary inputs
    fault_injection u_fa (
        .normal_signal (a),
        .fault_enable  (fault_enable && (fault_node == 4'd0)),
        .fault_stuck_at(fault_value),
        .faulty_signal (a_f)
    );

    fault_injection u_fb (
        .normal_signal (b),
        .fault_enable  (fault_enable && (fault_node == 4'd1)),
        .fault_stuck_at(fault_value),
        .faulty_signal (b_f)
    );

    fault_injection u_fc (
        .normal_signal (c),
        .fault_enable  (fault_enable && (fault_node == 4'd2)),
        .fault_stuck_at(fault_value),
        .faulty_signal (c_f)
    );

    fault_injection u_fd (
        .normal_signal (d),
        .fault_enable  (fault_enable && (fault_node == 4'd3)),
        .fault_stuck_at(fault_value),
        .faulty_signal (d_f)
    );

    fault_injection u_fe (
        .normal_signal (e),
        .fault_enable  (fault_enable && (fault_node == 4'd4)),
        .fault_stuck_at(fault_value),
        .faulty_signal (e_f)
    );

    // Internal nodes
    assign x1_normal = a_f ^ b_f;

    fault_injection u_fx1 (
        .normal_signal (x1_normal),
        .fault_enable  (fault_enable && (fault_node == 4'd5)),
        .fault_stuck_at(fault_value),
        .faulty_signal (x1_f)
    );

    assign x2_normal = x1_f & c_f;

    fault_injection u_fx2 (
        .normal_signal (x2_normal),
        .fault_enable  (fault_enable && (fault_node == 4'd6)),
        .fault_stuck_at(fault_value),
        .faulty_signal (x2_f)
    );

    assign x3_normal = x2_f | d_f;

    fault_injection u_fx3 (
        .normal_signal (x3_normal),
        .fault_enable  (fault_enable && (fault_node == 4'd7)),
        .fault_stuck_at(fault_value),
        .faulty_signal (x3_f)
    );

    assign x4_normal = x3_f ^ e_f;

    fault_injection u_fx4 (
        .normal_signal (x4_normal),
        .fault_enable  (fault_enable && (fault_node == 4'd8)),
        .fault_stuck_at(fault_value),
        .faulty_signal (x4_f)
    );

    assign y_normal = x4_f;

    fault_injection u_fy (
        .normal_signal (y_normal),
        .fault_enable  (fault_enable && (fault_node == 4'd9)),
        .fault_stuck_at(fault_value),
        .faulty_signal (y_f)
    );

    assign y = y_f;

endmodule
