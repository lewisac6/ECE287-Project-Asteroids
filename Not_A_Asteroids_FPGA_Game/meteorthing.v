module meteorthing #(
    parameter integer SCREEN_W   = 640,
    parameter integer SCREEN_H   = 480,
    parameter integer BASE_SPEED = 1,      
    parameter [9:0]   SEED       = 10'h3A5  
)(
    input              clk,       
    input              reset_n,
    input              frame_tick, 
    input              hard_mode,  
    output reg [9:0]   meteor_x,
    output reg [9:0]   meteor_y,
    output reg [2:0]   meteor_size
);

    localparam integer HARD_MULT = 2;

    reg [9:0] speed_y;
    always @* begin
        if (hard_mode)
            speed_y = BASE_SPEED * HARD_MULT;  
        else
            speed_y = BASE_SPEED;
    end

    reg [9:0] lfsr;
    wire feedback = lfsr[9] ^ lfsr[6];

    task spawn_new_meteor;
    begin
        meteor_x    <= lfsr % SCREEN_W;
        meteor_y    <= 10'd0;
        meteor_size <= {1'b0, lfsr[2:1]};
    end
    endtask

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lfsr        <= SEED;
				meteor_x    <= SEED % SCREEN_W;  
            meteor_y    <=(SEED[3:2] * (SCREEN_H/4));
            meteor_size <= {1'b0, SEED[2:1]}; 
        end else begin
            if (frame_tick) begin
                lfsr <= {lfsr[8:0], feedback};
                if (meteor_y >= SCREEN_H + 10'd20) begin
                    spawn_new_meteor();
                end else begin
                    meteor_y <= meteor_y + speed_y;
                end
            end
        end
    end

endmodule
