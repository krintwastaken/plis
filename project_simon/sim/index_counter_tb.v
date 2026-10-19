`timescale 1ns / 1ps

module index_counter_tb;
    parameter WIDTH = 4;

    reg             clk;
    reg             reset;
    reg             load;
    reg             en_count;
    reg [WIDTH-1:0] data_load;
    reg [WIDTH-1:0] max_len;

    wire [WIDTH-1:0] count;
    wire            over;

    integer error_count;

    // Экземпляр тестируемого модуля (DUT)
    index_counter #(.WIDTH(WIDTH)) dut (
        .clk       (clk),
        .reset     (reset),
        .load      (load),
        .en_count  (en_count),
        .data_load (data_load),
        .max_len   (max_len),
        .count     (count),
        .over      (over)
    );

    // Генерация тактового сигнала (T = 10 нс, частота 100 МГц)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Процедура тестирования
    initial begin
        $display("\n");
        $display("     START TESTBENCH: index_counter     ");
        $display("\n");

        error_count = 0;
        reset       = 1'b0;
        load        = 1'b0;
        en_count    = 1'b0;
        data_load   = {WIDTH{1'b0}};
        max_len     = 4'd5; // Тестовая длина последовательности: 5 символов (индексы 0..4)

        // 1. Проверка сброса
        #2;
        reset = 1'b1;
        #10;
        @(negedge clk);
        if (count !== 0 || over !== 0) begin
            $display("[ERROR] Reset failed: count=%0d, over=%b", count, over);
            error_count = error_count + 1;
        end else begin
            $display("Time=%0t | Test 1: Reset OK | count=%0d, over=%b", $time, count, over);
        end
        reset = 1'b0;

        // 2. Проверка режима хранения (en_count = 0)
        #20;
        @(negedge clk);
        if (count !== 0) begin
            $display("[ERROR] Hold failed: count=%0d (expected 0)", count);
            error_count = error_count + 1;
        end else begin
            $display("Time=%0t | Test 2: Hold mode OK | count=%0d", $time, count);
        end

        // 3. Проверка последовательного счета (0 -> 1 -> 2 -> 3 -> 4)
        en_count = 1'b1;
        // На 4-м шаге (индекс 4 при длине 5) должен сформироваться over = 1
        repeat (4) @(negedge clk);
        $display("Time=%0t | Test 3: Counting to max-1 | count=%0d, over=%b", $time, count, over);
        if (count !== 4'd4 || over !== 1'b1) begin
            $display("[ERROR] Count/Over mismatch at end of sequence! count=%0d, over=%b", count, over);
            error_count = error_count + 1;
        end

        // 4. Проверка удержания в состоянии over при продолжении счета
        @(negedge clk);
        if (count !== 4'd4 || over !== 1'b1) begin
            $display("[ERROR] Saturation failed! count=%0d, over=%b", count, over);
            error_count = error_count + 1;
        end else begin
            $display("Time=%0t | Test 4: Saturation OK | count=%0d, over=%b", $time, count, over);
        end
        en_count = 1'b0;

        // 5. Проверка загрузки произвольного значения (load)
        #10;
        data_load = 4'd2;
        load      = 1'b1;
        #10;
        @(negedge clk);
        load = 1'b0;
        if (count !== 4'd2 || over !== 1'b0) begin
            $display("[ERROR] Load failed: count=%0d, over=%b", count, over);
            error_count = error_count + 1;
        end else begin
            $display("Time=%0t | Test 5: Load value 2 OK | count=%0d, over=%b", $time, count, over);
        end

        // 6. Проверка приоритета сигналов (reset > load > en_count)
        #10;
        en_count  = 1'b1;
        load      = 1'b1;
        data_load = 4'd1;
        reset     = 1'b1;
        #10;
        @(negedge clk);
        if (count !== 0 || over !== 0) begin
            $display("[ERROR] Reset priority failed! count=%0d", count);
            error_count = error_count + 1;
        end else begin
            $display("Time=%0t | Test 6: Priority (reset > load > en) OK | count=%0d", $time, count);
        end
        reset    = 1'b0;
        load     = 1'b0;
        en_count = 1'b0;

        // 7. Проверка новой длины последовательности (max_len = 8)
        @(negedge clk);
        max_len  = 4'd8;
        en_count = 1'b1;
        // Ровно 7 положительных тактов для инкремента от 0 до 7 (max_len - 1)
        repeat (7) @(posedge clk);
        @(negedge clk); // Проверяем результат после фиксации на спаде такта

        if (count !== 4'd7 || over !== 1'b1) begin
            $display("[ERROR] max_len=8 test failed! count=%0d, over=%b", count, over);
            error_count = error_count + 1;
        end else begin
            $display("Time=%0t | Test 7: Count to max_len=8 OK | count=%0d, over=%b", $time, count, over);
        end
        en_count = 1'b0;

        #20;
        $display("\n");
        if (error_count == 0) begin
            $display("TEST PASSED!");
        end else begin
            $display("TEST FAILED! Errors = %0d", error_count);
        end
        $display("\n");

        $finish;
    end
endmodule