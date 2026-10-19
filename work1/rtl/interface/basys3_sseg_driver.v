`timescale 1ns / 1ns 
//============================================================
// Драйвер четырехразрядного семисегментного индикатора Basys3.
// Сегменты и аноды активны низким уровнем.
//============================================================
module basys3_sseg_driver #(
    parameter integer CLK_FREQ     = 100_000_000,
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
    output reg [7:0] sseg
);

    //--------------------------------------------------------
    // Делитель частоты сканирования
    //--------------------------------------------------------
    localparam integer REFRESH_COUNT =
        (SCAN_FREQ_HZ >= CLK_FREQ)
            ? 1
        : CLK_FREQ / SCAN_FREQ_HZ;   

    localparam integer REFRESH_COUNTER_WIDTH =
        (REFRESH_COUNT <= 1)
            ? 1
            : $clog2(REFRESH_COUNT);

    reg [REFRESH_COUNTER_WIDTH-1:0] refresh_counter;
    reg [1:0] active_digit_bin;

    //--------------------------------------------------------
    // Выбранная цифра
    //--------------------------------------------------------
    reg [3:0] selected_digit;
    wire [7:0] selected_segments;

    //--------------------------------------------------------
    // Счетчик частоты сканирования
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            refresh_counter <= {REFRESH_COUNTER_WIDTH{1'b0}};
            active_digit_bin <= 2'b00;
        end
        else if (refresh_counter == REFRESH_COUNT - 1) begin
            refresh_counter <= {REFRESH_COUNTER_WIDTH{1'b0}};
            active_digit_bin <= active_digit_bin + 1'b1;
        end
        else begin
            refresh_counter <= refresh_counter + 1'b1;
        end
    end

    //--------------------------------------------------------
    // Мультиплексор цифр
    //--------------------------------------------------------
    always @(*) begin
        case (active_digit_bin)
            2'd0:    selected_digit = digit_0;
            2'd1:    selected_digit = digit_1;
            2'd2:    selected_digit = digit_2;
            2'd3:    selected_digit = digit_3;
            default: selected_digit = 4'd0;
        endcase
    end

    //--------------------------------------------------------
    // Преобразователь цифры в код сегментов
    //--------------------------------------------------------
    digit2sseg_verilog u_digit2sseg (
        .digit    (selected_digit),
        .segments (selected_segments)
    );

    //--------------------------------------------------------
    // Управление анодами и сегментами
    //--------------------------------------------------------
    always @(*) begin
        sseg = selected_segments;

        case (active_digit_bin)
            2'd0:    sseg_en_n = ~(4'b0001 & digit_en);
            2'd1:    sseg_en_n = ~(4'b0010 & digit_en);
            2'd2:    sseg_en_n = ~(4'b0100 & digit_en);
            2'd3:    sseg_en_n = ~(4'b1000 & digit_en);
            default: sseg_en_n = 4'b1111;
        endcase
    end

endmodule
