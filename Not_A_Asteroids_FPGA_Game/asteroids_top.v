module asteroids_top (
    input        CLOCK_50,
    input        reset_n,

    input        btn_up,
    input        btn_down,
    input        btn_left,
    input        btn_right,
    input        btn_fire,
    input        btn_start,  //normal
    input        btn_restart, //restart 
    input        btn_start2,   //hard

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

    wire start_pressed      = ~btn_start;     // KEY1
    wire restart_pressed    = ~btn_restart;   // KEY0
    wire hard_start_pressed = ~btn_start2;    // KEY2

    reg pix_clk_reg;
    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            pix_clk_reg <= 1'b0;
        else
            pix_clk_reg <= ~pix_clk_reg;
    end
    wire pix_clk = pix_clk_reg;

    // VGA timing
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

    // SHIP BULLET METEORS GAME STATE
    wire [9:0] ship_x;
    wire [9:0] ship_y;
    wire [1:0] ship_facing;

    wire [9:0] bullet_x;
    wire [9:0] bullet_y;
    wire       bullet_active;

    wire [9:0] meteor0_x;
    wire [9:0] meteor0_y;
    wire [2:0] meteor0_size;

    wire [9:0] meteor1_x;
    wire [9:0] meteor1_y;
    wire [2:0] meteor1_size;

    wire [9:0] meteor2_x;
    wire [9:0] meteor2_y;
    wire [2:0] meteor2_size;

    wire       meteor0_alive;
    wire       meteor1_alive;
	 wire       meteor2_alive; 
	 wire       meteor3_alive;
	 wire       meteor4_alive;
	 
	 wire [9:0] meteor3_x;
	 wire [9:0] meteor3_y;
	 wire [2:0] meteor3_size;

	 wire [9:0] meteor4_x;
	 wire [9:0] meteor4_y;
	 wire [2:0] meteor4_size;

    wire [15:0] score;
    wire [2:0]  ship_hp;
    wire        game_over;

    meteorthing #(
        .SCREEN_W   (SCREEN_W),
        .SCREEN_H   (SCREEN_H),
        .BASE_SPEED (1),
        .SEED       (10'h3A5)
    ) meteor0_inst (
        .clk         (pix_clk),
        .reset_n     (reset_n),
        .frame_tick  (frame_tick),
        .hard_mode   (hard_mode),
        .meteor_x    (meteor0_x),
        .meteor_y    (meteor0_y),
        .meteor_size (meteor0_size)
    );

    meteorthing #(
        .SCREEN_W   (SCREEN_W),
        .SCREEN_H   (SCREEN_H),
        .BASE_SPEED (1),
        .SEED       (10'h2F1)
    ) meteor1_inst (
        .clk         (pix_clk),
        .reset_n     (reset_n),
        .frame_tick  (frame_tick),
        .hard_mode   (hard_mode),
        .meteor_x    (meteor1_x),
        .meteor_y    (meteor1_y),
        .meteor_size (meteor1_size)
    );

    meteorthing #(
        .SCREEN_W   (SCREEN_W),
        .SCREEN_H   (SCREEN_H),
        .BASE_SPEED (1),
        .SEED       (10'h155)
    ) meteor2_inst (
        .clk         (pix_clk),
        .reset_n     (reset_n),
        .frame_tick  (frame_tick),
        .hard_mode   (hard_mode),
        .meteor_x    (meteor2_x),
        .meteor_y    (meteor2_y),
        .meteor_size (meteor2_size)
    );
	 
	 meteorthing #(
    .SCREEN_W   (SCREEN_W),
    .SCREEN_H   (SCREEN_H),
    .BASE_SPEED (1),
    .SEED       (10'h0C3)
) meteor3_inst (
    .clk         (pix_clk),
    .reset_n     (reset_n),
    .frame_tick  (frame_tick),
    .hard_mode   (hard_mode),
    .meteor_x    (meteor3_x),
    .meteor_y    (meteor3_y),
    .meteor_size (meteor3_size)
);

meteorthing #(
    .SCREEN_W   (SCREEN_W),
    .SCREEN_H   (SCREEN_H),
    .BASE_SPEED (1),
    .SEED       (10'h19D)
) meteor4_inst (
    .clk         (pix_clk),
    .reset_n     (reset_n),
    .frame_tick  (frame_tick),
    .hard_mode   (hard_mode),
    .meteor_x    (meteor4_x),
    .meteor_y    (meteor4_y),
    .meteor_size (meteor4_size)
);
    game_core_simple core_inst (
        .clk           (pix_clk),
        .reset_n       (reset_n),
        .frame_tick    (frame_tick),

        .btn_up        (btn_up),
        .btn_down      (btn_down),
        .btn_left      (btn_left),
        .btn_right     (btn_right),
        .btn_fire      (btn_fire),
        .btn_restart   (restart_pressed),

        .meteor0_x     (meteor0_x),
        .meteor0_y     (meteor0_y),
        .meteor0_size  (meteor0_size),
        .meteor1_x     (meteor1_x),
        .meteor1_y     (meteor1_y),
        .meteor1_size  (meteor1_size),
		  .meteor2_x     (meteor2_x), 
		  .meteor2_y     (meteor2_y), 
		  .meteor2_size  (meteor2_size),  
		  .meteor3_x     (meteor3_x),
		  .meteor3_y     (meteor3_y),
		  .meteor3_size  (meteor3_size),
		  .meteor4_x     (meteor4_x),
		  .meteor4_y     (meteor4_y),
		  .meteor4_size  (meteor4_size),

        .ship_x        (ship_x),
        .ship_y        (ship_y),
        .ship_facing   (ship_facing),

        .bullet_x      (bullet_x),
        .bullet_y      (bullet_y),
        .bullet_active (bullet_active),

        .meteor0_alive (meteor0_alive),
        .meteor1_alive (meteor1_alive),
		  .meteor2_alive (meteor2_alive),
		  .meteor3_alive (meteor3_alive),   
		  .meteor4_alive (meteor4_alive), 

        .score         (score),
        .ship_hp       (ship_hp),
        .game_over     (game_over)
    );

    localparam [1:0] ST_TITLE    = 2'd0;
    localparam [1:0] ST_PLAY     = 2'd1;
    localparam [1:0] ST_GAMEOVER = 2'd2;

    reg [1:0] ui_state;
    reg       hard_mode; 

    always @(posedge pix_clk or negedge reset_n) begin
        if (!reset_n) begin
            ui_state  <= ST_TITLE;
            hard_mode <= 1'b0;
        end else if (frame_tick) begin
            case (ui_state)
                ST_TITLE: begin
                    if (start_pressed) begin
                        ui_state  <= ST_PLAY;
                        hard_mode <= 1'b0;  
                    end else if (hard_start_pressed) begin
                        ui_state  <= ST_PLAY;
                        hard_mode <= 1'b1;  
                    end
                end

                ST_PLAY: begin
                    if (game_over)
                        ui_state <= ST_GAMEOVER;
                end

                ST_GAMEOVER: begin
                    if (restart_pressed) begin
                        ui_state  <= ST_TITLE;
                        hard_mode <= 1'b0; 
                    end
                end

                default: begin
                    ui_state  <= ST_TITLE;
                    hard_mode <= 1'b0;
                end
            endcase
        end
    end

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

wire bullet_pixel = bullet_active &&
                    (pixel_y == bullet_y) &&
                    (
                        (pixel_x == bullet_x - 2) ||
                        (pixel_x == bullet_x - 1) ||
                        (pixel_x == bullet_x    ) ||
                        (pixel_x == bullet_x + 1) ||
                        (pixel_x == bullet_x + 2)
                    );


    reg [9:0] meteor0_radius;
    reg [9:0] meteor1_radius;
    reg [9:0] meteor2_radius;
	 reg [9:0] meteor3_radius;
	 reg [9:0] meteor4_radius;

    always @* begin
        case (meteor0_size)
            3'd0: meteor0_radius = 10'd4;
            3'd1: meteor0_radius = 10'd8;
            3'd2: meteor0_radius = 10'd12;
            3'd3: meteor0_radius = 10'd16;
            default: meteor0_radius = 10'd20;
        endcase
    end

    always @* begin
        case (meteor1_size)
            3'd0: meteor1_radius = 10'd4;
            3'd1: meteor1_radius = 10'd8;
            3'd2: meteor1_radius = 10'd12;
            3'd3: meteor1_radius = 10'd16;
            default: meteor1_radius = 10'd20;
        endcase
    end

    always @* begin
        case (meteor2_size)
            3'd0: meteor2_radius = 10'd4;
            3'd1: meteor2_radius = 10'd8;
            3'd2: meteor2_radius = 10'd12;
            3'd3: meteor2_radius = 10'd16;
            default: meteor2_radius = 10'd20;
        endcase
    end
	 
	 always @* begin
    case (meteor3_size)
				3'd0: meteor3_radius = 10'd4;
				3'd1: meteor3_radius = 10'd8;
				3'd2: meteor3_radius = 10'd12;
				3'd3: meteor3_radius = 10'd16;
				default: meteor3_radius = 10'd20;
		  endcase
	end

	always @* begin
    case (meteor4_size)
				3'd0: meteor4_radius = 10'd4;
				3'd1: meteor4_radius = 10'd8;
				3'd2: meteor4_radius = 10'd12;
				3'd3: meteor4_radius = 10'd16;
				default: meteor4_radius = 10'd20;
		  endcase
	end


//mahanton distance
    wire [9:0] mdx0 = (pixel_x > meteor0_x) ? (pixel_x - meteor0_x) : (meteor0_x - pixel_x);
    wire [9:0] mdy0 = (pixel_y > meteor0_y) ? (pixel_y - meteor0_y) : (meteor0_y - pixel_y);
    wire [10:0] mdist0_sum = mdx0 + mdy0;

    wire [9:0] mdx1 = (pixel_x > meteor1_x) ? (pixel_x - meteor1_x) : (meteor1_x - pixel_x);
    wire [9:0] mdy1 = (pixel_y > meteor1_y) ? (pixel_y - meteor1_y) : (meteor1_y - pixel_y);
    wire [10:0] mdist1_sum = mdx1 + mdy1;

    wire [9:0] mdx2 = (pixel_x > meteor2_x) ? (pixel_x - meteor2_x) : (meteor2_x - pixel_x);
    wire [9:0] mdy2 = (pixel_y > meteor2_y) ? (pixel_y - meteor2_y) : (meteor2_y - pixel_y);
    wire [10:0] mdist2_sum = mdx2 + mdy2;
	 
	 wire [9:0] mdx3 = (pixel_x > meteor3_x) ? (pixel_x - meteor3_x) : (meteor3_x - pixel_x);
	 wire [9:0] mdy3 = (pixel_y > meteor3_y) ? (pixel_y - meteor3_y) : (meteor3_y - pixel_y);
	 wire [10:0] mdist3_sum = mdx3 + mdy3;

	 wire [9:0] mdx4 = (pixel_x > meteor4_x) ? (pixel_x - meteor4_x) : (meteor4_x - pixel_x);
	 wire [9:0] mdy4 = (pixel_y > meteor4_y) ? (pixel_y - meteor4_y) : (meteor4_y - pixel_y);
	 wire [10:0] mdist4_sum = mdx4 + mdy4;

    wire meteor0_pixel   = (mdist0_sum <= {1'b0, meteor0_radius});
    wire meteor1_pixel   = (mdist1_sum <= {1'b0, meteor1_radius});
    wire meteor2_pixel   = (mdist2_sum <= {1'b0, meteor2_radius});
	 wire meteor3_pixel   = (mdist3_sum <= {1'b0, meteor3_radius});
	 wire meteor4_pixel   = (mdist4_sum <= {1'b0, meteor4_radius});

    wire meteor0_visible = meteor0_pixel && meteor0_alive;
    wire meteor1_visible = meteor1_pixel && meteor1_alive;
    wire meteor2_visible = meteor2_pixel && meteor2_alive; 
	 wire meteor3_visible = meteor3_pixel && meteor3_alive;
	 wire meteor4_visible = meteor4_pixel && meteor4_alive; 
    
    // FONT

    function [7:0] font_row;
        input [4:0] cid;
        input [2:0] row;
        begin
            case (cid)
                // 0: A
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

                // 1: E
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

                // 2: G
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

                // 3: M
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

                // 4: O
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

                // 5: P
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

                // 6: R
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

                // 7: S
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

                // 8: T
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

                // 9: V
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

                // 10: space
                5'd10: font_row = 8'b00000000;

                // 11: K
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

                // 12: Y
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

                // 13: "0"
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

                // 14: "1"
                5'd14: case (row)
                    3'd0: font_row = 8'b00011000;
                    3'd1: font_row = 8'b00111000;
                    3'd2: font_row = 8'b00011000;
                    3'd3: font_row = 8'b00011000;
                    3'd4: font_row = 8'b00011000;
                    3'd5: font_row = 8'b00011000;
                    3'd6: font_row = 8'b01111110;
                    default: font_row = 8'b00000000;
                endcase

                // 15: "2"
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

                // 16: "3"
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

                // 17: "4"
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

                // 18: "5"
                5'd18: case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b01100000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b00000110;
                    3'd4: font_row = 8'b00000110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase

                // 19: "6"
                5'd19: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100000;
                    3'd3: font_row = 8'b01111100;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01100110;
                    3'd6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase

                // 20: "7"
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

                // 21: "8"
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

                // 22: "9"
                5'd22: case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100110;
                    3'd3: font_row = 8'b00111110;
                    3'd4: font_row = 8'b00000110;
                    3'd5: font_row = 8'b00001100;
                    3'd6: font_row = 8'b00111000;
                    default: font_row = 8'b00000000;
                endcase

                // 23: H
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

                // 24: C
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

                // 25: ':' (colon)
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

                // 26: N
                5'd26: case (row)
                    3'd0: font_row = 8'b01100011;
                    3'd1: font_row = 8'b01110011;
                    3'd2: font_row = 8'b01111011;
                    3'd3: font_row = 8'b01101111;
                    3'd4: font_row = 8'b01100111;
                    3'd5: font_row = 8'b01100011;
                    3'd6: font_row = 8'b01100011;
                    default: font_row = 8'b00000000;
                endcase

                // 27: D
                5'd27: case (row)
                    3'd0: font_row = 8'b01111100;
                    3'd1: font_row = 8'b01100110;
                    3'd2: font_row = 8'b01100011;
                    3'd3: font_row = 8'b01100011;
                    3'd4: font_row = 8'b01100110;
                    3'd5: font_row = 8'b01111100;
                    3'd6: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase

                // 28: I
                5'd28: case (row)
                    3'd0: font_row = 8'b00011100;
                    3'd1: font_row = 8'b00001100;
                    3'd2: font_row = 8'b00001100;
                    3'd3: font_row = 8'b00001100;
                    3'd4: font_row = 8'b00001100;
                    3'd5: font_row = 8'b00011110;
                    3'd6: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase

                // 29: F
                5'd29: case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b01100000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b01100000;
                    3'd4: font_row = 8'b01100000;
                    3'd5: font_row = 8'b01100000;
                    3'd6: font_row = 8'b01100000;
                    default: font_row = 8'b00000000;
                endcase

                default: font_row = 8'b00000000;
            endcase
        end
    endfunction

    function [4:0] digit_char_id;
        input [3:0] d;
        begin
            case (d)
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

    localparam CHAR_W = 8;
    localparam CHAR_H = 8;


    localparam integer TITLE_LEN = 19;
    localparam integer TITLE_X0  = (SCREEN_W - TITLE_LEN*CHAR_W)/2;
    localparam integer TITLE_Y0  = 10 + 70*CHAR_H/2;

    localparam integer GO_LEN = 9;
    localparam integer GO_X0  = (SCREEN_W - GO_LEN*CHAR_W)/2;
    localparam integer GO_Y0  = 150;

    localparam integer RESTART_LEN = 21;
    localparam integer RESTART_X0  = (SCREEN_W - RESTART_LEN*CHAR_W)/2;
    localparam integer RESTART_Y0  = 210;

    localparam integer SCORE_LEN = 11;
    localparam integer SCORE_X0  = 8;
    localparam integer SCORE_Y0  = 8;

    localparam integer HP_LEN = 4;
    localparam integer HP_X0  = SCREEN_W - HP_LEN*CHAR_W - 8;
    localparam integer HP_Y0  = 8;

    localparam integer LOGO_LEN = 20;
    localparam integer LOGO_X0  = (SCREEN_W - LOGO_LEN*CHAR_W)/2;
    localparam integer LOGO_Y0  = 80;

    localparam integer HARD_TITLE_LEN = 24;
    localparam integer HARD_TITLE_X0  = (SCREEN_W - HARD_TITLE_LEN*CHAR_W)/2;
    localparam integer HARD_TITLE_Y0  = TITLE_Y0 + CHAR_H + 8;

    function [4:0] title_char_id;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  title_char_id = 5'd5;   // P
                5'd1:  title_char_id = 5'd6;   // R
                5'd2:  title_char_id = 5'd1;   // E
                5'd3:  title_char_id = 5'd7;   // S
                5'd4:  title_char_id = 5'd7;   // S
                5'd5:  title_char_id = 5'd10;  // space
                5'd6:  title_char_id = 5'd11;  // K
                5'd7:  title_char_id = 5'd1;   // E
                5'd8:  title_char_id = 5'd12;  // Y
                5'd9:  title_char_id = 5'd14;  // '1'
                5'd10: title_char_id = 5'd10;  // space
                5'd11: title_char_id = 5'd8;   // T
                5'd12: title_char_id = 5'd4;   // O
                5'd13: title_char_id = 5'd10;  // space
                5'd14: title_char_id = 5'd7;   // S
                5'd15: title_char_id = 5'd8;   // T
                5'd16: title_char_id = 5'd0;   // A
                5'd17: title_char_id = 5'd6;   // R
                5'd18: title_char_id = 5'd8;   // T
                default: title_char_id = 5'd10;
            endcase
        end
    endfunction

    function [4:0] go_char_id;
        input [4:0] idx;
        begin
            case (idx)
                5'd0: go_char_id = 5'd2;  // G
                5'd1: go_char_id = 5'd0;  // A
                5'd2: go_char_id = 5'd3;  // M
                5'd3: go_char_id = 5'd1;  // E
                5'd4: go_char_id = 5'd10; // space
                5'd5: go_char_id = 5'd4;  // O
                5'd6: go_char_id = 5'd9;  // V
                5'd7: go_char_id = 5'd1;  // E
                5'd8: go_char_id = 5'd6;  // R
                default: go_char_id = 5'd10;
            endcase
        end
    endfunction

    function [4:0] restart_char_id;
        input [4:0] idx;
        begin
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
                5'd9:  restart_char_id = 5'd13;  // '0'
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

    function [4:0] logo_char_id;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  logo_char_id = 5'd26; // N
                5'd1:  logo_char_id = 5'd4;  // O
                5'd2:  logo_char_id = 5'd8;  // T
                5'd3:  logo_char_id = 5'd10; // space
                5'd4:  logo_char_id = 5'd0;  // A
                5'd5:  logo_char_id = 5'd10; // space
                5'd6:  logo_char_id = 5'd0;  // A
                5'd7:  logo_char_id = 5'd7;  // S
                5'd8:  logo_char_id = 5'd8;  // T
                5'd9:  logo_char_id = 5'd1;  // E
                5'd10: logo_char_id = 5'd6;  // R
                5'd11: logo_char_id = 5'd4;  // O
                5'd12: logo_char_id = 5'd28; // I
                5'd13: logo_char_id = 5'd27; // D
                5'd14: logo_char_id = 5'd7;  // S
                5'd15: logo_char_id = 5'd10; // space
                5'd16: logo_char_id = 5'd2;  // G
                5'd17: logo_char_id = 5'd0;  // A
                5'd18: logo_char_id = 5'd3;  // M
                5'd19: logo_char_id = 5'd1;  // E
                default: logo_char_id = 5'd10;
            endcase
        end
    endfunction

    function [4:0] hard_title_char_id;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  hard_title_char_id = 5'd5;   // P
                5'd1:  hard_title_char_id = 5'd6;   // R
                5'd2:  hard_title_char_id = 5'd1;   // E
                5'd3:  hard_title_char_id = 5'd7;   // S
                5'd4:  hard_title_char_id = 5'd7;   // S
                5'd5:  hard_title_char_id = 5'd10;  // space
                5'd6:  hard_title_char_id = 5'd11;  // K
                5'd7:  hard_title_char_id = 5'd1;   // E
                5'd8:  hard_title_char_id = 5'd12;  // Y
                5'd9:  hard_title_char_id = 5'd15;  // '2'
                5'd10: hard_title_char_id = 5'd10;  // space
                5'd11: hard_title_char_id = 5'd29;  // F
                5'd12: hard_title_char_id = 5'd4;   // O
                5'd13: hard_title_char_id = 5'd6;   // R
                5'd14: hard_title_char_id = 5'd10;  // space
                5'd15: hard_title_char_id = 5'd23;  // H
                5'd16: hard_title_char_id = 5'd0;   // A
                5'd17: hard_title_char_id = 5'd6;   // R
                5'd18: hard_title_char_id = 5'd27;  // D
                5'd19: hard_title_char_id = 5'd10;  // space
                5'd20: hard_title_char_id = 5'd3;   // M
                5'd21: hard_title_char_id = 5'd4;   // O
                5'd22: hard_title_char_id = 5'd27;  // D
                5'd23: hard_title_char_id = 5'd1;   // E
                default: hard_title_char_id = 5'd10;
            endcase
        end
    endfunction

    reg [3:0] score_d0, score_d1, score_d2, score_d3;
    integer tmp;

    always @* begin
        tmp = score;
        if (tmp > 9999) tmp = 9999;

        score_d0 = tmp % 10;
        tmp      = tmp / 10;
        score_d1 = tmp % 10;
        tmp      = tmp / 10;
        score_d2 = tmp % 10;
        tmp      = tmp / 10;
        score_d3 = tmp % 10;
    end

    reg title_px, go_px, restart_px, score_px, hp_px, logo_px, hard_title_px;

    always @* begin
        title_px = 1'b0;
        if (pixel_y >= TITLE_Y0 && pixel_y < TITLE_Y0 + CHAR_H &&
            pixel_x >= TITLE_X0 && pixel_x < TITLE_X0 + TITLE_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;

            rel_x    = pixel_x - TITLE_X0;
            rel_y    = pixel_y - TITLE_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;
            cid      = title_char_id(char_idx[4:0]);
            row_bits = font_row(cid, rel_y[2:0]);
            title_px = row_bits[7-col];
        end
    end

    always @* begin
        logo_px = 1'b0;
        if (pixel_y >= LOGO_Y0 && pixel_y < LOGO_Y0 + CHAR_H &&
            pixel_x >= LOGO_X0 && pixel_x < LOGO_X0 + LOGO_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;

            rel_x    = pixel_x - LOGO_X0;
            rel_y    = pixel_y - LOGO_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;

            cid      = logo_char_id(char_idx[4:0]);
            row_bits = font_row(cid, rel_y[2:0]);
            logo_px  = row_bits[7 - col];
        end
    end

    always @* begin
        hard_title_px = 1'b0;
        if (pixel_y >= HARD_TITLE_Y0 && pixel_y < HARD_TITLE_Y0 + CHAR_H &&
            pixel_x >= HARD_TITLE_X0 && pixel_x < HARD_TITLE_X0 + HARD_TITLE_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;

            rel_x    = pixel_x - HARD_TITLE_X0;
            rel_y    = pixel_y - HARD_TITLE_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;

            cid         = hard_title_char_id(char_idx[4:0]);
            row_bits    = font_row(cid, rel_y[2:0]);
            hard_title_px = row_bits[7 - col];
        end
    end

    always @* begin
        go_px = 1'b0;
        if (pixel_y >= GO_Y0 && pixel_y < GO_Y0 + CHAR_H &&
            pixel_x >= GO_X0 && pixel_x < GO_X0 + GO_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;

            rel_x    = pixel_x - GO_X0;
            rel_y    = pixel_y - GO_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;
            cid      = go_char_id(char_idx[4:0]);
            row_bits = font_row(cid, rel_y[2:0]);
            go_px    = row_bits[7-col];
        end
    end

    always @* begin
        restart_px = 1'b0;
        if (pixel_y >= RESTART_Y0 && pixel_y < RESTART_Y0 + CHAR_H &&
            pixel_x >= RESTART_X0 && pixel_x < RESTART_X0 + RESTART_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;

            rel_x    = pixel_x - RESTART_X0;
            rel_y    = pixel_y - RESTART_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;
            cid      = restart_char_id(char_idx[4:0]);
            row_bits = font_row(cid, rel_y[2:0]);
            restart_px = row_bits[7-col];
        end
    end

    always @* begin
        score_px = 1'b0;
        if (pixel_y >= SCORE_Y0 && pixel_y < SCORE_Y0 + CHAR_H &&
            pixel_x >= SCORE_X0 && pixel_x < SCORE_X0 + SCORE_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;

            rel_x    = pixel_x - SCORE_X0;
            rel_y    = pixel_y - SCORE_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;

            case (char_idx)
                0:  cid = 5'd7;               // S
                1:  cid = 5'd24;              // C
                2:  cid = 5'd4;               // O
                3:  cid = 5'd6;               // R
                4:  cid = 5'd1;               // E
                5:  cid = 5'd25;              // :
                6:  cid = digit_char_id(score_d3);
                7:  cid = digit_char_id(score_d2);
                8:  cid = digit_char_id(score_d1);
                9:  cid = digit_char_id(score_d0);
                10: cid = 5'd10;              
                default: cid = 5'd10;
            endcase

            row_bits = font_row(cid, rel_y[2:0]);
            score_px = row_bits[7-col];
        end
    end

    always @* begin
        hp_px = 1'b0;
        if (pixel_y >= HP_Y0 && pixel_y < HP_Y0 + CHAR_H &&
            pixel_x >= HP_X0 && pixel_x < HP_X0 + HP_LEN*CHAR_W) begin

            integer rel_x, rel_y, char_idx, col;
            reg [7:0] row_bits;
            reg [4:0] cid;
            reg [3:0] hp_digit;

            rel_x    = pixel_x - HP_X0;
            rel_y    = pixel_y - HP_Y0;
            char_idx = rel_x / CHAR_W;
            col      = rel_x % CHAR_W;

            hp_digit = {1'b0, ship_hp[2:0]};

            case (char_idx)
                0: cid = 5'd23;               
                1: cid = 5'd5;                
                2: cid = 5'd25;              
                3: cid = digit_char_id(hp_digit);
                default: cid = 5'd10;
            endcase

            row_bits = font_row(cid, rel_y[2:0]);
            hp_px    = row_bits[7-col];
        end
    end


    reg [2:0] rgb;

    always @* begin
        rgb = 3'b000;

        if (video_on) begin
            case (ui_state)
                ST_TITLE: begin
                    rgb = 3'b000;

                    if (logo_px)
                        rgb = 3'b111;  

                    if (title_px)
                        rgb = 3'b111;  

                    if (hard_title_px)
                        rgb = 3'b111; 
                end

                ST_PLAY: begin
                    rgb = 3'b000;

                    if (meteor0_visible || meteor1_visible || meteor2_visible ||
													meteor3_visible || meteor4_visible || bullet_pixel)
                        rgb = 3'b111;

                    if (ship_r | ship_g | ship_b)
                        rgb = {ship_r, ship_g, ship_b};

                    if (score_px || hp_px)
                        rgb = 3'b111;
                end

                ST_GAMEOVER: begin
                    rgb = 3'b100; 

                    if (go_px || restart_px || score_px || hp_px)
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
