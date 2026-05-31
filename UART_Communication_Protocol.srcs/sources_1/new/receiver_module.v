`timescale 1ns/1ps

module UART_RX #(
    parameter clk_freq = 100_000_000, //100MHz as clock freq
    parameter baud_rate = 9600 //UART baud rate 
    )(
    input wire clk, //FPGA system clock
    input wire rx, //serial input line
    input wire reset, //reset signal
    output reg [7:0] result, //received data byte
    output reg completed //goes high when all 8-bits results are received
    );
    
reg[2:0] current_state, next_state;
reg[31:0] count;
reg[3:0] index;
reg[7:0] result_internal;
reg[1:0] rx_sampled;

localparam integer T = clk_freq/baud_rate;
localparam Look_start_bit   = 3'b000,
           count_half_cycle = 3'b001,
           sample_byte      = 3'b010,
           get_stop_bit     = 3'b011,
           done             = 3'b100;
     
     //sequential Logic
always @(posedge clk or posedge reset) begin
     if (reset) begin //reset everythings clear all temp regs
        current_state   <= Look_start_bit;
        count           <= 0;
        index           <= 0;
        result_internal <= 0; 
        rx_sampled      <= 2'b11; //resets to '11' to avoid false falling-edge detection
        completed       <= 0;
     end
     else begin
        current_state   <= next_state;        
        rx_sampled <= {rx_sampled[0], rx};
        
    case (current_state)
        Look_start_bit: begin
            completed <= 0;
            count     <= 0;
            index     <= 0;
        end
        count_half_cycle: begin
            count   <= count + 1;
            if (count == T/2)
                count <= 0;
        end
        sample_byte: begin
            count <= count + 1;
            if (count == T/2) begin
                result_internal[index] <= rx; //stores result_internal while taking position in account
            end
            if (count == T) begin 
                 count <= 0; //counter is reset after counting
                 index <= index + 1; //index is the position of the bit which is being sampled
            end
       end
       get_stop_bit: begin
            count <= count + 1;
            if (count == T)
                count <= 0;
       end
       done: begin
            completed <=1;
            result <= result_internal;
       end
   endcase 
 end  
 end
 
 
 //Combinational Block
always @(*) begin
    next_state = current_state;
    
    case (current_state)
       Look_start_bit: begin
        if (rx_sampled == 2'b10)
            next_state = count_half_cycle;
        end
       count_half_cycle: begin
        if (count == T/2)
            next_state = sample_byte;
       end
       sample_byte: begin
        if (index == 4'b1000 && count == T)
            next_state = get_stop_bit;
       end
        get_stop_bit: begin
        if (count == T)
            next_state = done;
        end
        done: begin
        next_state = Look_start_bit;
        end
    endcase
 end
 endmodule     