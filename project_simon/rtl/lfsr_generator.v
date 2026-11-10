`timescale 1ns / 1ns

module lfsr_generator #(
    parameter integer WIDTH = 2,
    parameter integer LFSR_WIDTH = (WIDTH > 8) ? WIDTH : 8
)(
    input wire clk,
    input wire rst,
    input wire enable,
    output wire [WIDTH-1:0] random_number
);

    localparam [LFSR_WIDTH-1:0] SEED = 8'hA5;

    reg [LFSR_WIDTH-1:0] lfsr;
    wire feedback;

    // Полином обратной связи (для базового 8-битного регистра: x^8 + x^6 + x^5 + x^4 + 1)
    assign feedback = lfsr[LFSR_WIDTH-1] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk) begin
        if (rst) begin
            lfsr <= SEED;
        end else if (enable) begin
            lfsr <= {lfsr[LFSR_WIDTH-2:0], feedback};
        end
    end

    assign random_number = lfsr[WIDTH-1:0];

endmodule
