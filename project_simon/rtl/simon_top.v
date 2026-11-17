`timescale 1ns / 1ps

module simon_top #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer TICK_FREQ = 1
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire finish,
    input wire [1:0] mode,
    input wire rom_mode,
    input wire [3:0] btn_in,
    output wire [3:0] led_pattern,
    output wire [1:0] current_sym,
    output wire [3:0] seq_len,
    output wire [7:0] score,
    output wire [7:0] high_score,
    output wire [7:0] remaining,
    output wire game_active,
    output wire show_score,
    output wire foul_flag,
    output wire time_over
);

    // Внутренние управляющие сигналы от автомата simon_fsm
    wire settings_load;
    wire score_clear;
    wire score_add;
    wire idx_reset;
    wire idx_inc;
    wire len_reset;
    wire len_inc;
    wire timer_load;
    wire timer_enable;
    wire lfsr_enable;
    wire ram_we;
    wire led_enable;
    wire stats_we;
    wire foul_error;

    // Формирование слова конфигурации для сохранения в round_param_reg
    reg [3:0] mode_points;
    always @(*) begin
        case (mode)
            2'b00: mode_points = 4'd1;
            2'b01: mode_points = 4'd2;
            2'b10: mode_points = 4'd3;
            2'b11: mode_points = 4'd4;
            default: mode_points = 4'd1;
        endcase
    end

    wire [7:0] param_in = {mode, rom_mode, 1'b1, mode_points};
    wire [7:0] param_q;

    wire [1:0] latched_mode = param_q[7:6];
    wire latched_rom_mode = param_q[5];
    wire latched_foul_en = param_q[4];
    wire [3:0] latched_points = param_q[3:0];

    // Длительность интервала таймера в зависимости от сохраненного уровня сложности
    reg [7:0] timer_init_val;
    always @(*) begin
        case (latched_mode)
            2'b00: timer_init_val = 8'd6;
            2'b01: timer_init_val = 8'd4;
            2'b10: timer_init_val = 8'd3;
            2'b11: timer_init_val = 8'd2;
            default: timer_init_val = 8'd6;
        endcase
    end

    // 1. Регистр параметров текущего раунда
    round_param_reg #(
        .WIDTH(8)
    ) u_param_reg (
        .clk(clk),
        .rst(rst),
        .load(settings_load),
        .d(param_in),
        .q(param_q)
    );

    // 2. Генератор секундных импульсов
    wire tick_1s;
    tick_generator #(
        .CLK_FREQ(CLK_FREQ),
        .TICK_FREQ(TICK_FREQ)
    ) u_tick (
        .clk(clk),
        .rst(rst),
        .tick(tick_1s)
    );

    // 3. Таймер показа и ожидания ввода игрока
    countdown_timer #(
        .WIDTH(8)
    ) u_timer (
        .clk(clk),
        .rst(rst),
        .load(timer_load),
        .enable(timer_enable),
        .tick(tick_1s),
        .load_value(timer_init_val),
        .remaining(remaining),
        .zero(time_over)
    );

    // 4. Генератор псевдослучайных символов LFSR
    wire [1:0] random_sym;
    lfsr_generator #(
        .WIDTH(2)
    ) u_lfsr (
        .clk(clk),
        .rst(rst),
        .enable(lfsr_enable),
        .random_number(random_sym)
    );

    // 5. Счетчик текущей длины последовательности (от 1 до 15)
    wire len_over_unused;
    index_counter #(
        .WIDTH(4)
    ) u_len_cnt (
        .clk(clk),
        .reset(rst),
        .load(len_reset),
        .en_count(len_inc),
        .data_load(4'd1),
        .max_len(4'd15),
        .count(seq_len),
        .over(len_over_unused)
    );

    // 6. Счетчик текущего шага последовательности (от 0 до seq_len - 1)
    wire [3:0] step_idx;
    wire idx_over;
    index_counter #(
        .WIDTH(4)
    ) u_step_cnt (
        .clk(clk),
        .reset(rst || idx_reset),
        .load(1'b0),
        .en_count(idx_inc),
        .data_load(4'd0),
        .max_len(seq_len),
        .count(step_idx),
        .over(idx_over)
    );

    // 7. Постоянная память фиксированных последовательностей (ROM)
    wire [1:0] rom_sym;
    sequence_rom #(
        .DATA_WIDTH(2),
        .DEPTH(16),
        .INIT_FILE("patterns.mem")
    ) u_rom (
        .addr(step_idx),
        .data(rom_sym)
    );

    // 8. Оперативная память формируемой последовательности (RAM)
    wire [3:0] ram_addr = ram_we ? (seq_len - 1'b1) : step_idx;
    wire [1:0] ram_sym;
    sequence_ram #(
        .DATA_WIDTH(2),
        .DEPTH(16)
    ) u_seq_ram (
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr),
        .din(random_sym),
        .dout(ram_sym)
    );

    assign current_sym = latched_rom_mode ? rom_sym : ram_sym;

    // 9. Кодер пользовательского ввода и компаратор символов
    wire [1:0] user_sym;
    wire valid;
    wire match;
    wire mismatch;
    input_coder_comparator #(
        .NUM_INPUTS(4),
        .SYM_WIDTH(2)
    ) u_coder_comp (
        .btn_in(btn_in),
        .pattern_sym(current_sym),
        .user_sym(user_sym),
        .valid(valid),
        .match(match),
        .mismatch(mismatch)
    );

    // 10. Счетчик набранных очков
    score_counter #(
        .SCORE_WIDTH(8),
        .POINTS_WIDTH(4)
    ) u_score (
        .clk(clk),
        .rst(rst),
        .clear(score_clear),
        .add_score(score_add),
        .points(latched_points),
        .score(score)
    );

    // 11. Оперативная память таблицы рекордов и статистики
    stats_ram #(
        .DATA_WIDTH(8),
        .DEPTH(8),
        .INIT_FILE("stats_init.mem")
    ) u_stats_ram (
        .clk(clk),
        .we(stats_we),
        .addr({1'b0, latched_mode}),
        .din(score),
        .dout(high_score)
    );

    // 12. Управляющий конечный автомат
    simon_fsm u_fsm (
        .clk(clk),
        .rst(rst),
        .start(start),
        .finish(finish),
        .foul_en(latched_foul_en),
        .valid(valid),
        .match(match),
        .mismatch(mismatch),
        .timer_zero(time_over),
        .idx_over(idx_over),
        .score_val(score),
        .high_score_val(high_score),
        .settings_load(settings_load),
        .score_clear(score_clear),
        .score_add(score_add),
        .idx_reset(idx_reset),
        .idx_inc(idx_inc),
        .len_reset(len_reset),
        .len_inc(len_inc),
        .timer_load(timer_load),
        .timer_enable(timer_enable),
        .lfsr_enable(lfsr_enable),
        .ram_we(ram_we),
        .led_enable(led_enable),
        .stats_we(stats_we),
        .show_score(show_score),
        .game_active(game_active),
        .foul_error(foul_error)
    );

    // Триггер сохранения флага фальстарта для индикации до начала новой игры
    reg foul_reg;
    always @(posedge clk) begin
        if (rst || settings_load) begin
            foul_reg <= 1'b0;
        end else if (foul_error) begin
            foul_reg <= 1'b1;
        end
    end
    assign foul_flag = foul_reg;

    // Дешифрация активного светодиода во время фазы демонстрации
    assign led_pattern[0] = led_enable && (current_sym == 2'b00);
    assign led_pattern[1] = led_enable && (current_sym == 2'b01);
    assign led_pattern[2] = led_enable && (current_sym == 2'b10);
    assign led_pattern[3] = led_enable && (current_sym == 2'b11);

endmodule
