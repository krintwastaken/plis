`timescale 1ns / 1ns

module lfsr_generator_tb;

    parameter WIDTH = 2;

    reg clk;
    reg rst;
    reg enable;

    wire [WIDTH-1:0] random_number;
    reg [WIDTH-1:0] saved_number;
    wire [WIDTH-1:0] exp_reset = 8'hA5; // Автоматическое усечение константы под WIDTH
    integer i;
    integer errors;

    // Подключение тестируемого модуля (DUT)
    lfsr_generator #(
        .WIDTH ( WIDTH )
    ) DUT (
        .clk ( clk ),
        .rst ( rst ),
        .enable ( enable ),
        .random_number ( random_number )
    );

    // Тактовый сигнал с периодом 10 нс (частота 100 МГц)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst = 1'b1;
        enable = 1'b0;
        errors = 0;

        // 1. Проверка сброса
        @(negedge clk);
        rst = 1'b0;
        #1;
        if ( random_number !== exp_reset ) begin
            $display( "ERROR: reset failed, random_number = %h", random_number );
            errors = errors + 1;
        end

        // 2. Генерация 20 последовательных псевдослучайных символов
        enable = 1'b1;
        for ( i = 0; i < 20; i = i + 1 ) begin
            @(posedge clk);
            #1;
            $display( "Step %0d: random_number = %h", i, random_number );
        end

        // 3. Проверка режима удержания значения при enable = 0
        @(negedge clk);
        enable = 1'b0;
        saved_number = random_number;
        repeat ( 5 ) @(posedge clk);
        #1;
        if ( random_number !== saved_number ) begin
            $display( "ERROR: enable = 0 hold failed" );
            errors = errors + 1;
        end

        // 4. Возобновление генерации
        @(negedge clk);
        enable = 1'b1;
        repeat ( 5 ) begin
            @(posedge clk);
            #1;
            $display( "Next symbol = %h", random_number );
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