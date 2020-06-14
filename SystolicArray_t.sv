module SystolicArray_t;
    parameter size = 2;

    parameter size_input = 3;
    parameter size_output = 2;
    reg clk = 0;
    reg rst_n = 1;
    reg signed [31:0] input_weight;
    reg signed [31:0] net_weight   [0:size - 1];
    wire signed [31:0] output_weight[0:size - 1];
    wire signed [31:0] output0;
    wire signed [31:0] output1;

    parameter cyc = 2;

    always #(cyc / 2) clk = ~clk;

    SystolicArray#(2) sys(clk, rst_n, input_weight, net_weight, output_weight);

    initial begin
        $fsdbDumpfile("sys.fsdb");
        $fsdbDumpvars;
    end

    initial begin
        @(negedge clk)rst_n = 0;
        @(negedge clk)rst_n = 1;
        input_weight  = 32'd4;
        net_weight[0] = 32'd1;
        net_weight[1] = 32'd0;
        @(negedge clk)
        input_weight = 32'd3;
        net_weight[0] = 32'd3;
        net_weight[1] = 32'd2;
        @(negedge clk)
        input_weight = 32'd4;
        net_weight[0] = 32'd5;
        net_weight[1] = 32'd4;
        @(negedge clk)
        input_weight = 32'd0;
        net_weight[0] = 32'd0;
        net_weight[1] = 32'd6;
        @(negedge clk)
        input_weight = 32'd0;
        net_weight[0] = 32'd0;
        net_weight[1] = 32'd0;

        #(cyc)
        $finish;

    end

    assign output0 = output_weight[0];
    assign output1 = output_weight[1];
endmodule
