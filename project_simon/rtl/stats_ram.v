`timescale 1ns / 1ns

module stats_ram #(
    parameter integer DATA_WIDTH = 8,
    parameter integer DEPTH      = 8,
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH),
    parameter         INIT_FILE  = "stats_init.mem"
)(
    input  wire                  clk,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

    // Массив ячеек памяти статистики
    reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Инициализация начальных рекордов из файла
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    // Синхронная запись и чтение (режим Read-First)
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
        dout <= ram[addr];
    end

endmodule