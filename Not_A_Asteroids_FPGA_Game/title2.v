module title2 #(
    parameter WIDTH  = 80,  
    parameter HEIGHT = 10, 
    parameter SCALE  = 4  
)(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,

    input  wire [9:0] origin_x,
    input  wire [9:0] origin_y,

    output reg banner_r,
    output reg banner_g,
    output reg banner_b
);

    reg [8*WIDTH-1:0] ascii [0:HEIGHT-1];
    integer i;

    initial begin
        ascii[0] = "$$\   $$\            $$\            $$$$$$\              $$\                                   $$\       $$\           ";
        ascii[1] = "$$$\  $$ |           $$ |          $$  __$$\             $$ |                                  \__|      $$ |          ";
        ascii[2] = "$$$$\ $$ | $$$$$$\ $$$$$$\         $$ /  $$ | $$$$$$$\ $$$$$$\    $$$$$$\   $$$$$$\   $$$$$$\  $$\  $$$$$$$ | $$$$$$$\ ";
        ascii[3] = "$$ $$\$$ |$$  __$$\\_$$  _|        $$$$$$$$ |$$  _____|\_$$  _|  $$  __$$\ $$  __$$\ $$  __$$\ $$ |$$  __$$ |$$  _____|";
        ascii[4] = "$$ \$$$$ |$$ /  $$ | $$ |          $$  __$$ |\$$$$$$\    $$ |    $$$$$$$$ |$$ |  \__|$$ /  $$ |$$ |$$ /  $$ |\$$$$$$\  ";
        ascii[5] = "$$ |\$$$ |$$ |  $$ | $$ |$$\       $$ |  $$ | \____$$\   $$ |$$\ $$   ____|$$ |      $$ |  $$ |$$ |$$ |  $$ | \____$$\ ";
        ascii[6] = "$$ | \$$ |\$$$$$$  | \$$$$  |      $$ |  $$ |$$$$$$$  |  \$$$$  |\$$$$$$$\ $$ |      \$$$$$$  |$$ |\$$$$$$$ |$$$$$$$  |";
        ascii[7] = "\__|  \__| \______/   \____/       \__|  \__|\_______/    \____/  \_______|\__|       \______/ \__| \_______|\_______/ ";
       // ascii[8] = "  $$   $$  $$$$$   $$$$$    $$    $$ $$    $$ $$    $$   ";
        //ascii[9] = "   $$$$$   $$      $$       $$$$$$   $$$$$$   $$$$$$     ";

        for (i = 10; i < HEIGHT; i = i + 1)
            ascii[i] = {8*WIDTH{1'b0}};
    end
	 
    localparam integer CELL_W = SCALE;
    localparam integer CELL_H = SCALE;

    wire ln2 =
        (pixel_x >= origin_x) &&
        (pixel_x <  origin_x + WIDTH  * CELL_W) &&
        (pixel_y >= origin_y) &&
        (pixel_y <  origin_y + HEIGHT * CELL_H);

    wire [9:0] local_x = pixel_x - origin_x;
    wire [9:0] local_y = pixel_y - origin_y;

    wire [9:0] sx = local_x / SCALE; 
    wire [9:0] sy = local_y / SCALE; 

    reg [7:0] ch;

    always @* begin
        banner_r = 1'b0;
        banner_g = 1'b0;
        banner_b = 1'b0;

        if (ln2) begin
            ch = ascii[sy][(WIDTH-1-sx)*8 +: 8];

            if (ch != " " && ch != 8'd0) begin
                banner_r = 1'b1;
                banner_g = 1'b1;
                banner_b = 1'b1;
            end
        end
    end

endmodule
