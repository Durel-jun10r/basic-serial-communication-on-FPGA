module rx_top_module(
    input  wire        clk,
    input  wire        reset,    // cpu_resetn: 0 = button pressed, 1 = not pressed
    input  wire        rx,
    output wire [6:0]  seg,
    output wire [7:0]  an,
    output wire [7:0]  LEDS,
    output wire LED
);
    // cpu_resetn is 1 when idle, 0 when button pressed
    // We want active-high reset: assert reset when button IS pressed
    wire reset_active_high = ~reset;  // 1 when button pressed → reset active

    wire        completed;
    wire [7:0]  result;

    reg [7:0] display_byte = 8'h00;
    always @(posedge clk) begin
        if (reset_active_high)
            display_byte <= 8'h00;
        else if (completed)
            display_byte <= result;
    end

    // Debug: blink LED[7] for ~0.5s each time a byte is received
    reg [25:0] blink_count = 0;
    reg        blink_active = 0;

    always @(posedge clk) begin
        if (completed) begin
            blink_active <= 1;
            blink_count  <= 0;
        end else if (blink_active) begin
            if (blink_count == 26'd50_000_000)
                 blink_active <= 0;
            else
                 blink_count <= blink_count + 1;
        end
    end

assign LED = blink_active;

    UART_RX uart_rx_inst(
        .clk(clk),
        .rx(rx),
        .reset(reset_active_high),
        .result(result),
        .completed(completed)
    );

    SSD_Controller ssd_inst(
        .clk(clk),
        .data_in(display_byte),
        .seg(seg),
        .an(an)
    );

    LEDS_Controller led_control_inst(
        .clk(clk),
        .data_in(display_byte),
        .LEDS(LEDS)
    );
endmodule