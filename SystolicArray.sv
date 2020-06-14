

module SystolicArray(clk, rst_n, input_weight, net_weight, output_weight);
    parameter  size  = 100;
    input             clk;
    input             rst_n;
    input signed      [31:0] input_weight;
    input signed      [31:0] net_weight   [0:size - 1];
    output reg signed [31:0] output_weight[0:size - 1];

    reg signed [31:0] prop_input_weight   [0:size - 1];
    reg signed [31:0] next_output_weight  [0:size - 1];

    always@(posedge clk) begin
        if (!rst_n) begin
            for (int index = 0; index < size; index ++) begin
                output_weight[index]     <= 32'd0;
                prop_input_weight[index] <= 32'd0;
            end
        end else begin
            for (int index = 0; index < size; index ++) begin
                output_weight [index] <= next_output_weight [index];
            end
            for (int index = 1; index < size; index ++) begin
                prop_input_weight [index] <= prop_input_weight [index - 1'b1];
            end
            prop_input_weight[0] <= input_weight;
        end
    end

    always@(*) begin
        for (int index = 0; index < size; index ++) begin
            next_output_weight[index] = output_weight[index];
        end
        next_output_weight[0] = output_weight[0] + input_weight * net_weight[0];
        for (int index = 1; index < size; index ++) begin
            next_output_weight[index] = output_weight[index] + net_weight[index] * prop_input_weight[index - 1];
        end
    end
endmodule
