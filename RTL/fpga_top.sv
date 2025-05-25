

//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top
// Type    : synthesizable, FPGA's top, IP's example design
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: an example of sd_file_reader, read a file from SDcard via SPI, and send file content to UART
//           this example runs on Digilent Nexys4-DDR board (Xilinx Artix-7),
//           see http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga-trainer-board.html
//--------------------------------------------------------------------------------------------------------

module fpga_top (
    // clock = 100MHz
    input  logic         clk100mhz,
    // resetn active-low, You can re-scan and re-read SDcard by pushing the reset button.
    input  logic         resetn,
    // when sdcard_pwr_n = 0, SDcard power on
    output logic         sdcard_pwr_n,
    // signals connect to SD SPI bus
    output logic         sd_spi_ssn,
    output logic         sd_spi_sck,
    output logic         sd_spi_mosi,
    input  logic         sd_spi_miso,
    // 8 bit led to show the status of SDcard
    output logic [15:0]  led,
    // UART tx signal, connected to host-PC's UART-RXD, baud=115200
    output logic         uart_tx,
    output logic hdmi_clk_n,
    output logic hdmi_clk_p,
    output logic [2:0] hdmi_tx_n,
    output logic [2:0] hdmi_tx_p

);



assign led[12:9] = 0;
assign led[15] = clk;
assign led[14] = rstn;
assign led[13] = ~sd_spi_ssn;

assign sdcard_pwr_n = 1'b0;                  // keep SDcard power-on


//----------------------------------------------------------------------------------------------------
// generate 50MHz clk from 100MHz clk
//----------------------------------------------------------------------------------------------------
logic       clk;
logic       rstn;

clk_wiz_0 u_clk_wiz_0 (
    .reset      ( resetn       ),
    .clk_in1     ( clk100mhz    ),       // input 100MHz
    .locked      ( rstn         ),
    .clk_out1    ( clk          )        // output 50MHz
);



//----------------------------------------------------------------------------------------------------
// sd_spi_file_reader
//----------------------------------------------------------------------------------------------------
logic       outen;     // when outen=1, a byte of file content is read out from outbyte
logic [7:0] outbyte;   // a byte of file content

sd_spi_file_reader #(
    .FILE_NAME_LEN  ( 11             ),  // the length of "example.txt" (in bytes)
    .FILE_NAME      ( "example.RGB"  ),  // file name to read
    .SPI_CLK_DIV    ( 50             )   // because clk=50MHz, SPI_CLK_DIV is set to 50
) u_sd_spi_file_reader (
    .rstn           ( rstn           ),
    .clk            ( clk            ),
    .spi_ssn        ( sd_spi_ssn     ),
    .spi_sck        ( sd_spi_sck     ),
    .spi_mosi       ( sd_spi_mosi    ),
    .spi_miso       ( sd_spi_miso    ),
    .card_stat      ( led[3:0]       ),  // show the sdcard initialize status
    .card_type      ( led[5:4]       ),  // 0=UNKNOWN    , 1=SDv1    , 2=SDv2  , 3=SDHCv2
    .filesystem_type( led[7:6]       ),  // 0=UNASSIGNED , 1=UNKNOWN , 2=FAT16 , 3=FAT32 
    .filesystem_stat(                ),
    .file_found     ( led[  8]       ),  // 0=file not found, 1=file found
    .outen          ( outen          ),
    .outbyte        ( outbyte        )
);




//----------------------------------------------------------------------------------------------------
// send file content to UART
//----------------------------------------------------------------------------------------------------
uart_tx #(
    .CLK_FREQ                  ( 50000000             ),    // clk is 50MHz
    .BAUD_RATE                 ( 115200               ),
    .PARITY                    ( "NONE"               ),
    .STOP_BITS                 ( 1                    ), //4
    .BYTE_WIDTH                ( 1                    ),
    .FIFO_EA                   ( 14                   ), //14
    .EXTRA_BYTE_AFTER_TRANSFER ( ""                   ),
    .EXTRA_BYTE_AFTER_PACKET   ( ""                   )
) u_uart_tx (
    .rstn                      ( rstn                 ),
    .clk                       ( clk                  ),
    .i_tready                  (                      ),
    .i_tvalid                  ( outen                ), //outen
    .i_tdata                   ( doutB              ), //outbyte
    .i_tkeep                   ( 1'b1                 ),
    .i_tlast                   ( 1'b0                 ),
    .o_uart_tx                 ( uart_tx              )
);





//----------------------------------------------------------------------------------------------------
// Store Read Results to BRAM
//----------------------------------------------------------------------------------------------------

//Port A
logic [8:0] row_num;
logic [17:0] bram_addrA;
logic [23:0] dinA;
logic [23:0] doutA;
logic enA;
logic weA;
logic enB;
logic weB;

//Catch output before UART
assign dinA = outbyte;
assign enA = outen;
assign weA = outen; //Write mode
assign weB = 1'b0;
assign enB = 1'b1;

//Need to generate address
//On rising edge of outen, we increment address
always_ff @ (posedge clk) begin
    if(!resetn)
	begin
		bram_addrA <= 0;
	end
	else if(outen)
	begin
		bram_addrA <= bram_addrA + 1; //increments by 1 byte because it writes one byte
	end
	
end

//For testing set port B to the same signals but to read.
logic [17:0] bram_addrB;
logic [7:0] dinB;
logic [7:0] doutB;
logic enB;
logic weB;
//For testing purposes only read from previously written addresses to UART to avoid delay
assign bram_addrB = bram_addrA - 3; 
assign enB = 1'b1;
//Doesn't really matter since we're reading
assign weB = 1'b0;



// always_comb 
// begin 
	
// end

//BRAM
blk_mem_gen_0 block_mem1(
    //portA
    //SD Card
    .addra(bram_addrA),
    .clka(clk), 
    .dina(dinA), //8 bits, assigned to outbyte
    .douta(doutA), //left unused
    .ena(enA),  //assigned to outen
    .wea( weA), //don’t care? We’re not writing
   


    //portB
    //Color Mapper
    .addrb(bram_addrB),  
    .clkb(clk),
    .dinb(dinB),  
    .doutb(doutB),
    .enb(enB),
    .web(weB)
    );


//----------------------------------------------------------------------------------------------------
// Call VGA
//----------------------------------------------------------------------------------------------------
    
//might not need these

    assign hdmi_clk_p  = hdmi_tmds_clk_p;
    assign hdmi_clk_n = hdmi_tmds_clk_n;
    assign hdmi_tx_p = hdmi_tmds_data_p;
    assign hdmi_tx_n = hdmi_tmds_data_n;

    //MAKE THIS
    
    clk_wiz_1 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(resetn),
        .locked(locked),
        .clk_in1(axi_aclk)
    );
    
    logic hsync, vsync, vde;
    logic [7:0] red, green, blue;
    
    logic [2:0] hdmi_tmds_data_p;
    logic [2:0] hdmi_tmds_data_n;

    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY;
    
always_comb
begin
    if(bram_addrB % 3 == 0)
    begin
        red = doutB;
    end
    if(bram_addrB % 3 == 1)
    begin
        green = doutB;
    end
    if(bram_addrB % 3 == 2)
    begin
        blue = doutB;
    end
end


vga_controller vga (
    .pixel_clk(clk_25MHz), //make signal 
    .reset(~resetn), 
    .hs(hsync),
    .vs(vsync),
    .active_nblank(vde),
    .drawX(drawX), //set this
    .drawY(drawY) //set this
);    

hdmi_tx_0 vga_to_hdmi (
    //Clocking and Reset
    .pix_clk(clk_25MHz),
    .pix_clkx5(clk_125MHz),
    .pix_clk_locked(locked),
    //Reset is active LOW
    .rst(~resetn), 
    //Color and Sync Signals
    .red(red),
    .green(green),
    .blue(blue),
    .hsync(hsync),
    .vsync(vsync),
    .vde(vde),
    
    //aux Data (unused)
    .aux0_din(4'b0),
    .aux1_din(4'b0),
    .aux2_din(4'b0),
    .ade(1'b0),
    
    //Differential outputs
    .TMDS_CLK_P(hdmi_tmds_clk_p),          
    .TMDS_CLK_N(hdmi_tmds_clk_n),          
    .TMDS_DATA_P(hdmi_tmds_data_p),         
    .TMDS_DATA_N(hdmi_tmds_data_n)          
);




endmodule
