module meteorthing #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480
)
(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        frame_tick,

    output reg [9:0]   meteor_x,
    output reg [9:0]   meteor_y,
    output reg [2:0]   meteor_size
);

    //---------------------------------------
    // Pseudo-random generator
    // (increments each spawn; low bits look random enough)
    //---------------------------------------
    reg [7:0] rand_reg;

    //---------------------------------------
    // Slow-down divider: move every N frames
    //---------------------------------------
    localparam DROP_DIV = 1;   // meteor moves every 4 frames
    reg [2:0] drop_count;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meteor_x    <= SCREEN_W/2;
            meteor_y    <= 10'd0;
            meteor_size <= 3'd2;
            rand_reg    <= 8'h5A;      // non-zero seed
            drop_count  <= 3'd0;
        end 
        else if (frame_tick) begin

            //---------------------------------------
            // Only move meteor every DROP_DIV frames
            //---------------------------------------
            if (drop_count == DROP_DIV-1) begin
                drop_count <= 3'd0;
            end else begin
                drop_count <= drop_count + 3'd1;
            end

            // move meteor ONLY when divider hits
            if (drop_count == DROP_DIV-1) begin
                meteor_y <= meteor_y + 10'd2;   // **slower falling**
            end

            //---------------------------------------
            // Respawn when off screen
            //---------------------------------------
            if (meteor_y >= SCREEN_H) begin
                // update random seed
                rand_reg <= rand_reg + 8'h37;   // "random-looking" step

                // lane is based on lower 3 bits (0–4 usable)
                case (rand_reg[2:0])
                    3'd0: meteor_x <= 80;
                    3'd1: meteor_x <= 200;
                    3'd2: meteor_x <= 320;
                    3'd3: meteor_x <= 440;
                    3'd4: meteor_x <= 560;
                    default: meteor_x <= 320;    // fallback
                endcase

                meteor_y    <= 10'd0;

                // meteor size becomes random too
                meteor_size <= rand_reg[4:2];  // values 0–7; valid sizes 0–4
            end
        end
    end
endmodule
