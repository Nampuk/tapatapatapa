
module adder #(parameter WIDTH = 8) (
	input  wire         carry_in,
	input  wire [WIDTH-1:0] a,
	input  wire [WIDTH-1:0] b,
	output wire [WIDTH-1:0] res,
	output wire         carry_out
);

localparam MSB = WIDTH-1;

logic [WIDTH:0] tmp = carry_in ? (a + b + 1) : (a + b);

assign res = tmp[MSB:0];
assign carry_out = tmp[WIDTH];

endmodule
