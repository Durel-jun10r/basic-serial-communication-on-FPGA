`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 08:08:49
// Design Name: 
// Module Name: uart_rx_simulation
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


module uart_rx_simulation;
  
  //testbench signals
  reg clk = 0;
  reg reset = 0;
  reg rx = 1; // Idle high (everything begins if this falls to zero)
  wire [7:0] result;
  wire completed;
  wire [7:0] an;
  wire [6:0] seg;
  
  //Parameters
  localparam CLK_FREQ = 100_000_000;
  localparam BAUD_RATE = 9600;
  localparam BIT_PERIOD = 10*CLK_FREQ/BAUD_RATE; //in nanoseconds
  
 rx_top_module dut (
    .clk   (clk),
    .reset (reset),
    .rx    (rx),
    .seg   (seg),
    .an    (an)
    );
    //Generate 100MHz clock
    always #5 clk = ~clk; //10 ns period
    
    // Task to send one UART byte (LSB first)
    task send_byte (input [7:0] data);
        integer i;
        begin
        // Start bit
        rx = 0;
        #(BIT_PERIOD);
        
        // 8 data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #(BIT_PERIOD);
        end
        
        //Stop bit
        rx = 1;
        #(BIT_PERIOD);
        end
   endtask
   //debugging current_states







   
   //Test Sequence
   initial begin
   
   $display("Starting UART RX Simulation....");
   
   //Reset pulse
   reset = 1;
   #100;
   reset = 0;
    
   
   //Send byte
   send_byte(8'hAA);
   wait (completed == 1);
   send_byte(8'hB5);
   wait (completed == 1);
   #2_000_000
   $display("Received byte: %h at t=%0dns", result, $time);
   
   $stop;
   end
endmodule
