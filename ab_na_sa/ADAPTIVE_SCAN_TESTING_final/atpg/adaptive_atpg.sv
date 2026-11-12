// ============================================================================
// Dynamic ATPG / priority scheduler (simulation-side)
//
// For each request, evaluate all 32 possible 5-bit input patterns against all
// currently undetected faults. Select one pattern/fault pair that:
//   1) definitely detects the selected fault,
//   2) fits the remaining energy budget,
//   3) in HIGH-PRIORITY mode favors harder faults and lower scan cost.
//
// Patterns may be reused for different faults. A pattern is not permanently
// consumed; the state that matters is the undetected-fault bitmap.
// ============================================================================
module adaptive_atpg #(
    parameter integer WIDTH = 8,
    parameter integer TOTAL_FAULTS = 20,
    parameter integer NUM_PATTERNS = 32,
    parameter integer ENERGY_PER_TRANSITION = 1
)(
    input  logic                         clk,
    input  logic                         reset,
    input  logic                         request,
    input  logic                         high_priority,
    input  logic [TOTAL_FAULTS-1:0]      detected_map,
    input  logic [WIDTH-1:0]             previous_pattern,
    input  logic [31:0]                  energy_used,
    input  logic [31:0]                  energy_budget,

    output logic [WIDTH-1:0]             test_pattern,
    output logic [4:0]                   target_fault,
    output logic                         pattern_valid,
    output logic                         atpg_done,
    output logic [3:0]                   predicted_fault_gain,
    output logic [31:0]                  selected_score,
    output logic [31:0]                  selected_cost,
    output logic                         budget_blocked
);

    integer p, f, g;
    integer detect_count;
    integer pattern_span;
    integer transition_cost;
    integer energy_cost;
    integer score;
    integer hardness;
    integer best_pattern;
    integer best_fault;
    integer best_score;
    integer best_cost;
    integer best_gain;
    integer best_hardness;
    integer any_undetected_fault;
    integer any_budget_feasible;

    logic unused_clk;
    logic unused_reset;

    function automatic logic cut_function(input logic [4:0] v);
        logic a, b, c, d, e;
        logic x1, x2, x3, x4;
        begin
            a = v[0]; b = v[1]; c = v[2]; d = v[3]; e = v[4];
            x1 = a ^ b;
            x2 = x1 & c;
            x3 = x2 | d;
            x4 = x3 ^ e;
            cut_function = x4;
        end
    endfunction

    function automatic logic faulty_cut_function(
        input logic [4:0] v,
        input integer fault_index
    );
        logic a, b, c, d, e;
        logic x1, x2, x3, x4, y;
        integer node;
        logic sa;
        begin
            a = v[0]; b = v[1]; c = v[2]; d = v[3]; e = v[4];
            node = fault_index / 2;
            sa   = fault_index % 2;

            case (node)
                0: a = sa;
                1: b = sa;
                2: c = sa;
                3: d = sa;
                4: e = sa;
                default: ;
            endcase

            x1 = a ^ b;
            if (node == 5) x1 = sa;

            x2 = x1 & c;
            if (node == 6) x2 = sa;

            x3 = x2 | d;
            if (node == 7) x3 = sa;

            x4 = x3 ^ e;
            if (node == 8) x4 = sa;

            y = x4;
            if (node == 9) y = sa;

            faulty_cut_function = y;
        end
    endfunction

    function automatic logic detects_fault(
        input logic [4:0] v,
        input integer fault_index
    );
        begin
            detects_fault = (cut_function(v) != faulty_cut_function(v, fault_index));
        end
    endfunction

    function automatic integer scan_transition_cost(
        input logic [WIDTH-1:0] prev,
        input logic [WIDTH-1:0] candidate
    );
        integer i, j, c;
        logic [WIDTH-1:0] reg_value;
        logic [WIDTH-1:0] next_value;
        begin
            reg_value = prev;
            c = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1) begin
                next_value = {reg_value[WIDTH-2:0], candidate[i]};
                for (j = 0; j < WIDTH; j = j + 1)
                    c = c + (next_value[j] ^ reg_value[j]);
                reg_value = next_value;
            end
            scan_transition_cost = c;
        end
    endfunction

    always_comb begin
        best_pattern = -1;
        best_fault = -1;
        best_score = -2147483647;
        best_cost = 32'h7fffffff;
        best_gain = 0;
        best_hardness = 0;
        any_undetected_fault = 0;
        any_budget_feasible = 0;
        pattern_span = 0;
        detect_count = 0;
        transition_cost = 0;
        energy_cost = 0;
        score = 0;
        hardness = 0;

        // First choose among currently undetected faults and all detecting
        // patterns. Same pattern can legitimately be used on another fault.
        for (f = 0; f < TOTAL_FAULTS; f = f + 1) begin
            if (!detected_map[f]) begin
                any_undetected_fault = 1;

                detect_count = 0;
                for (p = 0; p < NUM_PATTERNS; p = p + 1)
                    if (detects_fault(p[4:0], f))
                        detect_count = detect_count + 1;

                hardness = NUM_PATTERNS - detect_count;

                for (p = 0; p < NUM_PATTERNS; p = p + 1) begin
                    if (detects_fault(p[4:0], f)) begin
                        transition_cost = scan_transition_cost(
                            previous_pattern,
                            {3'b000, p[4:0]}
                        );
                        energy_cost = transition_cost * ENERGY_PER_TRANSITION;

                        if ((energy_used + energy_cost) <= energy_budget) begin
                            any_budget_feasible = 1;

                            pattern_span = 0;
                            for (g = 0; g < TOTAL_FAULTS; g = g + 1)
                                if (!detected_map[g] && detects_fault(p[4:0], g))
                                    pattern_span = pattern_span + 1;

                            if (!high_priority) begin
                                // Normal phase: favor broad fault usefulness,
                                // then lower transition cost.
                                score = (pattern_span * 100000) +
                                        ((128 - transition_cost) * 1000) +
                                        hardness;
                            end
                            else begin
                                // Adaptive phase: target difficult remaining
                                // faults first, then fault span, then low cost.
                                score = (hardness * 100000) +
                                        (pattern_span * 10000) +
                                        ((128 - transition_cost) * 1000);
                            end

                            if ((best_pattern < 0) ||
                                (score > best_score) ||
                                ((score == best_score) && (energy_cost < best_cost))) begin
                                best_pattern  = p;
                                best_fault    = f;
                                best_score    = score;
                                best_cost     = energy_cost;
                                best_gain     = pattern_span;
                                best_hardness = hardness;
                            end
                        end
                    end
                end
            end
        end

        if (best_pattern >= 0) begin
            test_pattern         = {3'b000, best_pattern[4:0]};
            target_fault         = best_fault[4:0];
            pattern_valid       = request;
            atpg_done            = 1'b0;
            predicted_fault_gain = best_gain[3:0];
            selected_score       = best_score[31:0];
            selected_cost        = best_cost[31:0];
            budget_blocked       = 1'b0;
        end
        else begin
            test_pattern         = '0;
            target_fault         = 5'd0;
            pattern_valid        = 1'b0;
            atpg_done            = request;
            predicted_fault_gain = 4'd0;
            selected_score       = 32'd0;
            selected_cost        = 32'd0;
            budget_blocked       = request && any_undetected_fault && !any_budget_feasible;
        end
    end

    // clk/reset are intentionally present as interface signals so the module
    // can be integrated cleanly in the simulation environment. The pattern
    // selection itself is combinational with respect to the current state.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            unused_clk   <= 1'b0;
            unused_reset <= 1'b0;
        end
        else begin
            unused_clk   <= ~unused_clk;
            unused_reset <= 1'b0;
        end
    end
endmodule
