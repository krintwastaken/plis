`timescale 1ns / 1ns
//============================================================
// Модуль: display_controller
//
// Назначение:
//   Управление четырехразрядным семисегментным индикатором.
//
// Поддерживается:
//   - вывод четырех BCD цифр;
//   - отключение выбранного разряда при мигании.
//
// Порты:
//   blink           - сигнал генератора мигания;
//   blink_enable    - разрешение мигания;
//   selected_digit  - номер мигающего разряда.
//
//============================================================

module display_controller #(
    parameter integer CLK_FREQ     = 100_000_000,
    parameter integer SCAN_FREQ_HZ = 1000
)(

 input wire clk,
 input wire rst,

 input wire [3:0] digit0,
 input wire [3:0] digit1,
 input wire [3:0] digit2,
 input wire [3:0] digit3,

 input wire blink,
 input wire blink_enable,
 input wire [1:0] selected_digit,

 output wire [7:0] seg,
 output wire [3:0] an

);

reg [3:0] en_mask;

always @(*) begin

    en_mask = 4'b1111;

    if(blink_enable && !blink) begin

        case(selected_digit)

            2'd0: en_mask = 4'b1110;
            2'd1: en_mask = 4'b1101;
            2'd2: en_mask = 4'b1011;
            2'd3: en_mask = 4'b0111;

        endcase

    end

end


basys3_sseg_driver #(
    .CLK_FREQ     (CLK_FREQ),
    .SCAN_FREQ_HZ (SCAN_FREQ_HZ)
)
u_display (

    .clk(clk),
    .rst(rst),

    .digit_en(en_mask),

    .digit_0(digit0),
    .digit_1(digit1),
    .digit_2(digit2),
    .digit_3(digit3),

    .sseg(seg),
    .sseg_en_n(an)

);

endmodule
