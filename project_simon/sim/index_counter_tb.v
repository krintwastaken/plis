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

        // Сброс
        #2;
        reset = 1'b1;
        #10;
        @(negedge clk);
        if (count !== 0 || over !== 0) begin
            $display("ERROR: Reset failed");
            errors = errors + 1;
        end
        reset = 1'b0;

        // Проверка нулевой длины (max_len = 0)
        @(negedge clk);
        max_len = 4'd0;
        en_count = 1'b1;
        @(negedge clk);
        if (over !== 1'b1 || count !== 0) begin
            $display("ERROR: max_len = 0 counting failed");
            errors = errors + 1;
        end
        en_count = 1'b0;

        // Проверка load при max_len = 0
        @(negedge clk);
        data_load = 4'd2;
        load = 1'b1;
        @(negedge clk);
        load = 1'b0;
        if (over !== 1'b1) begin
            $display("ERROR: max_len = 0 load failed");
            errors = errors + 1;
        end

        // Штатный счет до max_len - 1 (длина 5, счет 0..4)
        @(negedge clk);
        reset = 1'b1;
        @(negedge clk);
        reset = 1'b0;
        max_len = 4'd5;
        en_count = 1'b1;
        repeat (4) @(negedge clk);
        if (count !== 4'd4 || over !== 1'b1) begin
            $display("ERROR: Count to max_len - 1 failed");
            errors = errors + 1;
        end

        // Насыщение при переполнении
        @(negedge clk);
        if (count !== 4'd4 || over !== 1'b1) begin
            $display("ERROR: Saturation failed");
            errors = errors + 1;
        end
        en_count = 1'b0;

        #20;
        if (errors == 0) begin
            $display("TEST PASSED: index_counter");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule