module KNN_PCPI(
	input                clk, resetn,
	input                pcpi_valid,
	input         [31:0] pcpi_insn,
	input         [31:0] pcpi_rs1,
	input         [31:0] pcpi_rs2,
	output               pcpi_wr,
	output reg    [31:0] pcpi_rd,
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
	parameter STATE_WAIT        = 3'b000;
	parameter STATE_FETCH_TRAIN = 3'b001;
	parameter STATE_FETCH_TEST  = 3'b010;
	parameter STATE_CALC        = 3'b011;
	parameter STATE_RETRV_TEST  = 3'b100;
	parameter STATE_RETRV_TRAIN = 3'b101;
	parameter NUM_CLASS		    = 10;
	parameter NUM_TEST_IMAGE    = 50;
	parameter NUM_TRAIN_IMAGE	= 950;
	parameter IMAGE_OFFSET 		= 65536;
	parameter DATA_LENGTH 		= 3073;

	parameter delay = 1;
	wire pcpi_insn_valid = pcpi_valid && pcpi_insn[6:0] == 7'b0101011 && pcpi_insn[31:25] == 7'b0000001;

	reg [3-1:0] state, next_state;
	reg [12-1:0] count, next_count;
	reg [32-1:0] next_addr;
	reg [32-1:0] test_addr, next_test_addr;
	reg [32-1:0] train_addr, next_train_addr;
	reg [32-1:0] train_data, next_train_data;
	reg [32-1:0] test_data, next_test_data;
	reg [32-1:0] result, next_result;
	wire done;
	assign done = (state == STATE_CALC && count == 32'd3072);
	assign pcpi_wr = done;
	assign pcpi_ready = done;
	assign pcpi_wait = (state != STATE_WAIT);
	
	always@(posedge clk or negedge resetn) begin
		if (!resetn) begin
			state      <= #(delay) STATE_WAIT;
			count      <= #(delay) 12'd1;	
			mem_addr   <= #(delay) 32'd0;
			test_addr  <= #(delay) 32'd0;
			train_addr <= #(delay) 32'd0;
			test_data  <= #(delay) 32'd0;
			train_data <= #(delay) 32'd0;
			result     <= #(delay) 32'd0;
		end
		else begin
			state      <= #(delay) next_state;
			count      <= #(delay) next_count;
			mem_addr   <= #(delay) next_addr;
			test_addr  <= #(delay) next_test_addr;
			train_addr <= #(delay) next_train_addr;
			test_data  <= #(delay) next_test_data;
			train_data <= #(delay) next_train_data;
			result     <= #(delay) next_result;
		end
	end

	always@(*) begin
		next_state      = state;
		next_addr       = mem_addr;
		next_test_addr  = test_addr;
		next_train_addr = train_addr;
		case(state) 
			STATE_WAIT: begin
				next_state = (!pcpi_insn_valid)? STATE_WAIT: STATE_FETCH_TRAIN;
				next_addr  = (!pcpi_insn_valid)? 32'd0: IMAGE_OFFSET + (pcpi_rs2) * DATA_LENGTH * 4 + count * 4; 
				next_train_addr = (!pcpi_insn_valid)? 32'd0: IMAGE_OFFSET + (pcpi_rs2) * DATA_LENGTH * 4 + count * 4; 
				next_test_addr  = IMAGE_OFFSET + pcpi_rs1 * DATA_LENGTH * 4 +  count * 4;
			end	
			STATE_FETCH_TRAIN: begin
				next_state = STATE_RETRV_TRAIN;
				next_addr  = train_addr;
				next_train_addr = train_addr;
				next_test_addr  = test_addr;
			end
			STATE_RETRV_TRAIN: begin
				next_state = STATE_FETCH_TEST;
				next_addr  = test_addr;
				next_train_addr = train_addr + 32'd4;
				next_test_addr  = test_addr;
			end
			STATE_FETCH_TEST: begin
				next_state = STATE_RETRV_TEST;
				next_addr = test_addr;
				next_train_addr = train_addr;
				next_test_addr = test_addr;
			end
			STATE_RETRV_TEST: begin
				next_state = STATE_CALC;
				next_addr = train_addr;
				next_train_addr = train_addr;
				next_test_addr  = test_addr + 32'd4;
			end
			STATE_CALC: begin
				next_state = (count == 32'd3072)? STATE_WAIT: STATE_FETCH_TRAIN;
				next_addr  = (count == 32'd3072)? 32'd0: train_addr;
				next_train_addr = (count == 32'd3072)? 32'd0: train_addr;
				next_test_addr  = (count == 32'd3072)? 32'd0: test_addr;
			end
		endcase
	end

	always@(*) begin
		next_train_data = train_data;
		if(state == STATE_RETRV_TRAIN) begin
			next_train_data = mem_rdata; 	
		end
	end

	always@(*) begin
		next_test_data = test_data;
		if (state == STATE_RETRV_TEST) begin
			next_test_data = mem_rdata;
		end	
	end
	
	always@(*) begin
		next_count = count;
		if (state == STATE_CALC) begin
			if (!done) next_count = count + 1;
			else next_count = 32'd1;
		end
	end

	always@(*) begin 
		next_result = result;
		if (state == STATE_CALC) begin
			if (!done) begin
				next_result = result + (train_data - test_data) * (train_data - test_data);
			end else begin
				next_result = 32'd0;
			end
		end
	end
	
	always@(*) begin
		if (done) begin
			pcpi_rd = result + (train_data - test_data) * (train_data - test_data);	
		end
	end
	//TODO: Memory interface. Modify these values to fit your needs
	assign mem_write = 0;
	assign mem_valid = 1;
	assign mem_wdata = 0;
	
	//TODO: Implement your k-NN design below
	
endmodule
