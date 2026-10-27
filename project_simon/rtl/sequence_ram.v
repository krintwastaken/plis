`timescale 1ns / 1ns

module sequence_ram #(
    parameter integer DATA_WIDTH = 2,
    parameter integer DEPTH      = 16,
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH)
)(
    input  wire                  clk,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

    // Массив ячеек оперативной памяти
    reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Синхронная запись и чтение (режим Read-First)
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
        dout <= ram[addr];
    end

endmodule