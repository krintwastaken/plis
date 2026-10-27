`timescale 1ns / 1ns

module sequence_ram_tb;

    parameter integer DATA_WIDTH = 2;
    parameter integer DEPTH = 10; // Глубина намеренно не степень двойки (ADDR_WIDTH = 4)
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);

    reg clk;
    reg we;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    reg [DATA_WIDTH-1:0] shadow_mem [0:DEPTH-1];
    integer i;
    integer errors;

    sequence_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        we = 1'b0;
        addr = {ADDR_WIDTH{1'b0}};
        din = {DATA_WIDTH{1'b0}};
        errors = 0;

        // Запись в допустимые адреса (0..9)
        @(negedge clk);
        for (i = 0; i < DEPTH; i = i + 1) begin
            we = 1'b1;
            addr = i[ADDR_WIDTH-1:0];
            din = i[DATA_WIDTH-1:0];
            shadow_mem[i] = din;
            @(negedge clk);
        end
        we = 1'b0;

        // Синхронное чтение допустимых адресов (задержка 1 такт)
        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = i[ADDR_WIDTH-1:0];
            @(posedge clk);
            #1;
            if (dout !== shadow_mem[i]) begin
                $display("ERROR read at addr %0d: dout = %b, expected = %b", i, dout, shadow_mem[i]);
                errors = errors + 1;
            end
            @(negedge clk);
        end

        // Проверка недопустимого адреса (addr = 13 >= DEPTH = 10)
        addr = 4'd13;
        din = 2'h3;
        we = 1'b1; // Попытка записи за пределы памяти
        @(posedge clk);
        @(negedge clk);
        we = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== {DATA_WIDTH{1'b0}}) begin
            $display("ERROR: Invalid address must return 0, got %b", dout);
            errors = errors + 1;
        end

        #20;
        if (errors == 0) begin
            $display("TEST PASSED: sequence_ram");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule