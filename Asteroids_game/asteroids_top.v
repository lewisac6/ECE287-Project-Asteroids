module asteroids_top (
    input        CLOCK_50,
    input        reset_n,

    input        btn_up,
    input        btn_down,
    input        btn_left,
    input        btn_right,
    input        btn_fire,
    input        btn_start,    // wired to KEY1 (active-LOW)
    input        btn_restart,  // wired to KEY0 (active-LOW)

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_CLK,
    output       VGA_BLANK_N,
    output       VGA_SYNC_N
);

    localparam integer SCREEN_W = 640;
    localparam integer SCREEN_H = 480;

    // Active-HIGH versions of KEY buttons
    wire start_pressed   = ~btn_start;    // KEY1
    wire restart_pressed = ~btn_restart;  // KEY0

    //------------------------------------------------
    // Pixel clock (25 MHz from 50 MHz by simple /2)
    //------------------------------------------------
    reg pix_clk_reg;
    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            pix_clk_reg <= 1'b0;
        else
            pix_clk_reg <= ~pix_clk_reg;
    end
    wire pix_clk = pix_clk_reg;

    //------------------------------------------------
    // VGA timing
    //------------------------------------------------
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_on;
    wire       frame_tick;
    wire       hsync;
    wire       vsync;

    vga_sync_640x480 vga_inst (
        .clk        (pix_clk),
        .reset_n    (reset_n),
        .hsync      (hsync),
        .vsync      (vsync),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .video_on   (video_on),
        .frame_tick (frame_tick)
    );

    assign VGA_HS      = hsync;
    assign VGA_VS      = vsync;
    assign VGA_CLK     = pix_clk;
    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N  = 1'b0;

    //------------------------------------------------
    // Ship / bullet wires
    //------------------------------------------------
    wire [9:0] ship_x;
    wire [9:0] ship_y;
    wire [1:0] ship_facing;

    wire [9:0] bullet_x;
    wire [9:0] bullet_y;
    wire       bullet_active;

    //------------------------------------------------
    // Meteor wires
    //------------------------------------------------
    wire [9:0] meteor0_x;
    wire [9:0] meteor0_y;
    wire [2:0] meteor0_size;

    wire [9:0] meteor1_x;
    wire [9:0] meteor1_y;
    wire [2:0] meteor1_size;

    wire       meteor0_alive;
    wire       meteor1_alive;

    wire [15:0] score;     // from game core
    wire [2:0]  ship_hp;   // from game core
    wire        game_over; // from game core

    //------------------------------------------------
    // Meteor generator: ONE meteorthing, derived second meteor
    //------------------------------------------------
    meteorthing #(
        .SCREEN_W(SCREEN_W),
        .SCREEN_H(SCREEN_H)
    ) meteor0_inst (
        .clk        (pix_clk),
        .reset_n    (reset_n),
        .frame_tick (frame_tick),

        .meteor_x   (meteor0_x),
        .meteor_y   (meteor0_y),
        .meteor_size(meteor0_size)
    );

    // Derive a second meteor from the first with an offset.
    wire [10:0] meteor1_x_sum = {1'b0, meteor0_x} + 11'd160;
    wire [10:1] dummy_unused1;
    wire [10:0] meteor1_y_sum = {1'b0, meteor0_y} + 11'd120;

    assign meteor1_x = (meteor1_x_sum >= 11'd640) ?
                       (meteor1_x_sum - 11'd640) : meteor1_x_sum[9:0];

    assign meteor1_y = (meteor1_y_sum >= 11'd480) ?
                       (meteor1_y_sum - 11'd480) : meteor1_y_sum[9:0];

    // Size variation: rotate through sizes
    assign meteor1_size = (meteor0_size == 3'd4) ? 3'd0 : (meteor0_size + 3'd1);

    //------------------------------------------------
    // Game core: movement, bullet, 2x meteor HP, score, HP, game_over
    //------------------------------------------------
    game_core_simple core_inst (
        .clk          (pix_clk),
        .reset_n      (reset_n),
        .frame_tick   (frame_tick),

        .btn_up       (btn_up),
        .btn_down     (btn_down),
        .btn_left     (btn_left),
        .btn_right    (btn_right),
        .btn_fire     (btn_fire),
        .btn_restart  (restart_pressed),  // active-HIGH restart

        .meteor0_x    (meteor0_x),
        .meteor0_y    (meteor0_y),
        .meteor0_size (meteor0_size),

        .meteor1_x    (meteor1_x),
        .meteor1_y    (meteor1_y),
        .meteor1_size (meteor1_size),

        .ship_x       (ship_x),
        .ship_y       (ship_y),
        .ship_facing  (ship_facing),

        .bullet_x     (bullet_x),
        .bullet_y     (bullet_y),
        .bullet_active(bullet_active),

        .meteor0_alive(meteor0_alive),
        .meteor1_alive(meteor1_alive),

        .score        (score),
        .ship_hp      (ship_hp),
        .game_over    (game_over)
    );

    //------------------------------------------------
    // Simple UI FSM for overlays: TITLE / PLAY / GAMEOVER
    //------------------------------------------------
    localparam [1:0] ST_TITLE    = 2'd0;
    localparam [1:0] ST_PLAY     = 2'd1;
    localparam [1:0] ST_GAMEOVER = 2'd2;

    reg [1:0] ui_state;

    always @(posedge pix_clk or negedge reset_n) begin
        if (!reset_n) begin
            ui_state <= ST_TITLE;
        end else if (frame_tick) begin
            case (ui_state)
                ST_TITLE: begin
                    if (start_pressed)
                        ui_state <= ST_PLAY;
                end
                ST_PLAY: begin
                    if (game_over)
                        ui_state <= ST_GAMEOVER;
                end
                ST_GAMEOVER: begin
                    if (restart_pressed)
                        ui_state <= ST_TITLE;
                end
                default: ui_state <= ST_TITLE;
            endcase
        end
    end

    //------------------------------------------------
    // Rendering: colored ship sprite, bullet pixel, TWO meteor circles
    //------------------------------------------------
    reg [2:0] rgb; // {R,G,B} one bit each

    // Ship sprite (color)
    wire ship_r, ship_g, ship_b;

    ship_sprite_color #(
        .SPRITE_W(16),
        .SPRITE_H(16)
    ) ship_color_inst (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .ship_x (ship_x),
        .ship_y (ship_y),
        .ship_r (ship_r),
        .ship_g (ship_g),
        .ship_b (ship_b)
    );

    // Bullet pixel (1x1)
    wire bullet_pixel = bullet_active &&
                        (pixel_x == bullet_x) &&
                        (pixel_y == bullet_y);

    // Meteor 0: approximate circle using |dx|+|dy|
    reg [9:0] meteor0_radius;
    always @* begin
        case (meteor0_size)
            3'd0: meteor0_radius = 10'd4;   // XS
            3'd1: meteor0_radius = 10'd8;   // S
            3'd2: meteor0_radius = 10'd12;  // M
            3'd3: meteor0_radius = 10'd16;  // L
            default: meteor0_radius = 10'd20; // XL / default
        endcase
    end

    wire [9:0] mdx0 = (pixel_x > meteor0_x) ? (pixel_x - meteor0_x) : (meteor0_x - pixel_x);
    wire [9:0] mdy0 = (pixel_y > meteor0_y) ? (pixel_y - meteor0_y) : (meteor0_y - pixel_y);
    wire [10:0] mdist0_sum = mdx0 + mdy0;

    wire meteor0_pixel   = (mdist0_sum <= {1'b0, meteor0_radius});
    wire meteor0_visible = meteor0_pixel && meteor0_alive;

    // Meteor 1: similar logic
    reg [9:0] meteor1_radius;
    always @* begin
        case (meteor1_size)
            3'd0: meteor1_radius = 10'd4;   // XS
            3'd1: meteor1_radius = 10'd8;   // S
            3'd2: meteor1_radius = 10'd12;  // M
            3'd3: meteor1_radius = 10'd16;  // L
            default: meteor1_radius = 10'd20; // XL / default
        endcase
    end

    wire [9:0] mdx1 = (pixel_x > meteor1_x) ? (pixel_x - meteor1_x) : (meteor1_x - pixel_x);
    wire [9:0] mdy1 = (pixel_y > meteor1_y) ? (pixel_y - meteor1_y) : (meteor1_y - pixel_y);
    wire [10:1] dummy_unused2;
    wire [10:0] mdist1_sum = mdx1 + mdy1;

    wire meteor1_pixel   = (mdist1_sum <= {1'b0, meteor1_radius});
    wire meteor1_visible = meteor1_pixel && meteor1_alive;

    //------------------------------------------------
    // Tiny 8x8 font for letters/numbers we need
    //------------------------------------------------
    // char_id encoding:
    // 0:A, 1:E, 2:G, 3:M, 4:O, 5:P, 6:R, 7:S, 8:T, 9:V,
    // 10:space, 11:K, 12:Y, 13:'0', 14:'1', 15:'2', 16:'3',
    // 17:'4', 18:'5', 19:'6', 20:'7', 21:'8', 22:'9',
    // 23:'H', 24:'C', 25:':'
    function [7:0] font_row;
        input [4:0] cid;
        input [2:0] row;
        begin
            case (cid)
                // A
                5'd0: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b01111110;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b01100110;
                    default: font_row = 8'b00000000;
                endcase
                // E
                5'd1: case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b01100000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b01100000;
                    3'd4: font_row = 8'b01100000;
                    3'd5: font_row = 8'b01100000;
                    3'd6: font_row = 8'b01111110;
                    default: font_row = 8'b00000000;
                endcase
                // G
                5'd2: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100000;
                    3'd3: font_row = 8'b01101110;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111110;
                    default: font_row = 8'b00000000;
                endcase
                // M
                5'd3: case (row)
                    3'd0: font_row = 8'b01100011;
                    3'd1: font_row = 8'b01110111;
                    3'd2: font_row = 8'b01111111;
                    3'd3: font_row = 8'b01101011;
                    3'd4: font_row = 8'b01100011;
                    3'd5: font_row = 8'b01100011;
                    3'd6: font_row = 8'b01100011;
                    default: font_row = 8'b00000000;
                endcase
                // O
                5'd4: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b01100110;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // P
                5'd5: case (row)
                    3'd0: font_row = 8'b01111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b01111100;
                    3'd4: font_row = 8'b01100000;
                    3'd5: font_row = 8'b01100000;
                    3'd6: font_row = 8'b01100000;
                    default: font_row = 8'b00000000;
                endcase
                // R
                5'd6: case (row)
                    3'd0: font_row = 8'b01111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b01111100;
                    3'd4: font_row = 8'b01101100;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b01100110;
                    default: font_row = 8'b00000000;
                endcase
                // S
                5'd7: case (row)
                    3'd0: font_row = 8'b00111110;
                    3'd1: font_row = 8'b01100000;
                    3'd2: font_row = 8'b01100000;
                    3'd3: font_row = 8'b00111100;
                    3'd4: font_row = 8'b00000110;
                    3'd5: font_row = 8'b00000110;
                    3'd6: font_row = 8'b01111100;
                    default: font_row = 8'b00000000;
                endcase
                // T
                5'd8: case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b00011000;
                    3'd2: font_row = 8'b00011000;
                    3'd3: font_row = 8'b00011000;
                    3'd4: font_row = 8'b00011000;
                    3'd5: font_row = 8'b00011000;
                    3'd6: font_row = 8'b00011000;
                    default: font_row = 8'b00000000;
                endcase
                // V
                5'd9: case (row)
                    3'd0: font_row = 8'b01100011;
                    3'd1: font_row = 8'b01100011;
                    3'd2: font_row = 8'b01100011;
                    3'd3: font_row = 8'b00110110;
                    3'd4: font_row = 8'b00110110;
                    3'd5: font_row = 8'b00011100;
                    3'd6: font_row = 8'b00001000;
                    default: font_row = 8'b00000000;
                endcase
                // space
                5'd10: font_row = 8'b00000000;

                // K
                5'd11: case (row)
                    3'd0: font_row = 8'b01100110;
                    3'd1: font_row = 8'b01101100;
                    3'd2: font_row = 8'b01111000;
                    3'd3: font_row = 8'b01110000;
                    3'd4: font_row = 8'b01111000;
                    3'd5: font_row = 8'b01101100;
                    3'd6: font_row = 8'b01100110;
                    default: font_row = 8'b00000000;
                endcase

                // Y
                5'd12: case (row)
                    3'd0: font_row = 8'b01100110;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b00111100;
                    3'd3: font_row = 8'b00011000;
                    3'd4: font_row = 8'b00011000;
                    3'd5: font_row = 8'b00011000;
                    3'd6: font_row = 8'b00011000;
                    default: font_row = 8'b00000000;
                endcase

                // '0'
                5'd13: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01101110;
                    3'd3: font_row = 8'b01110110;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // '1'
                5'd14: case (row)
                    3'd0: font_row = 8'b00011000;
                    3'd1: font_row = 8'b00111000;
                    3'd2: font_row = 8'b00011000;
                    3'd3: font_row = 8'b00011000;
                    3'd4: font_row = 8'b00011000;
                    3'd5: font_row = 8'b00011000;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // '2'
                5'd15: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b00000110;
                    3'd3: font_row = 8'b00001100;
                    3'd4: font_row = 8'b00110000;
                    3'd5: font_row = 8'b01100000;
                    3'd6: font_row = 8'b01111110;
                    default: font_row = 8'b00000000;
                endcase
                // '3'
                5'd16: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b00000110;
                    3'd3: font_row = 8'b00011100;
                    3'd4: font_row = 8'b00000110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // '4'
                5'd17: case (row)
                    3'd0: font_row = 8'b00001100;
                    3'd1: font_row = 8'b00011100;
                    3'd2: font_row = 8'b00101100;
                    3'd3: font_row = 8'b01001100;
                    3'd4: font_row = 8'b01111110;
                    3'd5: font_row = 8'b00001100;
                    3'd6: font_row = 8'b00001100;
                    default: font_row = 8'b00000000;
                endcase
                // '5'
                5'd18: case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b01100000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b00000110;
                    3'd4: font_row = 8'b00000110;
                    3'd5: font_row = 8'b01100110; // typo but ignored visually
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // '6'
                5'd19: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100000;
                    3'd2: font_row = 8'b01100000;
                    3'd3: font_row = 8'b01111100;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // '7'
                5'd20: case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b00000110;
                    3'd2: font_row = 8'b00001100;
                    3'd3: font_row = 8'b00011000;
                    3'd4: font_row = 8'b00110000;
                    3'd5: font_row = 8'b00110000;
                    3'd6: font_row = 8'b00110000;
                    default: font_row = 8'b00000000;
                endcase
                // '8'
                5'd21: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b00111100;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // '9'
                5'd22: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b00111110;
                    3'd4: font_row = 8'b00000110;
                    3'd5: font_row = 8'b00000110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // H
                5'd23: case (row)
                    3'd0: font_row = 8'b01100110;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b01111110;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b01100110;
                    default: font_row = 8'b00000000;
                endcase
                // C
                5'd24: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100000;
                    3'd3: font_row = 8'b01100000;
                    3'd4: font_row = 8'b01100000;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                // ':'
                5'd25: case (row)
                    3'd0: font_row = 8'b00000000;
                    3'd1: font_row = 8'b00011000;
                    3'd2: font_row = 8'b00011000;
                    3'd3: font_row = 8'b00000000;
                    3'd4: font_row = 8'b00011000;
                    3'd5: font_row = 8'b00011000;
                    3'd6: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase

                default: font_row = 8'b00000000;
            endcase
        end
    endfunction

    //------------------------------------------------
    // Messages + HUD layout
    //------------------------------------------------
    localparam CHAR_W = 8;
    localparam CHAR_H = 8;

    localparam integer TITLE_LEN   = 11;
    localparam integer GO_LEN      = 9;
    localparam integer RESTART_LEN = 21;
    localparam integer SCORE_LEN   = 10;  // "SCORE:0000"
    localparam integer HP_LEN      = 4;   // "HP:x"

    localparam integer TITLE_X0   = (SCREEN_W - TITLE_LEN*CHAR_W)   / 2;
    localparam integer TITLE_Y0   = 180;
    localparam integer GO_X0      = (SCREEN_W - GO_LEN*CHAR_W)      / 2;
    localparam integer GO_Y0      = 160;
    localparam integer RESTART_X0 = (SCREEN_W - RESTART_LEN*CHAR_W) / 2;
    localparam integer RESTART_Y0 = 220;

    localparam integer SCORE_X0   = 16;
    localparam integer SCORE_Y0   = 16;
    localparam integer HP_X0      = SCREEN_W - HP_LEN*CHAR_W - 16;
    localparam integer HP_Y0      = 16;

    // Map character index -> char_id for TITLE / GO / RESTART
    function [4:0] title_char_id;
        input [4:0] idx;
        begin
            // "PRESS START"
            case (idx)
                5'd0:  title_char_id = 5'd5;   // P
                5'd1:  title_char_id = 5'd6;   // R
                5'd2:  title_char_id = 5'd1;   // E
                5'd3:  title_char_id = 5'd7;   // S
                5'd4:  title_char_id = 5'd7;   // S
                5'd5:  title_char_id = 5'd10;  // space
                5'd6:  title_char_id = 5'd7;   // S
                5'd7:  title_char_id = 5'd8;   // T
                5'd8:  title_char_id = 5'd0;   // A
                5'd9:  title_char_id = 5'd6;   // R
                5'd10: title_char_id = 5'd8;   // T
                default: title_char_id = 5'd10;
            endcase
        end
    endfunction

    function [4:0] go_char_id;
        input [4:0] idx;
        begin
            // "GAME OVER"
            case (idx)
                5'd0: go_char_id = 5'd2;   // G
                5'd1: go_char_id = 5'd0;   // A
                5'd2: go_char_id = 5'd3;   // M
                5'd3: go_char_id = 5'd1;   // E
                5'd4: go_char_id = 5'd10;  // space
                5'd5: go_char_id = 5'd4;   // O
                5'd6: go_char_id = 5'd9;   // V
                5'd7: go_char_id = 5'd1;   // E
                5'd8: go_char_id = 5'd6;   // R
                default: go_char_id = 5'd10;
            endcase
        end
    endfunction

    function [4:0] restart_char_id;
        input [4:0] idx;
        begin
            // "PRESS KEY0 TO RESTART"
            case (idx)
                5'd0:  restart_char_id = 5'd5;   // P
                5'd1:  restart_char_id = 5'd6;   // R
                5'd2:  restart_char_id = 5'd1;   // E
                5'd3:  restart_char_id = 5'd7;   // S
                5'd4:  restart_char_id = 5'd7;   // S
                5'd5:  restart_char_id = 5'd10;  // space
                5'd6:  restart_char_id = 5'd11;  // K
                5'd7:  restart_char_id = 5'd1;   // E
                5'd8:  restart_char_id = 5'd12;  // Y
                5'd9:  restart_char_id = 5'd13;  // 0
                5'd10: restart_char_id = 5'd10;  // space
                5'd11: restart_char_id = 5'd8;   // T
                5'd12: restart_char_id = 5'd4;   // O
                5'd13: restart_char_id = 5'd10;  // space
                5'd14: restart_char_id = 5'd6;   // R
                5'd15: restart_char_id = 5'd1;   // E
                5'd16: restart_char_id = 5'd7;   // S
                5'd17: restart_char_id = 5'd8;   // T
                5'd18: restart_char_id = 5'd0;   // A
                5'd19: restart_char_id = 5'd6;   // R
                5'd20: restart_char_id = 5'd8;   // T
                default: restart_char_id = 5'd10;
            endcase
        end
    endfunction

    // Map digit 0..9 -> char ID for '0'..'9'
    function [4:0] digit_char_id;
        input [3:0] val;
        begin
            case (val)
                4'd0: digit_char_id = 5'd13;
                4'd1: digit_char_id = 5'd14;
                4'd2: digit_char_id = 5'd15;
                4'd3: digit_char_id = 5'd16;
                4'd4: digit_char_id = 5'd17;
                4'd5: digit_char_id = 5'd18;
                4'd6: digit_char_id = 5'd19;
                4'd7: digit_char_id = 5'd20;
                4'd8: digit_char_id = 5'd21;
                4'd9: digit_char_id = 5'd22;
                default: digit_char_id = 5'd13;
            endcase
        end
    endfunction

    //------------------------------------------------
    // Convert binary score to 4 decimal digits (BCD)
    //------------------------------------------------
    reg [3:0] score_thousands, score_hundreds, score_tens, score_ones;
    integer i;
    reg [27:0] shift_reg;

    always @* begin
        shift_reg = 28'd0;
        shift_reg[15:0] = score;

        for (i = 0; i < 16; i = i + 1) begin
            if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;
            if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
            if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
            shift_reg = shift_reg << 1;
        end

        score_thousands = shift_reg[27:24];
        score_hundreds  = shift_reg[23:20];
        score_tens      = shift_reg[19:16];
        score_ones      = shift_reg[15:12];
    end

    //------------------------------------------------
    // Text pixel generators (TITLE, GO, RESTART, SCORE, HP)
    //------------------------------------------------
    // TITLE
    reg title_px;
    integer t_rel_x, t_rel_y, t_char_idx, t_col;
    reg [7:0] t_row_bits;
    reg [4:0] t_cid;

    always @* begin
        title_px = 1'b0;
        if (pixel_y >= TITLE_Y0 && pixel_y < TITLE_Y0 + CHAR_H &&
            pixel_x >= TITLE_X0 && pixel_x < TITLE_X0 + TITLE_LEN*CHAR_W) begin

            t_rel_x    = pixel_x - TITLE_X0;
            t_rel_y    = pixel_y - TITLE_Y0;
            t_char_idx = t_rel_x / CHAR_W;
            t_col      = t_rel_x % CHAR_W;

            t_cid      = title_char_id(t_char_idx[4:0]);
            t_row_bits = font_row(t_cid, t_rel_y[2:0]);
            title_px   = t_row_bits[7 - t_col];
        end
    end
    wire title_text_pixel = title_px;

    // GAME OVER
    reg go_px;
    integer g_rel_x, g_rel_y, g_char_idx, g_col;
    reg [7:0] g_row_bits;
    reg [4:0] g_cid;

    always @* begin
        go_px = 1'b0;
        if (pixel_y >= GO_Y0 && pixel_y < GO_Y0 + CHAR_H &&
            pixel_x >= GO_X0 && pixel_x < GO_X0 + GO_LEN*CHAR_W) begin

            g_rel_x    = pixel_x - GO_X0;
            g_rel_y    = pixel_y - GO_Y0;
            g_char_idx = g_rel_x / CHAR_W;
            g_col      = g_rel_x % CHAR_W;

            g_cid      = go_char_id(g_char_idx[4:0]);
            g_row_bits = font_row(g_cid, g_rel_y[2:0]);
            go_px      = g_row_bits[7 - g_col];
        end
    end
    wire go_text_pixel = go_px;

    // "PRESS KEY0 TO RESTART"
    reg restart_px;
    integer r_rel_x, r_rel_y, r_char_idx, r_col;
    reg [7:0] r_row_bits;
    reg [4:0] r_cid;

    always @* begin
        restart_px = 1'b0;
        if (pixel_y >= RESTART_Y0 && pixel_y < RESTART_Y0 + CHAR_H &&
            pixel_x >= RESTART_X0 && pixel_x < RESTART_X0 + RESTART_LEN*CHAR_W) begin

            r_rel_x    = pixel_x - RESTART_X0;
            r_rel_y    = pixel_y - RESTART_Y0;
            r_char_idx = r_rel_x / CHAR_W;
            r_col      = r_rel_x % CHAR_W;

            r_cid      = restart_char_id(r_char_idx[4:0]);
            r_row_bits = font_row(r_cid, r_rel_y[2:0]);
            restart_px = r_row_bits[7 - r_col];
        end
    end
    wire restart_text_pixel = restart_px;

    // SCORE HUD: "SCORE:0000"
    reg score_px;
    integer s_rel_x, s_rel_y, s_char_idx, s_col;
    reg [7:0] s_row_bits;
    reg [4:0] s_cid;

    always @* begin
        score_px = 1'b0;
        if (pixel_y >= SCORE_Y0 && pixel_y < SCORE_Y0 + CHAR_H &&
            pixel_x >= SCORE_X0 && pixel_x < SCORE_X0 + SCORE_LEN*CHAR_W) begin

            s_rel_x    = pixel_x - SCORE_X0;
            s_rel_y    = pixel_y - SCORE_Y0;
            s_char_idx = s_rel_x / CHAR_W;
            s_col      = s_rel_x % CHAR_W;

            case (s_char_idx)
                0: s_cid = 5'd7;                      // S
                1: s_cid = 5'd24;                     // C
                2: s_cid = 5'd4;                      // O
                3: s_cid = 5'd6;                      // R
                4: s_cid = 5'd1;                      // E
                5: s_cid = 5'd25;                     // ':'
                6: s_cid = digit_char_id(score_thousands);
                7: s_cid = digit_char_id(score_hundreds);
                8: s_cid = digit_char_id(score_tens);
                9: s_cid = digit_char_id(score_ones);
                default: s_cid = 5'd10;              // space
            endcase

            s_row_bits = font_row(s_cid, s_rel_y[2:0]);
            score_px   = s_row_bits[7 - s_col];
        end
    end
    wire score_text_pixel = score_px;

    // HP HUD: "HP:x"
    reg hp_px;
    integer h_rel_x, h_rel_y, h_char_idx, h_col;
    reg [7:0] h_row_bits;
    reg [4:0] h_cid;
    reg [3:0] hp_digit;

    always @* begin
        hp_px = 1'b0;
        if (pixel_y >= HP_Y0 && pixel_y < HP_Y0 + CHAR_H &&
            pixel_x >= HP_X0 && pixel_x < HP_X0 + HP_LEN*CHAR_W) begin

            h_rel_x    = pixel_x - HP_X0;
            h_rel_y    = pixel_y - HP_Y0;
            h_char_idx = h_rel_x / CHAR_W;
            h_col      = h_rel_x % CHAR_W;

            if (ship_hp[2:0] > 3'd9)
                hp_digit = 4'd9;
            else
                hp_digit = {1'b0, ship_hp[2:0]};

            case (h_char_idx)
                0: h_cid = 5'd23;                  // H
                1: h_cid = 5'd5;                   // P
                2: h_cid = 5'd25;                  // ':'
                3: h_cid = digit_char_id(hp_digit);
                default: h_cid = 5'd10;
            endcase

            h_row_bits = font_row(h_cid, h_rel_y[2:0]);
            hp_px      = h_row_bits[7 - h_col];
        end
    end
    wire hp_text_pixel = hp_px;

    //------------------------------------------------
    // Final RGB mux with overlays
    //------------------------------------------------
    always @* begin
        rgb = 3'b000;  // default black

        if (video_on) begin
            case (ui_state)
                ST_TITLE: begin
                    // Black background + "PRESS START"
                    if (title_text_pixel)
                        rgb = 3'b111;   // white text
                    else
                        rgb = 3'b000;
                end

                ST_PLAY: begin
                    // default black
                    rgb = 3'b000;

                    // Start with white objects: bullet + meteors
                    if (bullet_pixel || meteor0_visible || meteor1_visible)
                        rgb = 3'b111;  // white

                    // Then overlay the colored ship
                    if (ship_r | ship_g | ship_b)
                        rgb = {ship_r, ship_g, ship_b};

                    // HUD on top (white)
                    if (score_text_pixel || hp_text_pixel)
                        rgb = 3'b111;
                end

                ST_GAMEOVER: begin
                    // Red background
                    rgb = 3'b100;

                    // Game over text + restart hint + HUD in white
                    if (go_text_pixel || restart_text_pixel ||
                        score_text_pixel || hp_text_pixel)
                        rgb = 3'b111;
                end

                default: begin
                    rgb = 3'b000;
                end
            endcase
        end
    end

    assign VGA_R = {8{rgb[2]}};
    assign VGA_G = {8{rgb[1]}};
    assign VGA_B = {8{rgb[0]}};

endmodule
