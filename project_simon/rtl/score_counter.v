`timescale 1ns / 1ns

module score_counter #(
    parameter integer SCORE_WIDTH = 8,
    parameter integer POINTS_WIDTH = 4
)(
    input wire clk,
    input wire rst,
    input wire clear,
    input wire add_score,
    input wire [POINTS_WIDTH-1:0] points,
    output reg [SCORE_WIDTH-1:0] score
);

    localparam integer SUM_WIDTH = (SCORE_WIDTH > POINTS_WIDTH) ? (SCORE_WIDTH + 1) : (POINTS_WIDTH + 1);
    localparam [SCORE_WIDTH-1:0] MAX_SCORE = {SCORE_WIDTH{1'b1}};

    wire [SUM_WIDTH-1:0] score_ext;
    wire [SUM_WIDTH-1:0] points_ext;
    wire [SUM_WIDTH-1:0] max_score_ext;
    wire [SUM_WIDTH-1:0] next_score;

    assign score_ext = {{(SUM_WIDTH - SCORE_WIDTH){1'b0}}, score};
    assign points_ext = {{(SUM_WIDTH - POINTS_WIDTH){1'b0}}, points};
    assign max_score_ext = {{(SUM_WIDTH - SCORE_WIDTH){1'b0}}, MAX_SCORE};
    assign next_score = score_ext + points_ext;

    always @(posedge clk) begin
        if (rst) begin
            score <= {SCORE_WIDTH{1'b0}};
        end else if (clear) begin
            score <= {SCORE_WIDTH{1'b0}};
        end else if (add_score) begin
            if (next_score > max_score_ext) begin
                score <= MAX_SCORE;
            end else begin
                score <= next_score[SCORE_WIDTH-1:0];
            end
        end
    end

endmodule
