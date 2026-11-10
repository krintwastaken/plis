`timescale 1ns / 1ps

module index_counter_tb;

    parameter integer WIDTH = 4;

    reg clk;
    reg reset;
    reg load;
    reg en_count;
    reg [WIDTH-1:0] data_load;
    reg [WIDTH-1:0] max_len;

    wire [WIDTH-1:0] count;
    wire over;
    integer errors;

    index_counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .en_count(en_count),
        .data_load(data_load),
        .max_len(max_len),
        .count(count),
        .over(over)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        errors = 0;
        reset = 1'b0;
        load = 1'b0;
        en_count = 1'b0;
        data_load = {WIDTH{1'b0}};
        max_len = 4'd5;

        // 1. Сброс
        #2;
        reset = 1'b1;
        #10;
        @(negedge clk);
        if (count !== 4'd0 || over !== 1'b0) begin
            $display("ERROR: Reset failed: count = %0d, over = %b", count, over);
            errors = errors + 1;
        end
        reset = 1'b0;

        // 2. Проверка нулевой длины (max_len = 0) без счета и со счетом
        @(negedge clk);
        max_len = 4'd0;
        #1;
        if (over !== 1'b1) begin
            $display("ERROR: Immediate over on max_len = 0 failed");
            errors = errors + 1;
        end
        en_count = 1'b1;
        @(negedge clk);
        if (over !== 1'b1 || count !== 4'd0) begin
            $display("ERROR: max_len = 0 counting failed");
            errors = errors + 1;
        end
        en_count = 1'b0;

        // 3. Проверка параллельной загрузки при max_len = 0
        @(negedge clk);
        data_load = 4'd2;
        load = 1'b1;
        @(negedge clk);
        load = 1'b0;
        if (over !== 1'b1 || count !== 4'd2) begin
            $display("ERROR: max_len = 0 load failed");
            errors = errors + 1;
        end

        // 4. Штатный счет до max_len - 1 (длина 5, счет 0..4)
        @(negedge clk);
        reset = 1'b1;
        max_len = 4'd5;
        @(negedge clk);
        reset = 1'b0;
        en_count = 1'b1;
        repeat (4) @(negedge clk);
        if (count !== 4'd4 || over !== 1'b1) begin
            $display("ERROR: Count to max_len - 1 failed: count = %0d, over = %b", count, over);
            errors = errors + 1;
        end

        // 5. Насыщение при продолжении подачи en_count = 1
        @(negedge clk);
        if (count !== 4'd4 || over !== 1'b1) begin
            $display("ERROR: Saturation failed");
            errors = errors + 1;
        end
        en_count = 1'b0;

        // 6. Немедленный пересчет over при изменении max_len в режиме удержания (load = 0, en_count = 0)
        @(negedge clk);
        max_len = 4'd8;
        #1;
        if (over !== 1'b0) begin
            $display("ERROR: over did not clear immediately when max_len increased to 8");
            errors = errors + 1;
        end
        max_len = 4'd4;
        #1;
        if (over !== 1'b1) begin
            $display("ERROR: over did not assert immediately when max_len decreased to 4");
            errors = errors + 1;
        end

        // 7. Проверка приоритета сигналов (reset > load > en_count)
        @(negedge clk);
        max_len = 4'd5;
        reset = 1'b1;
        load = 1'b1;
        en_count = 1'b1;
        data_load = 4'd3;
        @(negedge clk);
        reset = 1'b0;
        load = 1'b0;
        en_count = 1'b0;
        if (count !== 4'd0 || over !== 1'b0) begin
            $display("ERROR: Reset priority failed");
            errors = errors + 1;
        end

        #20;
        if (errors == 0) begin
            $display("TEST PASSED: index_counter");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule
