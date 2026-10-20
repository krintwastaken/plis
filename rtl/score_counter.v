`timescale 1ns / 1ns

module score_counter #(
    parameter SCORE_WIDTH = 8,
    parameter POINTS_WIDTH = 4
)(
    input wire clk,
    input wire rst,
    input wire clear,
    input wire add_score,
    input wire [POINTS_WIDTH-1:0] points,
    output reg [SCORE_WIDTH-1:0] score
);

    // Максимальное значение для насыщения счетчика
    localparam [SCORE_WIDTH-1:0] MAX_SCORE = {SCORE_WIDTH{1'b1}};

    // Расширенная шина суммы для контроля выхода за разрядную сетку
    wire [SCORE_WIDTH:0] next_score;

    assign next_score = {1'b0, score} + {{(SCORE_WIDTH+1-POINTS_WIDTH){1'b0}}, points};

    always @(posedge clk) begin
        if (rst) begin
            score <= {SCORE_WIDTH{1'b0}};
        end else if (clear) begin
            score <= {SCORE_WIDTH{1'b0}};
        end else if (add_score) begin
            if (next_score > {1'b0, MAX_SCORE}) begin
                score <= MAX_SCORE;
            end else begin
                score <= next_score[SCORE_WIDTH-1:0];
            end
        end
    end

endmodule