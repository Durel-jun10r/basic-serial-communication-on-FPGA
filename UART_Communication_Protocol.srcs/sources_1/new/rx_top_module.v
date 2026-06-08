module rx_top_module #( 
   parameter CLK_FREQ  = 100_000_000,
   parameter BAUD_RATE = 9600 
)
 (
    input  wire        clk,
    input  wire        reset,    // cpu_resetn: 0 = button pressed, 1 = not pressed
    input  wire        rx,
    output wire [6:0]  seg,
    output wire [7:0]  an,
    output wire [7:0]  LEDS
//    output wire LED
);
    // cpu_resetn is 1 when idle, 0 when button pressed
    // We want active-high reset: assert reset when button IS pressed
    wire reset_active_high = ~reset;  // 1 when button pressed → reset active

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


    UART_RX #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE))
       uart_rx_inst (
        .clk(clk),
        .rx(rx),
        .reset(reset_active_high),
        .result(result),
        .completed(completed),
        .frame_error(frame_error)
    );

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
 // LEDS[7] = frame error indicator, LEDS[6:0] = data bits    
assign LEDS = {frame_error, leds_out[6:0]};
endmodule