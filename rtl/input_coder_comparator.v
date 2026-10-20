`timescale 1ns / 1ns

module input_coder_comparator #(
    parameter NUM_INPUTS = 4,
    parameter SYM_WIDTH = 2
)(
    input wire [NUM_INPUTS-1:0] btn_in,
    input wire [SYM_WIDTH-1:0] pattern_sym,
    output reg [SYM_WIDTH-1:0] user_sym,
    output reg valid,
    output wire match,
    output wire mismatch
);

    integer i;

    always @(*) begin
        valid = 1'b0;
        user_sym = {SYM_WIDTH{1'b0}};

        for (i = 0; i < NUM_INPUTS; i = i + 1) begin
            if (btn_in[i]) begin
                user_sym = i[SYM_WIDTH-1:0];
                valid = 1'b1;
            end
        end
    end

    assign match = valid & (user_sym == pattern_sym);
    assign mismatch = valid & (user_sym != pattern_sym);

endmodule