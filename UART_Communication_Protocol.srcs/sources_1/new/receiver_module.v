`timescale 1ns/1ps
module UART_RX #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rx,
    input  wire        reset,
    output reg  [7:0]  result,
    output reg         completed
);

localparam integer T = CLK_FREQ / BAUD_RATE;  // 10416 cycles per bit

// States
localparam S_IDLE     = 3'd0,
           S_START    = 3'd1,
           S_DATA     = 3'd2,
           S_STOP     = 3'd3,
           S_DONE     = 3'd4;

// Two-stage synchroniser for rx (metastability protection)
reg [1:0] rx_sync = 2'b11;
always @(posedge clk)
    rx_sync <= {rx_sync[0], rx};

wire rx_s = rx_sync[1];  // stable, synchronised rx

reg [2:0]  state    = S_IDLE;
reg [31:0] count    = 0;
reg [3:0]  bit_idx  = 0;
reg [7:0]  shift    = 0;

always @(posedge clk) begin
    completed <= 0;  // default: pulse for one cycle only

    if (reset) begin
        state     <= S_IDLE;
        count     <= 0;
        bit_idx   <= 0;
        shift     <= 0;
        completed <= 0;
    end else begin
        case (state)

            S_IDLE: begin
                count   <= 0;
                bit_idx <= 0;
                if (rx_s == 1'b0)        // falling edge = start bit detected
                    state <= S_START;
            end

            // Wait half a bit period to centre sampling on data bits
            S_START: begin
                if (count == T/2 - 1) begin
                    count <= 0;
                    // Verify start bit is still low (noise rejection)
                    if (rx_s == 1'b0)
                        state <= S_DATA;
                    else
                        state <= S_IDLE;   // glitch - abort
                end else begin
                    count <= count + 1;
                end
            end

            // Sample 8 data bits, one per bit period
            S_DATA: begin
                if (count == T - 1) begin
                    count          <= 0;
                    shift[bit_idx] <= rx_s;
                    if (bit_idx == 3'd7)
                        state <= S_STOP;
                    else
                        bit_idx <= bit_idx + 1;
                end else begin
                    count <= count + 1;
                end
            end

            // Wait one full bit period for stop bit
            S_STOP: begin
                if (count == T - 1) begin
                    count <= 0;
                    state <= S_DONE;
                end else begin
                    count <= count + 1;
                end
            end

            S_DONE: begin
                result    <= shift;
                completed <= 1;    // pulses exactly one cycle
                state     <= S_IDLE;
            end

        endcase
    end
end

endmodule