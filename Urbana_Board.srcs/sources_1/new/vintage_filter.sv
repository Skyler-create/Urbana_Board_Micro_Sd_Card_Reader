module vintage_filter (
    input  logic        clk,
    input  logic [7:0]  R_in,
    input  logic [7:0]  G_in,
    input  logic [7:0]  B_in,
    output logic [7:0]  R_out,
    output logic [7:0]  G_out,
    output logic [7:0]  B_out
);

    // --- Grain generator (8-bit LFSR, taps at 7 & 5)
    logic [7:0] lfsr = 8'hAC;    
    logic [1:0] noise;           

    always_ff @(posedge clk) begin
        lfsr  <= { lfsr[6:0], lfsr[7] ^ lfsr[5] };
        noise <= lfsr[7:6];    // 2-bit 0-3
    end

    // --- Tint & grain pipeline (9 bits to catch overflow)
    logic [8:0] R_t, G_t, B_t;   

    always_comb begin
        // 1) Warm tint
        R_t = R_in + (R_in >> 4);  // +1/16th
        G_t = G_in + (G_in >> 5);  // +1/32nd
        B_t = B_in;                // no tint on blue

        // 2) Add grain only to red & green
        R_t = R_t + noise;
        G_t = G_t + noise;
        // B_t unchanged

        // 3) Proper clamp at 255 (no wrap-around)
        R_out = (R_t > 9'd255 ? 8'd255 : R_t[7:0]);
        G_out = (G_t > 9'd255 ? 8'd255 : G_t[7:0]);
        B_out = B_t[7:0];  // passthrough blue
    end

endmodule
