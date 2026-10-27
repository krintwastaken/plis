`timescale 1ns / 1ns

module round_param_reg #(
    parameter integer WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             load,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

    always @(posedge clk) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else if (load) begin
            q <= d;
        end
    end

endmodule