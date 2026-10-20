`timescale 1ns / 1ns

module score_counter_tb;

    parameter SCORE_WIDTH = 8;
    parameter POINTS_WIDTH = 4;

    reg clk;
    reg rst;
    reg clear;
    reg add_score;
    reg [POINTS_WIDTH-1:0] points;

    wire [SCORE_WIDTH-1:0] score;
    integer errors;

    // Экземпляр тестируемого модуля (DUT)
    score_counter #(
        .SCORE_WIDTH ( SCORE_WIDTH ),
        .POINTS_WIDTH ( POINTS_WIDTH )
    ) DUT (
        .clk ( clk ),
        .rst ( rst ),
        .clear ( clear ),
        .add_score ( add_score ),
        .points ( points ),
        .score ( score )
    );

    // Тактовый сигнал (T = 10 нс, частота 100 МГц)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst = 1'b1;
        clear = 1'b0;
        add_score = 1'b0;
        points = {POINTS_WIDTH{1'b0}};
        errors = 0;

        // 1. Проверка системного сброса
        #12;
        rst = 1'b0;
        #1;
        if ( score !== 8'd0 ) begin
            $display( "ERROR: rst failed, score = %0d", score );
            errors = errors + 1;
        end

        // 2. Раунд 1: базовый уровень (начисление 1 очка)
        points = 4'd1;
        add_score = 1'b1;
        #10;
        add_score = 1'b0;
        #1;
        if ( score !== 8'd1 ) begin
            $display( "ERROR: points = 1 failed, score = %0d", score );
            errors = errors + 1;
        end

        // 3. Раунд 2: средний уровень (начисление 2 очков)
        points = 4'd2;
        add_score = 1'b1;
        #10;
        add_score = 1'b0;
        #1;
        if ( score !== 8'd3 ) begin
            $display( "ERROR: points = 2 failed, score = %0d", score );
            errors = errors + 1;
        end

        // 4. Раунд 3: высокий уровень (начисление 3 очков)
        points = 4'd3;
        add_score = 1'b1;
        #10;
        add_score = 1'b0;
        #1;
        if ( score !== 8'd6 ) begin
            $display( "ERROR: points = 3 failed, score = %0d", score );
            errors = errors + 1;
        end

        // 5. Проверка режима хранения
        #20;
        if ( score !== 8'd6 ) begin
            $display( "ERROR: hold mode failed, score = %0d", score );
            errors = errors + 1;
        end

        // 6. Проверка обнуления счета по clear
        clear = 1'b1;
        #10;
        clear = 1'b0;
        #1;
        if ( score !== 8'd0 ) begin
            $display( "ERROR: clear failed, score = %0d", score );
            errors = errors + 1;
        end

        // 7. Проверка насыщения счетчика (MAX_SCORE = 255)
        @(negedge clk);
        DUT.score = 8'd254;
        points = 4'd3;
        add_score = 1'b1;
        #10;
        add_score = 1'b0;
        #1;
        if ( score !== 8'd255 ) begin
            $display( "ERROR: saturation failed, score = %0d", score );
            errors = errors + 1;
        end

        // Итоги тестирования
        #20;
        if ( errors == 0 ) begin
            $display( "TEST PASSED" );
        end else begin
            $display( "TEST FAILED: %0d errors", errors );
        end

        $finish;
    end

endmodule