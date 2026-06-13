module rx_top_module #( 
   parameter CLK_FREQ  = 100_000_000,
   parameter BAUD_RATE = 9600 
)
 (
    input  wire        clk,
    input  wire        reset,    
    input  wire        rx,
    output wire        tx,        // <-- ADDED: UART TX output
    output wire [6:0]  seg,
    output wire [7:0]  an,
    output wire [7:0]  LEDS
);

    wire reset_active_high = ~reset;

    wire        completed;
    wire [7:0]  result;
    wire        frame_error;

    reg [7:0] display_byte = 8'h00;
    always @(posedge clk) begin
        if (reset_active_high)
            display_byte <= 8'h00;
        else if (completed)
            display_byte <= result;
    end

    // -----------------------------
    // UART RX
    // -----------------------------
    UART_RX #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE))
    uart_rx_inst (
        .clk(clk),
        .rx(rx),
        .reset(reset_active_high),
        .result(result),
        .completed(completed),
        .frame_error(frame_error)
    );

    // -----------------------------
    // UART TX (ECHO)
    // -----------------------------
    UART_TX #(.baud_rate(BAUD_RATE), .clk_freq(CLK_FREQ))
    uart_tx_inst (
        .clk(clk),
        .reset(reset_active_high),
        .start(completed),   // <-- transmit when RX completes
        .data_in(result),    // <-- echo the received byte
        .tx(tx),             // <-- output to top-level
        .busy()              // unused
    );

    // -----------------------------
    // Display + LEDs
    // -----------------------------
    SSD_Controller ssd_inst(
        .clk(clk),
        .data_in(display_byte),
        .seg(seg),
        .an(an)
    );

    wire [7:0] leds_out;
    LEDS_Controller led_control_inst(
        .clk(clk),
        .data_in(display_byte),
        .LEDS(leds_out)
    );

    assign LEDS = {frame_error, leds_out[6:0]};

endmodule
