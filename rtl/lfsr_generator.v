`timescale 1ns / 1ns

module lfsr_generator #(
    parameter integer WIDTH = 2
)(
    input wire clk,
    input wire rst,
    input wire enable,
    output wire [WIDTH-1:0] random_number
);

    reg [7:0] lfsr;
    wire feedback;

    // Полином максимального периода: x^8 + x^6 + x^5 + x^4 + 1
    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 8'hA5;
        end else if (enable) begin
            lfsr <= {lfsr[6:0], feedback};
        end
    end

    assign random_number = lfsr[WIDTH-1:0];

endmodule