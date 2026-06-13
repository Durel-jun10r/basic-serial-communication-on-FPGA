`timescale 1ns / 1ps

module UART_TX #(
    parameter baud_rate = 9600,
    parameter clk_freq  = 100_000_000
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       start,       // pulse to start transmission
    input  wire [7:0] data_in,     // byte to send
    output reg        tx,          // UART TX line
    output reg        busy         // high while transmitting
);

localparam IDLE    = 3'd0,
           START   = 3'd1,
           DATA    = 3'd2,
           STOP    = 3'd3,
           CLEANUP = 3'd4;

reg [2:0] state;
reg [7:0] shift_reg;
reg [3:0] bit_index;
reg [31:0] count;

localparam integer T = clk_freq / baud_rate;

// Baud counter
always @(posedge clk) begin
    if (reset)
        count <= 0;
    else if (count == T)
        count <= 0;
    else
        count <= count + 1;
end

// Main FSM
always @(posedge clk) begin
    if (reset) begin
        state     <= IDLE;
        tx        <= 1'b1;   // idle high
        busy      <= 1'b0;
        bit_index <= 0;
    end 
    else begin
        case (state)

            // ---------------------------------------------------------
            // IDLE - waiting for start pulse
            // ---------------------------------------------------------
            IDLE: begin
                tx   <= 1'b1;
                busy <= 1'b0;

                if (start) begin
                    shift_reg <= data_in;
                    bit_index <= 0;
                    busy      <= 1'b1;
                    state     <= START;
                end
            end

            // ---------------------------------------------------------
            // START BIT - send 0 for 1 baud period
            // ---------------------------------------------------------
            START: begin
                if (count == T) begin
                    tx    <= 1'b0;
                    state <= DATA;
                end
            end

            // ---------------------------------------------------------
            // DATA BITS - send LSB first
            // ---------------------------------------------------------
            DATA: begin
                if (count == T) begin
                    tx <= shift_reg[bit_index];

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end
            end

            // ---------------------------------------------------------
            // STOP BIT - send 1 for 1 baud period
            // ---------------------------------------------------------
            STOP: begin
                if (count == T) begin
                    tx    <= 1'b1;
                    state <= CLEANUP;
                end
            end

            // ---------------------------------------------------------
            // CLEANUP - return to idle
            // ---------------------------------------------------------
            CLEANUP: begin
                busy  <= 1'b0;
                state <= IDLE;
            end

        endcase
    end
end

endmodule
