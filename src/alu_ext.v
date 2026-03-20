
module alu_ext (
	input  wire  [2:0] ctl,
	input wire increment,
	input [7:0] a_lo,
	input [7:0] a_hi,
	input [7:0] b_lo,
	input [7:0] b_hi,
	output [7:0] res_lo,
	output [7:0] res_hi,
	output wire  [3:0] flags
);

localparam CF = 2'd3;

wire [7:0] alu_res;
wire [3:0] alu_flags;
wire alu_carry = alu_flags[CF];

alu #(.WIDTH(8)) alu_inst (
	.ctl(ctl),
	.increment(increment),
	.a(a_lo),
	.b(b_lo),
	.res(alu_res),
	.flags(alu_flags)
);

wire hi_carry;
adder #(.WIDTH(8)) adder_inst (
	.carry_in(alu_carry),
	.a(a_hi),
	.b(b_hi),
	.res(res_hi),
	.carry_out(hi_carry)
);

assign res_lo = alu_res;
assign flags = alu_flags;

wire _unused = &{hi_carry};


endmodule
