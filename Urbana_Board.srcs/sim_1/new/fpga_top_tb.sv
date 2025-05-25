`timescale 1ns/1ps

module fpga_top_tb();

  //--------------------------------------------------------------------------
  // Parameters
  //--------------------------------------------------------------------------
  localparam int WIDTH  = 320;
  localparam int HEIGHT = 240;
  localparam int BYTES_PER_PIXEL = 3;
  localparam int TOTAL_BYTES = WIDTH * HEIGHT * BYTES_PER_PIXEL;

  //--------------------------------------------------------------------------
  // Clock & reset
  //--------------------------------------------------------------------------
  reg clk;
  reg rstn;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz
  end

  initial begin
    rstn = 0;
    #100;
    rstn = 1;
  end

  //--------------------------------------------------------------------------
  // Image memory: [0] = first byte of pixel(0,0) ? [2] = B of pixel(0,0),
  // then pixel(1,0), … row-major.
  // Here we generate a simple test pattern; you can replace this with
  // $readmemh if you like.
  //--------------------------------------------------------------------------
  reg [7:0] image_mem [0:TOTAL_BYTES-1];
  initial begin
    integer idx;
    for (idx = 0; idx < TOTAL_BYTES; idx += BYTES_PER_PIXEL) begin
      // Example pattern: R = X coordinate, G = Y coordinate, B = constant
      integer pixel = idx / BYTES_PER_PIXEL;
      integer x = pixel % WIDTH;
      integer y = pixel / WIDTH;
      image_mem[idx + 0] = x[7:0];       // Red
      image_mem[idx + 1] = y[7:0];       // Green
      image_mem[idx + 2] = 8'hFF;        // Blue
    end
  end

  //--------------------------------------------------------------------------
  // Stream these bytes into the DUT
  //--------------------------------------------------------------------------
  reg  [7:0] pixel_byte;
  reg        pixel_byte_valid;

  initial begin
    // wait for reset de-assertion
    wait (rstn == 1);
    #20;

    // send all bytes
    integer i;
    for (i = 0; i < TOTAL_BYTES; i = i + 1) begin
      @(posedge clk);
      pixel_byte       <= image_mem[i];
      pixel_byte_valid <= 1;
    end

    // finish up
    @(posedge clk);
    pixel_byte_valid <= 0;
    $display("=== All %0d bytes sent ===", TOTAL_BYTES);
    #1000;
    $finish;
  end

  //--------------------------------------------------------------------------
  // DUT instantiation
  //--------------------------------------------------------------------------
  // Replace `your_module` / the port list with whatever your top-level or
  // color_mapper expects.  For example if your design uses `outen` / `outbyte`
  // instead of `pixel_byte_valid` / `pixel_byte`, rename them here.
  //
  your_module #(
    .IMAGE_WIDTH (WIDTH),
    .IMAGE_HEIGHT(HEIGHT)
  ) dut (
    .clk                (clk),
    .rstn               (rstn),
    .pixel_byte         (pixel_byte),
    .pixel_byte_valid   (pixel_byte_valid)
    // … other ports (e.g. VGA signals, etc.)
  );

endmodule
