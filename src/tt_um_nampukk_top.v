
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
assign uio_out = 0;
assign uio_oe  = 0;

assign uio_out = 0;
assign uio_oe  = 0;

wire [7:0] _output;
assign uo_out = _output;


wire [1:0] addr = ui_in[5:4];
wire [1:0] command  = ui_in[7:6];
wire [3:0] alu_mode  = ui_in[3:0];

wire [7:0] word = uio_in;


wire [2:0] ctl = alu_mode[2:0];
wire carry = alu_mode[3];

reg [7:0] a_lo;
reg [7:0] a_hi;
reg [7:0] b_lo;
reg [7:0] b_hi;


wire [7:0] res_lo;
wire [7:0] res_hi;
wire [3:0] res_flags;

alu_ext inst (
	.ctl(ctl),
	.a_lo(a_lo),
	.a_hi(a_hi),
	.b_lo(b_lo),
	.b_hi(b_hi),
	.increment(carry),
	.res_lo(res_lo),
	.res_hi(res_hi),
	.flags(res_flags)
);

function [7:0] mux_output();
	case (command)
		0: mux_output = res_lo;
		1: mux_output = res_hi;
		2: mux_output = {4'd0, res_flags};
		3: mux_output = '0;
	endcase
endfunction

assign _output = mux_output();

always @(posedge clk) begin
	if (!rst_n) begin
		a_lo <= 0;
		a_hi <= 0;
		b_lo <= 0;
		b_hi <= 0;
	end else begin
		case (addr)
			0: begin
				a_lo <= word;
			end
			1: begin
				a_hi <= word;
			end
			2: begin
				b_lo <= word;
			end
			3: begin
				b_hi <= word;
			end
		endcase
	end
end

// List all unused inputs to prevent warnings
wire _unused = &{ena, 1'b0};

endmodule
