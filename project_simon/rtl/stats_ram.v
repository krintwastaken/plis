`timescale 1ns / 1ns

module stats_ram #(
    parameter integer DATA_WIDTH = 8,
    parameter integer DEPTH = 8,
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH),
    parameter INIT_FILE = "stats_init.mem"
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            ram[i] = {DATA_WIDTH{1'b0}};
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    // Синхронная запись и чтение с блокировкой недопустимых адресов
    always @(posedge clk) begin
        if (we && (addr < DEPTH)) begin
            ram[addr] <= din;
        end

        if (addr < DEPTH) begin
            dout <= ram[addr];
        end else begin
            dout <= {DATA_WIDTH{1'b0}};
        end
    end

endmodule