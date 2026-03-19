
module memio (
	input wire clk,
	input wire rst_n,

	// External SPI interface
	input  wire spi_miso,
    output wire spi_select,
    output wire spi_clk_out,
    output wire spi_mosi,

	///
	input  wire [15:0] addr_in,
	input  wire [7:0]  data_in,
	input  wire is_write,
	input  wire start,
	output wire [7:0] data_out,
	output wire busy
);

spi_ram_controller #(.DATA_WIDTH_BYTES(1), .ADDR_BITS(16)) spi_controller (
	.clk(clk),
	.rstn(rst_n),
	//
	.spi_miso(spi_miso),
	.spi_select(spi_select),
	.spi_clk_out(spi_clk_out),
	.spi_mosi(spi_mosi),
	//
	.addr_in(addr_in),
	.data_in(data_in),
	.start_read(~is_write & start),
	.start_write(is_write & start),
	.data_out(data_out),
	.busy(busy)
);

endmodule
