`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2026 06:37:44
// Design Name: 
// Module Name: rx_top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rx_top_module(
    input  wire        clk,
    input  wire        reset,
    input  wire        rx,
    output wire [6:0]  seg,
    output wire [7:0]  an
    );
    
wire       completed;
wire [7:0] rx_byte;

UART_RX uart_rx_inst(
        .clk(clk),
        .rx(rx),
        .reset(reset),
        .result(rx_byte),
        .completed(completed)
);

SSD_Controller ssd_inst(
    .clk(clk),
    .data_in(rx_byte),
    .seg(seg),
    .an(an)
    );
    
endmodule
