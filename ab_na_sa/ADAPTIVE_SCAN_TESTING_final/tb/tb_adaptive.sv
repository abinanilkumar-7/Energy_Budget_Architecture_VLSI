// ============================================================================
// HYBRID / SEQUENTIAL ADAPTIVE SCAN TESTBENCH
//
// Phase 1: Conventional fixed scheduling on the SAME scan hardware.
//          Stop the conventional scheduler once cumulative energy reaches
//          70% of the configured total budget.
//
// Phase 2: Dynamic ATPG takes over the SAME hardware/state.
//          Use high-priority scheduling for remaining undetected faults.
//
// 95% is an acceptable milestone, not a stop condition.
// Continue toward 100% while energy remains within budget.
// ============================================================================
module tb_adaptive;

    localparam integer WIDTH = 8;
    localparam integer TOTAL_FAULTS = 20;
    localparam integer ENERGY_PER_TRANSITION = 1;
    localparam [7:0] ACCEPTABLE_COVERAGE = 8'd95;
    localparam [7:0] STOP_COVERAGE = 8'd100;
    localparam [7:0] PRIORITY_PERCENT = 8'd70;

    localparam [1:0] PHASE_CONVENTIONAL = 2'd0;
    localparam [1:0] PHASE_ADAPTIVE     = 2'd1;
    localparam [1:0] PHASE_DONE         = 2'd2;

    logic clk;
    logic reset;
    logic fault_enable;

    integer energy_budget_cfg;
    logic [31:0] energy_budget;

    logic phase_adaptive;
    logic pattern_valid_drive;
    logic [WIDTH-1:0] pattern_drive;
    logic [4:0] target_fault_drive;
    logic atpg_done_drive;

    logic [WIDTH-1:0] conv_pattern;
    logic [4:0]       conv_fault;
    logic             conv_pattern_valid;

    logic atpg_request;
    wire [WIDTH-1:0] atpg_test_pattern;
    wire [4:0] atpg_target_fault;
    wire atpg_pattern_valid;
    wire atpg_done;
    wire [3:0] atpg_predicted_gain;
    wire [31:0] atpg_score;
    wire [31:0] atpg_selected_cost;
    wire atpg_budget_blocked;

    wire scan_out, scan_in, scan_enable;
    wire [WIDTH-1:0] scan_data;
    wire [31:0] activity, activity_delta;
    wire [31:0] energy, energy_increment;
    wire actual_y, fault_detected;
    wire [7:0] detected_faults, coverage;
    wire [TOTAL_FAULTS-1:0] detected_map;
    wire [1:0] decision;
    wire high_priority, adaptive_mode;
    wire acceptable_reached, full_coverage, budget_exhausted;
    wire test_complete, pattern_done, atpg_done_seen;
    wire [31:0] priority_threshold;
    wire [4:0] active_fault;

    logic golden_y;
    wire [4:0] scan_inputs = scan_data[4:0];

    logic [1:0] test_phase;
    logic [WIDTH-1:0] issued_pattern;
    logic [4:0] issued_fault;
    integer issued_cost;
    integer issued_score;

    integer conventional_patterns_used;
    integer adaptive_patterns_used;
    integer total_patterns_used;
    integer switch_energy;
    integer switch_coverage;
    integer adaptive_energy_added;
    integer wait_cycles;
    integer result_fd;
    integer csv_fd;

    // ========================================================================
    // DUT + golden model
    // ========================================================================
    reference_model u_ref (
        .scan_inputs(scan_inputs),
        .golden_y(golden_y)
    );

    adaptive_design_top #(
        .WIDTH(WIDTH),
        .TOTAL_FAULTS(TOTAL_FAULTS),
        .ENERGY_PER_TRANSITION(ENERGY_PER_TRANSITION),
        .ACCEPTABLE_COVERAGE(ACCEPTABLE_COVERAGE),
        .STOP_COVERAGE(STOP_COVERAGE),
        .PRIORITY_PERCENT(PRIORITY_PERCENT)
    ) dut (
        .clk(clk),
        .reset(reset),
        .pattern_valid(pattern_valid_drive),
        .test_pattern(pattern_drive),
        .target_fault(target_fault_drive),
        .atpg_done(atpg_done_drive),
        .fault_enable(fault_enable),
        .golden_y(golden_y),
        .energy_budget(energy_budget),
        .scan_out(scan_out),
        .scan_in(scan_in),
        .scan_enable(scan_enable),
        .scan_data(scan_data),
        .activity(activity),
        .activity_delta(activity_delta),
        .energy(energy),
        .energy_increment(energy_increment),
        .actual_y(actual_y),
        .fault_detected(fault_detected),
        .detected_faults(detected_faults),
        .coverage(coverage),
        .detected_map(detected_map),
        .decision(decision),
        .high_priority(high_priority),
        .adaptive_mode(adaptive_mode),
        .acceptable_reached(acceptable_reached),
        .full_coverage(full_coverage),
        .budget_exhausted(budget_exhausted),
        .test_complete(test_complete),
        .pattern_done(pattern_done),
        .atpg_done_seen(atpg_done_seen),
        .priority_threshold(priority_threshold),
        .active_fault(active_fault)
    );

    adaptive_atpg #(
        .WIDTH(WIDTH),
        .TOTAL_FAULTS(TOTAL_FAULTS),
        .NUM_PATTERNS(32),
        .ENERGY_PER_TRANSITION(ENERGY_PER_TRANSITION)
    ) u_atpg (
        .clk(clk),
        .reset(reset),
        .request(atpg_request),
        .high_priority(high_priority),
        .detected_map(detected_map),
        .previous_pattern(issued_pattern),
        .energy_used(energy),
        .energy_budget(energy_budget),
        .test_pattern(atpg_test_pattern),
        .target_fault(atpg_target_fault),
        .pattern_valid(atpg_pattern_valid),
        .atpg_done(atpg_done),
        .predicted_fault_gain(atpg_predicted_gain),
        .selected_score(atpg_score),
        .selected_cost(atpg_selected_cost),
        .budget_blocked(atpg_budget_blocked)
    );

    adaptive_assertions u_assertions (
        .clk(clk), .reset(reset), .scan_enable(scan_enable),
        .test_complete(test_complete), .coverage(coverage),
        .energy(energy), .energy_budget(energy_budget),
        .decision(decision), .priority_threshold(priority_threshold),
        .high_priority(high_priority)
    );

    adaptive_coverage u_coverage (
        .clk(clk), .reset(reset), .decision(decision), .coverage(coverage),
        .energy(energy), .high_priority(high_priority),
        .pattern_done(pattern_done), .acceptable_reached(acceptable_reached),
        .full_coverage(full_coverage)
    );

    // Exactly ONE pattern source is active at any time.
    assign pattern_valid_drive = phase_adaptive ? atpg_pattern_valid : conv_pattern_valid;
    assign pattern_drive       = phase_adaptive ? atpg_test_pattern  : conv_pattern;
    assign target_fault_drive  = phase_adaptive ? atpg_target_fault  : conv_fault;
    assign atpg_done_drive     = phase_adaptive ? atpg_done : 1'b0;

    // ========================================================================
    // Clock
    // ========================================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // Conventional pattern application
    // ========================================================================
    task automatic issue_conventional_pattern(
        input logic [WIDTH-1:0] p,
        input logic [4:0] f
    );
        begin
            conv_pattern       = p;
            conv_fault         = f;
            conv_pattern_valid = 1'b1;
            issued_pattern     = p;
            issued_fault       = f;
            issued_cost        = 0;
            issued_score       = 0;

            @(posedge clk);
            #1 conv_pattern_valid = 1'b0;

            wait_cycles = 0;
            while ((pattern_done !== 1'b1) &&
                   (test_complete !== 1'b1) &&
                   (wait_cycles < 40)) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
            end

            // Allow response, coverage and energy pipelines to settle.
            repeat (3) @(posedge clk);
            #1;

            conventional_patterns_used = conventional_patterns_used + 1;

            $display("CONV | n=%0d | pattern=%02h | fault=%0d | energy=%0d/%0d | coverage=%0d%% | threshold=%0d",
                     conventional_patterns_used, p, f, energy, energy_budget,
                     coverage, priority_threshold);

            $fwrite(csv_fd, "%0d,%02h,%0d,CONVENTIONAL,%0d,%0d,%0d,%0d\n",
                    conventional_patterns_used, p, f, 0, 0, energy, coverage, high_priority);
        end
    endtask

    // ========================================================================
    // Dynamic ATPG request
    // ========================================================================
    task automatic issue_atpg_pattern(output logic no_pattern);
        begin
            no_pattern = 1'b0;
            atpg_request = 1'b1;
            #1;

            if (atpg_pattern_valid) begin
                issued_pattern = atpg_test_pattern;
                issued_fault   = atpg_target_fault;
                issued_cost    = atpg_selected_cost;
                issued_score   = atpg_score;
            end
            else begin
                no_pattern = 1'b1;
            end

            @(posedge clk);
            #1 atpg_request = 1'b0;
        end
    endtask

    // ========================================================================
    // Main hybrid test
    // ========================================================================
    initial begin : hybrid_test
        logic no_pattern;
        integer p;
        integer f;

        energy_budget_cfg = 5000;
        if ($value$plusargs("BUDGET=%d", energy_budget_cfg)) begin
            $display("INFO: BUDGET plusarg detected: %0d", energy_budget_cfg);
        end
        energy_budget = energy_budget_cfg;

        result_fd = $fopen("../results/adaptive_results.txt", "w");
        csv_fd    = $fopen("../results/adaptive_trace.csv", "w");
        if ((result_fd == 0) || (csv_fd == 0)) begin
            $display("ERROR: Cannot open result files.");
            $finish;
        end

        $fwrite(csv_fd, "seq,pattern,fault,phase,cost,score,energy,coverage,decision,high_priority\n");

        reset = 1'b1;
        fault_enable = 1'b0;
        phase_adaptive = 1'b0;
        test_phase = PHASE_CONVENTIONAL;
        conv_pattern_valid = 1'b0;
        conv_pattern = '0;
        conv_fault = '0;
        atpg_request = 1'b0;
        issued_pattern = '0;
        issued_fault = '0;
        conventional_patterns_used = 0;
        adaptive_patterns_used = 0;
        switch_energy = 0;
        switch_coverage = 0;

        repeat (3) @(posedge clk);
        #1;
        reset = 1'b0;
        fault_enable = 1'b1;

        $display("============================================================");
        $display(" HYBRID ADAPTIVE SCAN TEST");
        $display(" Budget=%0d | 70%% threshold=%0d | acceptable=95%% | stop=100%%",
                 energy_budget, priority_threshold);
        $display("============================================================");

        // --------------------------------------------------------------------
        // PHASE 1: fixed conventional scheduling.
        // Pattern list is fixed and not influenced by the measured energy or
        // detected-fault map. We only stop when the 70%% threshold is reached.
        // --------------------------------------------------------------------
        conventional_phase: begin
            for (f = 0; f < TOTAL_FAULTS; f = f + 1) begin
                for (p = 0; p < 32; p = p + 1) begin
                    if (full_coverage || budget_exhausted ||
                        (energy >= priority_threshold))
                        disable conventional_phase;

                    issue_conventional_pattern({3'b000, p[4:0]}, f[4:0]);

                    if (full_coverage || budget_exhausted ||
                        (energy >= priority_threshold))
                        disable conventional_phase;
                end
            end
        end

        switch_energy = energy;
        switch_coverage = coverage;

        if (full_coverage) begin
            test_phase = PHASE_DONE;
            $display("Conventional phase itself reached 100%% coverage.");
        end
        else if (budget_exhausted) begin
            test_phase = PHASE_DONE;
            $display("Budget exhausted before adaptive handoff.");
        end
        else begin
            // No reset: preserve cumulative energy and coverage.
            phase_adaptive = 1'b1;
            test_phase = PHASE_ADAPTIVE;
            $display("------------------------------------------------------------");
            $display("SWITCH: conventional -> adaptive");
            $display("switch energy   = %0d", switch_energy);
            $display("switch coverage = %0d%%", switch_coverage);
            $display("high_priority   = %0d", high_priority);
            $display("------------------------------------------------------------");

            // ----------------------------------------------------------------
            // PHASE 2: dynamic ATPG.
            // ----------------------------------------------------------------
            adaptive_phase: begin
                forever begin
                    if (full_coverage || budget_exhausted)
                        disable adaptive_phase;

                    issue_atpg_pattern(no_pattern);

                    if (no_pattern) begin
                        // Either no undetected fault remains or no remaining
                        // candidate can fit the remaining budget.
                        repeat (3) @(posedge clk);
                        if (atpg_budget_blocked)
                            $display("ADAPT: budget-blocked: no feasible remaining pattern.");
                        disable adaptive_phase;
                    end

                    wait_cycles = 0;
                    while ((pattern_done !== 1'b1) &&
                           (test_complete !== 1'b1) &&
                           (wait_cycles < 40)) begin
                        @(posedge clk);
                        wait_cycles = wait_cycles + 1;
                    end

                    if (pattern_done !== 1'b1) begin
                        if (test_complete !== 1'b1)
                            $display("ERROR: timeout waiting for adaptive pattern_done");
                        disable adaptive_phase;
                    end

                    repeat (3) @(posedge clk);
                    #1;

                    adaptive_patterns_used = adaptive_patterns_used + 1;

                    $display("ADAPT | n=%0d | pattern=%02h | target_fault=%0d | cost=%0d | energy=%0d/%0d | coverage=%0d%% | decision=%0d | HIGH=%0d",
                             adaptive_patterns_used,
                             issued_pattern,
                             issued_fault,
                             issued_cost,
                             energy,
                             energy_budget,
                             coverage,
                             decision,
                             high_priority);

                    $fwrite(csv_fd,
                            "%0d,%02h,%0d,ADAPTIVE,%0d,%0d,%0d,%0d,%0d,%0d\n",
                            conventional_patterns_used + adaptive_patterns_used,
                            issued_pattern,
                            issued_fault,
                            issued_cost,
                            issued_score,
                            energy,
                            coverage,
                            decision,
                            high_priority);

                    if (full_coverage || budget_exhausted)
                        disable adaptive_phase;
                end
            end
        end

        test_phase = PHASE_DONE;
        total_patterns_used = conventional_patterns_used + adaptive_patterns_used;
        adaptive_energy_added = energy - switch_energy;

        $fwrite(result_fd, "energy_budget=%0d\n", energy_budget);
        $fwrite(result_fd, "priority_threshold=%0d\n", priority_threshold);
        $fwrite(result_fd, "switch_energy=%0d\n", switch_energy);
        $fwrite(result_fd, "switch_coverage=%0d\n", switch_coverage);
        $fwrite(result_fd, "adaptive_energy_added=%0d\n", adaptive_energy_added);
        $fwrite(result_fd, "total_energy=%0d\n", energy);
        $fwrite(result_fd, "final_coverage=%0d\n", coverage);
        $fwrite(result_fd, "conventional_patterns=%0d\n", conventional_patterns_used);
        $fwrite(result_fd, "adaptive_patterns=%0d\n", adaptive_patterns_used);
        $fwrite(result_fd, "total_patterns=%0d\n", total_patterns_used);
        $fwrite(result_fd, "acceptable_95_reached=%0d\n", (coverage >= ACCEPTABLE_COVERAGE));
        $fwrite(result_fd, "full_100_reached=%0d\n", full_coverage);
        $fwrite(result_fd, "budget_exhausted=%0d\n", budget_exhausted);
        $fwrite(result_fd, "within_budget=%0d\n", (energy <= energy_budget));

        $fclose(result_fd);
        $fclose(csv_fd);

        $display("============================================================");
        $display(" FINAL HYBRID RESULT");
        $display(" switch energy       = %0d", switch_energy);
        $display(" switch coverage     = %0d%%", switch_coverage);
        $display(" adaptive energy add = %0d", adaptive_energy_added);
        $display(" total energy        = %0d/%0d", energy, energy_budget);
        $display(" final coverage      = %0d%%", coverage);
        $display(" conventional tests  = %0d", conventional_patterns_used);
        $display(" adaptive tests      = %0d", adaptive_patterns_used);
        $display(" 95%% milestone       = %0d", (coverage >= ACCEPTABLE_COVERAGE));
        $display(" 100%% reached        = %0d", full_coverage);
        $display(" high-priority used  = %0d", (high_priority || switch_energy >= priority_threshold));
        $display("============================================================");

        if (coverage >= ACCEPTABLE_COVERAGE)
            $display("PASS: 95%% acceptable fault coverage achieved.");
        else
            $display("INFO: 95%% acceptable fault coverage not achieved.");

        if (full_coverage)
            $display("PASS: 100%% full fault coverage achieved.");
        else if (budget_exhausted || atpg_budget_blocked)
            $display("INFO: test stopped because the total energy budget was exhausted/insufficient.");
        else
            $display("INFO: test stopped before 100%% coverage.");

        if (energy <= energy_budget)
            $display("PASS: total hybrid test stayed within the energy budget.");
        else
            $display("FAIL: total hybrid test exceeded the energy budget.");

        $finish;
    end
endmodule
