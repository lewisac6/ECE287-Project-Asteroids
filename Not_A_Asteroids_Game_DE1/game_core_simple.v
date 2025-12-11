module game_core_simple (
    input        clk,
    input        reset_n,
    input        frame_tick,

    input        btn_up,
    input        btn_down,
    input        btn_left,
    input        btn_right,
    input        btn_fire,
    input        btn_restart, 

    input  [9:0] meteor0_x,
    input  [9:0] meteor0_y,
    input  [2:0] meteor0_size,

    input  [9:0] meteor1_x,
    input  [9:0] meteor1_y,
    input  [2:0] meteor1_size,
    
    input  [9:0] meteor2_x,
    input  [9:0] meteor2_y,
    input  [2:0] meteor2_size,

    input  [9:0] meteor3_x,
    input  [9:0] meteor3_y,
    input  [2:0] meteor3_size,

    input  [9:0] meteor4_x,
    input  [9:0] meteor4_y,
    input  [2:0] meteor4_size,

    output reg [9:0] ship_x,
    output reg [9:0] ship_y,
    output reg [1:0] ship_facing,  

    output reg [9:0] bullet_x,
    output reg [9:0] bullet_y,
    output reg       bullet_active,

    output reg   meteor0_alive,
    output reg   meteor1_alive,
    output reg   meteor2_alive, 
    output reg   meteor3_alive,
    output reg   meteor4_alive,

    output reg [15:0] score,

    output reg [2:0] ship_hp, 
    output reg       game_over
);

    localparam SCREEN_W       = 640;
    localparam SCREEN_H       = 480;
    localparam SHIP_SPEED     = 2;    
    localparam BULLET_SPEED   = 10;   
    localparam SHIP_MAX_HP    = 4;  
    localparam INVINC_FRAMES  = 60; 
    localparam SHIP_COLL_R    = 10; 
    localparam FIRE_COOLDOWN_FRAMES = 30;
    localparam [9:0] BULLET_HIT_R   = 10'd4; 

    reg [7:0] fire_cooldown;

    reg [2:0] meteor0_hp, meteor1_hp, meteor2_hp, meteor3_hp, meteor4_hp;
    reg [9:0] prev_meteor0_y, prev_meteor1_y, prev_meteor2_y, prev_meteor3_y, prev_meteor4_y;
    reg [7:0] invinc_timer;

    reg [9:0] meteor0_radius_core;
    reg [9:0] meteor1_radius_core;
    reg [9:0] meteor2_radius_core;
    reg [9:0] meteor3_radius_core;
    reg [9:0] meteor4_radius_core;

    always @* begin
        case (meteor0_size)
            3'd0: meteor0_radius_core = 10'd4;   
            3'd1: meteor0_radius_core = 10'd8;    
            3'd2: meteor0_radius_core = 10'd12;   
            3'd3: meteor0_radius_core = 10'd16;   
            default: meteor0_radius_core = 10'd20; 
        endcase
    end

    always @* begin
        case (meteor1_size)
            3'd0: meteor1_radius_core = 10'd4;   
            3'd1: meteor1_radius_core = 10'd8;   
            3'd2: meteor1_radius_core = 10'd12;  
            3'd3: meteor1_radius_core = 10'd16;   
            default: meteor1_radius_core = 10'd20; 
        endcase
    end

    always @* begin
        case (meteor2_size)
            3'd0: meteor2_radius_core = 10'd4;   
            3'd1: meteor2_radius_core = 10'd8;   
            3'd2: meteor2_radius_core = 10'd12;  
            3'd3: meteor2_radius_core = 10'd16;   
            default: meteor2_radius_core = 10'd20; 
        endcase
    end

    always @* begin
        case (meteor3_size)
            3'd0: meteor3_radius_core = 10'd4;   
            3'd1: meteor3_radius_core = 10'd8;   
            3'd2: meteor3_radius_core = 10'd12;  
            3'd3: meteor3_radius_core = 10'd16;   
            default: meteor3_radius_core = 10'd20; 
        endcase
    end

    always @* begin
        case (meteor4_size)
            3'd0: meteor4_radius_core = 10'd4;   
            3'd1: meteor4_radius_core = 10'd8;   
            3'd2: meteor4_radius_core = 10'd12;  
            3'd3: meteor4_radius_core = 10'd16;   
            default: meteor4_radius_core = 10'd20; 
        endcase
    end

    reg [7:0] meteor0_points, meteor1_points, meteor2_points, meteor3_points, meteor4_points;
    always @* begin
        case (meteor0_size)
            3'd0: meteor0_points = 8'd10; 
            3'd1: meteor0_points = 8'd20; 
            3'd2: meteor0_points = 8'd30; 
            3'd3: meteor0_points = 8'd40; 
            default: meteor0_points = 8'd50; 
        endcase
    end

    always @* begin
        case (meteor1_size)
            3'd0: meteor1_points = 8'd10; 
            3'd1: meteor1_points = 8'd20; 
            3'd2: meteor1_points = 8'd30; 
            3'd3: meteor1_points = 8'd40; 
            default: meteor1_points = 8'd50; 
        endcase
    end

    always @* begin
        case (meteor2_size)
            3'd0: meteor2_points = 8'd10; 
            3'd1: meteor2_points = 8'd20; 
            3'd2: meteor2_points = 8'd30; 
            3'd3: meteor2_points = 8'd40; 
            default: meteor2_points = 8'd50; 
        endcase
    end

    always @* begin
        case (meteor3_size)
            3'd0: meteor3_points = 8'd10; 
            3'd1: meteor3_points = 8'd20; 
            3'd2: meteor3_points = 8'd30; 
            3'd3: meteor3_points = 8'd40; 
            default: meteor3_points = 8'd50; 
        endcase
    end

    always @* begin
        case (meteor4_size)
            3'd0: meteor4_points = 8'd10; 
            3'd1: meteor4_points = 8'd20; 
            3'd2: meteor4_points = 8'd30; 
            3'd3: meteor4_points = 8'd40; 
            default: meteor4_points = 8'd50; 
        endcase
    end

    wire [9:0] bdx0 = (bullet_x > meteor0_x) ? (bullet_x - meteor0_x) : (meteor0_x - bullet_x);
    wire [9:0] bdy0 = (bullet_y > meteor0_y) ? (bullet_y - meteor0_y) : (meteor0_y - bullet_y);

    wire [9:0] bdx1 = (bullet_x > meteor1_x) ? (bullet_x - meteor1_x) : (meteor1_x - bullet_x);
    wire [9:0] bdy1 = (bullet_y > meteor1_y) ? (bullet_y - meteor1_y) : (meteor1_y - bullet_y);

    wire [9:0] bdx2 = (bullet_x > meteor2_x) ? (bullet_x - meteor2_x) : (meteor2_x - bullet_x);
    wire [9:0] bdy2 = (bullet_y > meteor2_y) ? (bullet_y - meteor2_y) : (meteor2_y - bullet_y);

    wire [9:0] bdx3 = (bullet_x > meteor3_x) ? (bullet_x - meteor3_x) : (meteor3_x - bullet_x);
    wire [9:0] bdy3 = (bullet_y > meteor3_y) ? (bullet_y - meteor3_y) : (meteor3_y - bullet_y);

    wire [9:0] bdx4 = (bullet_x > meteor4_x) ? (bullet_x - meteor4_x) : (meteor4_x - bullet_x);
    wire [9:0] bdy4 = (bullet_y > meteor4_y) ? (bullet_y - meteor4_y) : (meteor4_y - bullet_y);

    wire [10:0] bdist0_sum = bdx0 + bdy0;
    wire [10:0] bdist1_sum = bdx1 + bdy1;
    wire [10:1] bdist2_sum = bdx2 + bdy2;
    wire [10:0] bdist3_sum = bdx3 + bdy3;
    wire [10:0] bdist4_sum = bdx4 + bdy4;

    wire bullet_hits_meteor0 = bullet_active &&
                               meteor0_alive &&
                               (bdist0_sum <= {1'b0, meteor0_radius_core});

    wire bullet_hits_meteor1 = bullet_active &&
                               meteor1_alive &&
                               (bdist1_sum <= {1'b0, meteor1_radius_core});

    wire bullet_hits_meteor2 = bullet_active &&
                               meteor2_alive &&
                               (bdist2_sum <= {1'b0, meteor2_radius_core});

    wire bullet_hits_meteor3 = bullet_active &&
                               meteor3_alive &&
                               (bdist3_sum <= {1'b0, meteor3_radius_core});

    wire bullet_hits_meteor4 = bullet_active &&
                               meteor4_alive &&
                               (bdist4_sum <= {1'b0, meteor4_radius_core});

    // Ship -> meteor distances
    wire [9:0] sdx0 = (ship_x > meteor0_x) ? (ship_x - meteor0_x) : (meteor0_x - ship_x);
    wire [9:0] sdy0 = (ship_y > meteor0_y) ? (ship_y - meteor0_y) : (meteor0_y - ship_y);

    wire [9:0] sdx1 = (ship_x > meteor1_x) ? (ship_x - meteor1_x) : (meteor1_x - ship_x);
    wire [9:0] sdy1 = (ship_y > meteor1_y) ? (ship_y - meteor1_y) : (meteor1_y - ship_y);

    wire [9:0] sdx2 = (ship_x > meteor2_x) ? (ship_x - meteor2_x) : (meteor2_x - ship_x);
    wire [9:0] sdy2 = (ship_y > meteor2_y) ? (ship_y - meteor2_y) : (meteor2_y - ship_y);

    wire [9:0] sdx3 = (ship_x > meteor3_x) ? (ship_x - meteor3_x) : (meteor3_x - ship_x);
    wire [9:0] sdy3 = (ship_y > meteor3_y) ? (ship_y - meteor3_y) : (meteor3_y - ship_y);

    wire [9:0] sdx4 = (ship_x > meteor4_x) ? (ship_x - meteor4_x) : (meteor4_x - ship_x);
    wire [9:0] sdy4 = (ship_y > meteor4_y) ? (ship_y - meteor4_y) : (meteor4_y - ship_y);

    wire [10:0] sdist0_sum = sdx0 + sdy0;
    wire [10:0] sdist1_sum = sdx1 + sdy1;
    wire [10:0] sdist2_sum = sdx2 + sdy2;
    wire [10:0] sdist3_sum = sdx3 + sdy3;
    wire [10:0] sdist4_sum = sdx4 + sdy4;

    wire [10:0] coll0_thresh = {1'b0, (SHIP_COLL_R + meteor0_radius_core)};
    wire [10:0] coll1_thresh = {1'b0, (SHIP_COLL_R + meteor1_radius_core)};
    wire [10:0] coll2_thresh = {1'b0, (SHIP_COLL_R + meteor2_radius_core)};
    wire [10:0] coll3_thresh = {1'b0, (SHIP_COLL_R + meteor3_radius_core)};
    wire [10:0] coll4_thresh = {1'b0, (SHIP_COLL_R + meteor4_radius_core)};

    wire ship_hits_meteor0 = meteor0_alive && (sdist0_sum <= coll0_thresh);
    wire ship_hits_meteor1 = meteor1_alive && (sdist1_sum <= coll1_thresh);
    wire ship_hits_meteor2 = meteor2_alive && (sdist2_sum <= coll2_thresh);
    wire ship_hits_meteor3 = meteor3_alive && (sdist3_sum <= coll3_thresh);
    wire ship_hits_meteor4 = meteor4_alive && (sdist4_sum <= coll4_thresh);

    wire ship_takes_hit = (ship_hits_meteor0 ||
                           ship_hits_meteor1 ||
                           ship_hits_meteor2 ||
                           ship_hits_meteor3 ||
                           ship_hits_meteor4) &&
                          (invinc_timer == 0) &&
                          (ship_hp > 0);

    task soft_reset;
    begin
        ship_x        <= SCREEN_W / 2;
        ship_y        <= SCREEN_H / 2;
        ship_facing   <= 2'b00; 

        bullet_x      <= 10'd0;
        bullet_y      <= 10'd0;
        bullet_active <= 1'b0;
        fire_cooldown <= 8'd0;

        meteor0_alive   <= 1'b1;
        meteor1_alive   <= 1'b1;
        meteor2_alive   <= 1'b1;
        meteor3_alive   <= 1'b1;
        meteor4_alive   <= 1'b1;

        meteor0_hp      <= 3'd3;
        meteor1_hp      <= 3'd3;
        meteor2_hp      <= 3'd3;
        meteor3_hp      <= 3'd3;
        meteor4_hp      <= 3'd3;

        prev_meteor0_y  <= meteor0_y;
        prev_meteor1_y  <= meteor1_y;
        prev_meteor2_y  <= meteor2_y;
        prev_meteor3_y  <= meteor3_y;
        prev_meteor4_y  <= meteor4_y;

        score         <= 16'd0;
        ship_hp       <= SHIP_MAX_HP[2:0];
        invinc_timer  <= 8'd0;
        game_over     <= 1'b0;
    end
    endtask

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            soft_reset();
        end 
        else if (frame_tick) begin

            if (fire_cooldown != 0)
                fire_cooldown <= fire_cooldown - 8'd1;

            if (game_over) begin
                if (btn_restart) begin
                    soft_reset();
                end

                prev_meteor0_y <= meteor0_y;
                prev_meteor1_y <= meteor1_y;
                prev_meteor2_y <= meteor2_y;
                prev_meteor3_y <= meteor3_y;
                prev_meteor4_y <= meteor4_y;

                if (invinc_timer != 0)
                    invinc_timer <= invinc_timer - 8'd1;
            end 
            else begin
                if (btn_up) begin
                    ship_facing <= 2'b00; 
                    if (ship_y > SHIP_SPEED)
                        ship_y <= ship_y - SHIP_SPEED;
                    else
                        ship_y <= 10'd0;
                end 
                else if (btn_down) begin
                    ship_facing <= 2'b10; 
                    if (ship_y < SCREEN_H - SHIP_SPEED - 1)
                        ship_y <= ship_y + SHIP_SPEED;
                    else
                        ship_y <= SCREEN_H - 1;
                end 
                else if (btn_right) begin
                    ship_facing <= 2'b01;
                    if (ship_x < SCREEN_W - SHIP_SPEED - 1)
                        ship_x <= ship_x + SHIP_SPEED;
                    else
                        ship_x <= SCREEN_W - 1;
                end 
                else if (btn_left) begin
                    ship_facing <= 2'b11; 
                    if (ship_x > SHIP_SPEED)
                        ship_x <= ship_x - SHIP_SPEED;
                    else
                        ship_x <= 10'd0;
                end

                if (!bullet_active) begin
                    if (btn_fire && (fire_cooldown == 0)) begin
                        bullet_active  <= 1'b1;
                        bullet_x       <= ship_x;
                        bullet_y       <= ship_y;
                        fire_cooldown  <= FIRE_COOLDOWN_FRAMES; 
                    end
                end
                else begin
                    if (bullet_y > BULLET_SPEED)
                        bullet_y <= bullet_y - BULLET_SPEED;
                    else begin
                        bullet_y      <= 10'd0;
                        bullet_active <= 1'b0;
                    end
                end

                if (meteor0_y < prev_meteor0_y) begin
                    meteor0_alive <= 1'b1;
                    case (meteor0_size)
                        3'd0: meteor0_hp <= 3'd1; 
                        3'd1: meteor0_hp <= 3'd2;
                        3'd2: meteor0_hp <= 3'd3; 
                        3'd3: meteor0_hp <= 3'd4; 
                        default: meteor0_hp <= 3'd5; 
                    endcase
                end

                if (meteor1_y < prev_meteor1_y) begin
                    meteor1_alive <= 1'b1;
                    case (meteor1_size)
                        3'd0: meteor1_hp <= 3'd1;
                        3'd1: meteor1_hp <= 3'd2; 
                        3'd2: meteor1_hp <= 3'd3;
                        3'd3: meteor1_hp <= 3'd4; 
                        default: meteor1_hp <= 3'd5; 
                    endcase
                end

                if (meteor2_y < prev_meteor2_y) begin
                    meteor2_alive <= 1'b1;
                    case (meteor2_size)
                        3'd0: meteor2_hp <= 3'd1;
                        3'd1: meteor2_hp <= 3'd2; 
                        3'd2: meteor2_hp <= 3'd3; 
                        3'd3: meteor2_hp <= 3'd4; 
                        default: meteor2_hp <= 3'd5; 
                    endcase
                end

                if (meteor3_y < prev_meteor3_y) begin
                    meteor3_alive <= 1'b1;
                    case (meteor3_size)
                        3'd0: meteor3_hp <= 3'd1; 
                        3'd1: meteor3_hp <= 3'd2; 
                        3'd2: meteor3_hp <= 3'd3; 
                        3'd3: meteor3_hp <= 3'd4; 
                        default: meteor3_hp <= 3'd5; 
                    endcase
                end

                if (meteor4_y < prev_meteor4_y) begin
                    meteor4_alive <= 1'b1;
                    case (meteor4_size)
                        3'd0: meteor4_hp <= 3'd1; 
                        3'd1: meteor4_hp <= 3'd2; 
                        3'd2: meteor4_hp <= 3'd3; 
                        3'd3: meteor4_hp <= 3'd4; 
                        default: meteor4_hp <= 3'd5; 
                    endcase
                end

                if (bullet_hits_meteor0) begin
                    bullet_active <= 1'b0;  
                    if (meteor0_hp > 0)
                        meteor0_hp <= meteor0_hp - 3'd1;

                    if (meteor0_hp == 3'd1) begin
                        meteor0_alive <= 1'b0;
                        score         <= score + meteor0_points;
                    end
                end

                if (bullet_hits_meteor1) begin
                    bullet_active <= 1'b0; 
                    if (meteor1_hp > 0)
                        meteor1_hp <= meteor1_hp - 3'd1;

                    if (meteor1_hp == 3'd1) begin
                        meteor1_alive <= 1'b0;
                        score         <= score + meteor1_points;
                    end
                end

                if (bullet_hits_meteor2) begin
                    bullet_active <= 1'b0; 
                    if (meteor2_hp > 0)
                        meteor2_hp <= meteor2_hp - 3'd1;

                    if (meteor2_hp == 3'd1) begin
                        meteor2_alive <= 1'b0;
                        score         <= score + meteor2_points;
                    end
                end

                if (bullet_hits_meteor3) begin
                    bullet_active <= 1'b0; 
                    if (meteor3_hp > 0)
                        meteor3_hp <= meteor3_hp - 3'd1;

                    if (meteor3_hp == 3'd1) begin
                        meteor3_alive <= 1'b0;
                        score         <= score + meteor3_points;
                    end
                end

                if (bullet_hits_meteor4) begin
                    bullet_active <= 1'b0; 
                    if (meteor4_hp > 0)
                        meteor4_hp <= meteor4_hp - 3'd1;

                    if (meteor4_hp == 3'd1) begin
                        meteor4_alive <= 1'b0;
                        score         <= score + meteor4_points;
                    end
                end

                if (invinc_timer != 0)
                    invinc_timer <= invinc_timer - 8'd1;

                if (ship_takes_hit) begin
                    if (ship_hp > 0)
                        ship_hp <= ship_hp - 3'd1;

                    invinc_timer <= INVINC_FRAMES[7:0];

						if (ship_hp == 3'd1)
								game_over <= 1'b1;
                end

                prev_meteor0_y <= meteor0_y;
                prev_meteor1_y <= meteor1_y;
                prev_meteor2_y <= meteor2_y;
                prev_meteor3_y <= meteor3_y;
                prev_meteor4_y <= meteor4_y;
            end
        end
    end

endmodule
