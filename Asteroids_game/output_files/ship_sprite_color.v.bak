//============================================================
// 16x16 COLOR SHIP SPRITE
//  - Centered at (ship_x, ship_y)
//  - 2-bit color encoding per pixel:
//       2'b00 = transparent
//       2'b01 = white  (ship body)
//       2'b10 = blue   (cockpit)
//       2'b11 = yellow (engine flame)
//  - Outputs 1-bit R,G,B suitable for simple VGA pipelines
//============================================================
module ship_sprite_color #(
    parameter SPRITE_W = 16,
    parameter SPRITE_H = 16
)(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [9:0] ship_x,   // center position (from game_core)
    input  wire [9:0] ship_y,

    output reg  ship_r,  // 1 = red
    output reg  ship_g,  // 1 = green
    output reg  ship_b   // 1 = blue
);

    // 2-bit color per pixel:
    //   00 = transparent
    //   01 = white
    //   10 = blue
    //   11 = yellow
    //
    // rom[row][col], row/col in [0..15]
    reg [1:0] rom [0:SPRITE_H-1][0:SPRITE_W-1];

    // --------------------------------------------------------
    // Sprite bitmap (16x16)
    // Rough shape:
    //
    //       ..WW..
    //      .WWWWW.
    //     WWBBWWW.
    //     WWBBWWW.
    //    WWWWWWWW.
    //    WWWWWWWW.
    //     WWBBWWW.
    //     WWBBWWW.
    //      .WWWWW.
    //      .WWWWW.
    //        YY
    //        YY
    //       YYYY
    //       YYYY
    //        YY
    //        YY
    //
    // W = white (body), B = blue (cockpit), Y = yellow (flame)
    // --------------------------------------------------------
    integer r, c;
    initial begin
        // default all to transparent
        for (r = 0; r < SPRITE_H; r = r + 1)
            for (c = 0; c < SPRITE_W; c = c + 1)
                rom[r][c] = 2'b00;

        // Row 0:       ..WW..
        rom[0][5]  = 2'b01;
        rom[0][6]  = 2'b01;

        // Row 1:      .WWWWW.
        rom[1][4]  = 2'b01;
        rom[1][5]  = 2'b01;
        rom[1][6]  = 2'b01;
        rom[1][7]  = 2'b01;
        rom[1][8]  = 2'b01;

        // Row 2:     WWBBWWW.
        rom[2][3]  = 2'b01;
        rom[2][4]  = 2'b01;
        rom[2][5]  = 2'b10;  // blue cockpit
        rom[2][6]  = 2'b10;  // blue cockpit
        rom[2][7]  = 2'b01;
        rom[2][8]  = 2'b01;
        rom[2][9]  = 2'b01;

        // Row 3:     WWBBWWW.
        rom[3][3]  = 2'b01;
        rom[3][4]  = 2'b01;
        rom[3][5]  = 2'b10;  // blue cockpit
        rom[3][6]  = 2'b10;
        rom[3][7]  = 2'b01;
        rom[3][8]  = 2'b01;
        rom[3][9]  = 2'b01;

        // Row 4:    WWWWWWWW.
        rom[4][2]  = 2'b01;
        rom[4][3]  = 2'b01;
        rom[4][4]  = 2'b01;
        rom[4][5]  = 2'b01;
        rom[4][6]  = 2'b01;
        rom[4][7]  = 2'b01;
        rom[4][8]  = 2'b01;
        rom[4][9]  = 2'b01;

        // Row 5:    WWWWWWWW.
        rom[5][2]  = 2'b01;
        rom[5][3]  = 2'b01;
        rom[5][4]  = 2'b01;
        rom[5][5]  = 2'b01;
        rom[5][6]  = 2'b01;
        rom[5][7]  = 2'b01;
        rom[5][8]  = 2'b01;
        rom[5][9]  = 2'b01;

        // Row 6:     WWBBWWW.
        rom[6][3]  = 2'b01;
        rom[6][4]  = 2'b01;
        rom[6][5]  = 2'b10;
        rom[6][6]  = 2'b10;
        rom[6][7]  = 2'b01;
        rom[6][8]  = 2'b01;
        rom[6][9]  = 2'b01;

        // Row 7:     WWBBWWW.
        rom[7][3]  = 2'b01;
        rom[7][4]  = 2'b01;
        rom[7][5]  = 2'b10;
        rom[7][6]  = 2'b10;
        rom[7][7]  = 2'b01;
        rom[7][8]  = 2'b01;
        rom[7][9]  = 2'b01;

        // Row 8:      .WWWWW.
        rom[8][4]  = 2'b01;
        rom[8][5]  = 2'b01;
        rom[8][6]  = 2'b01;
        rom[8][7]  = 2'b01;
        rom[8][8]  = 2'b01;

        // Row 9:      .WWWWW.
        rom[9][4]  = 2'b01;
        rom[9][5]  = 2'b01;
        rom[9][6]  = 2'b01;
        rom[9][7]  = 2'b01;
        rom[9][8]  = 2'b01;

        // Row 10:        YY
        rom[10][6] = 2'b11;  // yellow flame
        rom[10][7] = 2'b11;

        // Row 11:        YY
        rom[11][6] = 2'b11;
        rom[11][7] = 2'b11;

        // Row 12:       YYYY
        rom[12][5] = 2'b11;
        rom[12][6] = 2'b11;
        rom[12][7] = 2'b11;
        rom[12][8] = 2'b11;

        // Row 13:       YYYY
        rom[13][5] = 2'b11;
        rom[13][6] = 2'b11;
        rom[13][7] = 2'b11;
        rom[13][8] = 2'b11;

        // Row 14:        YY
        rom[14][6] = 2'b11;
        rom[14][7] = 2'b11;

        // Row 15:        YY
        rom[15][6] = 2'b11;
        rom[15][7] = 2'b11;
    end

    // --------------------------------------------------------
    // Compute local sprite coordinates from center position
    // --------------------------------------------------------
    wire [9:0] left = ship_x - SPRITE_W/2;
    wire [9:0] top  = ship_y - SPRITE_H/2;

    wire inside =
        (pixel_x >= left) && (pixel_x < left + SPRITE_W) &&
        (pixel_y >= top ) && (pixel_y < top  + SPRITE_H);

    wire [3:0] sx = pixel_x - left;  // 0..15
    wire [3:0] sy = pixel_y - top;   // 0..15

    // --------------------------------------------------------
    // Color decode: rom[sy][sx] -> ship_r/g/b
    // --------------------------------------------------------
    always @* begin
        ship_r = 1'b0;
        ship_g = 1'b0;
        ship_b = 1'b0;

        if (inside) begin
            case (rom[sy][sx])
                2'b00: begin
                    // transparent
                end

                2'b01: begin
                    // white (body)
                    ship_r = 1'b1;
                    ship_g = 1'b1;
                    ship_b = 1'b1;
                end

                2'b10: begin
                    // blue (cockpit)
                    ship_r = 1'b0;
                    ship_g = 1'b0;
                    ship_b = 1'b1;
                end

                2'b11: begin
                    // yellow (flame)
                    ship_r = 1'b1;
                    ship_g = 1'b1;
                    ship_b = 1'b0;
                end
            endcase
        end
    end

endmodule
