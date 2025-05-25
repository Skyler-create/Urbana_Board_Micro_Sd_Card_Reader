`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 12:22:19 AM
// Design Name: 
// Module Name: bram_vga_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bram_vga_tb();
//Define logic needed for top module
logic clk100mhz;
logic resetn;

//SD card signals are all 0 because its kinda hard to simulate a virtual sd card
logic sdcard_pwr_n;
logic sd_spi_ssn;
logic sd_spi_sck;
logic sd_spi_mosi;
logic sd_spi_miso;

logic [15:0]  led;
logic uart_tx;
logic hdmi_clk_n;
logic hdmi_clk_p;
logic [2:0] hdmi_tx_n;
logic [2:0] hdmi_tx_p;


 //-------------------------------------------------------------------------------------
 //Instantiate top module
 //-------------------------------------------------------------------------------------

fpga_top sd_reader_1 (
    .clk100mhz(clk100mhz),
    .resetn(resetn),
    .sdcard_pwr_n(sdcard_pwr_n),
    .sd_spi_ssn(sd_spi_ssn),
    .sd_spi_sck(sd_spi_sck),
    .sd_spi_mosi(sd_spi_mosi),
    .sd_spi_miso(sd_spi_miso),
    .led(led),
    .uart_tx(uart_tx),
    .hdmi_clk_n(hdmi_clk_n),
    .hdmi_clk_p(hdmi_clk_p),
    .hdmi_tx_n(hdmi_tx_n),
    .hdmi_tx_p(hdmi_tx_p)
);


//  //-------------------------------------------------------------------------------------
//  // Initialize clock
//  //-------------------------------------------------------------------------------------

// initial begin: CLOCK_INITIALIZATION
//     clk100mhz = 1'b1;
//  end 
    
//  always begin : CLOCK_GENERATION
//      #5 clk100mhz = ~clk100mhz;
//  end

//  //-------------------------------------------------------------------------------------
//  // Probe internal signal
//  //-------------------------------------------------------------------------------------

// // logic clk; //50MHz
// // assign clk = sd_reader_1.clk;
// // logic [9:0] drawX;
// // assign drawX = sd_reader_1.drawX;
// // logic [9:0] drawY;
// // assign drawY = sd_reader_1.drawY;
// // logic [7:0] red, green, blue;
// // assign red = sd_reader_1.red;
// // assign green = sd_reader_1.green;
// // assign blue = sd_reader_1.blue;
// // logic hsync, vsync, vde;
// // assign hsync = sd_reader_1.hsync;
// // assign vsync = sd_reader_1.vsync;
// // assign vde = sd_reader_1.vde;

//  //-------------------------------------------------------------------------------------
// // Testing stuff
//  //-------------------------------------------------------------------------------------

//  initial begin: TEST_VECTORS
//     //Reset program
//     // resetn <= 0;
//     // repeat (4) @(posedge clk100mhz);
//     // resetn <= 1;
//     // repeat (10) @(posedge clk100mhz);


// //Idea for later: Maybe simulate BRAM by forcing outbyte & outen?

//  end




endmodule
