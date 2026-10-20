`timescale 1ns / 1ps

module basys3_lab2_top (
    input  wire        clk,        // Тактовый генератор 100 МГц (вывод W5)
    input  wire        btnC,       // Системный сброс rst (центральная кнопка, U18)
    input  wire        btnU,       // Разрешение генерации enable (кнопка вверх, T18)
    input  wire [3:0]  sw,         // Ввод символа игроком (тумблеры V17, V16, W16, W17)
    output wire [3:0]  led,        // Отображение сгенерированного символа (U16, E19, U19, V19)
    output wire        led4_match, // Флаг верного ввода (светодиод W18)
    output wire        led5_mism   // Флаг ошибки ввода (светодиод U15)
);

    wire [1:0] random_sym;
    wire [1:0] user_sym;
    wire       valid;
    wire       tick;
    wire [3:0] remaining;
    wire       timer_zero;

    // 1. Генератор псевдослучайных символов (LFSR)
    lfsr_generator #(
        .WIDTH ( 2 )
    ) u_lfsr (
        .clk           ( clk ),
        .rst           ( btnC ),
        .enable        ( btnU ),
        .random_number ( random_sym )
    );

    // 2. Приоритетный кодер ввода и компаратор с эталоном
    input_coder_comparator #(
        .NUM_INPUTS ( 4 ),
        .SYM_WIDTH  ( 2 )
    ) u_coder_comp (
        .btn_in      ( sw ),
        .pattern_sym ( random_sym ),
        .user_sym    ( user_sym ),
        .valid       ( valid ),
        .match       ( led4_match ),
        .mismatch    ( led5_mism )
    );

    // 3. Формирователь импульсов 1 Гц (деление 100 МГц)
    tick_generator #(
        .CLK_FREQ  ( 100_000_000 ),
        .TICK_FREQ ( 1 )
    ) u_tick (
        .clk  ( clk ),
        .rst  ( btnC ),
        .tick ( tick )
    );

    // 4. Вычитающий таймер
    countdown_timer #(
        .WIDTH ( 4 )
    ) u_timer (
        .clk        ( clk ),
        .rst        ( btnC ),
        .load       ( btnU ),
        .enable     ( 1'b1 ),
        .tick       ( tick ),
        .load_value ( 4'd9 ),
        .remaining  ( remaining ),
        .zero       ( timer_zero )
    );

    // Отображение текущего 2-битного эталона в унитарный код на 4 светодиодах
    assign led[0] = (random_sym == 2'b00);
    assign led[1] = (random_sym == 2'b01);
    assign led[2] = (random_sym == 2'b10);
    assign led[3] = (random_sym == 2'b11);

endmodule