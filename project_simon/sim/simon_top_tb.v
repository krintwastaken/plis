`timescale 1ns / 1ps

module simon_top_tb;

    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst = 1'b1;
    reg start = 1'b0;
    reg finish = 1'b0;
    reg [1:0] mode = 2'b00;
    reg rom_mode = 1'b0;
    reg [3:0] btn_in = 4'b0000;

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

    integer errors = 0;
    integer cycles;
    integer step_i;

    // Ускоренная временная база для моделирования: 4 такта на один шаг таймера
    simon_top #(
        .CLK_FREQ(4),
        .TICK_FREQ(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .finish(finish),
        .mode(mode),
        .rom_mode(rom_mode),
        .btn_in(btn_in),
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

    task check;
        input condition;
        input [8*48-1:0] description;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("ERROR t=%0t: %0s", $time, description);
            end
        end
    endtask

    task pulse_start;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    // Ожидание перехода автомата в фазу ожидания ввода игрока (S_WAIT_INPUT = 4'd7)
    task wait_input_phase;
        begin
            cycles = 0;
            while (dut.u_fsm.state !== 4'd7 && cycles < 2000) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            check(cycles < 2000, "Wait input phase timeout");
        end
    endtask

    // Подача нажатия одной из 4 кнопок по 2-битному коду символа
    task press_button;
        input [1:0] sym;
        begin
            @(negedge clk);
            btn_in = (4'b0001 << sym);
            repeat (2) @(negedge clk);
            btn_in = 4'b0000;
            repeat (2) @(negedge clk);
        end
    endtask

    // Ожидание завершения игры (show_score == 1)
    task wait_game_over;
        begin
            cycles = 0;
            while (show_score !== 1'b1 && cycles < 2000) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            check(cycles < 2000, "Game over timeout");
        end
    endtask

    initial begin
        $display("=== SIMON_TOP SYSTEM TEST START ===");
        repeat (4) @(negedge clk);
        rst = 1'b0;
        @(negedge clk);
        check(!game_active && !show_score && score == 8'd0, "Initial state after reset");

        // Сценарий 1: Запуск в режиме 1 (2 очка за раунд), прохождение 2 раундов и ошибка ввода
        mode = 2'b01;
        rom_mode = 1'b0;
        pulse_start();

        // Раунд 1 (длина последовательности = 1)
        wait_input_phase();
        check(seq_len == 4'd1 && game_active, "Round 1 active, seq_len = 1");
        press_button(dut.u_seq_ram.ram[0]);

        // Раунд 2 (длина последовательности автоматически выросла до 2)
        wait_input_phase();
        check(seq_len == 4'd2 && score == 8'd2, "Round 1 passed, score = 2, seq_len = 2");
        for (step_i = 0; step_i < 2; step_i = step_i + 1) begin
            wait_input_phase();
            press_button(dut.u_seq_ram.ram[step_i]);
        end

        // Раунд 3 (длина = 3): проверка сохранения настроек при переключении тумблера mode на ходу
        mode = 2'b11;
        wait_input_phase();
        check(seq_len == 4'd3 && score == 8'd4, "Round 2 passed, score = 4, seq_len = 3");
        check(dut.latched_points == 4'd2, "Mode settings latched during active game");

        // Подача заведомо неверного символа на первом шаге раунда 3
        press_button(~dut.u_seq_ram.ram[0]);
        wait_game_over();
        check(show_score && !game_active && score == 8'd4, "Game ended on wrong input");
        $display("Scenario 1 completed: final score = %0d", score);

        // Сценарий 2: Повторный запуск и проверка защиты от фальстарта (ввод во время показа)
        mode = 2'b10;
        pulse_start();
        cycles = 0;
        while (dut.u_fsm.state !== 4'd4 && cycles < 500) begin
            @(negedge clk);
            cycles = cycles + 1;
        end
        check(dut.u_fsm.state == 4'd4, "Entered S_SHOW_LED state");
        // Игрок нажимает кнопку во время демонстрации светодиода
        btn_in = 4'b0010;
        repeat (2) @(negedge clk);
        btn_in = 4'b0000;
        wait_game_over();
        check(foul_flag == 1'b1 && show_score == 1'b1, "False start detected during SHOW");
        $display("Scenario 2 completed: foul_flag = %b", foul_flag);

        // Сценарий 3: Завершение игры по истечению времени таймера (time_over)
        pulse_start();
        wait_input_phase();
        wait_game_over();
        check(time_over == 1'b1 && show_score == 1'b1, "Game ended by input timeout");
        $display("Scenario 3 completed: timeout verified");

        // Сценарий 4: Возврат в S_IDLE по импульсу finish и проверка сброса во время игры
        @(negedge clk);
        finish = 1'b1;
        @(negedge clk);
        finish = 1'b0;
        #1;
        check(!game_active && !show_score, "Returned to S_IDLE on finish");

        pulse_start();
        wait_input_phase();
        @(negedge clk);
        rst = 1'b1;
        @(negedge clk);
        rst = 1'b0;
        #1;
        check(!game_active && !show_score && score == 8'd0, "Reset during active game");

        if (errors == 0) begin
            $display("TEST PASSED: simon_top");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule
