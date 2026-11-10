`timescale 1ns / 1ns

module score_counter_tb;

    parameter integer SCORE_WIDTH = 8;
    parameter integer POINTS_WIDTH = 4;

    reg clk;
    reg rst;
    reg clear;
    reg add_score;
    reg [POINTS_WIDTH-1:0] points;
    wire [SCORE_WIDTH-1:0] score;

    reg [7:0] wide_points;
    wire [3:0] narrow_score;

    integer errors;

    score_counter #(
        .SCORE_WIDTH(SCORE_WIDTH),
        .POINTS_WIDTH(POINTS_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .add_score(add_score),
        .points(points),
        .score(score)
    );

    // Дополнительный экземпляр с POINTS_WIDTH > SCORE_WIDTH для проверки универсальности
    score_counter #(
        .SCORE_WIDTH(4),
        .POINTS_WIDTH(8)
    ) dut_wide_points (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .add_score(add_score),
        .points(wide_points),
        .score(narrow_score)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst = 1'b1;
        clear = 1'b0;
        add_score = 1'b0;
        points = {POINTS_WIDTH{1'b0}};
        wide_points = 8'd0;
        errors = 0;

        // 1. Проверка системного сброса
        #12;
        rst = 1'b0;
        #1;
        if (score !== 8'd0 || narrow_score !== 4'd0) begin
            $display("ERROR: rst failed, score = %0d", score);
            errors = errors + 1;
        end

        // 2. Начисление 1 очка
        @(negedge clk);
        points = 4'd1;
        wide_points = 8'd2;
        add_score = 1'b1;
        @(posedge clk);
        #1;
        if (score !== 8'd1 || narrow_score !== 4'd2) begin
            $display("ERROR: step 2 failed, score = %0d, narrow_score = %0d", score, narrow_score);
            errors = errors + 1;
        end

        // 3. Начисление 2 очков (проверка переполнения при POINTS_WIDTH > SCORE_WIDTH)
        @(negedge clk);
        points = 4'd2;
        wide_points = 8'd20;
        add_score = 1'b1;
        @(posedge clk);
        #1;
        if (score !== 8'd3 || narrow_score !== 4'd15) begin
            $display("ERROR: step 3 failed, score = %0d, narrow_score = %0d", score, narrow_score);
            errors = errors + 1;
        end

        // 4. Начисление 3 очков
        @(negedge clk);
        points = 4'd3;
        add_score = 1'b1;
        @(posedge clk);
        #1;
        if (score !== 8'd6) begin
            $display("ERROR: points = 3 failed, score = %0d", score);
            errors = errors + 1;
        end

        // 5. Режим удержания (add_score = 0)
        @(negedge clk);
        add_score = 1'b0;
        points = 4'd15;
        repeat (2) @(posedge clk);
        #1;
        if (score !== 8'd6) begin
            $display("ERROR: hold mode failed, score = %0d", score);
            errors = errors + 1;
        end

        // 6. Сброс счета по сигналу clear
        @(negedge clk);
        clear = 1'b1;
        @(posedge clk);
        #1;
        if (score !== 8'd0 || narrow_score !== 4'd0) begin
            $display("ERROR: clear failed, score = %0d", score);
            errors = errors + 1;
        end
        @(negedge clk);
        clear = 1'b0;

        // 7. Проверка насыщения основного счетчика (MAX_SCORE = 255)
        dut.score = 8'd254;
        points = 4'd3;
        add_score = 1'b1;
        @(posedge clk);
        #1;
        if (score !== 8'd255) begin
            $display("ERROR: saturation failed, score = %0d", score);
            errors = errors + 1;
        end
        @(negedge clk);
        add_score = 1'b0;

        #20;
        if (errors == 0) begin
            $display("TEST PASSED: score_counter");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule
