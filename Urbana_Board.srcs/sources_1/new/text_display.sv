`timescale 1ns / 1ps
module text_display
    (
    input logic i_clk25m,
    input logic i_rstn_clk25m,
    
    // I/O VGA top        
    input logic [9:0]   drawX,          // o_VGA_x
    input logic [9:0]   drawY,          // o_VGA_y
    input logic [15:0] sw_s,
    output logic        display_text,   // signal to tell VGA top to write text
    output logic        text_data       // data of the text
    
//    input logic detected

    );
    logic [7:0]  font_data;
    logic [10:0] font_addr;
    
    // instantiate font_rom
    font_rom font_rom
    (
        .data   (font_data),
        .addr   (font_addr)   
    );
    
    // temp logic to simulate the detected signal from facial detection
    logic detected;        
    assign detected = 1'b1;

    logic [4:0]     char_idx;   // which char to write
    assign char_idx = (drawX-10)/ 8;
    logic [3:0]     row_idx;    // which of a single char to write
    assign row_idx = drawY -10;
    
    logic [6:0]     char_addr;  // the address of the char, pass to font_rom  
    
    // assign char_addr to each char_idx
//    always_comb begin
//        if (detected) begin
//            if (char_idx == 0 || char_idx == 7)
//                char_addr = 'h44;   // "D"
//            else if (char_idx == 1 || char_idx == 3 || char_idx == 6)
//                char_addr = 'h45;   // "E"
//            else if (char_idx == 2 || char_idx == 5)
//                char_addr = 'h54;   //  "T"
//            else if (char_idx == 4)
//                char_addr = 'h43;   //  "C"
//            else if (char_idx == 8)
//                char_addr = 'h3a;   // ":"
//            else if (char_idx == 9)
//                char_addr = 'h00;   // " "
//            else if (char_idx == 10)
//                char_addr = 'h59;   // "Y"
//            else if (char_idx == 11)
//                char_addr = 'h45;   //"E"
//            else if (char_idx == 12)
//                char_addr = 'h53;   // "S"
//            else
//                char_addr = 'h00;
//        end else begin
//        if (char_idx == 0 || char_idx == 7)
//                char_addr = 'h44;   // "D"
//            else if (char_idx == 1 || char_idx == 3 || char_idx == 6)
//                char_addr = 'h45;   // "E"
//            else if (char_idx == 2 || char_idx == 5)
//                char_addr = 'h54;   //  "T"
//            else if (char_idx == 4)
//                char_addr = 'h43;   //  "C"
//            else if (char_idx == 8)
//                char_addr = 'h3a;   // ":"
//            else if (char_idx == 9)
//                char_addr = 'h00;   // " "
//            else if (char_idx == 10)
//                char_addr = 'h4e;   // "N"
//            else if (char_idx == 11)
//                char_addr = 'h4f;   //"O"
//            else if (char_idx == 12)
//                char_addr = 'h00;   // " " 
//            else
//                char_addr = 'h00;
//        end 
//    end  


always_comb begin
    case (char_idx)
        // Shared screen region for label
        0:  char_addr = sw_s[0] ? "I" :
                        sw_s[2] ? "G" :
                        sw_s[3] ? "C" : 
                        sw_s[4] ? "F" :
                        sw_s[5] ? "F" : " ";
        1:  char_addr = sw_s[0] ? "N" :
                        sw_s[2] ? "R" :
                        sw_s[3] ? "O" : 
                        sw_s[4] ? "U" :
                        sw_s[5] ? "U" : " ";

        2:  char_addr = sw_s[0] ? "V" :
                        sw_s[2] ? "A" :
                        sw_s[3] ? "N" : 
                        sw_s[4] ? "N" :
                        sw_s[5] ? "N" : " ";
        3:  char_addr = sw_s[0] ? "E" :
                        sw_s[2] ? "Y" :
                        sw_s[3] ? "T" : 
                        sw_s[4] ? "K" :
                        sw_s[5] ? "K" : " ";
        4:  char_addr = sw_s[0] ? "R" :
                        sw_s[2] ? "S" :
                        sw_s[3] ? "R" :
                        sw_s[4] ? "Y" :
                        sw_s[5] ? "Y" : " ";
        5:  char_addr = sw_s[0] ? "T" :
                        sw_s[2] ? "C" :
                        sw_s[3] ? "A" : 
                        sw_s[4] ? "1" :
                        sw_s[5] ? "2" : " ";
        6:  char_addr = sw_s[0] ? "E" :
                        sw_s[2] ? "A" :
                        sw_s[3] ? "S" : " ";
        7:  char_addr = sw_s[0] ? "D" :
                        sw_s[2] ? "L" :
                        sw_s[3] ? "T" : " ";
        8:  char_addr = sw_s[2] ? "E" : " ";  // GRAYSCALE has 9 letters
        default: char_addr = " ";
    endcase
end


    
    logic [7:0]     rom_data;      
    logic [10:0]    rom_addr; 
    assign rom_addr = {char_addr, row_idx};
    
    always_comb begin
        font_addr = rom_addr;
        rom_data = font_data;
    end
    
    logic [2:0] pixel_idx;
    assign pixel_idx = drawX % 8;      // which pixel in the current row
    
    always_ff @(posedge i_clk25m) begin
        if (!i_rstn_clk25m) begin
            display_text <= 0;
            text_data <= 0;
        end else begin
            if ((drawX >= 10) && (drawX < (10 + 16 * 9)) &&  // 9 characters max
                (drawY >= 10) && (drawY < (10 + 16)))        // 8 rows high
                display_text <= 1;
            else
                display_text <= 0;
    
            text_data <= rom_data[7 - (drawX - 10) % 8];  // shifted pixel index
        end
    end
    
    
endmodule