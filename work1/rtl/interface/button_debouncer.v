`timescale 1ns / 1ns 
//============================================================
// Модуль подавления дребезга одной кнопки.
//
// Выполняет:
//   1. синхронизацию асинхронного входа;
//   2. проверку устойчивости нового значения;
//   3. формирование очищенного уровня;
//   4. формирование импульса только при нажатии.
//
// Для Basys3:
//   CLK_FREQ = 100_000_000 Гц;
//   DEBOUNCE_MS = 20 мс.
//============================================================
module button_debouncer #(
    parameter integer CLK_FREQ    = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
    
)(
    input  wire clk,
    input  wire rst,
    input  wire button_in,

    output reg  button_level,
    output wire button_pulse
);

    //--------------------------------------------------------
    // Число тактов, соответствующее времени фильтрации
    //--------------------------------------------------------
localparam integer DEBOUNCE_CYCLES_CALC =
    (CLK_FREQ / 1000) * DEBOUNCE_MS;

localparam integer DEBOUNCE_CYCLES =
    (DEBOUNCE_CYCLES_CALC < 1)
        ? 1
        : DEBOUNCE_CYCLES_CALC;

    localparam integer COUNTER_WIDTH =
        (DEBOUNCE_CYCLES <= 1)
            ? 1
            : $clog2(DEBOUNCE_CYCLES);

    //--------------------------------------------------------
    // Двухтактный синхронизатор
    //--------------------------------------------------------
    reg button_meta;
    reg button_sync;

    //--------------------------------------------------------
    // Счетчик устойчивости входного сигнала
    //--------------------------------------------------------
    reg [COUNTER_WIDTH-1:0] counter;

    //--------------------------------------------------------
    // Предыдущее очищенное состояние
    //--------------------------------------------------------
    reg button_level_d;

    //--------------------------------------------------------
    // Синхронизация входа
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            button_meta <= 1'b0;
            button_sync <= 1'b0;
        end
        else begin
            button_meta <= button_in;
            button_sync <= button_meta;
        end
    end

    //--------------------------------------------------------
    // Подавление дребезга
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            counter      <= {COUNTER_WIDTH{1'b0}};
            button_level <= 1'b0;
        end
        else begin

            // Вход совпадает с текущим очищенным состоянием:
            // подтверждать изменение не требуется.
            if (button_sync == button_level) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end

            // Обнаружено возможное изменение состояния.
            else if (counter == DEBOUNCE_CYCLES - 1) begin
                counter      <= {COUNTER_WIDTH{1'b0}};
                button_level <= button_sync;
            end

            // Ожидание устойчивого входного уровня.
            else begin
                counter <= counter + 1'b1;
            end

        end
    end

    //--------------------------------------------------------
    // Регистрация предыдущего очищенного уровня
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            button_level_d <= 1'b0;
        else
            button_level_d <= button_level;
    end


    //--------------------------------------------------------
    // Импульс длительностью один такт только при нажатии
    //--------------------------------------------------------
    assign button_pulse = button_level & ~button_level_d;

endmodule
