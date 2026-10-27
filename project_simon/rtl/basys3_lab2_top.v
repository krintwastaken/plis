`timescale 1ns / 1ps

module basys3_lab2_top (
    input wire clk,
    input wire btnC,
    input wire btnU,
    input wire [3:0] sw,
    output wire [3:0] led,
    output wire led4_match,
    output wire led5_mism
);

    wire [1:0] random_sym;
    wire [1:0] user_sym;
    wire valid;
    wire tick;
    wire [3:0] remaining;
    wire timer_zero;
    wire btnU_state;
    wire btnU_pulse;

    // Синхронизация асинхронной кнопки сброса
    reg [1:0] rst_sync;
    always @(posedge clk) begin
        rst_sync <= {rst_sync[0], btnC};
    end
    wire rst = rst_sync[1];

    // Подавление дребезга и формирование одиночного строба по нажатию btnU
    button_debouncer #(
        .CLK_FREQ(100_000_000),
        .DEBOUNCE_MS(20)
    ) u_btnU_debouncer (
        .clk(clk),
        .rst(rst),
        .btn_in(btnU),
        .btn_state(btnU_state),
        .btn_pulse(btnU_pulse)
    );

    lfsr_generator #(
        .WIDTH(2)
    ) u_lfsr (
        .clk(clk),
        .rst(rst),
        .enable(btnU_pulse),
        .random_number(random_sym)
    );

    input_coder_comparator #(
        .NUM_INPUTS(4),
        .SYM_WIDTH(2)
    ) u_coder_comp (
        .btn_in(sw),
        .pattern_sym(random_sym),
        .user_sym(user_sym),
        .valid(valid),
        .match(led4_match),
        .mismatch(led5_mism)
    );

    tick_generator u_tick (
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );

    countdown_timer #(
        .WIDTH(4)
    ) u_timer (
        .clk(clk),
        .rst(rst),
        .load(btnU_pulse),
        .enable(1'b1),
        .tick(tick),
        .load_value(4'd9),
        .remaining(remaining),
        .zero(timer_zero)
    );

    assign led[0] = (random_sym == 2'b00);
    assign led[1] = (random_sym == 2'b01);
    assign led[2] = (random_sym == 2'b10);
    assign led[3] = (random_sym == 2'b11);

endmodule