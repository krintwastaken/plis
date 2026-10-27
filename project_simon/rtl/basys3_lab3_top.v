`timescale 1ns / 1ps

module basys3_lab3_top (
    input  wire        clk,
    input  wire        btnC,
    input  wire        btnU,
    input  wire        btnD,
    input  wire [15:0] sw,
    output reg  [15:0] led
);

    // 1. Подавление дребезга и формирование одиночных стробов
    reg [2:0] btnC_sync;
    reg [2:0] btnU_sync;
    reg [2:0] btnD_sync;

    always @(posedge clk) begin
        btnC_sync <= {btnC_sync[1:0], btnC};
        btnU_sync <= {btnU_sync[1:0], btnU};
        btnD_sync <= {btnD_sync[1:0], btnD};
    end

    wire we_pulse   = (btnC_sync[2:1] == 2'b01);
    wire load_pulse = (btnU_sync[2:1] == 2'b01);
    wire rst_sync   = btnD_sync[2];

    // 2. Сигналы интерфейсов модулей памяти
    wire [1:0] rom_data;
    wire [1:0] seq_ram_dout;
    wire [7:0] stats_dout;
    wire [7:0] reg_q;

    // 3. Экземпляр постоянной памяти фиксированных последовательностей
    sequence_rom #(
        .DATA_WIDTH ( 2 ),
        .DEPTH      ( 16 ),
        .INIT_FILE  ( "patterns.mem" )
    ) u_rom (
        .addr ( sw[3:0] ),
        .data ( rom_data )
    );

    // 4. Экземпляр оперативной памяти формируемой последовательности
    sequence_ram #(
        .DATA_WIDTH ( 2 ),
        .DEPTH      ( 16 )
    ) u_seq_ram (
        .clk  ( clk ),
        .we   ( we_pulse && (sw[5:4] == 2'b01) ),
        .addr ( sw[3:0] ),
        .din  ( sw[7:6] ),
        .dout ( seq_ram_dout )
    );

    // 5. Экземпляр памяти статистики и таблицы рекордов
    stats_ram #(
        .DATA_WIDTH ( 8 ),
        .DEPTH      ( 8 ),
        .INIT_FILE  ( "stats_init.mem" )
    ) u_stats_ram (
        .clk  ( clk ),
        .we   ( we_pulse && (sw[5:4] == 2'b10) ),
        .addr ( sw[2:0] ),
        .din  ( sw[15:8] ),
        .dout ( stats_dout )
    );

    // 6. Экземпляр параметризованного регистра раунда
    round_param_reg #(
        .WIDTH ( 8 )
    ) u_param_reg (
        .clk  ( clk ),
        .rst  ( rst_sync ),
        .load ( load_pulse && (sw[5:4] == 2'b11) ),
        .d    ( sw[15:8] ),
        .q    ( reg_q )
    );

    // 7. Комбинационный мультиплексор вывода на линейку светодиодов
    always @(*) begin
        led = 16'h0000;
        led[5:4] = sw[5:4]; // Индикация активного режима

        case (sw[5:4])
            2'b00: begin // Режим 0: Sequence ROM
                led[1:0] = rom_data;
                led[3:2] = 2'b00;
            end
            2'b01: begin // Режим 1: Sequence RAM
                led[1:0] = seq_ram_dout;
                led[7:6] = sw[7:6]; // Эхо записываемых данных
            end
            2'b10: begin // Режим 2: Stats RAM
                led[15:8] = stats_dout;
            end
            2'b11: begin // Режим 3: Round Param Register
                led[15:8] = reg_q;
            end
        endcase
    end

endmodule