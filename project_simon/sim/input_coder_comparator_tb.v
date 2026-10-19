`timescale 1ns / 1ps

module input_coder_comparator_tb;

    // Параметры модуля
    parameter NUM_INPUTS = 4;
    parameter SYM_WIDTH  = 2;

    // Входные сигналы DUT
    reg  [NUM_INPUTS-1:0] btn_in;
    reg  [SYM_WIDTH-1:0]  pattern_sym;

    // Выходные сигналы DUT
    wire [SYM_WIDTH-1:0]  user_sym;
    wire                  valid;
    wire                  match;
    wire                  mismatch;

    // Сигналы эталонной модели (Reference Model)
    reg  [SYM_WIDTH-1:0]  exp_user_sym;
    reg                   exp_valid;
    reg                   exp_match;
    reg                   exp_mismatch;

    // Переменные цикла и подсчета ошибок
    integer i, p, k;
    integer error_count;

    // Экземпляр тестируемого модуля (DUT)
    input_coder_comparator #(
        .NUM_INPUTS(NUM_INPUTS),
        .SYM_WIDTH(SYM_WIDTH)
    ) dut (
        .btn_in(btn_in),
        .pattern_sym(pattern_sym),
        .user_sym(user_sym),
        .valid(valid),
        .match(match),
        .mismatch(mismatch)
    );

    // Эталонная модель для автоматической проверки
    always @(*) begin
        exp_valid    = 1'b0;
        exp_user_sym = {SYM_WIDTH{1'b0}};
        for (k = 0; k < NUM_INPUTS; k = k + 1) begin
            if (btn_in[k]) begin
                exp_user_sym = k[SYM_WIDTH-1:0];
                exp_valid    = 1'b1;
            end
        end
        exp_match    = exp_valid & (exp_user_sym == pattern_sym);
        exp_mismatch = exp_valid & (exp_user_sym != pattern_sym);
    end

    // Процедура тестирования
    initial begin

        error_count = 0;
        btn_in      = 0;
        pattern_sym = 0;
        #20;

        // Полный перебор: все значения эталона (0..3) и все комбинации кнопок (0..15)
        for (p = 0; p < (1 << SYM_WIDTH); p = p + 1) begin
            pattern_sym = p[SYM_WIDTH-1:0];
            $display("--- Testing with pattern_sym = %0d ---", pattern_sym);

            for (i = 0; i < (1 << NUM_INPUTS); i = i + 1) begin
                btn_in = i[NUM_INPUTS-1:0];
                #10; // Задержка для распространения комбинационного сигнала

                // Автоматическое сравнение выходов DUT с эталонными значениями
                if ((user_sym !== exp_user_sym) || 
                    (valid    !== exp_valid)    || 
                    (match    !== exp_match)    || 
                    (mismatch !== exp_mismatch)) begin
                    
                    $display("[ERROR] Time=%0t | btn_in=%b pattern=%0d | DUT: valid=%b sym=%0d match=%b mismatch=%b | EXP: valid=%b sym=%0d match=%b mismatch=%b",
                             $time, btn_in, pattern_sym, valid, user_sym, match, mismatch, exp_valid, exp_user_sym, exp_match, exp_mismatch);
                    error_count = error_count + 1;
                end else begin
                    $display("Time=%0t | btn_in=%b pattern=%0d | valid=%b sym=%0d | match=%b mismatch=%b [OK]",
                             $time, btn_in, pattern_sym, valid, user_sym, match, mismatch);
                end
            end
        end

        #20;
        if (error_count == 0) begin
            $display("TEST PASSED!");
        end else begin
            $display("TEST FAILED! Total errors = %0d", error_count);
        end

        $finish;
    end

endmodule