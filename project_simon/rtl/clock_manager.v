`timescale 1ns / 1ps

module clock_manager (
    input wire clk100,
    input wire reset,
    output wire clk_sys,
    output wire reset_sync
);

    reg [1:0] rst_pipe = 2'b11;

    assign clk_sys = clk100;

    always @(posedge clk_sys) begin
        rst_pipe <= {rst_pipe[0], reset};
    end

    assign reset_sync = rst_pipe[1];

endmodule
