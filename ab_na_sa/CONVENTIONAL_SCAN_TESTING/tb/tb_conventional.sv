module tb_conventional;
    localparam integer WIDTH = 8;
    localparam integer TOTAL_FAULTS = 20;
    localparam integer ENERGY_PER_TRANSITION = 1;

    logic clk = 1'b0;
    logic reset = 1'b1;
    logic scan_enable = 1'b0;
    logic scan_in = 1'b0;
    logic response_valid = 1'b0;
    logic fault_enable = 1'b0;
    logic [4:0] fault_index = 5'd0;
    wire golden_y;

    wire scan_out;
    wire [WIDTH-1:0] scan_data;
    wire [31:0] activity, activity_delta, energy, energy_increment;
    wire actual_y, fault_detected;
    wire [7:0] detected_faults, coverage;
    wire [TOTAL_FAULTS-1:0] detected_map;

    integer f, p, b;
    integer patterns_run = 0;
    integer result_fd, csv_fd;

    always #5 clk = ~clk;

    reference_model u_ref (
        .scan_inputs(scan_data[4:0]),
        .golden_y(golden_y)
    );

    conventional_design_top #(
        .WIDTH(WIDTH),
        .TOTAL_FAULTS(TOTAL_FAULTS),
        .ENERGY_PER_TRANSITION(ENERGY_PER_TRANSITION)
    ) dut (
        .clk(clk),
        .reset(reset),
        .scan_enable(scan_enable),
        .scan_in(scan_in),
        .response_valid(response_valid),
        .fault_enable(fault_enable),
        .fault_index(fault_index),
        .golden_y(golden_y),
        .scan_out(scan_out),
        .scan_data(scan_data),
        .activity(activity),
        .activity_delta(activity_delta),
        .energy(energy),
        .energy_increment(energy_increment),
        .actual_y(actual_y),
        .fault_detected(fault_detected),
        .detected_faults(detected_faults),
        .coverage(coverage),
        .detected_map(detected_map)
    );

    conventional_assertions u_assertions(
        .clk(clk), .reset(reset), .coverage(coverage), .energy(energy)
    );

    task automatic apply_pattern(input logic [7:0] pattern);
        begin
            scan_enable = 1'b1;
            for(b=7; b>=0; b=b-1) begin
                scan_in = pattern[b];
                @(posedge clk);
            end
            scan_enable = 1'b0;
            response_valid = 1'b1;
            @(posedge clk);
            #1;
            response_valid = 1'b0;
            repeat(2) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        result_fd = $fopen("../results/conventional_results.txt","w");
        csv_fd = $fopen("../results/conventional_results.csv","w");
        $fwrite(csv_fd,"fault,pattern,pattern_hex,energy,coverage\n");

        repeat(3) @(posedge clk);
        #1;
        reset = 1'b0;
        fault_enable = 1'b1;

        $display("============================================================");
        $display(" CONVENTIONAL SCAN TESTING ONLY");
        $display(" 20 faults x 32 fixed patterns = 640 applications");
        $display("============================================================");

        for(f=0; f<TOTAL_FAULTS; f=f+1) begin
            fault_index = f[4:0];
            for(p=0; p<32; p=p+1) begin
                apply_pattern({3'b000,p[4:0]});
                patterns_run = patterns_run + 1;
                $fwrite(csv_fd,"%0d,%0d,%02h,%0d,%0d\n",
                        f,p,{3'b000,p[4:0]},energy,coverage);
            end
        end

        fault_enable = 1'b0;
        repeat(3) @(posedge clk);
        #1;

        $fwrite(result_fd,"conventional_energy=%0d\n",energy);
        $fwrite(result_fd,"conventional_coverage=%0d\n",coverage);
        $fwrite(result_fd,"pattern_count=%0d\n",patterns_run);
        $fclose(result_fd);
        $fclose(csv_fd);

        $display("============================================================");
        $display(" CONVENTIONAL FINAL RESULT");
        $display(" Energy   = %0d",energy);
        $display(" Coverage = %0d%%",coverage);
        $display(" Patterns = %0d",patterns_run);
        $display("============================================================");
        $display("RESULT_FILE=../results/conventional_results.txt");
        $finish;
    end
endmodule
