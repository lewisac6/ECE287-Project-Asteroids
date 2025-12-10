module ship_sprite_color #(
    parameter SPRITE_W = 16,
    parameter SPRITE_H = 16
)(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [9:0] ship_x,   // center position
    input  wire [9:0] ship_y,

    output reg ship_r,  // 1 = red
    output reg ship_g,  // 1 = green
    output reg ship_b   // 1 = blue
);

    // 2-bit color encoding:
    // 00 = transparent
    // 01 = white
    // 10 = blue
    // 11 = yellow

    reg [1:0] ship_rom [0:SPRITE_H-1][0:SPRITE_W-1];

    // -------------------------
    // Load 16×16 color sprite
    // -------------------------
    initial begin
        // Row 0
        ship_rom[0][0] = 0; ship_rom[0][1] = 0; ship_rom[0][2] = 1; ship_rom[0][3] = 1;
        ship_rom[0][4] = 0; ship_rom[0][5] = 0; ship_rom[0][6] = 0; ship_rom[0][7] = 0;
        ship_rom[0][8] = 0; ship_rom[0][9] = 0; ship_rom[0][10]=0; ship_rom[0][11]=0;
        ship_rom[0][12]=0; ship_rom[0][13]=0; ship_rom[0][14]=0; ship_rom[0][15]=0;

        // Row 1
        ship_rom[1][0]=0; ship_rom[1][1]=0; ship_rom[1][2]=1; ship_rom[1][3]=1;
        ship_rom[1][4]=1; ship_rom[1][5]=1; ship_rom[1][6]=0; ship_rom[1][7]=0;
        ship_rom[1][8]=0; ship_rom[1][9]=0; ship_rom[1][10]=0; ship_rom[1][11]=0;
        ship_rom[1][12]=0; ship_rom[1][13]=0; ship_rom[1][14]=0; ship_rom[1][15]=0;

        // Row 2  (blue cockpit)
        ship_rom[2][0]=0; ship_rom[2][1]=1; ship_rom[2][2]=1; ship_rom[2][3]=2;
        ship_rom[2][4]=2; ship_rom[2][5]=1; ship_rom[2][6]=1; ship_rom[2][7]=1;
        ship_rom[2][8]=1; ship_rom[2][9]=0; ship_rom[2][10]=0; ship_rom[2][11]=0;
        ship_rom[2][12]=0; ship_rom[2][13]=0; ship_rom[2][14]=0; ship_rom[2][15]=0;

        // Row 3  (blue cockpit)
        ship_rom[3][0]=0; ship_rom[3][1]=1; ship_rom[3][2]=1; ship_rom[3][3]=2;
        ship_rom[3][4]=2; ship_rom[3][5]=1; ship_rom[3][6]=1; ship_rom[3][7]=1;
        ship_rom[3][8]=1; ship_rom[3][9]=0; ship_rom[3][10]=0; ship_rom[3][11]=0;
        ship_rom[3][12]=0; ship_rom[3][13]=0; ship_rom[3][14]=0; ship_rom[3][15]=0;

        // Row 4
        ship_rom[4][0]=0; ship_rom[4][1]=1; ship_rom[4][2]=1; ship_rom[4][3]=1;
        ship_rom[4][4]=1; ship_rom[4][5]=1; ship_rom[4][6]=1; ship_rom[4][7]=1;
        ship_rom[4][8]=1; ship_rom[4][9]=0; ship_rom[4][10]=0; ship_rom[4][11]=0;
        ship_rom[4][12]=0; ship_rom[4][13]=0; ship_rom[4][14]=0; ship_rom[4][15]=0;

        // Row 5
        ship_rom[5][0]=0; ship_rom[5][1]=1; ship_rom[5][2]=1; ship_rom[5][3]=1;
        ship_rom[5][4]=1; ship_rom[5][5]=1; ship_rom[5][6]=1; ship_rom[5][7]=1;
        ship_rom[5][8]=1; ship_rom[5][9]=0; ship_rom[5][10]=0; ship_rom[5][11]=0;
        ship_rom[5][12]=0; ship_rom[5][13]=0; ship_rom[5][14]=0; ship_rom[5][15]=0;

        // Row 6
        ship_rom[6][0]=0; ship_rom[6][1]=1; ship_rom[6][2]=1; ship_rom[6][3]=2;
        ship_rom[6][4]=2; ship_rom[6][5]=1; ship_rom[6][6]=1; ship_rom[6][7]=1;
        ship_rom[6][8]=1; ship_rom[6][9]=0; ship_rom[6][10]=0; ship_rom[6][11]=0;
        ship_rom[6][12]=0; ship_rom[6][13]=0; ship_rom[6][14]=0; ship_rom[6][15]=0;

        // Row 7
        ship_rom[7][0]=0; ship_rom[7][1]=1; ship_rom[7][2]=1; ship_rom[7][3]=2;
        ship_rom[7][4]=2; ship_rom[7][5]=1; ship_rom[7][6]=1; ship_rom[7][7]=1;
        ship_rom[7][8]=1; ship_rom[7][9]=0; ship_rom[7][10]=0; ship_rom[7][11]=0;
        ship_rom[7][12]=0; ship_rom[7][13]=0; ship_rom[7][14]=0; ship_rom[7][15]=0;

        // Row 8
        ship_rom[8][0]=0; ship_rom[8][1]=1; ship_rom[8][2]=1; ship_rom[8][3]=1;
        ship_rom[8][4]=1; ship_rom[8][5]=1; ship_rom[8][6]=1; ship_rom[8][7]=1;
        ship_rom[8][8]=1; ship_rom[8][9]=0; ship_rom[8][10]=0; ship_rom[8][11]=0;
        ship_rom[8][12]=0; ship_rom[8][13]=0; ship_rom[8][14]=0; ship_rom[8][15]=0;

        // Row 9
        ship_rom[9][0]=0; ship_rom[9][1]=1; ship_rom[9][2]=1; ship_rom[9][3]=1;
        ship_rom[9][4]=1; ship_rom[9][5]=1; ship_rom[9][6]=1; ship_rom[9][7]=1;
        ship_rom[9][8]=1; ship_rom[9][9]=0; ship_rom[9][10]=0; ship_rom[9][11]=0;
        ship_rom[9][12]=0; ship_rom[9][13]=0; ship_rom[9][14]=0; ship_rom[9][15]=0;

        // Row 10  (YELLOW FLAME)
        ship_rom[10][0]=0; ship_rom[10][1]=0; ship_rom[10][2]=3; ship_rom[10][3]=3;
        ship_rom[10][4]=0; ship_rom[10][5]=0; ship_rom[10][6]=0; ship_rom[10][7]=0;
        ship_rom[10][8]=0; ship_rom[10][9]=0; ship_rom[10][10]=0; ship_rom[10][11]=0;
        ship_rom[10][12]=0; ship_rom[10][13]=0; ship_rom[10][14]=0; ship_rom[10][15]=0;

        // Row 11  (YELLOW FLAME)
        ship_rom[11][0]=0; ship_rom[11][1]=0; ship_rom[11][2]=3; ship_rom[11][3]=3;
        ship_rom[11][4]=0; ship_rom[11][5]=0; ship_rom[11][6]=0; ship_rom[11][7]=0;
        ship_rom[11][8]=0; ship_rom[11][9]=0; ship_rom[11][10]=0; ship_rom[11][11]=0;
        ship_rom[11][12]=0; ship_rom[11][13]=0; ship_rom[11][14]=0; ship_rom[11][15]=0;

        // Row 12 (tail)
        ship_rom[12][0]=0; ship_rom[12][1]=3; ship_rom[12][2]=3; ship_rom[12][3]=0;
        ship_rom[12][4]=0; ship_rom[12][5]=0; ship_rom[12][6]=0; ship_rom[12][7]=0;
        ship_rom[12][8]=0; ship_rom[12][9]=0; ship_rom[12][10]=0; ship_rom[12][11]=0;
        ship_rom[12][12]=0; ship_rom[12][13]=0; ship_rom[12][14]=0; ship_rom[12][15]=0;

        // Row 13
        ship_rom[13][0]=0; ship_rom[13][1]=3; ship_rom[13][2]=3; ship_rom[13][3]=0;
        ship_rom[13][4]=0; ship_rom[13][5]=0; ship_rom[13][6]=0; ship_rom[13][7]=0;
        ship_rom[13][8]=0; ship_rom[13][9]=0; ship_rom[13][10]=0; ship_rom[13][11]=0;
        ship_rom[13][12]=0; ship_rom[13][13]=0; ship_rom[13][14]=0; ship_rom[13][15]=0;

        // Row 14
        ship_rom[14][0]=0; ship_rom[14][1]=0; ship_rom[14][2]=3; ship_rom[14][3]=3;
        ship_rom[14][4]=0; ship_rom[14][5]=0; ship_rom[14][6]=0; ship_rom[14][7]=0;
        ship_rom[14][8]=0; ship_rom[14][9]=0; ship_rom[14][10]=0; ship_rom[14][11]=0;
        ship_rom[14][12]=0; ship_rom[14][13]=0; ship_rom[14][14]=0; ship_rom[14][15]=0;

        // Row 15
        ship_rom[15][0]=0; ship_rom[15][1]=0; ship_rom[15][2]=3; ship_rom[15][3]=3;
        ship_rom[15][4]=0; ship_rom[15][5]=0; ship_rom[15][6]=0; ship_rom[15][7]=0;
        ship_rom[15][8]=0; ship_rom[15][9]=0; ship_rom[15][10]=0; ship_rom[15][11]=0;
        ship_rom[15][12]=0; ship_rom[15][13]=0; ship_rom[15][14]=0; ship_rom[15][15]=0;
    end

    // --------------------------------------------------
    // Bounding box → local sprite coordinates
    // --------------------------------------------------
    wire [9:0] left = ship_x - SPRITE_W/2;
    wire [9:0] top  = ship_y - SPRITE_H/2;

    wire inside =
        (pixel_x >= left) && (pixel_x < left + SPRITE_W) &&
        (pixel_y >= top ) && (pixel_y < top + SPRITE_H);

    wire [3:0] sx = pixel_x - left;
    wire [3:0] sy = pixel_y - top;

    // --------------------------------------------------
    // Convert color code → RGB bit outputs
    // --------------------------------------------------
    always @* begin
        ship_r = 0;
        ship_g = 0;
        ship_b = 0;

        if (inside) begin
            case (ship_rom[sy][sx])
                2'b00: begin
                    // transparent
                end
                2'b01: begin
                    // white
                    ship_r = 1;
                    ship_g = 1;
                    ship_b = 1;
                end
                2'b10: begin
                    // blue
                    ship_r = 0;
                    ship_g = 0;
                    ship_b = 1;
                end
                2'b11: begin
                    // yellow
                    ship_r = 1;
                    ship_g = 1;
                    ship_b = 0;
                end
            endcase
        end
    end

endmodule
