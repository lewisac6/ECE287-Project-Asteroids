module vga_sync_640x480 (
    input        clk,
    input        reset_n,
    output reg   hsync,
    output reg   vsync,
    output reg [9:0] pixel_x,
    output reg [9:0] pixel_y,
    output       video_on,
    output reg   frame_tick   // 1-cycle pulse each new frame
);

    // Horizontal timing
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    // Vertical timing
    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Counters
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            h_count    <= 10'd0;
            v_count    <= 10'd0;
            frame_tick <= 1'b0;
        end else begin
            frame_tick <= 1'b0;

            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count    <= 10'd0;
                    frame_tick <= 1'b1; // new frame at top-left
                end else begin
                    v_count <= v_count + 10'd1;
                end
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // Visible region
    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // Pixel coordinates within visible region
    always @* begin
        if (video_on) begin
            pixel_x = h_count;
            pixel_y = v_count;
        end else begin
            pixel_x = 10'd0;
            pixel_y = 10'd0;
        end
    end

    // Sync signals (active low)
    always @* begin
        hsync = ~((h_count >= H_VISIBLE + H_FRONT) &&
                  (h_count <  H_VISIBLE + H_FRONT + H_SYNC));

        vsync = ~((v_count >= V_VISIBLE + V_FRONT) &&
                  (v_count <  V_VISIBLE + V_FRONT + V_SYNC));
    end

endmodule
