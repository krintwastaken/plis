`timescale 1ns / 1ns

module input_coder_comparator_tb;

    parameter NUM_INPUTS = 4;
    parameter SYM_WIDTH = 2;

    reg [NUM_INPUTS-1:0] btn_in;
    reg [SYM_WIDTH-1:0] pattern_sym;
    
    wire [SYM_WIDTH-1:0] user_sym;
    wire valid;
    wire match;
    wire mismatch;
    
    reg [SYM_WIDTH-1:0] exp_user_sym;
    reg exp_valid;
    reg exp_match;
    reg exp_mismatch;
    
    integer i, p, k;
    integer errors;
    input_coder_comparator #(
        .NUM_INPUTS(NUM_INPUTS),
        .SYM_WIDTH(SYM_WIDTH)
    ) DUT (
        .btn_in(btn_in),
        .pattern_sym(pattern_sym),
        .user_sym(user_sym),
        .valid(valid),
        .match(match),
        .mismatch(mismatch)
    );
    always @(*) begin
        exp_valid = 1'b0;
        exp_user_sym = {SYM_WIDTH{1'b0}};
        for (k = 0; k < NUM_INPUTS; k = k + 1) begin
            if (btn_in[k]) begin
                exp_user_sym = k[SYM_WIDTH-1:0];
                exp_valid = 1'b1;
            end
        end
        exp_match = exp_valid & (exp_user_sym == pattern_sym);
        exp_mismatch = exp_valid & (exp_user_sym != pattern_sym);
    end
    initial begin
        errors = 0;
        btn_in = 0;
        pattern_sym = 0;
        #20;
        for (p = 0; p < (1 << SYM_WIDTH); p = p + 1) begin
            pattern_sym = p[SYM_WIDTH-1:0];
            for (i = 0; i < (1 << NUM_INPUTS); i = i + 1) begin
                btn_in = i[NUM_INPUTS-1:0];
                #10;
                if ((user_sym !== exp_user_sym) || (valid !== exp_valid) || (match !== exp_match) || (mismatch !== exp_mismatch)) begin
                    $display("ERROR: Time=%0t | btn_in=%b pattern=%0d | DUT: valid=%b sym=%0d match=%b mismatch=%b | EXP: valid=%b sym=%0d match=%b mismatch=%b",
                             $time, btn_in, pattern_sym, valid, user_sym, match, mismatch, exp_valid, exp_user_sym, exp_match, exp_mismatch);
                    errors = errors + 1;
                end
            end
        end
        #20;
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);
        $finish;
    end
endmodule