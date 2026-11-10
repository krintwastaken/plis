`timescale 1ns / 1ns

module stats_ram_tb;

    parameter integer DATA_WIDTH = 8;
    parameter integer DEPTH = 6;
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);

    reg clk;
    reg we;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    integer errors;

    stats_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .INIT_FILE("stats_init.mem")
    ) dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check_addr;
        input [ADDR_WIDTH-1:0] target_addr;
        input [DATA_WIDTH-1:0] expected_val;
        begin
            addr = target_addr;
            @(posedge clk);
            #1;
            if (dout !== expected_val) begin
                $display("ERROR at addr %0d: dout = %h, expected = %h", target_addr, dout, expected_val);
                errors = errors + 1;
            end
            @(negedge clk);
        end
    endtask

    initial begin
        we = 1'b0;
        addr = {ADDR_WIDTH{1'b0}};
        din = {DATA_WIDTH{1'b0}};
        errors = 0;

        // 1. Проверка чтения начальных значений рекордов (адреса 0..3)
        @(negedge clk);
        check_addr(3'd0, 8'h05);
        check_addr(3'd1, 8'h0A);
        check_addr(3'd2, 8'h0F);
        check_addr(3'd3, 8'h14);

        // 2. Обновление рекорда среднего уровня (адрес 1) и проверка режима Read-First
        addr = 3'd1;
        din = 8'd25;
        we = 1'b1;
        @(posedge clk);
        #1;
        if (dout !== 8'h0A) begin
            $display("ERROR Read-First: expected 0A, got %h", dout);
            errors = errors + 1;
        end
        @(negedge clk);
        we = 1'b0;

        // 3. Проверка считывания обновленного рекорда
        check_addr(3'd1, 8'd25);

        // 4. Проверка удержания данных при запрете записи (we = 0)
        addr = 3'd1;
        din = 8'hFF;
        we = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== 8'd25) begin
            $display("ERROR hold mode: expected 25, got %h", dout);
            errors = errors + 1;
        end
        @(negedge clk);

        // 5. Проверка последнего допустимого граничного адреса (DEPTH - 1 = 5)
        addr = 3'd5;
        din = 8'h55;
        we = 1'b1;
        @(posedge clk);
        @(negedge clk);
        we = 1'b0;
        check_addr(3'd5, 8'h55);

        // 6. Проверка недопустимых адресов (addr = 6 и addr = 7 при DEPTH = 6)
        addr = 3'd6;
        din = 8'hAA;
        we = 1'b1;
        @(posedge clk);
        #1;
        if (dout !== 8'h00) begin
            $display("ERROR invalid addr 6 write: expected 00, got %h", dout);
            errors = errors + 1;
        end
        @(negedge clk);
        we = 1'b0;
        check_addr(3'd6, 8'h00);
        check_addr(3'd7, 8'h00);

        #20;
        if (errors == 0) begin
            $display("TEST PASSED: stats_ram");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule
