
module idecoder (
	input  wire [15:0]	instruction,
	output wire [1:0]	mode_outer,
	output wire [1:0]	mode_inner,
	output wire [2:0]	ctl_alu,
	output wire			ctl_carry,
	output wire [1:0]	dst,
	output wire [1:0]	src_1,
	output wire [1:0]	src_2,
	output wire [7:0]	word,
	output wire [3:0]	flag_mask
);

assign mode_outer = instruction[15:14];
assign mode_inner = instruction[11:10];
assign ctl_alu = instruction[3:1];
assign ctl_carry = instruction[0];
assign dst = instruction[13:12];
assign src_1 = instruction[9:8];
assign src_2 = instruction[5:4];
assign word = instruction[7:0];
assign flag_mask = instruction[13:10];

endmodule

