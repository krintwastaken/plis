`timescale 1ns / 1ps

module basys3_sseg_driver #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer SCAN_FREQ_HZ = 1000
)(
    input wire clk,
    input wire rst,
    input wire [3:0] digit_en,
    input wire [3:0] digit_0,
    input wire [3:0] digit_1,
    input wire [3:0] digit_2,
    input wire [3:0] digit_3,
    output reg [3:0] sseg_en_n,
    output wire [7:0] sseg
);

    localparam integer DIVIDER = CLK_FREQ / (SCAN_FREQ_HZ * 4);
    localparam integer CNT_WIDTH = $clog2(DIVIDER + 1);

    reg [CNT_WIDTH-1:0] scan_cnt;
    reg [1:0] sel;
    reg [3:0] mux_digit;
    wire [6:0] seg_raw;

    always @(posedge clk) begin
        if (rst) begin
            scan_cnt <= {CNT_WIDTH{1'b0}};
            sel <= 2'b00;
        end else if (scan_cnt >= DIVIDER - 1) begin
            scan_cnt <= {CNT_WIDTH{1'b0}};
            sel <= sel + 1'b1;
        end else begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

    always @(*) begin
        sseg_en_n = 4'b1111;
        mux_digit = 4'h0;
        case (sel)
            2'b00: begin
                mux_digit = digit_0;
                sseg_en_n = digit_en[0] ? 4'b1110 : 4'b1111;
            end
            2'b01: begin
                mux_digit = digit_1;
                sseg_en_n = digit_en[1] ? 4'b1101 : 4'b1111;
            end
            2'b10: begin
                mux_digit = digit_2;
                sseg_en_n = digit_en[2] ? 4'b1011 : 4'b1111;
            end
            2'b11: begin
                mux_digit = digit_3;
                sseg_en_n = digit_en[3] ? 4'b0111 : 4'b1111;
            end
        endcase
    end

    digit2sseg u_dec (
        .digit(mux_digit),
        .seg(seg_raw)
    );

    assign sseg = {1'b1, seg_raw};

endmodule
