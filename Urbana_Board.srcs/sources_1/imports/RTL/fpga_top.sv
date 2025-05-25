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
    output logic [2:0] hdmi_tx_p,
    input logic [15:0] sw_i
);

logic       clk;
logic       rstn;
assign sdcard_pwr_n = 1'b0;                  // keep SDcard power-on


//----------------------------------------------------------------------------------------------------
// Debug LEDs
//----------------------------------------------------------------------------------------------------

assign led[10:9] = 0;
assign led[15] = enA;
assign led[14:13] = bit_count;
assign led[12] = done_reading;
assign led[11] = outen;
assign led[10] = 0;
assign led[9] = 0;

//Lower LEDs are for reading SD card state machine status

//----------------------------------------------------------------------------------------------------
// Switch Debouncing
//----------------------------------------------------------------------------------------------------

logic [15:0] sw_s;
sync_flop sw_sync [15:0] (
	.clk	(clk),
	.d		(sw_i),

	.q		(sw_s)
);	


//----------------------------------------------------------------------------------------------------
// generate 50MHz clk, 25MHz, 125MHz from 100MHz clk
//----------------------------------------------------------------------------------------------------
//bruh
//Clock wizard for both SD reader and VGA
clk_wiz_0 u_clk_wiz_0 (
    .reset      ( resetn       ),
    .clk_in1     ( clk100mhz    ),       // input 100MHz
    .locked      ( rstn         ),
    .clk_out1    ( clk          ),        // output 50MHz
    .clk_out2(clk_25MHz),
    .clk_out3(clk_125MHz)
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
    .outbyte        ( outbyte        ),
    .state (state)
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
    .i_tdata                   ( outbyte              ), //outbyte
    .i_tkeep                   ( 1'b1                 ),
    .i_tlast                   ( 1'b0                 ),
    .o_uart_tx                 ( uart_tx              )
);






//----------------------------------------------------------------------------------------------------
// Store Read Results to BRAM
//----------------------------------------------------------------------------------------------------

//Port A
logic [16:0] bram_addrA;
logic [23:0] dinA;
logic [23:0] doutA;
logic enA;
logic [2:0] weA;
logic [7:0] R_temp;
logic [7:0] G_temp;
logic [7:0] B_temp;
logic [1:0] bit_count = 0;

//Need to generate address
//Every time outen goes high we need to send it to BRAM


logic write_pending;

always_ff @ (posedge clk) begin
    if (resetn) begin
        bit_count     <= 2'd0;
        bram_addrA    <= 17'd0;
        enA           <= 1'b0;
        write_pending <= 1'b0;
    end else begin
        enA <= 1'b0;  // default to no write

        if (outen) begin
            case (bit_count)
                2'd0: begin
                    R_temp <= outbyte;
                    bit_count <= 2'd1;
                end
                2'd1: begin
                    G_temp <= outbyte;
                    bit_count <= 2'd2;
                end
                2'd2: begin
                    B_temp <= outbyte;
                    write_pending <= 1'b1;
                    bit_count <= 2'd0;
                end
            endcase
        end

        // Delay write one clock after B was latched
        if (write_pending) 
        begin
            if(sw_s[1])
            begin
                vint_Rin <= R_temp;
                vint_Gin <= G_temp;
                vint_Bin <= B_temp;
                dinA <= {vint_Ro, vint_Go, vint_Bo};
            end
            else begin
            dinA <= {R_temp, G_temp, B_temp};
            end
            enA <= 1'b1;
            weA <= 3'b111;
            bram_addrA <= bram_addrA + 1;
            write_pending <= 1'b0;       
        end
    end
end



//BRAM
blk_mem_gen_0   block_mem1(
    //portA
    //SD Card
    .addra(bram_addrA),
    .clka(clk100mhz), 
    .dina(dinA), //8 bits, assigned to outbyte
    .douta(doutA), //left unused
    .ena(enA),  //assigned to outen
    .wea( weA), //don't care? We're not writing

    //portB
    //Color Mapper
    .addrb(bram_addrB),  
    .clkb(clk100mhz), 
    .dinb(dinB),  
    .doutb(doutB),
    .enb(enB),
    .web(weB)
    );


//----------------------------------------------------------------------------------------------------
// Read from BRAM
//----------------------------------------------------------------------------------------------------
    
//State machine for controlling reading/writting
//LED 876543 ON means its done reading & LED 210 OFF
logic [2:0] state;
logic done_reading;


assign led[12] = done_reading;

always_ff @(posedge clk) begin
   if (resetn)
       done_reading <= 1'b0;
   else if (state == 3'd6)
       done_reading <= 1'b1;
end

//When done reading is true, start reading from BRAM and sending to VGA probably can steal from lab 7?
//Use DrawX DrawY to determine address
//3 clock cycles per pixel
//READREADREADREADREADREADREADREADREADREADREADREADREADREAREADREADREADREADREADREADREADREADREADREADREADREADREADREAREADREADREADREADREADREADREADREADREADREADREADREADREADREAREADREADREADREADREADREADREADREADREADREADREADREADREADREA
logic [16:0] bram_addrB;
logic [16:0] pixel_idx;
logic [23:0] dinB;
logic [23:0] doutB; 
logic enB;
logic [2:0] weB;
logic [23:0] doutB_reg;


always_comb begin
//    vint_Rin = doutB_d1[23:16];
//    vint_Gin = doutB_d1[15:8];
//    vint_Bin = doutB_d1[7:0];
    cont_Rin = doutB_d1[23:16];
    cont_Gin = doutB_d1[15:8];
    cont_Bin = doutB_d1[7:0];
    if(sw_s[14])
    begin
        scale_fixed = 16'h01C0; //1.5 scale
    end
    
    else if(sw_s[13])
    begin
        scale_fixed = 16'h00E6; // 0.9 scale
    end
    
    else if(sw_s[12])
    begin
        scale_fixed = 16'h00CD; //0.8 scale
    end
    
    else if(sw_s[11])
    begin
        scale_fixed = 16'h00C0; //0.75 scale
    end

    else if(sw_s[10])
    begin
        scale_fixed = 16'h00B3; // 0.7 scale
    end

    else if(sw_s[9])
    begin
        scale_fixed = 16'h00A6; // 0.65 scale
    end
    
    else if(sw_s[9])
    begin
        scale_fixed = 16'h0099; // 0.6 scale
    end
    
    
end

logic [9:0] drawX_d1, drawY_d1;
logic [23:0] doutB_d1;
logic [16:0] pixel_idx_d1, bram_addrB_d1;


always_ff @(posedge clk) begin
// Force left/right/top/bottom edges to black to hide glitches
    
    pixel_idx_d1 <= pixel_idx;
    bram_addrB <= pixel_idx;
    bram_addrB_d1 <= bram_addrB;
    drawX_d1 <= drawX;
    drawY_d1 <= drawY;
    doutB_d1 <= doutB;
    pixel_idx <= (drawX >> 1) + (drawY >> 1) * 320;

    if(done_reading) begin
        enB <= 1'b1;
        weB <= 3'b0;
        doutB_reg <= doutB;  // Delay the output read
        
        //Color invert
        if (sw_s[0]) 
        begin
            red <= 8'd255 - doutB_d1[23:16];
            green <= 8'd255 - doutB_d1[15:8];
            blue <= 8'd255 - doutB_d1[7:0];
        end 
        
        //Vintage filter
        else if (sw_s[1]) 
        begin
            red <= vint_Ro;
            green <= vint_Go;
            blue <= vint_Bo;
        end
        
        //grayscale
        else if (sw_s[2])
        begin
            red = (doutB_d1[23:16] >> 2) + (doutB_d1[15:8] >> 1) + (doutB_d1[7:0] >> 2);
            green = (doutB_d1[23:16] >> 2) + (doutB_d1[15:8] >> 1) + (doutB_d1[7:0] >> 2);
            blue = (doutB_d1[23:16] >> 2) + (doutB_d1[15:8] >> 1) + (doutB_d1[7:0] >> 2);
        end
        //contrast
        else if (sw_s[3])
        begin
            red <= cont_Ro;
            green <= cont_Go;
            blue <= cont_Bo;    
        end
//hi
        //funky1
        else if (sw_s[4])
        begin
            red <= doutB_d1[15:8];
            green <= doutB_d1[7:0];
            blue <= doutB_d1[23:16];
        end
        
        //funky2
        else if (sw_s[5])
        begin
            red <= doutB_d1[7:0];
            green <= doutB_d1[15:8];
            blue <= doutB_d1[23:16];
        end
        //No filter
        else begin
            red <= doutB_d1[23:16];
            green <= doutB_d1[15:8];
            blue <= doutB_d1[7:0];
        end
        if (drawX < 7 || drawX >= 633 || drawY < 7 || drawY >= 473) 
        begin
            red   <= 8'd0;
            green <= 8'd0;
            blue  <= 8'd0;
        end

        if (display_text && text_data) begin
            red   <= 8'd0;
            green <= 8'd0;
            blue  <= 8'd0;
        end
       

        
    end 
    else begin
        enB <= 1'b0;
        weB <= 3'b0;
        red <= 8'b0;
        green <= 8'b0;
        blue <= 8'b0;
    end
end



//----------------------------------------------------------------------------------------------------
// Call VGA
//----------------------------------------------------------------------------------------------------
    
    logic [2:0] hdmi_tmds_data_p;
    logic [2:0] hdmi_tmds_data_n;
    logic hdmi_tmds_clk_n;
    logic hdmi_tmds_clk_p;

    assign hdmi_clk_p  = hdmi_tmds_clk_p;
    assign hdmi_clk_n = hdmi_tmds_clk_n;
    assign hdmi_tx_p = hdmi_tmds_data_p;
    assign hdmi_tx_n = hdmi_tmds_data_n;

    
    logic hsync, vsync, vde;
    logic [7:0] red, green, blue;

    logic clk_25MHz, clk_125MHz, clk;
    logic locked;
    logic [9:0] drawX, drawY;



vga_controller vga (
    .pixel_clk(clk_25MHz), //make signal 
    .reset(resetn), 
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
    .pix_clk_locked(rstn),
    //Reset is active LOW
    .rst(resetn), 
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

//----------------------------------------------------------------------------------------------------
// Filter modules
//----------------------------------------------------------------------------------------------------
logic [7:0] vint_Rin;
logic [7:0] vint_Gin;
logic [7:0] vint_Bin;
logic [7:0] vint_Ro;
logic [7:0] vint_Go;
logic [7:0] vint_Bo;
vintage_filter vintage_1 (
    .clk(clk_25MHz),
    .R_in(vint_Rin),
    .G_in(vint_Gin),
    .B_in(vint_Bin),
    .R_out(vint_Ro),
    .G_out(vint_Go),
    .B_out(vint_Bo)
);

logic [7:0] cont_Rin;
logic [7:0] cont_Gin;
logic [7:0] cont_Bin;
logic [7:0] cont_Ro;
logic [7:0] cont_Go;
logic [7:0] cont_Bo;
logic [15:0] scale_fixed;

contrast_stretch_rgb contrast_1(
    .clk(clk_25MHz),
    .r_in(cont_Rin),
    .g_in(cont_Gin),
    .b_in(cont_Bin),
    .scale_fixed(scale_fixed),
    .r_out(cont_Ro),
    .g_out(cont_Go),
    .b_out(cont_Bo)
);

logic [7:0] sepia_R, sepia_G, sepia_B;

sepia_filter sepia_1 (
    .R_in(doutB_d1[23:16]),
    .G_in(doutB_d1[15:8]),
    .B_in(doutB_d1[7:0]),
    .R_out(sepia_R),
    .G_out(sepia_G),
    .B_out(sepia_B)
);

logic display_text;
logic text_data;

text_display text_display (
    .i_clk25m       (clk_25MHz),
    .i_rstn_clk25m  (rstn),
    .drawX          (drawX),
    .drawY          (drawY),
    .display_text   (display_text),
    .text_data      (text_data),
    .sw_s           (sw_s)
);



logic [71:0] label_grayscale [0:7] = '{
    72'b011111001000001010111000101000001011100010001000011110000100000001111110,
    72'b100000101000001010000100101000001000000010000000100000101000000010000000,
    72'b100000101000001010000100101000001000000010000000100000101000000010000000,
    72'b100000101111111010000100101000001111100010000000111110101000000010000000,
    72'b100000101000001010000100101000001000000010000000100000101000000010000000,
    72'b100000101000001010000100101000001000000010000000100000101000000010000000,
    72'b011111001000001010000100010111001111100001111000011111000111111001111110,
    72'b000000000000000000000000000000000000000000000000000000000000000000000000
};

logic [63:0] label_contrast [0:7] = '{
    64'b00111100011111000111110011111100100000100111110001111110,
    64'b01000010100000101000000010000010100000101000000000010000,
    64'b10000000100000001000000010000010100000101000000000010000,
    64'b10000000111100001111100011111000111111001111100000010000,
    64'b10000000100000001000000010100000100010001000000000010000,
    64'b01000010100000101000000010010000100010001000000000010000,
    64'b00111100011111001000000010001000100010000111110000010000,
    64'b00000000000000000000000000000000000000000000000000000000
};

logic [47:0] label_invert [0:7] = '{
    48'b0111111001000010011111000111110001000010,
    48'b0001000001000010100001001000001010000010,
    48'b0001000001000010100001001000001010000010,
    48'b0001000001000010100001000111110011111110,
    48'b0001000001000010100001001000001010000010,
    48'b0001000001000010100001001000001010000010,
    48'b0111111001111110011111000111110010000010,
    48'b0000000000000000000000000000000000000000
};




endmodule