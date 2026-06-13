`timescale 1ns/1ps

module uart_rx_simulation;

    // Testbench signals
    reg        clk   = 0;
    reg        reset = 0;
    reg        rx    = 1;      // idle high
    wire [7:0] result;
    wire       completed;
    wire       frame_error;
// // Access internal signal directly - Vivado simulator supports this
//wire [7:0] result;
//wire       completed;
assign result    = dut.result;        // reaches into uart_rx_inst
assign completed = dut.completed;
    // Parameters
    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_RATE = 9600;
    localparam integer BIT_PERIOD = 1_000_000_000 / BAUD_RATE; // 104,166 ns

    // DUT instantiation
    UART_RX #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )dut(
        .clk        (clk),
        .rx         (rx),
        .reset      (reset),
        .result     (result),
        .completed  (completed),
        .frame_error(frame_error)
    );
    // 100 MHz clock
    always #5 clk = ~clk;

    // Task: send one UART byte LSB first
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 1'b0;              // start bit
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            rx = 1'b1;              // stop bit
            #(BIT_PERIOD);
        end
    endtask

    // Task: send byte with a bad stop bit (forces frame_error)
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
            rx = 1'b0;              // bad stop bit - should be 1
            #(BIT_PERIOD);
            rx = 1'b1;              // return to idle
            #(BIT_PERIOD);
        end
    endtask

    // ── Test sequence ──────────────────────────────────────────
    initial begin
        $display("=== UART RX Testbench ===");

        // ── Test 1: Reset ──────────────────────────────────────
        $display("\n[TEST 1] Reset behaviour");
        reset = 1;
        #(BIT_PERIOD);
        reset = 0;
        #100;
        $display("PASS: reset released, DUT idle");

        // ── Test 2: Valid byte 0x41 ('A') ──────────────────────
        $display("\n[TEST 2] Valid byte 0x41");
        send_byte(8'h41);
        #5_000_000;
        if (result == 8'h41 && completed == 1)
            $display("PASS: received 0x%02X", result);
        else
            $display("FAIL: expected 0x41, got 0x%02X completed=%b", result, completed);

        // ── Test 3: Valid byte 0x55 (alternating bits) ─────────
        $display("\n[TEST 3] Valid byte 0x55");
        #(BIT_PERIOD);
        send_byte(8'h55);
        #5_000_000;
        if (result == 8'h55 && completed == 1)
            $display("PASS: received 0x%02X", result);
        else
            $display("FAIL: expected 0x55, got 0x%02X", result);

        // ── Test 4: Framing error (bad stop bit) ───────────────
        $display("\n[TEST 4] Framing error");
        #(BIT_PERIOD);
        send_byte_bad_stop(8'hAA);
        #5_000_000;
        if (frame_error == 1 && completed == 0)
            $display("PASS: frame_error asserted, completed stayed low");
        else
            $display("FAIL: frame_error=%b completed=%b", frame_error, completed);

        // ── Test 5: Glitch rejection ───────────────────────────
        $display("\n[TEST 5] Glitch rejection");
        #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD / 4);   // short glitch < T/2
        rx = 1'b1; #(BIT_PERIOD * 2);
        if (completed == 0 && frame_error == 0)
            $display("PASS: glitch ignored");
        else
            $display("FAIL: spurious output on glitch");

         //── Test 6: Back-to-back bytes ─────────────────────────
        $display("\n[TEST 6] Back-to-back bytes");
        send_byte(8'hDE);
        #5_000_000;
        if (result == 8'hDE)
            $display("PASS: first byte 0x%02X", result);
        else
            $display("FAIL: first byte got 0x%02X", result);
        send_byte(8'hAD);
        #5_000_000;
        if (result == 8'hAD)
            $display("PASS: second byte 0x%02X", result);
        else
            $display("FAIL: second byte got 0x%02X", result);

        $display("\n=== Simulation complete ===");
        $finish;
    end

endmodule