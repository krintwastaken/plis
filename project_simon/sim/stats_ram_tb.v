`timescale 1ns / 1ns

module stats_ram_tb;

    parameter integer DATA_WIDTH = 8;
    parameter integer DEPTH      = 8;
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);

    reg                  clk;
    reg                  we;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    integer errors;

    // Подключение тестируемого модуля (DUT)
    stats_ram #(
        .DATA_WIDTH ( DATA_WIDTH ),
        .DEPTH      ( DEPTH ),
        .INIT_FILE  ( "stats_init.mem" )
    ) DUT (
        .clk  ( clk ),
        .we   ( we ),
        .addr ( addr ),
        .din  ( din ),
        .dout ( dout )
    );

    // Тактовый сигнал (T = 10 нс, частота 100 МГц)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Процедура контроля ожидаемого значения с тактовой задержкой
    task check_data;
        input [ADDR_WIDTH-1:0] check_addr;
        input [DATA_WIDTH-1:0] expected_val;
        begin
            addr = check_addr;
            @(posedge clk);
            #1;
            if (dout !== expected_val) begin
                $display("ERROR at addr %0d: dout = %h, expected = %h", check_addr, dout, expected_val);
                errors = errors + 1;
            end else begin
                $display("OK: addr = %0d, stat = %h", check_addr, dout);
            end
            @(negedge clk);
        end
    endtask

    initial begin
        clk    = 1'b0;
        we     = 1'b0;
        addr   = {ADDR_WIDTH{1'b0}};
        din    = {DATA_WIDTH{1'b0}};
        errors = 0;

        // 1. Проверка чтения инициализированных рекордов (адреса 0..3)
        @(negedge clk);
        check_data(3'd0, 8'h05);
        check_data(3'd1, 8'h0A);
        check_data(3'd2, 8'h0F);
        check_data(3'd3, 8'h14);

        // 2. Обновление рекорда среднего уровня (запись 8'd25 по адресу 1)
        addr = 3'd1;
        din  = 8'd25;
        we   = 1'b1;
        @(posedge clk);
        #1;
        // Проверка режима Read-First (старое значение 8'h0A на такте записи)
        if (dout !== 8'h0A) begin
            $display("ERROR Read-First: dout = %h, expected old = 0A", dout);
            errors = errors + 1;
        end
        @(negedge clk);
        we = 1'b0;

        // 3. Проверка считывания обновленного рекорда
        check_data(3'd1, 8'd25);

        // 4. Проверка режима удержания данных (we = 0)
        addr = 3'd1;
        din  = 8'hFF;
        we   = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== 8'd25) begin
            $display("ERROR hold failed: dout = %h, expected = 25", dout);
            errors = errors + 1;
        end
        @(negedge clk);

        // 5. Проверка записи и чтения предельного граничного адреса (addr = 7)
        addr = 3'd7;
        din  = 8'h55;
        we   = 1'b1;
        @(posedge clk);
        @(negedge clk);
        we = 1'b0;
        check_data(3'd7, 8'h55);

        // Итоги верификации
        #20;
        if (errors == 0) begin
            $display("TEST PASSED: stats_ram");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule