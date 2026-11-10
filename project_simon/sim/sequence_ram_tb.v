`timescale 1ns / 1ns

module sequence_ram_tb;

    parameter integer DATA_WIDTH = 2;
    parameter integer DEPTH = 10;
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

        // 1. Запись в допустимые адреса (0..DEPTH-1)
        @(negedge clk);
        for (i = 0; i < DEPTH; i = i + 1) begin
            we = 1'b1;
            addr = i[ADDR_WIDTH-1:0];
            din = (i + 1) % 4;
            shadow_mem[i] = din;
            @(negedge clk);
        end
        we = 1'b0;

        // 2. Синхронное чтение всех допустимых адресов с контролем задержки 1 такт
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

        // 3. Проверка сохранения данных при запрете записи (we = 0)
        addr = 4'd3;
        din = ~shadow_mem[3];
        we = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== shadow_mem[3]) begin
            $display("ERROR hold mode at addr 3: dout = %b, expected = %b", dout, shadow_mem[3]);
            errors = errors + 1;
        end
        @(negedge clk);

        // 4. Проверка одновременного чтения и записи (Read-First) по адресу 2
        addr = 4'd2;
        din = 2'h0;
        we = 1'b1;
        @(posedge clk);
        #1;
        if (dout !== shadow_mem[2]) begin
            $display("ERROR Read-First at addr 2: dout = %b, expected old = %b", dout, shadow_mem[2]);
            errors = errors + 1;
        end
        @(negedge clk);
        we = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== 2'h0) begin
            $display("ERROR new value after Read-First at addr 2: dout = %b", dout);
            errors = errors + 1;
        end
        @(negedge clk);

        // 5. Проверка обращения к недопустимым адресам (addr >= DEPTH, адреса 10..15)
        for (i = DEPTH; i < (1 << ADDR_WIDTH); i = i + 1) begin
            addr = i[ADDR_WIDTH-1:0];
            din = 2'h3;
            we = 1'b1;
            @(posedge clk);
            #1;
            if (dout !== {DATA_WIDTH{1'b0}}) begin
                $display("ERROR invalid addr %0d on write: dout = %b, expected 0", i, dout);
                errors = errors + 1;
            end
            @(negedge clk);
            we = 1'b0;
            @(posedge clk);
            #1;
            if (dout !== {DATA_WIDTH{1'b0}}) begin
                $display("ERROR invalid addr %0d on read: dout = %b, expected 0", i, dout);
                errors = errors + 1;
            end
            @(negedge clk);
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
