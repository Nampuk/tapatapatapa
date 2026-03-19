
/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_nampukk_top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  assign uio_out = 0;
  assign uio_oe  = 0;

wire [3:0] addr = ui_in[7:4];
wire [3:0] nibble  = ui_in[3:0];

reg [2:0] ctl;
reg carry;
reg [7:0] a;
wire [7:0] b = uio_in;

wire [3:0] oflags;

alu #(.WIDTH(8)) inst (
	.ctl(ctl),
	.a(a),
	.b(b),
	.increment(carry),
	.res(uo_out),
	.flags(oflags)
);

always @(posedge clk) begin
	if (!rst_n) begin
		a <= 0;
		ctl <= 0;
		carry <= 0;
	end else begin
		case (addr)
			0: begin
			end
			1: begin
				ctl <= nibble[2:0];
				carry <= nibble[3];
			end
			2: begin
				a[3:0] <= nibble;
			end
			3: begin
				a[7:4] <= nibble;
			end
		endcase
	end
end

  // List all unused inputs to prevent warnings

wire _unused = &{ena, clk, rst_n, 1'b0, oflags};

endmodule
