

// tt_nampuk_top
module top(
	input  wire       clk,
	input  wire       rst_n,
	input  wire [7:0] ui_in,
	output wire [7:0] uo_out,
	inout  wire [7:0] uio
);

wire spi_miso;
wire spi_select;
wire spi_clk_out;
wire spi_mosi;

localparam INSTRUCTION_WIDTH = 16;
parameter WORD_WITH = 8;

localparam
	MSB = WORD_WITH-1,
	LSB = 0;

reg [(8*10)-1:0] register;


localparam
	flag_lt    = 2'd0,
	flag_eq    = 2'd1,
	flag_gt    = 2'd2,
	flag_carry = 2'd3;

reg [3:0] flags;
reg [15: 0] current_instruction;


wire [1:0] i_mode_outer;
wire [1:0] i_mode_inner;
wire [2:0] i_alu_ctl;
wire       i_alu_carry;
wire [1:0] i_dst;
wire [1:0] i_src_1;
wire [1:0] i_src_2;
wire [7:0] i_word;
wire [3:0] i_flag_mask;

idecoder decoder_inst (
	.instruction(current_instruction),
	.mode_outer(i_mode_outer),
	.mode_inner(i_mode_inner),
	.ctl_alu(i_alu_ctl),
	.ctl_carry(i_alu_carry),
	.dst(i_dst),
	.src_1(i_src_1),
	.src_2(i_src_2),
	.word(i_word),
	.flag_mask(i_flag_mask)
);

wire is_memory_op;
wire is_immediate;

wire [MSB:0] s1 = register[(i_src_1*8) +: 8];
wire [MSB:0] s2 = register[(i_src_2*8) +: 8];
wire [MSB:0] m_hi;
wire [MSB:0] m_lo;
wire [MSB:0] word_lo = i_word;
wire [MSB:0] word_hi = {8{i_word[7]}}; // sign extend


// wire [MSB:0] alpha_lo = is_memory_op ? m_lo : s1;
// wire [MSB:0] alpha_hi = m_hi;
// //
// wire [MSB:0] beta_lo = is_immediate ? word_lo : s2;
// wire [MSB:0] beta_hi = word_hi;

wire [MSB:0] alpha_lo;
wire [MSB:0] alpha_hi;
//
wire [MSB:0] beta_lo;
wire [MSB:0] beta_hi;

wire  [2:0] alu_ctl;
wire [MSB:0] alu_a = alpha_lo;
wire [MSB:0] alu_b = beta_lo;
wire [MSB:0] alu_res;
wire  [3:0] alu_flags;
wire did_overflow = alu_flags[flag_carry];

alu #(.WIDTH(8)) alu_inst (
	.ctl(alu_ctl),
	.a(alu_a),
	.b(alu_b),
	.increment(0), // TODO: fixme
	.res(alu_res),
	.flags(alu_flags)
);

adder #(.WIDTH(8)) adder_inst (
	.carry_in(did_overflow),
	.a(alpha_hi),
	.b(beta_hi),
	.res(gamma_hi),
	.carry_out(gamma_carry)
);

wire gamma_carry;
wire [MSB:0] gamma_lo = alu_res;
wire [MSB:0] gamma_hi;

wire [MSB:0] delta = register[(i_src_1*8) +: 8];

wire [15:0] mem_addr;
wire [7:0] mem_data_in;
wire mem_is_write;
wire mem_start;
wire [7:0] mem_data_out;
wire mem_busy;

memio memory_inst (
	.clk(clk),
	.rst_n(rst_n),
	// External SPI interface
	.spi_miso(spi_miso),
    .spi_select(spi_select),
    .spi_clk_out(spi_clk_out),
    .spi_mosi(spi_mosi),
	//
	.addr_in(mem_addr),
	.data_in(mem_data_in),
	.is_write(mem_is_write),
	.start(mem_start),
	.data_out(mem_data_out),
	.busy(mem_busy)
);

localparam
	STATE_IDLE     = 3'd0,
	STATE_FETCH_LO = 3'd1,
	STATE_WAIT_LO  = 3'd2,
	STATE_FETCH_HI = 3'd3,
	STATE_WAIT_HI  = 3'd4,
	STATE_EXEC     = 3'd5,
	STATE_WAIT_MEM = 3'd6,
	STATE_WRAPUP   = 3'd7;

reg [2:0] state;

function alpha_lo_driver();
	case (state)
		STATE_IDLE:     alpha_lo_driver = 0;
		STATE_FETCH_LO: alpha_lo_driver = 0;
		STATE_WAIT_LO:  alpha_lo_driver = 0;
		STATE_FETCH_HI: alpha_lo_driver = 0;
		STATE_WAIT_HI:  alpha_lo_driver = 0;
		STATE_EXEC,
		STATE_WAIT_MEM,
		STATE_WRAPUP:   alpha_lo_driver = 0;
	endcase
endfunction

function alpha_hi_driver();
	case (state)
		STATE_IDLE:     alpha_hi_driver = 0;
		STATE_FETCH_LO: alpha_hi_driver = 0;
		STATE_WAIT_LO:  alpha_hi_driver = 0;
		STATE_FETCH_HI: alpha_hi_driver = 0;
		STATE_WAIT_HI:  alpha_hi_driver = 0;
		STATE_EXEC,
		STATE_WAIT_MEM,
		STATE_WRAPUP:   alpha_hi_driver = 0;
	endcase
endfunction

always @(posedge clk) begin
	if (!rst_n) begin
		register <= '0;
		current_instruction <= '0;
		flags <= '0;
		state <= STATE_IDLE;
	end else begin
	case (state)
		STATE_IDLE: begin
			state <= STATE_FETCH_LO;
		end
		STATE_FETCH_LO: begin
			state <= STATE_WAIT_LO;
		end
		STATE_WAIT_LO: begin
			if (mem_busy) begin
				state <= STATE_WAIT_LO;
			end else begin
				current_instruction[7:0] <= mem_data_out;
				state <= STATE_FETCH_HI;
			end
		end
		STATE_FETCH_HI: begin
			state <= STATE_WAIT_HI;
		end
		STATE_WAIT_HI: begin
			if (mem_busy) begin
				state <= STATE_WAIT_HI;
			end else begin
				current_instruction[15:8] <= mem_data_out;
				state <= STATE_EXEC;
			end
		end
		STATE_EXEC: begin
		end
		STATE_WAIT_MEM: begin
		end
		STATE_WRAPUP: begin
		end
	endcase
	end
end

endmodule
