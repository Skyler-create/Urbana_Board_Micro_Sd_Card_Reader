module sepia_filter (
    input  logic [7:0] R_in,
    input  logic [7:0] G_in,
    input  logic [7:0] B_in,
    output logic [7:0] R_out,
    output logic [7:0] G_out,
    output logic [7:0] B_out
);

    // Sepia calculation (Q8.8 scaling)
    logic [17:0] r_sepia, g_sepia, b_sepia;
    logic [8:0] r_s, g_s, b_s;

    // Blended output
    logic [9:0] r_blend, g_blend, b_blend;

    always_comb begin
        // Classic sepia conversion
        r_sepia = (R_in * 8'd101) + (G_in * 8'd197) + (B_in * 8'd48);
        g_sepia = (R_in * 8'd89)  + (G_in * 8'd176) + (B_in * 8'd43);
        b_sepia = (R_in * 8'd70)  + (G_in * 8'd137) + (B_in * 8'd34);

        r_s = r_sepia[17:8];
        g_s = g_sepia[17:8];
        b_s = b_sepia[17:8];

        // Blend 80% original, 20% sepia
        r_blend = (R_in * 8'd204 + r_s * 8'd51) >> 8;  // 0.8 * R_in + 0.2 * r_s
        g_blend = (G_in * 8'd204 + g_s * 8'd51) >> 8;
        b_blend = (B_in * 8'd204 + b_s * 8'd51) >> 8;

        // Clamp
        R_out = (r_blend > 255) ? 8'd255 : r_blend[7:0];
        G_out = (g_blend > 255) ? 8'd255 : g_blend[7:0];
        B_out = (b_blend > 255) ? 8'd255 : b_blend[7:0];
    end

endmodule
