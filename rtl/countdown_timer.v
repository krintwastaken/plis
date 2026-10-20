`timescale 1ns / 1ns

module countdown_timer #(
    parameter integer WIDTH = 12
)(
    input wire clk,
    input wire rst,
    input wire load,
    input wire enable,
    input wire tick,
    input wire [WIDTH-1:0] load_value,
    output reg [WIDTH-1:0] remaining,
    output wire zero
);

    assign zero = (remaining == {WIDTH{1'b0}});

    always @(posedge clk) begin
        if (rst) begin
            remaining <= {WIDTH{1'b0}};
        end else if (load) begin
            remaining <= load_value;
        end else if (enable && tick && !zero) begin
            remaining <= remaining - 1'b1;
        end
    end

endmodule