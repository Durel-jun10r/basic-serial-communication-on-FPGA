`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2026 16:29:44
// Design Name: 
// Module Name: LEDS_Controller
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


module LEDS_Controller(
    input wire clk,
    input wire [7:0] data_in,
    output reg [7:0] LEDS
    );
    
   always @(posedge clk) begin
        LEDS <= data_in;
   end
   
endmodule
