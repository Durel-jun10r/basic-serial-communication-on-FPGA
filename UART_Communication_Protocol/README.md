# basic-serial-communication-on-FPGA
This repository contains the implementation of UART_receiver_Module on the Xilinx Artix 7 FPGA

It has 3 inputs (clk, reset, and rx) and output (segment_LEDs and their enable signals)

The purpose of this module is taking data in series from the rx_line, convert them to parallel bits and display the result
on a 7-segment display.
