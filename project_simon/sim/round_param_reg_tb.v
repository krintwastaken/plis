`timescale 1ns / 1ns

module round_param_reg_tb;

    parameter integer WIDTH = 8;

    reg             clk;
    reg             rst;
    reg             load;
    reg [WIDTH-1:0] d;
    wire [WIDTH-1:0] q;

    integer errors;

    // Подключение тестируемого модуля (DUT)
    round_param_reg #(
        .WIDTH ( WIDTH )
    ) DUT (
        .clk  ( clk ),
        .rst  ( rst ),
        .load ( load ),
        .d    ( d ),
        .q    ( q )
    );

    // Тактовый сигнал с периодом 10 нс (частота 100 МГц)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Задача автоматической проверки с задержкой стробирования
    task check;
        input [WIDTH-1:0] expected;
        begin
            #1;
            if (q !== expected) begin
                $display("ERROR at time %0t: q = %h, expected = %h", $time, q, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        clk = 1'b0;
        rst = 1'b0;
        load = 1'b0;
        d = {WIDTH{1'b0}};

        // 1. Проверка синхронного сброса
        rst = 1'b1;
        @(posedge clk);
        check({WIDTH{1'b0}});

        // 2. Загрузка параметров раунда
        @(negedge clk);
        rst = 1'b0;
        load = 1'b1;
        d = 8'hA5;
        @(posedge clk);
        check(8'hA5);

        // 3. Проверка режима удержания данных при load = 0
        @(negedge clk);
        load = 1'b0;
        d = 8'hFF;
        @(posedge clk);
        check(8'hA5);

        // 4. Загрузка граничного значения 8'h00
        @(negedge clk);
        load = 1'b1;
        d = 8'h00;
        @(posedge clk);
        check(8'h00);

        // 5. Загрузка граничного значения 8'hFF
        @(negedge clk);
        load = 1'b1;
        d = 8'hFF;
        @(posedge clk);
        check(8'hFF);

        // 6. Проверка приоритета сброса над загрузкой
        @(negedge clk);
        rst = 1'b1;
        load = 1'b1;
        d = 8'h3C;
        @(posedge clk);
        check(8'h00);

        // Итоги верификации
        #20;
        if (errors == 0) begin
            $display("TEST PASSED: round_param_reg");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule