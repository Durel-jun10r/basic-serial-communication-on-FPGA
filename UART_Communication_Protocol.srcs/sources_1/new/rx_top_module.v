module rx_top_module(
    input  wire        clk,
    input  wire        reset,
    input  wire        rx,
    output wire [6:0]  seg,
    output wire [7:0]  an,
    output wire [7:0]  LEDS
);

    // cpu_resetn is active-low; invert to get active-high for UART_RX
    wire reset_active_high = ~reset;

    wire        completed;
    wire [7:0]  result;

    // Latch last received byte - completed only pulses for one clock
    reg [7:0] display_byte = 8'h00;
    always @(posedge clk) begin
        if (reset_active_high)
            display_byte <= 8'h00;
        else if (completed)
            display_byte <= result;
    end

    UART_RX uart_rx_inst(
        .clk(clk),
        .rx(rx),
        .reset(reset_active_high),
        .result(result),
        .completed(completed)
    );

    SSD_Controller ssd_inst(
        .clk(clk),
        .data_in(display_byte),   // ← latched, not raw result
        .seg(seg),
        .an(an)
    );

    LEDS_Controller led_control_inst(
        .clk(clk),
        .data_in(display_byte),   // ← latched, not raw result
        .LEDS(LEDS)
    );

endmodule