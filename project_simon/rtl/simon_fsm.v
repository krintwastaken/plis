`timescale 1ns / 1ps

module simon_fsm (
    input wire clk,
    input wire rst,
    input wire start,
    input wire finish,
    input wire foul_en,
    input wire valid,
    input wire match,
    input wire mismatch,
    input wire timer_zero,
    input wire idx_over,
    input wire [7:0] score_val,
    input wire [7:0] high_score_val,
    output reg settings_load,
    output reg score_clear,
    output reg score_add,
    output reg idx_reset,
    output reg idx_inc,
    output reg len_reset,
    output reg len_inc,
    output reg timer_load,
    output reg timer_enable,
    output reg lfsr_enable,
    output reg ram_we,
    output reg led_enable,
    output reg stats_we,
    output reg show_score,
    output reg game_active,
    output reg foul_error
);

    localparam [3:0]
        S_IDLE         = 4'd0,
        S_PREPARE      = 4'd1,
        S_APPEND       = 4'd2,
        S_SHOW_ADDR    = 4'd3,
        S_SHOW_LED     = 4'd4,
        S_SHOW_GAP     = 4'd5,
        S_PRE_INPUT    = 4'd6,
        S_WAIT_INPUT   = 4'd7,
        S_CHECK_INPUT  = 4'd8,
        S_WAIT_RELEASE = 4'd9,
        S_INPUT_INC    = 4'd10,
        S_SUCCESS      = 4'd11,
        S_FOUL         = 4'd12,
        S_UPDATE_STATS = 4'd13,
        S_RESULT       = 4'd14;

    reg [3:0] state;
    reg [3:0] next_state;

    // 1. Синхронный регистр текущего состояния
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 2. Комбинационная логика переходов
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (start) begin
                    next_state = S_PREPARE;
                end
            end

            S_PREPARE: begin
                next_state = S_APPEND;
            end

            S_APPEND: begin
                next_state = S_SHOW_ADDR;
            end

            S_SHOW_ADDR: begin
                next_state = S_SHOW_LED;
            end

            S_SHOW_LED: begin
                if (foul_en && valid) begin
                    next_state = S_FOUL;
                end else if (timer_zero) begin
                    if (idx_over) begin
                        next_state = S_PRE_INPUT;
                    end else begin
                        next_state = S_SHOW_GAP;
                    end
                end
            end

            S_SHOW_GAP: begin
                next_state = S_SHOW_ADDR;
            end

            S_PRE_INPUT: begin
                next_state = S_WAIT_INPUT;
            end

            S_WAIT_INPUT: begin
                if (timer_zero) begin
                    if (score_val > high_score_val) begin
                        next_state = S_UPDATE_STATS;
                    end else begin
                        next_state = S_RESULT;
                    end
                end else if (valid) begin
                    next_state = S_CHECK_INPUT;
                end
            end

            S_CHECK_INPUT: begin
                if (timer_zero || mismatch) begin
                    if (score_val > high_score_val) begin
                        next_state = S_UPDATE_STATS;
                    end else begin
                        next_state = S_RESULT;
                    end
                end else if (match) begin
                    next_state = S_WAIT_RELEASE;
                end else begin
                    next_state = S_WAIT_INPUT;
                end
            end

            S_WAIT_RELEASE: begin
                if (timer_zero) begin
                    if (score_val > high_score_val) begin
                        next_state = S_UPDATE_STATS;
                    end else begin
                        next_state = S_RESULT;
                    end
                end else if (!valid) begin
                    if (idx_over) begin
                        next_state = S_SUCCESS;
                    end else begin
                        next_state = S_INPUT_INC;
                    end
                end
            end

            S_INPUT_INC: begin
                next_state = S_WAIT_INPUT;
            end

            S_SUCCESS: begin
                next_state = S_APPEND;
            end

            S_FOUL: begin
                if (score_val > high_score_val) begin
                    next_state = S_UPDATE_STATS;
                end else begin
                    next_state = S_RESULT;
                end
            end

            S_UPDATE_STATS: begin
                next_state = S_RESULT;
            end

            S_RESULT: begin
                if (start) begin
                    next_state = S_PREPARE;
                end else if (finish) begin
                    next_state = S_IDLE;
                end
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // 3. Комбинационная логика выходов автомата Мура
    always @(*) begin
        settings_load = 1'b0;
        score_clear = 1'b0;
        score_add = 1'b0;
        idx_reset = 1'b0;
        idx_inc = 1'b0;
        len_reset = 1'b0;
        len_inc = 1'b0;
        timer_load = 1'b0;
        timer_enable = 1'b0;
        lfsr_enable = 1'b0;
        ram_we = 1'b0;
        led_enable = 1'b0;
        stats_we = 1'b0;
        show_score = 1'b0;
        game_active = 1'b0;
        foul_error = 1'b0;

        case (state)
            S_PREPARE: begin
                settings_load = 1'b1;
                score_clear = 1'b1;
                idx_reset = 1'b1;
                len_reset = 1'b1;
                game_active = 1'b1;
            end

            S_APPEND: begin
                lfsr_enable = 1'b1;
                ram_we = 1'b1;
                idx_reset = 1'b1;
                game_active = 1'b1;
            end

            S_SHOW_ADDR: begin
                timer_load = 1'b1;
                game_active = 1'b1;
            end

            S_SHOW_LED: begin
                led_enable = 1'b1;
                timer_enable = 1'b1;
                game_active = 1'b1;
            end

            S_SHOW_GAP: begin
                idx_inc = 1'b1;
                game_active = 1'b1;
            end

            S_PRE_INPUT: begin
                idx_reset = 1'b1;
                timer_load = 1'b1;
                game_active = 1'b1;
            end

            S_WAIT_INPUT: begin
                timer_enable = 1'b1;
                game_active = 1'b1;
            end

            S_CHECK_INPUT: begin
                game_active = 1'b1;
            end

            S_WAIT_RELEASE: begin
                timer_enable = 1'b1;
                game_active = 1'b1;
            end

            S_INPUT_INC: begin
                idx_inc = 1'b1;
                timer_load = 1'b1;
                game_active = 1'b1;
            end

            S_SUCCESS: begin
                score_add = 1'b1;
                len_inc = 1'b1;
                game_active = 1'b1;
            end

            S_FOUL: begin
                foul_error = 1'b1;
                show_score = 1'b1;
            end

            S_UPDATE_STATS: begin
                stats_we = 1'b1;
                show_score = 1'b1;
            end

            S_RESULT: begin
                show_score = 1'b1;
            end

            default: begin
                // S_IDLE и неопределенные состояния: все выходы равны нулю
            end
        endcase
    end

endmodule
