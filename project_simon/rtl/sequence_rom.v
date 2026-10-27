`timescale 1ns / 1ns

module sequence_rom #(
    parameter integer DATA_WIDTH = 2,
    parameter integer DEPTH      = 16,
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH),
    parameter         INIT_FILE  = "patterns.mem"
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] data
);

    // Массив ячеек постоянной памяти
    reg [DATA_WIDTH-1:0] rom [0:DEPTH-1];

    // Инициализация памяти из внешнего файла
    initial begin
        $readmemh(INIT_FILE, rom);
    end

    // Асинхронное комбинационное чтение
    assign data = rom[addr];

endmodule