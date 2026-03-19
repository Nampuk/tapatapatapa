
module alu_tb();

// Overflow (result > INT_MAX): (b < 0) && (a > INT_MAX + b)
// Underflow (result < INT_MIN): (b > 0) && (a < INT_MIN + b)

localparam
	W = 8,
	MSB = W-1,
	LSB = 0;

reg  [2:0] alu_ctl;
reg [MSB:LSB] a;
reg [MSB:LSB] b;
reg inc;

wire signed [MSB:LSB] sa = a;
wire signed [MSB:LSB] sb = b;

wire [MSB:LSB] alu_res;
wire  [3:0] alu_flags;

reg [MSB:LSB] exp_res;
wire signed [MSB:LSB] sr = exp_res;

reg exp_o;
wire  [2:0] cmp_flags = { sa > sb, sa == sb, sa < sb  };

wire alu_carry = alu_flags[alu_inst.CF];
wire [2:0] alu_cmp = alu_flags[2:0];

reg check_carry;
wire error = check_carry
	? (exp_o != alu_carry | alu_res[MSB:LSB] != exp_res[MSB:LSB])
	: cmp_flags != alu_cmp;

function [MSB:LSB] negative(input [MSB:LSB] val);
	negative = (~val) + 1;
endfunction

alu #(.WIDTH(W)) alu_inst (
	.ctl(alu_ctl),
	.a(a),
	.b(b),
	.increment(inc),
	.res(alu_res),
	.flags(alu_flags)
);

wire [MSB:LSB] sub_res;
wire  [3:0] sub_flags;
alu #(.WIDTH(W)) alu_sub_via_add (
	.ctl(alu_sub_via_add.ADD),
	.a(a),
	.increment(0),
	.b(negative(b)),
	.res(sub_res),
	.flags(sub_flags)
);

initial begin
	inc = 0;

	$display("============================================================");
	$display("STATS");
	$display("============================================================");
	$display("Size: %d", $size(a));
	$display("Bits: %d", $bits(a));
	$display("MSB         = %d", alu_inst.MSB);
	$display("LSB         = %d", alu_inst.LSB);
	$display("POSBITS     = %d", alu_inst.POSBITS);
	$display("MINUS_ONE   = %b | %d", alu_inst.MINUS_ONE, alu_inst.MINUS_ONE);
	$display("MIN_VAL     = %b | %d", alu_inst.MIN_VAL, alu_inst.MIN_VAL);
	$display("MAX_VAL     = %b | %d", alu_inst.MAX_VAL, alu_inst.MAX_VAL);


	$display("============================================================");
	$display("SANITY CHECKS: ADD MODE");
	$display("============================================================");

	check_carry = 1;
	alu_ctl = alu_inst.ADD;
	$display("Overflow by one");
	a = alu_inst.MAX_VAL; b = 1; exp_res = alu_inst.MIN_VAL; exp_o = 1;
	#1;
	$display(
		"mode:%h  | a=%h b=%h res=%h (%h) | carry=%b (%b) error=%b",
		alu_ctl, a, b, alu_res, exp_res, alu_carry, exp_o, error);

	$display("Overflow by one");
	alu_ctl = alu_inst.ADD;
	a = alu_inst.MAX_VAL; b = 1; exp_res = alu_inst.MIN_VAL; exp_o = 1;
	#1;
	$display(
		"mode:%h  | a=%h b=%h res=%h (%h) | carry=%b (%b) error=%b",
		alu_ctl, a, b, alu_res, exp_res, alu_carry, exp_o, error);

	$display("max + max");
	alu_ctl = alu_inst.ADD;
	a = alu_inst.MAX_VAL; b = alu_inst.MAX_VAL; exp_res = { {(alu_inst.WIDTH-1){1'b1}}, 1'b0}; exp_o = 1;
	#1;
	$display(
		"mode:%h  | a=%h b=%h res=%h (%h) | carry=%b (%b) error=%b",
		alu_ctl, a, b, alu_res, exp_res, alu_carry, exp_o, error);

	// $display("============================================================");
	// $display("COMPARISONS");
	// $display("============================================================");
	// alu_ctl = alu_inst.ADD;
	// check_carry = 0;
	// for (int ia = 0; ia <= alu_inst.MINUS_ONE; ia=ia+1) begin
	// for (int ib = 0; ib <= alu_inst.MINUS_ONE; ib=ib+1) begin
	// 	a = ia[MSB:LSB]; b = ib[MSB:LSB];
	// 	#1;
	// 	$display(
	// 		"mode:%h  | a=%d (%d) b=%d (%d) | LT=%b(%b) EQ=%b(%b) GT=%b(%b) | flags=%b (%b) error=%b",
	// 		alu_ctl, a, sa, b, sb, alu_flags[alu_inst.LT], cmp_flags[alu_inst.LT], alu_flags[alu_inst.EQ], cmp_flags[alu_inst.EQ], alu_flags[alu_inst.GT], cmp_flags[alu_inst.GT], alu_cmp, cmp_flags, error);
	// end end
	// check_carry = 1;

	$display("============================================================");
	$display("MODE ADD");
	$display("============================================================");
	alu_ctl = alu_inst.ADD;
	for (int ia = 0; ia <= alu_inst.MINUS_ONE; ia=ia+1) begin
	for (int ib = 0; ib <= alu_inst.MINUS_ONE; ib=ib+1) begin
		a = ia[MSB:LSB]; b = ib[MSB:LSB];
		exp_o = (~ia[MSB] & ~ib[MSB] & ia + ib > alu_inst.MAX_VAL) | (a[MSB] & b[MSB] & ~{ia + ib}[MSB]); // TODO: das ist unsauber
		exp_res = {ia + ib}[MSB:LSB];
		#1;
		$display(
			"mode:%h  | a=%d b=%d res=%d (%d (%d) = %d + %d) | carry=%b (%b) error=%b",
			alu_ctl, a, b, alu_res, exp_res, sr, sa, sb, alu_carry, exp_o, error);
	end end

	// $display("============================================================");
	// $display("MODE SUB");
	// $display("============================================================");
	// alu_ctl = alu_inst.SUB;
	// for (int ia = 0; ia <= alu_inst.MINUS_ONE; ia=ia+1) begin
	// for (int ib = 0; ib <= alu_inst.MINUS_ONE; ib=ib+1) begin
	// 	a = ia[MSB:LSB]; b = ib[MSB:LSB];
	// 	exp_o = (~ia[MSB] & ~ib[MSB] & ia + ib > alu_inst.MAX_VAL) | (a[MSB] & b[MSB] & ~{ia + ib}[MSB]); // TODO: das ist unsauber
	// 	exp_res = {ia + ib}[MSB:LSB];
	// 	#1;
	// 	$display(
	// 		"mode:%h  | a=%d b=%d res=%d (%d (%d) = %d + %d) | carry=%b (%b) error=%b",
	// 		alu_ctl, a, b, alu_res, exp_res, sr, sa, sb, alu_carry, exp_o, error);
	// end end

	// $display("============================================================");
	// $display("MODE ADD");
	// $display("============================================================");
	// alu_ctl = alu_inst.ADD;
	// for (int ia = 0; ia <= alu_inst.MINUS_ONE; ia=ia+1) begin
	// for (int ib = 0; ib <= alu_inst.MINUS_ONE; ib=ib+1) begin
	// 	a = ia[MSB:LSB]; b = ib[MSB:LSB];
	// 	exp_o = (~ia[MSB] & ~ib[MSB] & ia + ib > alu_inst.MAX_VAL) | (a[MSB] & b[MSB] & ~{ia + ib}[MSB]); // TODO: das ist unsauber
	// 	exp_res = {ia + ib}[MSB:LSB];
	// 	#1;
	// 	$display(
	// 		"mode:%h  | a=%d b=%d res=%d (%d (%d) = %d + %d) | carry=%b (%b) error=%b",
	// 		alu_ctl, a, b, alu_res, exp_res, sr, sa, sb, alu_carry, exp_o, error);
	// end end

end

endmodule
