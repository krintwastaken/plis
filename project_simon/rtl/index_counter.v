module index_counter
#(
    parameter WIDTH = 4
)
(
    input  wire             clk,        // Синхросигнал
    input  wire             reset,      // Синхронный сброс
    input  wire             load,       // Загрузка начального значения
    input  wire             en_count,   // Разрешение счета
    input  wire [WIDTH-1:0] data_load,  // Значение для загрузки
    input  wire [WIDTH-1:0] max_len,    // Текущая длина последовательности
    output reg  [WIDTH-1:0] count,      // Текущий индекс символа
    output reg              over        // Флаг завершения последовательности
);

    always @(posedge clk) begin
        if (reset) begin
            count <= {WIDTH{1'b0}};
            over  <= 1'b0;
        end
        else if (load) begin
            count <= data_load;
            over  <= (data_load >= (max_len - 1'b1)) && (max_len != {WIDTH{1'b0}});
        end
        else if (en_count) begin
            if (count >= (max_len - 1'b1)) begin
                // Достигнут конец последовательности: фиксация флага over и останов счета
                over  <= 1'b1;
            end
            else begin
                count <= count + 1'b1;
                // Формирование over на последнем шаге
                over  <= ((count + 1'b1) >= (max_len - 1'b1));
            end
        end
    end

endmodule