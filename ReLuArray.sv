module ReLuArray(in, out);
    parameter size = 100;
    input [31:0] in[0:size - 1];
    output reg [31:0] out[0:size - 1];

    always@(*) begin
        for (int index = 0; index < 100; index ++) begin
            if (in[index] > 0) begin
                out[index] = in[index];
            end else begin
                out[index] = 32'd0;
            end
        end
    end
endmodule
