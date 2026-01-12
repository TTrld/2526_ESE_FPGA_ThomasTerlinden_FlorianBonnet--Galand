
module nios (
	clk_clk,
	reset_reset_n,
	pio_0_external_connection_export,
	i2c_0_i2c_serial_sda_in,
	i2c_0_i2c_serial_scl_in,
	i2c_0_i2c_serial_sda_oe,
	i2c_0_i2c_serial_scl_oe);	

	input		clk_clk;
	input		reset_reset_n;
	output	[9:0]	pio_0_external_connection_export;
	input		i2c_0_i2c_serial_sda_in;
	input		i2c_0_i2c_serial_scl_in;
	output		i2c_0_i2c_serial_sda_oe;
	output		i2c_0_i2c_serial_scl_oe;
endmodule
