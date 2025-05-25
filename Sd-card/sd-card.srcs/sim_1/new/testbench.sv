//--------------------------------------------------------------------------------------------------------
// Module  : testbench
// Type    : Simulation testbench
// Standard: SystemVerilog
// Function: Testbench for fpga_top module that reads RGB data from SD card and outputs to HDMI
//--------------------------------------------------------------------------------------------------------

`timescale 1ns/1ps

module testbench();

    // Clock and reset signals
    logic         clk100mhz;
    logic         resetn;
    
    // SD card interface
    logic         sdcard_pwr_n;
    logic         sd_spi_ssn;
    logic         sd_spi_sck;
    logic         sd_spi_mosi;
    logic         sd_spi_miso;
    
    // Status indicators
    logic [15:0]  led;
    
    // UART output
    logic         uart_tx;
    
    // HDMI signals (added for monitoring)
    logic         hdmi_tmds_clk_p;
    logic         hdmi_tmds_clk_n;
    logic [2:0]   hdmi_tmds_data_p;
    logic [2:0]   hdmi_tmds_data_n;

    // Clock generation
    initial begin
        clk100mhz = 0;
        forever #5 clk100mhz = ~clk100mhz; // 100MHz clock (10ns period)
    end
    
    // SD card emulator variables
    logic [7:0] sd_test_data [320*240*3-1:0]; // 320x240 RGB888 image (3 bytes per pixel)
    integer sd_byte_counter;
    integer i;
    
    // Instantiate the module under test
    fpga_top DUT (
        .clk100mhz      (clk100mhz),
        .resetn         (resetn),
        .sdcard_pwr_n   (sdcard_pwr_n),
        .sd_spi_ssn     (sd_spi_ssn),
        .sd_spi_sck     (sd_spi_sck),
        .sd_spi_mosi    (sd_spi_mosi),
        .sd_spi_miso    (sd_spi_miso),
        .led            (led),
        .uart_tx        (uart_tx)
        // HDMI signals are internal in the original module but can be monitored
    );
    
    // Task to emulate SD card response
    task emulate_sd_response;
        begin
            // Wait for SPI clock edge
            @(negedge sd_spi_sck);
            
            // When SS is active (low), respond with test data
            if (!sd_spi_ssn) begin
                // Send back preconfigured response based on command and state
                // For simplicity, we'll just return valid data after initial commands
                if (sd_byte_counter < 320*240*3) begin
                    sd_spi_miso = sd_test_data[sd_byte_counter][7]; // MSB first
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][6];
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][5];
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][4];
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][3];
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][2];
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][1];
                    @(posedge sd_spi_sck);
                    sd_spi_miso = sd_test_data[sd_byte_counter][0];
                    
                    sd_byte_counter = sd_byte_counter + 1;
                end
            end
        end
    endtask
    
    // Monitor internal signals by binding to relevant modules
    // These signals would be useful for debugging in simulation
    // Uncomment these if the internal signals are exposed in your design
    /*
    initial begin
        $monitor("Time=%0t, RED=%0h, GREEN=%0h, BLUE=%0h, X=%0d, Y=%0d", 
                 $time, DUT.red, DUT.green, DUT.blue, DUT.drawX, DUT.drawY);
    end
    */
    
    // Monitor BRAM access and pixel output
    initial begin
        forever begin
            @(posedge DUT.clk);
            if (DUT.outen) begin
                $display("Time=%0t: SD data read: %h, Address: %0d", $time, DUT.outbyte, DUT.bram_addrA);
            end
            
            // Monitor VGA output when active
            if (DUT.vde) begin
                $display("Time=%0t: VGA Output - X=%0d, Y=%0d, RGB=(%0d,%0d,%0d)", 
                        $time, DUT.drawX, DUT.drawY, DUT.red, DUT.green, DUT.blue);
            end
        end
    end
    
    // Test sequence
    initial begin
        // Initialize test pattern for SD card emulation
        // This could be a colored gradient or pattern
        for (i = 0; i < 320*240*3; i = i + 3) begin
            // Simple RGB test pattern
            sd_test_data[i]   = i % 256;        // R - increasing pattern 
            sd_test_data[i+1] = (i / 3) % 256;  // G - increasing based on pixel position
            sd_test_data[i+2] = 255 - (i % 256); // B - decreasing pattern
        end
        
        // Initialize signals
        resetn = 0;
        sd_spi_miso = 1;  // Idle high
        sd_byte_counter = 0;
        
        // Wait for a bit and release reset
        #100;
        resetn = 1;
        
        // Give some time for SD initialization
        #5000;
        
        // Start SD response emulation loop
        fork
            forever begin
                emulate_sd_response();
            end
        join_none
        
        // Run simulation for enough time to read a significant portion of the image
        // A full image would be 320×240×3 = 230,400 bytes
        #50000000;  // Simulate for 50ms
        
        // Check status through LEDs
        $display("Test complete. LED status: %16b", led);
        $display("SD Card status: %4b", led[3:0]);
        $display("Card type: %2b", led[5:4]);
        $display("Filesystem: %2b", led[7:6]);
        $display("File found: %b", led[8]);
        
        $finish;
    end
    
    // Optional: Save VGA output to file for visual inspection
    integer file_handle;
    initial begin
        file_handle = $fopen("vga_output.txt", "w");
        
        // Wait until we expect display to be active
        #10000000;
        
        // Record a full frame of data
        for (int y = 0; y < 240; y++) begin
            for (int x = 0; x < 320; x++) begin
                // Wait for relevant pixel
                wait(DUT.drawX == x && DUT.drawY == y && DUT.vde);
                $fwrite(file_handle, "%d,%d,%d,%d,%d\n", x, y, DUT.red, DUT.green, DUT.blue);
                @(posedge DUT.clk_25MHz);
            end
        end
        
        $fclose(file_handle);
    end

endmodule