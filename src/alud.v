
module alu_d #(parameter WIDTH = 16) (
	input  wire  [2:0] ctl,
	input  wire [MSB:LSB] a,
	input  wire [MSB:LSB] b,
	input wire increment,
	output wire [MSB:LSB] res,
	output wire  [3:0] flags
);

localparam
	MSB         = WIDTH - 1,
	LSB         = 0,
	POSBITS     = WIDTH - 1,
	MINUS_ONE   = { WIDTH{1'b1} },
	MIN_VAL     = {1'b1,  {POSBITS{1'b0}} },
	MAX_VAL     = {1'b0,  {POSBITS{1'b1}} };

localparam
	AND = 3'b000,
	 OR = 3'b001,
	ADD = 3'b010,
	SUB = 3'b011,
	XOR = 3'b100,
	NOT = 3'b101,
	SHL = 3'b110,
	SHR = 3'b111;

localparam
	LT = 2'd0,
	EQ = 2'd1,
	GT = 2'd2,
	CF = 2'd3;

function [MSB:LSB] negative(input [MSB:LSB] val);
	negative = (~val) + 1;
endfunction

wire shut_up =  MINUS_ONE | MIN_VAL & MAX_VAL | LT & EQ & GT & CF;

wire lt_flag = (~a[MSB] & ~b[MSB] & a < b) | (a[MSB] && ~b[MSB]) | (a[MSB] & b[MSB] & a < b);
wire gt_flag = ~lt_flag & a != b;
wire eq_flag = a == b;
wire carry_flag;

assign flags[3:0] = {carry_flag, gt_flag, eq_flag, lt_flag };

function [MSB:LSB] alu_calc();
	case(ctl)
		AND : alu_calc = a & b;
		NOT : alu_calc =   ~a;
		ADD : alu_calc = increment ? (a + b + '1) : (a + b);
		SUB : alu_calc = a + negative(b);
		OR  : alu_calc = a | b;
		XOR : alu_calc = a ^ b;
		SHL : alu_calc = { a[MSB-1:LSB], 1'b0 };
		SHR : alu_calc = { 1'b0, a[MSB:LSB+1] };
	endcase
endfunction

function [0:0] alu_carry();
	case(ctl)
		AND : alu_carry = 1'b0;
		NOT : alu_carry = 1'b0;
		ADD : alu_carry = (a[MSB] & b[MSB] & ~res[MSB]) | (~a[MSB] & ~b[MSB] & res[MSB]); // two negative becomes positive | two positive becomes negative
		SUB : alu_carry = (a[MSB] & ~b[MSB] & ~res[MSB]) | (~a[MSB] & b[MSB] & res[MSB]); // negative - positive becomes positive | positive - negative becomes negative
		OR  : alu_carry = 1'b0;
		XOR : alu_carry = (a & b) != 0;
		SHL : alu_carry = a[MSB];
		SHR : alu_carry = a[0];
	endcase
endfunction

assign res = alu_calc();
assign carry_flag = alu_carry();

endmodule
