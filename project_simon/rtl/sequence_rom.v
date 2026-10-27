`timescale 1ns / 1ns

module sequence_rom #(
    parameter integer DATA_WIDTH = 2,
    parameter integer DEPTH = 16,
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH),
    parameter INIT_FILE = "patterns.mem"
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] data
);

    reg [DATA_WIDTH-1:0] rom [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            rom[i] = {DATA_WIDTH{1'b0}};
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, rom);
        end
    end

    // Безопасное чтение при обращении за пределы DEPTH
    assign data = (addr < DEPTH) ? rom[addr] : {DATA_WIDTH{1'b0}};

endmodule