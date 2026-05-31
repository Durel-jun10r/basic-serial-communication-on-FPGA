module SSD_Controller(
    input  wire        clk,
    input  wire [7:0]  data_in,
    output reg  [7:0]  an,
    output reg  [6:0]  seg
);

    wire [3:0] upper_nibble = data_in[7:4];
    wire [3:0] lower_nibble = data_in[3:0];

    localparam REFRESH_MAX = 100_000;
    reg [16:0] refresh_count = 0;
    wire refresh_tick = (refresh_count == REFRESH_MAX - 1);

    always @(posedge clk) begin
        if (refresh_tick) refresh_count <= 0;
        else              refresh_count <= refresh_count + 1;
    end

    reg digit_select = 0;
    always @(posedge clk)
        if (refresh_tick)
            digit_select <= ~digit_select;

    function [6:0] hex_to_seg;
        input [3:0] hex;
        case (hex)
            4'h0: hex_to_seg = 7'b0111111;
            4'h1: hex_to_seg = 7'b0000110;
            4'h2: hex_to_seg = 7'b1011011;
            4'h3: hex_to_seg = 7'b1001111;
            4'h4: hex_to_seg = 7'b1100110; // fixed
            4'h5: hex_to_seg = 7'b1101101;
            4'h6: hex_to_seg = 7'b1111101;
            4'h7: hex_to_seg = 7'b0000111;
            4'h8: hex_to_seg = 7'b1111111;
            4'h9: hex_to_seg = 7'b1101111;
            4'hA: hex_to_seg = 7'b1110111;
            4'hB: hex_to_seg = 7'b1111100;
            4'hC: hex_to_seg = 7'b0111001;
            4'hD: hex_to_seg = 7'b1011110;
            4'hE: hex_to_seg = 7'b1111001;
            4'hF: hex_to_seg = 7'b1110001;
        endcase
    endfunction

    always @(posedge clk) begin
        if (digit_select == 0) begin
            an  <= 8'b1111_1110;
            seg <= ~hex_to_seg(lower_nibble); // active-low
        end else begin
            an  <= 8'b1111_1101;
            seg <= ~hex_to_seg(upper_nibble); // active-low
        end
    end

endmodule