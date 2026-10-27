`timescale 1ns / 1ns

module sequence_ram_tb;

    parameter integer DATA_WIDTH = 2;
    parameter integer DEPTH      = 16;
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);

    reg                  clk;
    reg                  we;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    reg [DATA_WIDTH-1:0] shadow_mem [0:DEPTH-1];
    integer i;
    integer errors;

    // Подключение тестируемого модуля (DUT)
    sequence_ram #(
        .DATA_WIDTH ( DATA_WIDTH ),
        .DEPTH      ( DEPTH )
    ) DUT (
        .clk  ( clk ),
        .we   ( we ),
        .addr ( addr ),
        .din  ( din ),
        .dout ( dout )
    );

    // Тактовый сигнал с периодом 10 нс (100 МГц)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        clk    = 1'b0;
        we     = 1'b0;
        addr   = {ADDR_WIDTH{1'b0}};
        din    = {DATA_WIDTH{1'b0}};
        errors = 0;

        // 1. Запись цепочки символов раунда (адреса 0..7)
        @(negedge clk);
        for (i = 0; i < 8; i = i + 1) begin
            we   = 1'b1;
            addr = i[ADDR_WIDTH-1:0];
            // Тестовый набор псевдослучайных символов: 1, 2, 0, 3, 2, 1, 3, 0
            case (i)
                0: din = 2'h1;
                1: din = 2'h2;
                2: din = 2'h0;
                3: din = 2'h3;
                4: din = 2'h2;
                5: din = 2'h1;
                6: din = 2'h3;
                7: din = 2'h0;
            endcase
            shadow_mem[i] = din;
            @(negedge clk);
        end
        we = 1'b0;

        // 2. Последовательное синхронное считывание и автоматическая верификация
        for (i = 0; i < 8; i = i + 1) begin
            addr = i[ADDR_WIDTH-1:0];
            @(posedge clk); // Такт защелкивания адреса
            #1;             // Учет тактовой задержки синхронного чтения
            if (dout !== shadow_mem[i]) begin
                $display("ERROR read at addr %0d: dout = %b, expected = %b", i, dout, shadow_mem[i]);
                errors = errors + 1;
            end else begin
                $display("OK read: addr = %0d, symbol = %0d", i, dout);
            end
            @(negedge clk);
        end

        // 3. Проверка режима удержания данных (попытка записи при we = 0)
        addr = 4'd3;
        din  = 2'h1; // Попытка затереть символ 3 на шаге 3
        we   = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== shadow_mem[3]) begin
            $display("ERROR: we=0 hold failed! dout = %b, expected = %b", dout, shadow_mem[3]);
            errors = errors + 1;
        end

        // 4. Проверка записи и чтения предельного граничного адреса (DEPTH - 1 = 15)
        @(negedge clk);
        addr = 4'd15;
        din  = 2'h2;
        we   = 1'b1;
        @(negedge clk);
        we   = 1'b0;
        @(posedge clk);
        #1;
        if (dout !== 2'h2) begin
            $display("ERROR: boundary addr 15 failed! dout = %b", dout);
            errors = errors + 1;
        end

        // 5. Проверка режима Read-First (одновременная запись и чтение по адресу 4'd1)
        @(negedge clk);
        addr = 4'd1;
        din  = 2'h0; // Новое значение для записи
        we   = 1'b1;
        @(posedge clk);
        #1;
        // В режиме Read-First на этом такте должно появиться старое значение shadow_mem[1] = 2'h2
        if (dout !== shadow_mem[1]) begin
            $display("ERROR: Read-First mode failed! dout = %b, expected old = %b", dout, shadow_mem[1]);
            errors = errors + 1;
        end
        @(negedge clk);
        we = 1'b0;

        // Контроль, что новое значение 2'h0 действительно записалось в память
        @(posedge clk);
        #1;
        if (dout !== 2'h0) begin
            $display("ERROR: New value not written in Read-First test! dout = %b", dout);
            errors = errors + 1;
        end

        // Итоги верификации
        #20;
        if (errors == 0) begin
            $display("TEST PASSED: sequence_ram");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule