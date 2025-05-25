module contrast_stretch_rgb (
    input  logic         clk,
    input  logic  [7:0]  r_in,
    input  logic  [7:0]  g_in,
    input  logic  [7:0]  b_in,
    input  logic  [15:0] scale_fixed,  // signed 8.8 fixed-point scale
    output logic  [7:0]  r_out,
    output logic  [7:0]  g_out,
    output logic  [7:0]  b_out
);

    function automatic [8:0] stretch_pixel(input [7:0] val, input [15:0] scale);
        logic signed [8:0] centered;
        logic signed [17:0] scaled;
        logic signed [8:0] result;

        begin
            centered = $signed({1'b0, val}) - 128;
            scaled   = centered * $signed(scale);
            result   = (scaled >>> 8) + 128;
            stretch_pixel = result;
        end
    endfunction

    // Internal results after contrast
    logic signed [8:0] r_stretched, g_stretched, b_stretched;
    logic signed [8:0] r_tint, g_tint, b_tint;

    always_ff @(posedge clk) begin
        // Apply contrast stretching
        r_stretched = stretch_pixel(r_in, scale_fixed);
        g_stretched = stretch_pixel(g_in, scale_fixed);
        b_stretched = stretch_pixel(b_in, scale_fixed);

        // Add warm tint: slight red + green boost, slight blue reduction
        r_tint = r_stretched + 15;
        g_tint = g_stretched + 10;
        b_tint = b_stretched - 10;

        // Clamp all outputs to 0-255
        r_out <= (r_tint > 255) ? 8'd255 : (r_tint < 0) ? 8'd0 : r_tint[7:0];
        g_out <= (g_tint > 255) ? 8'd255 : (g_tint < 0) ? 8'd0 : g_tint[7:0];
        b_out <= (b_tint > 255) ? 8'd255 : (b_tint < 0) ? 8'd0 : b_tint[7:0];
    end

endmodule
