`timescale 1ns / 1ps

module simon_fsm_tb;

    localparam [3:0]
        S_IDLE         = 4'd0,
        S_PREPARE      = 4'd1,
        S_APPEND       = 4'd2,
        S_SHOW_ADDR    = 4'd3,
        S_SHOW_LED     = 4'd4,
        S_SHOW_GAP     = 4'd5,
        S_PRE_INPUT    = 4'd6,
        S_WAIT_INPUT   = 4'd7,
        S_CHECK_INPUT  = 4'd8,
        S_WAIT_RELEASE = 4'd9,
        S_INPUT_INC    = 4'd10,
        S_SUCCESS      = 4'd11,
        S_FOUL         = 4'd12,
        S_UPDATE_STATS = 4'd13,
        S_RESULT       = 4'd14;

    reg clk;
    reg rst;
    reg start;
    reg finish;
    reg foul_en;
    reg valid;
    reg match;
    reg mismatch;
    reg timer_zero;
    reg idx_over;
    reg [7:0] score_val;
    reg [7:0] high_score_val;

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
    wire show_score;
    wire game_active;
    wire foul_error;

    integer errors;
    integer checks;

    simon_fsm dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .finish(finish),
        .foul_en(foul_en),
        .valid(valid),
        .match(match),
        .mismatch(mismatch),
        .timer_zero(timer_zero),
        .idx_over(idx_over),
        .score_val(score_val),
        .high_score_val(high_score_val),
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

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Преобразование кода состояния в текстовую строку
    function [8*16-1:0] state_name;
        input [3:0] s;
        begin
            case (s)
                S_IDLE:         state_name = "S_IDLE";
                S_PREPARE:      state_name = "S_PREPARE";
                S_APPEND:       state_name = "S_APPEND";
                S_SHOW_ADDR:    state_name = "S_SHOW_ADDR";
                S_SHOW_LED:     state_name = "S_SHOW_LED";
                S_SHOW_GAP:     state_name = "S_SHOW_GAP";
                S_PRE_INPUT:    state_name = "S_PRE_INPUT";
                S_WAIT_INPUT:   state_name = "S_WAIT_INPUT";
                S_CHECK_INPUT:  state_name = "S_CHECK_INPUT";
                S_WAIT_RELEASE: state_name = "S_WAIT_RELEASE";
                S_INPUT_INC:    state_name = "S_INPUT_INC";
                S_SUCCESS:      state_name = "S_SUCCESS";
                S_FOUL:         state_name = "S_FOUL";
                S_UPDATE_STATS: state_name = "S_UPDATE_STATS";
                S_RESULT:       state_name = "S_RESULT";
                default:        state_name = "UNKNOWN";
            endcase
        end
    endfunction

    // Эталонный вектор выходов автомата Мура
    function [15:0] out_for_state;
        input [3:0] s;
        begin
            case (s)
                S_IDLE:         out_for_state = 16'b0000000000000000;
                S_PREPARE:      out_for_state = 16'b1101010000000010;
                S_APPEND:       out_for_state = 16'b0001000001100010;
                S_SHOW_ADDR:    out_for_state = 16'b0000000100000010;
                S_SHOW_LED:     out_for_state = 16'b0000000010010010;
                S_SHOW_GAP:     out_for_state = 16'b0000100000000010;
                S_PRE_INPUT:    out_for_state = 16'b0001000100000010;
                S_WAIT_INPUT:   out_for_state = 16'b0000000010000010;
                S_CHECK_INPUT:  out_for_state = 16'b0000000000000010;
                S_WAIT_RELEASE: out_for_state = 16'b0000000010000010;
                S_INPUT_INC:    out_for_state = 16'b0000100100000010;
                S_SUCCESS:      out_for_state = 16'b0010001000000010;
                S_FOUL:         out_for_state = 16'b0000000000000101;
                S_UPDATE_STATS: out_for_state = 16'b0000000000001100;
                S_RESULT:       out_for_state = 16'b0000000000000100;
                default:        out_for_state = 16'b0000000000000000;
            endcase
        end
    endfunction

    task check;
        input [3:0] expected_state;
        input [15:0] expected_outputs;
        reg [15:0] actual_outputs;
        begin
            #1;
            checks = checks + 1;
            actual_outputs = {
                settings_load,
                score_clear,
                score_add,
                idx_reset,
                idx_inc,
                len_reset,
                len_inc,
                timer_load,
                timer_enable,
                lfsr_enable,
                ram_we,
                led_enable,
                stats_we,
                show_score,
                game_active,
                foul_error
            };

            if (dut.state !== expected_state || actual_outputs !== expected_outputs) begin
                errors = errors + 1;
                $display("ERROR t=%0t: state=%0s expected=%0s, outputs=%b expected=%b",
                         $time, state_name(dut.state), state_name(expected_state), actual_outputs, expected_outputs);
            end else begin
                $display("OK    t=%0t: state=%0s outputs=%b",
                         $time, state_name(dut.state), actual_outputs);
            end
        end
    endtask

    task next_expect;
        input [3:0] s;
        begin
            @(posedge clk);
            check(s, out_for_state(s));
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;
        rst = 1'b0;
        start = 1'b0;
        finish = 1'b0;
        foul_en = 1'b1;
        valid = 1'b0;
        match = 1'b0;
        mismatch = 1'b0;
        timer_zero = 1'b0;
        idx_over = 1'b0;
        score_val = 8'd0;
        high_score_val = 8'd5;

        // 1. Сброс и начальное состояние S_IDLE
        @(negedge clk);
        rst = 1'b1;
        next_expect(S_IDLE);
        @(negedge clk);
        rst = 1'b0;
        next_expect(S_IDLE);

        // 2. Демонстрация последовательности из 2 символов и полностью правильный ввод
        @(negedge clk);
        start = 1'b1;
        next_expect(S_PREPARE);
        @(negedge clk);
        start = 1'b0;
        next_expect(S_APPEND);
        next_expect(S_SHOW_ADDR);
        next_expect(S_SHOW_LED);

        // Показ первого символа (idx_over = 0 -> переход через S_SHOW_GAP)
        @(negedge clk);
        timer_zero = 1'b1;
        idx_over = 1'b0;
        next_expect(S_SHOW_GAP);
        @(negedge clk);
        timer_zero = 1'b0;
        next_expect(S_SHOW_ADDR);
        next_expect(S_SHOW_LED);

        // Показ второго (последнего) символа (idx_over = 1 -> переход к вводу)
        @(negedge clk);
        timer_zero = 1'b1;
        idx_over = 1'b1;
        next_expect(S_PRE_INPUT);
        @(negedge clk);
        timer_zero = 1'b0;
        idx_over = 1'b0;
        next_expect(S_WAIT_INPUT);

        // Ввод первого символа (верно, есть еще символы: idx_over = 0)
        @(negedge clk);
        valid = 1'b1;
        match = 1'b1;
        next_expect(S_CHECK_INPUT);
        next_expect(S_WAIT_RELEASE);
        @(negedge clk);
        valid = 1'b0;
        match = 1'b0;
        next_expect(S_INPUT_INC);
        next_expect(S_WAIT_INPUT);

        // Ввод второго (последнего) символа (верно, вся последовательность: idx_over = 1)
        @(negedge clk);
        valid = 1'b1;
        match = 1'b1;
        idx_over = 1'b1;
        next_expect(S_CHECK_INPUT);
        next_expect(S_WAIT_RELEASE);
        @(negedge clk);
        valid = 1'b0;
        match = 1'b0;
        next_expect(S_SUCCESS);

        // 3. Увеличение длины последовательности (S_SUCCESS -> S_APPEND -> S_SHOW_ADDR)
        next_expect(S_APPEND);
        next_expect(S_SHOW_ADDR);
        next_expect(S_SHOW_LED);

        // 4. Попытка ввода во время демонстрации (фальстарт, Уровень 3)
        @(negedge clk);
        valid = 1'b1;
        score_val = 8'd2;
        high_score_val = 8'd5;
        next_expect(S_FOUL);
        @(negedge clk);
        valid = 1'b0;
        next_expect(S_RESULT);

        // 5. Перезапуск из S_RESULT и ошибка игрока на первом/среднем символе
        @(negedge clk);
        start = 1'b1;
        next_expect(S_PREPARE);
        @(negedge clk);
        start = 1'b0;
        next_expect(S_APPEND);
        next_expect(S_SHOW_ADDR);
        next_expect(S_SHOW_LED);
        @(negedge clk);
        timer_zero = 1'b1;
        idx_over = 1'b1;
        next_expect(S_PRE_INPUT);
        @(negedge clk);
        timer_zero = 1'b0;
        idx_over = 1'b0;
        next_expect(S_WAIT_INPUT);

        // Ошибка ввода (mismatch = 1) с превышением рекорда (score_val > high_score_val)
        @(negedge clk);
        valid = 1'b1;
        mismatch = 1'b1;
        score_val = 8'd10;
        high_score_val = 8'd5;
        next_expect(S_CHECK_INPUT);
        next_expect(S_UPDATE_STATS);
        @(negedge clk);
        valid = 1'b0;
        mismatch = 1'b0;
        next_expect(S_RESULT);

        // 6. Возврат в S_IDLE по сигналу finish и проверка таймаута в S_WAIT_INPUT
        @(negedge clk);
        finish = 1'b1;
        next_expect(S_IDLE);
        @(negedge clk);
        finish = 1'b0;
        start = 1'b1;
        score_val = 8'd1;
        next_expect(S_PREPARE);
        @(negedge clk);
        start = 1'b0;
        next_expect(S_APPEND);
        next_expect(S_SHOW_ADDR);
        next_expect(S_SHOW_LED);
        @(negedge clk);
        timer_zero = 1'b1;
        idx_over = 1'b1;
        next_expect(S_PRE_INPUT);
        @(negedge clk);
        timer_zero = 1'b0;
        next_expect(S_WAIT_INPUT);

        // Приоритет истечения времени над вводом (timer_zero = 1 и valid = 1 одновременно)
        @(negedge clk);
        timer_zero = 1'b1;
        valid = 1'b1;
        next_expect(S_RESULT);
        @(negedge clk);
        timer_zero = 1'b0;
        valid = 1'b0;

        // 7. Проверка свойства Мура (изменение входов внутри такта не меняет выходы)
        #2;
        valid = 1'b1;
        match = 1'b1;
        timer_zero = 1'b1;
        check(S_RESULT, out_for_state(S_RESULT));
        valid = 1'b0;
        match = 1'b0;
        timer_zero = 1'b0;

        // 8. Выход из неопределенного состояния (4'd15 -> S_IDLE)
        @(negedge clk);
        dut.state = 4'd15;
        next_expect(S_IDLE);

        // 9. Сброс из рабочего состояния
        @(negedge clk);
        start = 1'b1;
        next_expect(S_PREPARE);
        @(negedge clk);
        start = 1'b0;
        rst = 1'b1;
        next_expect(S_IDLE);
        @(negedge clk);
        rst = 1'b0;

        #20;
        $display("----------------------------------------");
        if (errors == 0) begin
            $display("TEST PASSED: %0d checks", checks);
        end else begin
            $display("TEST FAILED: %0d errors / %0d checks", errors, checks);
        end
        $finish;
    end

    initial begin
        #50000;
        $display("TEST FAILED: timeout");
        $finish;
    end

endmodule
