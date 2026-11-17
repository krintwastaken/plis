`timescale 1ns / 1ps

module tick_generator #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer TICK_FREQ = 1
)(
    input wire clk,
    input wire rst,
    output reg tick
);

    localparam integer CNT_MAX = (CLK_FREQ / TICK_FREQ) - 1;
    localparam integer CNT_WIDTH = (CNT_MAX < 2) ? 1 : $clog2(CNT_MAX + 1);

    reg [CNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= {CNT_WIDTH{1'b0}};
            tick <= 1'b0;
        end else if (counter >= CNT_MAX) begin
            counter <= {CNT_WIDTH{1'b0}};
            tick <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            tick <= 1'b0;
        end
    end

endmodule
