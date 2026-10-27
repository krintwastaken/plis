`timescale 1ns / 1ns

module sequence_rom_tb;

    parameter integer DATA_WIDTH = 2;
    parameter integer DEPTH = 16;
    parameter integer ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);

    reg [ADDR_WIDTH-1:0] addr;
    wire [DATA_WIDTH-1:0] data;

    reg [DATA_WIDTH-1:0] expected;
    integer i;
    integer errors;

    sequence_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .INIT_FILE("patterns.mem")
    ) dut (
        .addr(addr),
        .data(data)
    );

    // Эталонная цепочка строго соответствует patterns.mem
    function [DATA_WIDTH-1:0] get_expected;
        input integer idx;
        begin
            case (idx)
                0: get_expected = 2'h0;
                1: get_expected = 2'h1;
                2: get_expected = 2'h3;
                3: get_expected = 2'h2;
                4: get_expected = 2'h1;
                5: get_expected = 2'h0;
                6: get_expected = 2'h2;
                7: get_expected = 2'h3;
                8: get_expected = 2'h3;
                9: get_expected = 2'h2;
                10: get_expected = 2'h0;
                11: get_expected = 2'h1;
                12: get_expected = 2'h2;
                13: get_expected = 2'h3;
                14: get_expected = 2'h1;
                15: get_expected = 2'h0;
                default: get_expected = 2'h0;
            endcase
        end
    endfunction

    initial begin
        addr = {ADDR_WIDTH{1'b0}};
        errors = 0;
        #10;

        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = i[ADDR_WIDTH-1:0];
            expected = get_expected(i);
            #10;
            if (data !== expected) begin
                $display("ERROR: addr = %0d, data = %b, expected = %b", addr, data, expected);
                errors = errors + 1;
            end
        end

        #10;
        if (errors == 0) begin
            $display("TEST PASSED: sequence_rom");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end

endmodule