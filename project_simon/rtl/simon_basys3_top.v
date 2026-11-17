`timescale 1ns / 1ps

module simon_basys3_top #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer TICK_FREQ = 1,
    parameter integer DEBOUNCE_MS = 20
)(
    input wire clk,
    input wire btnC,
    input wire btnU,
    input wire btnD,
    input wire [15:0] sw,
    output wire [15:0] led,
    output wire [7:0] seg,
    output wire [3:0] an
);

    wire clk_sys;
    wire reset_sync;
    wire start_pulse;
    wire finish_pulse;

    wire [3:0] led_pattern;
    wire [1:0] current_sym;
    wire [3:0] seq_len;
    wire [7:0] score;
    wire [7:0] high_score;
    wire [7:0] remaining;
    wire game_active;
    wire show_score;
    wire foul_flag;
    wire time_over;

    // Синхронизация переключателей ввода игрока sw[3:0]
    reg [3:0] sw_sync_0;
    reg [3:0] sw_sync_1;
    always @(posedge clk_sys) begin
        sw_sync_0 <= sw[3:0];
        sw_sync_1 <= sw_sync_0;
    end

    // 1. Менеджер тактирования и синхронизации сброса (btnC)
    clock_manager u_clock (
        .clk100(clk),
        .reset(btnC),
        .clk_sys(clk_sys),
        .reset_sync(reset_sync)
    );

    // 2. Подавитель дребезга кнопки запуска игры (btnU -> start_pulse)
    button_debouncer #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_deb_start (
        .clk(clk_sys),
        .rst(reset_sync),
        .btn_in(btnU),
        .btn_state(),
        .btn_pulse(start_pulse)
    );

    // 3. Подавитель дребезга кнопки выхода в ожидание (btnD -> finish_pulse)
    button_debouncer #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_deb_finish (
        .clk(clk_sys),
        .rst(reset_sync),
        .btn_in(btnD),
        .btn_state(),
        .btn_pulse(finish_pulse)
    );

    // 4. Функциональное ядро игрового автомата Simon Says
    simon_top #(
        .CLK_FREQ(CLK_FREQ),
        .TICK_FREQ(TICK_FREQ)
    ) u_game (
        .clk(clk_sys),
        .rst(reset_sync),
        .start(start_pulse),
        .finish(finish_pulse),
        .mode(sw[15:14]),
        .rom_mode(sw[13]),
        .btn_in(sw_sync_1),
        .led_pattern(led_pattern),
        .current_sym(current_sym),
        .seq_len(seq_len),
        .score(score),
        .high_score(high_score),
        .remaining(remaining),
        .game_active(game_active),
        .show_score(show_score),
        .foul_flag(foul_flag),
        .time_over(time_over)
    );

    // 5. Контроллер динамической индикации ССИ:
    // AN0: текущая длина цепочки, AN1: рекорд режима, AN3..AN2: текущий счет
    basys3_sseg_driver #(
        .CLK_FREQ(CLK_FREQ),
        .SCAN_FREQ_HZ(1000)
    ) u_sseg (
        .clk(clk_sys),
        .rst(reset_sync),
        .digit_en(4'b1111),
        .digit_0(seq_len),
        .digit_1(high_score[3:0]),
        .digit_2(score[3:0]),
        .digit_3(score[7:4]),
        .sseg_en_n(an),
        .sseg(seg)
    );

    // Назначение светодиодов платы Basys3
    assign led[3:0] = led_pattern;
    assign led[4] = game_active;
    assign led[5] = show_score;
    assign led[6] = foul_flag;
    assign led[7] = time_over;
    assign led[15:8] = remaining;

endmodule
