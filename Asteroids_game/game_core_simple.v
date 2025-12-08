//============================================================
// Simple game core with TWO meteors
//  - Ship position & facing
//  - One bullet, ALWAYS moves UP
//  - Two meteors: HP + bullet collision + score
//  - Ship HP + collision with meteors + invincibility
//  - GAME OVER + restart button
//  - Updated once per frame using frame_tick
//============================================================
module game_core_simple (
    input        clk,
    input        reset_n,
    input        frame_tick,   // 1 pulse per frame (from VGA core)

    input        btn_up,
    input        btn_down,
    input        btn_left,
    input        btn_right,
    input        btn_fire,
    input        btn_restart,  // NEW: restart game when in GAME OVER

    // Meteor 0 info
    input  [9:0] meteor0_x,
    input  [9:0] meteor0_y,
    input  [2:0] meteor0_size,

    // Meteor 1 info
    input  [9:0] meteor1_x,
    input  [9:0] meteor1_y,
    input  [2:0] meteor1_size,

    // Ship & bullet outputs
    output reg [9:0] ship_x,
    output reg [9:0] ship_y,
    output reg [1:0] ship_facing,   // 00=up, 01=right, 10=down, 11=left

    output reg [9:0] bullet_x,
    output reg [9:0] bullet_y,
    output reg       bullet_active,

    // Meteor alive flags (for draw gating)
    output reg       meteor0_alive,
    output reg       meteor1_alive,

    // Score
    output reg [15:0] score,

    // Ship HP + game over (for HUD / top-level logic)
    output reg [2:0] ship_hp,      // e.g. 3 lives
    output reg       game_over
);

    // Screen & movement parameters
    localparam SCREEN_W       = 640;
    localparam SCREEN_H       = 480;
    localparam SHIP_SPEED     = 2;    // ship pixels per frame
    localparam BULLET_SPEED   = 4;    // bullet pixels per frame
    localparam SHIP_MAX_HP    = 3;    // starting HP
    localparam INVINC_FRAMES  = 60;   // ~1 second at 60 FPS
    localparam SHIP_COLL_R    = 10;   // approx ship radius for collision

    // Meteor HP
    reg [2:0] meteor0_hp, meteor1_hp;

    // Track previous Y to detect respawn (Y jump back)
    reg [9:0] prev_meteor0_y, prev_meteor1_y;

    // Ship invincibility timer (frames)
    reg [7:0] invinc_timer;

    //---------------------------------------------
    // Meteor radii (for collision), based on size
    //---------------------------------------------
    reg [9:0] meteor0_radius_core;
    reg [9:0] meteor1_radius_core;

    always @* begin
        case (meteor0_size)
            3'd0: meteor0_radius_core = 10'd4;    // XS
            3'd1: meteor0_radius_core = 10'd8;    // S
            3'd2: meteor0_radius_core = 10'd12;   // M
            3'd3: meteor0_radius_core = 10'd16;   // L
            default: meteor0_radius_core = 10'd20; // XL / default
        endcase
    end

    always @* begin
        case (meteor1_size)
            3'd0: meteor1_radius_core = 10'd4;    // XS
            3'd1: meteor1_radius_core = 10'd8;    // S
            3'd2: meteor1_radius_core = 10'd12;   // M
            3'd3: meteor1_radius_core = 10'd16;   // L
            default: meteor1_radius_core = 10'd20; // XL / default
        endcase
    end

    //---------------------------------------------
    // Meteor points based on size
    //---------------------------------------------
    reg [7:0] meteor0_points, meteor1_points;
    always @* begin
        case (meteor0_size)
            3'd0: meteor0_points = 8'd10; // XS
            3'd1: meteor0_points = 8'd20; // S
            3'd2: meteor0_points = 8'd30; // M
            3'd3: meteor0_points = 8'd40; // L
            default: meteor0_points = 8'd50; // XL
        endcase
    end

    always @* begin
        case (meteor1_size)
            3'd0: meteor1_points = 8'd10; // XS
            3'd1: meteor1_points = 8'd20; // S
            3'd2: meteor1_points = 8'd30; // M
            3'd3: meteor1_points = 8'd40; // L
            default: meteor1_points = 8'd50; // XL
        endcase
    end

    //---------------------------------------------
    // Bullet -> meteor collision (Manhattan distance)
    //---------------------------------------------
    wire [9:0] bdx0 = (bullet_x > meteor0_x) ? (bullet_x - meteor0_x) : (meteor0_x - bullet_x);
    wire [9:0] bdy0 = (bullet_y > meteor0_y) ? (bullet_y - meteor0_y) : (meteor0_y - bullet_y);

    wire [9:0] bdx1 = (bullet_x > meteor1_x) ? (bullet_x - meteor1_x) : (meteor1_x - bullet_x);
    wire [9:0] bdy1 = (bullet_y > meteor1_y) ? (bullet_y - meteor1_y) : (meteor1_y - bullet_y);

    wire [10:0] bdist0_sum = bdx0 + bdy0;
    wire [10:0] bdist1_sum = bdx1 + bdy1;

    wire bullet_hits_meteor0 = bullet_active &&
                               meteor0_alive &&
                               (bdist0_sum <= {1'b0, meteor0_radius_core});

    wire bullet_hits_meteor1 = bullet_active &&
                               meteor1_alive &&
                               (bdist1_sum <= {1'b0, meteor1_radius_core});

    //---------------------------------------------
    // Ship -> meteor collision (Manhattan distance)
    //---------------------------------------------
    wire [9:0] sdx0 = (ship_x > meteor0_x) ? (ship_x - meteor0_x) : (meteor0_x - ship_x);
    wire [9:0] sdy0 = (ship_y > meteor0_y) ? (ship_y - meteor0_y) : (meteor0_y - ship_y);

    wire [9:0] sdx1 = (ship_x > meteor1_x) ? (ship_x - meteor1_x) : (meteor1_x - ship_x);
    wire [9:0] sdy1 = (ship_y > meteor1_y) ? (ship_y - meteor1_y) : (meteor1_y - ship_y);

    wire [10:0] sdist0_sum = sdx0 + sdy0;
    wire [10:0] sdist1_sum = sdx1 + sdy1;

    // collision threshold approx ship radius + meteor radius
    wire [10:0] coll0_thresh = {1'b0, (SHIP_COLL_R + meteor0_radius_core)};
    wire [10:0] coll1_thresh = {1'b0, (SHIP_COLL_R + meteor1_radius_core)};

    wire ship_hits_meteor0 = meteor0_alive && (sdist0_sum <= coll0_thresh);
    wire ship_hits_meteor1 = meteor1_alive && (sdist1_sum <= coll1_thresh);

    wire ship_takes_hit = (ship_hits_meteor0 || ship_hits_meteor1) &&
                          (invinc_timer == 0) &&
                          (ship_hp > 0);

    //------------------------------------------------------------
    // Soft reset task (restart button)
    //------------------------------------------------------------
    task soft_reset;
    begin
        // Ship
        ship_x        <= SCREEN_W / 2;
        ship_y        <= SCREEN_H / 2;
        ship_facing   <= 2'b00;      // up

        // Bullet
        bullet_x      <= 10'd0;
        bullet_y      <= 10'd0;
        bullet_active <= 1'b0;

        // Meteors: mark as alive, HP will be reloaded on respawn
        meteor0_alive   <= 1'b1;
        meteor1_alive   <= 1'b1;
        meteor0_hp      <= 3'd3;
        meteor1_hp      <= 3'd3;
        prev_meteor0_y  <= meteor0_y;
        prev_meteor1_y  <= meteor1_y;

        // Score + ship HP + invinc + game_over
        score         <= 16'd0;
        ship_hp       <= SHIP_MAX_HP[2:0];
        invinc_timer  <= 8'd0;
        game_over     <= 1'b0;
    end
    endtask

    //------------------------------------------------------------
    // Main state update: once per frame
    //------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            soft_reset();
        end 
        else if (frame_tick) begin
            //----------------------------------------
            // If game over, only allow restart
            //----------------------------------------
            if (game_over) begin
                // Restart if button pressed
                if (btn_restart) begin
                    soft_reset();
                end
                // Still track meteor_y so respawn detection doesn't glitch
                prev_meteor0_y <= meteor0_y;
                prev_meteor1_y <= meteor1_y;

                // let invinc_timer count down (not really needed here)
                if (invinc_timer != 0)
                    invinc_timer <= invinc_timer - 8'd1;
            end 
            else begin
                //----------------------------------------
                // Ship movement & facing
                //----------------------------------------
                if (btn_up) begin
                    ship_facing <= 2'b00; // up
                    if (ship_y > SHIP_SPEED)
                        ship_y <= ship_y - SHIP_SPEED;
                    else
                        ship_y <= 10'd0;
                end 
                else if (btn_down) begin
                    ship_facing <= 2'b10; // down
                    if (ship_y < SCREEN_H - SHIP_SPEED - 1)
                        ship_y <= ship_y + SHIP_SPEED;
                    else
                        ship_y <= SCREEN_H - 1;
                end 
                else if (btn_right) begin
                    ship_facing <= 2'b01; // right
                    if (ship_x < SCREEN_W - SHIP_SPEED - 1)
                        ship_x <= ship_x + SHIP_SPEED;
                    else
                        ship_x <= SCREEN_W - 1;
                end 
                else if (btn_left) begin
                    ship_facing <= 2'b11; // left
                    if (ship_x > SHIP_SPEED)
                        ship_x <= ship_x - SHIP_SPEED;
                    else
                        ship_x <= 10'd0;
                end

                //----------------------------------------
                // Bullet logic: one bullet at a time
                //----------------------------------------
                if (!bullet_active) begin
                    // Start new bullet if fire pressed
                    if (btn_fire) begin
                        bullet_active <= 1'b1;
                        bullet_x      <= ship_x;
                        bullet_y      <= ship_y;
                    end
                end 
                else begin
                    // ALWAYS MOVE BULLET UP (independent of ship facing)
                    if (bullet_y > BULLET_SPEED)
                        bullet_y <= bullet_y - BULLET_SPEED;
                    else begin
                        bullet_y      <= 10'd0;
                        bullet_active <= 1'b0;  // bullet disappears at top
                    end
                end

                //----------------------------------------
                // Detect meteor respawn (Y reset)
                //----------------------------------------
                if (meteor0_y < prev_meteor0_y) begin
                    meteor0_alive <= 1'b1;
                    case (meteor0_size)
                        3'd0: meteor0_hp <= 3'd1; // XS
                        3'd1: meteor0_hp <= 3'd2; // S
                        3'd2: meteor0_hp <= 3'd3; // M
                        3'd3: meteor0_hp <= 3'd4; // L
                        default: meteor0_hp <= 3'd5; // XL
                    endcase
                end

                if (meteor1_y < prev_meteor1_y) begin
                    meteor1_alive <= 1'b1;
                    case (meteor1_size)
                        3'd0: meteor1_hp <= 3'd1; // XS
                        3'd1: meteor1_hp <= 3'd2; // S
                        3'd2: meteor1_hp <= 3'd3; // M
                        3'd3: meteor1_hp <= 3'd4; // L
                        default: meteor1_hp <= 3'd5; // XL
                    endcase
                end

                //----------------------------------------
                // Bullet–meteor collision handling
                //----------------------------------------
                if (bullet_hits_meteor0) begin
                    bullet_active <= 1'b0;   // bullet disappears on hit
                    if (meteor0_hp > 0)
                        meteor0_hp <= meteor0_hp - 3'd1;

                    if (meteor0_hp == 3'd1) begin
                        meteor0_alive <= 1'b0;
                        score         <= score + meteor0_points;
                    end
                end

                if (bullet_hits_meteor1) begin
                    bullet_active <= 1'b0;   // bullet disappears on hit
                    if (meteor1_hp > 0)
                        meteor1_hp <= meteor1_hp - 3'd1;

                    if (meteor1_hp == 3'd1) begin
                        meteor1_alive <= 1'b0;
                        score         <= score + meteor1_points;
                    end
                end

                //----------------------------------------
                // Ship HP + invincibility + collision
                //----------------------------------------
                // Count down invincibility timer
                if (invinc_timer != 0)
                    invinc_timer <= invinc_timer - 8'd1;

                if (ship_takes_hit) begin
                    if (ship_hp > 0)
                        ship_hp <= ship_hp - 3'd1;

                    invinc_timer <= INVINC_FRAMES[7:0];

                    // If we just used the last HP, go to game over
                    if (ship_hp == 3'd1)
                        game_over <= 1'b1;
                end

                //----------------------------------------
                // Update previous meteor_y for next frame
                //----------------------------------------
                prev_meteor0_y <= meteor0_y;
                prev_meteor1_y <= meteor1_y;
            end
        end
    end

endmodule
