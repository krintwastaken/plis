`timescale 1ns / 1ps

module button_debouncer #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input wire clk,
    input wire rst,
    input wire btn_in,
    output reg btn_state,
    output reg btn_pulse
);

    localparam integer CNT_MAX = (CLK_FREQ / 1000) * DEBOUNCE_MS;
    localparam integer CNT_WIDTH = $clog2(CNT_MAX + 1);

    reg [CNT_WIDTH-1:0] timer;
    reg [2:0] sync_reg;

    always @(posedge clk) begin
        if (rst) begin
            sync_reg <= 3'b000;
            timer <= {CNT_WIDTH{1'b0}};
            btn_state <= 1'b0;
            btn_pulse <= 1'b0;
        end else begin
            sync_reg <= {sync_reg[1:0], btn_in};
            btn_pulse <= 1'b0;

            if (sync_reg[2] != btn_state) begin
                if (timer >= CNT_MAX) begin
                    btn_state <= sync_reg[2];
                    timer <= {CNT_WIDTH{1'b0}};
                    if (sync_reg[2] == 1'b1) begin
                        btn_pulse <= 1'b1;
                    end
                end else begin
                    timer <= timer + 1'b1;
                end
            end else begin
                timer <= {CNT_WIDTH{1'b0}};
            end
        end
    end

endmodule