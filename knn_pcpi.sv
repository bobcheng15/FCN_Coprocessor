
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

module NN_PCPI(
	input                clk, resetn,
	input                pcpi_valid,
	input         [31:0] pcpi_insn,
	input         [31:0] pcpi_rs1,
	input         [31:0] pcpi_rs2,
	output               pcpi_wr,
	output        [31:0] pcpi_rd,
	output               pcpi_wait,
	output               pcpi_ready,
	//memory interface
	input         [31:0] mem_rdata,
	input                mem_ready,
	output               mem_valid,
	output               mem_write,
	output reg    [31:0] mem_addr,
	output        [31:0] mem_wdata
);
    parameter STATE_IDLE             = 3'b110;
	parameter STATE_WRITE_REG_FILE_1 = 3'b000;
    parameter STATE_WRITE_REG_FILE_2 = 3'b001;
    parameter STATE_READ_INPUT       = 3'b010;
    parameter STATE_MAX              = 3'b011;
	parameter STATE_SYS_PROP_1		 = 3'b100;
	parameter STATE_SYS_RPOP_2		 = 3'b101;
    parameter STATE_READ             = 1'b0;
    parameter STATE_RETRV            = 1'b1;


    parameter net_weight_base_1      = 32'd65536;
    parameter net_weight_base_2      = 32'd379136;
    parameter net_weight_limit_1     = 32'd379132;
    parameter net_weight_limit_2     = 32'd383132;
	parameter pic_input_base 	     = 32'd383136;
	parameter pic_input_limit	     = 32'd386268;

	parameter delay = 1;
	wire pcpi_insn_valid = pcpi_valid && pcpi_insn[6:0] == 7'b0101011 && pcpi_insn[31:25] == 7'b0000001;

    reg [3-1:0]  state, next_state;
    reg [3-1:0]  read_state, next_read_state;
    reg [31:0]   next_raddr;
    reg [31:0]   net_weight1 [0:99][0:783];
    reg [31:0]   next_net_weight1 [0:99][0:783];
    reg [31:0]   net_weight2 [0:9][0:99];
    reg [31:0]   next_net_weight2 [0:9][0:99];
    reg [31:0]   pic_input [0:783];
    reg [31:0]   next_pic_input [0:783];
    reg [31:0]   index_i, next_index_i;
    reg [31:0]   index_j, next_index_j;
    wire [31:0]  tmp0;
    wire [31:0]  tmp1;
    wire [31:0]  tmp2;
    wire [31:0]  tmp3;
    wire [31:0]  tmp4;
    wire [31:0]  tmp5;
    wire [31:0]  tmp6;
    wire [31:0]  tmp7;
    wire [31:0]  tmp8;
    wire [31:0]  tmp9;

	reg signed [31:0]	 sys_input_data;
	reg signed [31:0] 	 sys_input_weight[0:99];
 	wire signed [31:0]  output_layer1 [0:99];
	reg [31:0]  recitfied_layer1[0:99];
	reg [31:0]   interm_result[0:99];
	reg [31:0]   next_interm_result[0:99];
	reg [31:0]   result[0:99];
	reg [31:0]	 next_result[0:99];
    reg [3:0]    max_index, next_max_index;
    reg [31:0]   max, next_max;
    reg [4:0]    image_index, next_image_index;
	reg rst_sys, next_rst_sys;
    reg loaded, next_loaded;
    reg done;
    wire [31:0] data;
    assign data = pic_input[0];
    assign pcpi_rd = max_index;
	assign pcpi_ready = done;
	assign pcpi_wait = (state == STATE_IDLE)? 0: 1;
	assign pcpi_wr = done;


    assign tmp0 = recitfied_layer1[0];
    assign tmp1 = recitfied_layer1[1];

    assign tmp2 = recitfied_layer1[2];

    assign tmp3 = recitfied_layer1[3];

    assign tmp4 = recitfied_layer1[4];

    assign tmp5 = recitfied_layer1[5];

    assign tmp6 = recitfied_layer1[6];

    assign tmp7 = recitfied_layer1[7];

    assign tmp8 = recitfied_layer1[8];
    assign tmp9 = recitfied_layer1[9];

 	SystolicArray#(100) sys(clk, rst_sys, sys_input_data, sys_input_weight, output_layer1);


    always@(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state      <= #(delay)STATE_IDLE;
            read_state <= #(delay)STATE_READ;
            mem_addr      <= #(delay)net_weight_base_1;
            index_i    <= #(delay)32'd0;
            index_j    <= #(delay)32'd0;
			rst_sys    <= #(delay)32'd1;
            max_index  <= #(delay)32'd0;
            max        <= #(delay)32'd0;
            image_index<= #(delay)5'd0;
            loaded     <= #(delay)1'b0;
        end else begin
            state      <= #(delay)next_state;
            read_state <= #(delay)next_read_state;
            mem_addr      <= #(delay)next_raddr;
            net_weight1<= #(delay)next_net_weight1;
            net_weight2<= #(delay)next_net_weight2;
            index_i    <= #(delay)next_index_i;
            index_j    <= #(delay)next_index_j;
			interm_result <= #(delay) next_interm_result;
			result     <= #(delay)next_result;
			rst_sys    <= #(delay)next_rst_sys;
            pic_input  <= #(delay)next_pic_input;
            max_index  <= #(delay)next_max_index;
            max        <= #(delay)next_max;
            image_index<= #(delay)next_image_index;
            loaded     <= #(delay)next_loaded;
        end
    end

    always@(*) begin
		//$display("go");
        next_state       = state;
        next_raddr       = mem_addr;
        next_read_state  = read_state;
        next_net_weight1 = net_weight1;
        next_net_weight2 = net_weight2;
        next_index_i     = index_i;
        next_index_j     = index_j;
		next_interm_result = interm_result;
		next_result = result;
		next_rst_sys = rst_sys;
        next_pic_input = pic_input;
        next_max_index = max_index;
        next_max       = max;
        next_image_index = image_index;
        next_loaded    = loaded;
        case(state)
            STATE_IDLE: begin
                next_image_index        = (pcpi_insn_valid)? pcpi_rs1: image_index;
                if (loaded) begin
                    next_raddr = (pcpi_insn_valid)? pic_input_base + pcpi_rs1 * 784 * 4: 32'd0;
                    next_state = (pcpi_insn_valid)? STATE_READ_INPUT: state;
                    next_read_state = STATE_READ;
                end else begin
                    next_raddr = net_weight_base_1;
                    next_state = (pcpi_insn_valid)? STATE_WRITE_REG_FILE_1: state;
                    next_read_state = STATE_READ;
                end
            end
            STATE_WRITE_REG_FILE_1: begin
                case(read_state)
                    STATE_READ: begin
                        next_state      = STATE_WRITE_REG_FILE_1;
                        next_raddr      = mem_addr;
                        next_read_state = STATE_RETRV;
                    end
                    STATE_RETRV: begin
                        next_state       = (mem_addr == net_weight_limit_1)? STATE_WRITE_REG_FILE_2: state;
                        next_read_state  = STATE_READ;
                        next_raddr       = mem_addr + 4;
                        next_net_weight1[index_i][index_j] = mem_rdata;
						if (mem_addr == net_weight_limit_1) begin
							next_index_i = 32'd0;
							next_index_j = 32'd0;
                        end else begin
							next_index_i = (index_j == 32'd783)? index_i + 1: index_i;
							next_index_j = (index_j == 32'd783)? 32'd0      : index_j + 1;
						end
                    end
                endcase
            end
            STATE_WRITE_REG_FILE_2: begin
                case(read_state)
                    STATE_READ: begin
                        next_state      = STATE_WRITE_REG_FILE_2;
                        next_raddr      = mem_addr;
                        next_read_state = STATE_RETRV;
                    end
                    STATE_RETRV: begin
                        next_state      = (mem_addr == net_weight_limit_2)? STATE_READ_INPUT: state;
                        next_read_state = STATE_READ;
                        next_raddr      = (mem_addr == net_weight_limit_2)? pic_input_base + image_index * 784  * 4: mem_addr + 4;
                        next_net_weight2[index_i][index_j] = mem_rdata;
						if (mem_addr == net_weight_limit_2) begin
							next_index_i = 32'd0;
							next_index_j = 32'd0;
                            next_loaded = 1'b1;
						end else begin
	                        next_index_i = (index_j == 32'd99)? index_i + 1: index_i;
	                        next_index_j = (index_j == 32'd99)? 32'd0      : index_j + 1;
						end
                    end
                endcase
            end
            STATE_READ_INPUT: begin
				case(read_state)
					STATE_READ: begin
						next_state      = state;
						next_raddr      = mem_addr;
						next_read_state = STATE_RETRV;
					end
					STATE_RETRV: begin
						next_state      = (mem_addr == pic_input_limit + image_index * 784 * 4)? STATE_SYS_PROP_1 : state;
						next_read_state = STATE_READ;
						next_raddr      = mem_addr + 4;
						next_pic_input[index_i] = mem_rdata;
						next_index_i = (mem_addr == pic_input_limit + image_index * 784 * 4)? 32'd0: index_i + 1'b1;
						next_rst_sys = (mem_addr == pic_input_limit + image_index * 783 * 4)? 1'b0: 1'b1;
					end
				endcase
			end
			STATE_SYS_PROP_1: begin
				next_state = (index_i == 32'd885)? STATE_SYS_RPOP_2: state;
				next_raddr = 32'd0;
				next_index_i = (index_i == 32'd885)? 32'd0: index_i + 1'b1;
				next_interm_result = (index_i == 885)? recitfied_layer1: interm_result;
                next_rst_sys = (index_i == 884)? 1'b0: 1'b1;

			end
			STATE_SYS_RPOP_2: begin
				next_state = (index_i == 32'd111)? STATE_MAX: state;
				next_raddr = 32'd0;
				next_index_i = (index_i == 32'd111)? 32'd0: index_i + 1'b1;
				next_result = (index_i == 32'd110)? recitfied_layer1: result;
                next_rst_sys = (index_i == 32'd110)? 1'b0: 1'b1;
			end
            STATE_MAX: begin
                next_state = (index_i == 32'd10)? STATE_IDLE: state;
                next_index_i = (index_i == 32'd10)? 32'd0: index_i + 1;
                if (index_i < 32'd10) begin
                    next_max = (max < result[index_i])? result[index_i]: max;
                    next_max_index= (max < result[index_i])? index_i: max_index;
                end else begin
                    next_max = 32'd0;
                    next_max_index = 32'd0;
                end

            end
        endcase
    end
	always@(*) begin
		case(state)
			STATE_SYS_PROP_1: begin
				sys_input_data = (index_i < 784)? pic_input[index_i]: 32'd0;
				for (int index = 0; index < 100; index ++) begin
					if (index_i < index) begin
						sys_input_weight[index] = 32'd0;
					end else begin
						if (index_i > 783 + index) begin
							sys_input_weight[index] = 32'd0;
						end else begin
							sys_input_weight[index] = net_weight1[index][index_i - index];
						end
					end
				end
			end
			STATE_SYS_RPOP_2: begin
				sys_input_data = (index_i < 100)? interm_result[index_i]: 32'd0;
				for (int index = 0; index < 100; index ++) begin
					if (index_i < index) begin
						sys_input_weight[index] = 32'd0;
					end else begin
						if (index_i > 99 + index) begin
							sys_input_weight[index] = 32'd0;
						end else begin
							sys_input_weight[index] = net_weight2[index][index_i - index];
						end
					end
				end
			end
			default: begin
				sys_input_data = 32'd0;
				for (int index = 0; index < 100; index ++) begin
					sys_input_weight[index] = 32'd0;
				end
			end
		endcase
	end
    always@(*) begin
        if (index_i == 10 && state == STATE_MAX) begin
            done = 1'b1;
        end else begin
            done = 1'b0;
        end
    end
	always@(*) begin
        for (int index = 0; index < 100; index ++) begin
            if (output_layer1[index] > 0) begin
                recitfied_layer1[index] = output_layer1[index];
            end else begin
                recitfied_layer1[index] = 32'd0;
            end
        end
    end

	assign mem_write = 0;
	assign mem_valid = 1;
	assign mem_wdata = 0;

endmodule
