`timescale 1ns/1ps
module UART_RX #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rx,
    input  wire        reset,
    output reg  [7:0]  result    = 8'h00,
    output reg         completed = 1'b0
);
    localparam integer T     = CLK_FREQ / BAUD_RATE;  // 10416
    localparam integer T_HALF = T / 2;                // 5208

    localparam S_IDLE  = 3'd0,
               S_START = 3'd1,
               S_DATA  = 3'd2,
               S_STOP  = 3'd3,
               S_DONE  = 3'd4;

    // Two-stage synchroniser
    reg [1:0] rx_sync = 2'b11;
    always @(posedge clk)
        rx_sync <= {rx_sync[0], rx};
    wire rx_s = rx_sync[1];

    reg [2:0]  state   = S_IDLE;
    reg [13:0] count   = 0;       // 14 bits is enough for T=10416
    reg [2:0]  bit_idx = 0;       // 3 bits sufficient for 0-7
    reg [7:0]  shift   = 0;

    always @(posedge clk) begin
        completed <= 1'b0;  // default pulse-low

        if (reset) begin
            state     <= S_IDLE;
            count     <= 0;
            bit_idx   <= 0;
            shift     <= 0;
            result    <= 8'h00;
            completed <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    count   <= 0;
                    bit_idx <= 0;
                    shift   <= 0;
                    if (rx_s == 1'b0)        // start bit detected
                        state <= S_START;
                end

                // Wait T/2 to centre-sample the start bit
                S_START: begin
                    if (count == T_HALF - 1) begin
                        count <= 0;
                        if (rx_s == 1'b0)
                            state <= S_DATA;
                        else
                            state <= S_IDLE;  // glitch, abort
                    end else begin
                        count <= count + 1;
                    end
                end

                // Sample 8 data bits at full bit periods
                S_DATA: begin
                    if (count == T - 1) begin
                        count             <= 0;
                        shift[bit_idx]    <= rx_s;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                // Wait for stop bit (verify high for noise rejection)
                S_STOP: begin
                    if (count == T - 1) begin
                        count <= 0;
                        if (rx_s == 1'b1)    // valid stop bit
                            state <= S_DONE;
                        else
                            state <= S_IDLE;  // framing error, discard
                    end else begin
                        count <= count + 1;
                    end
                end

                S_DONE: begin
                    result    <= shift;
                    completed <= 1'b1;
                    state     <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule