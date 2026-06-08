`timescale 1ns/1ps

module uart_rx_simulation;

    reg        clk         = 0;
    reg        reset       = 0;
    reg        rx          = 1;
    wire [7:0] result;
    wire       completed;
    wire       frame_error;

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_RATE = 9600;
    localparam integer BIT_PERIOD = 1_000_000_000 / BAUD_RATE;

    UART_RX #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk        (clk),
        .rx         (rx),
        .reset      (reset),
        .result     (result),
        .completed  (completed),
        .frame_error(frame_error)
    );

    always #5 clk = ~clk;

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 1'b0;
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            rx = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    task send_byte_bad_stop;
        input [7:0] data;
        integer i;
        begin
            rx = 1'b0;
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            rx = 1'b0;          // bad stop bit
            #(BIT_PERIOD);
            rx = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    initial begin
        $display("=== UART RX Testbench ===");

        // Test 1: Reset
        $display("\n[TEST 1] Reset behaviour");
        reset = 1; #200; reset = 0; #200;
        $display("PASS: reset released, DUT idle");

        // Test 2: Valid byte 0x41
        $display("\n[TEST 2] Valid byte 0x41");
        send_byte(8'h41);
        @(posedge completed);
        @(posedge clk);
        if (result == 8'h41)
            $display("PASS: received 0x%02X", result);
        else
            $display("FAIL: expected 0x41, got 0x%02X", result);

        // Test 3: Valid byte 0x55
        $display("\n[TEST 3] Valid byte 0x55");
        #(BIT_PERIOD);
        send_byte(8'h55);
        @(posedge completed);
        @(posedge clk);
        if (result == 8'h55)
            $display("PASS: received 0x%02X", result);
        else
            $display("FAIL: expected 0x55, got 0x%02X", result);

        // Test 4: Framing error
        $display("\n[TEST 4] Framing error - bad stop bit");
        #(BIT_PERIOD);
        send_byte_bad_stop(8'hAA);
        @(posedge clk);
        if (frame_error == 1 && completed == 0)
            $display("PASS: frame_error asserted, completed low");
        else
            $display("FAIL: frame_error=%b completed=%b", frame_error, completed);

        // Test 5: Glitch rejection
        $display("\n[TEST 5] Glitch rejection");
        #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD / 4);
        rx = 1'b1; #(BIT_PERIOD * 3);
        if (completed == 0 && frame_error == 0)
            $display("PASS: glitch ignored");
        else
            $display("FAIL: spurious output on glitch");

        // Test 6: Back-to-back bytes
        $display("\n[TEST 6] Back-to-back 0xDE then 0xAD");
        send_byte(8'hDE);
        @(posedge completed);
        @(posedge clk);
        if (result == 8'hDE)
            $display("PASS: first byte 0x%02X", result);
        else
            $display("FAIL: first byte got 0x%02X", result);

        send_byte(8'hAD);
        @(posedge completed);
        @(posedge clk);
        if (result == 8'hAD)
            $display("PASS: second byte 0x%02X", result);
        else
            $display("FAIL: second byte got 0x%02X", result);

        // Test 7: Reset mid-reception
        $display("\n[TEST 7] Reset mid-byte");
        #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD);
        rx = 1'b1; #(BIT_PERIOD * 3);
        reset = 1; #200; reset = 0;
        #(BIT_PERIOD * 10);
        rx = 1'b1;
        if (completed == 0)
            $display("PASS: completed stayed low after reset");
        else
            $display("FAIL: completed fired after reset");

        $display("\n=== Simulation complete ===");
        $finish;
    end

endmodule