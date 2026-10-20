`timescale 1ns / 1ns

module countdown_timer_tb();

    reg clk;
    reg rst;
    reg load;
    reg enable;
    reg tick;
    reg [3:0] load_value;

    wire [3:0] remaining;
    wire zero;

    countdown_timer #(
        .WIDTH ( 4 )
    ) DUT (
        .clk ( clk ),
        .rst ( rst ),
        .load ( load ),
        .enable ( enable ),
        .tick ( tick ),
        .load_value ( load_value ),
        .remaining ( remaining ),
        .zero ( zero )
    );

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        load = 1'b0;
        enable = 1'b0;
        tick = 1'b0;
        load_value = 4'b1100;
    end

    always #5 clk = ~clk;

    initial begin
        @(negedge clk);
        rst = 1'b0;
        load = 1'b1;

        @(negedge clk);
        load = 1'b0;
        enable = 1'b1;
        tick = 1'b1;

        repeat ( load_value ) @(negedge clk);
        #1;
        if ( remaining !== 4'd0 || !zero ) begin
            $fatal( 1 , "countdown failed" );
        end

        repeat ( load_value ) @(negedge clk);
        #1;
        if ( remaining !== 4'd0 ) begin
            $fatal( 1 , "underflow" );
        end

        $display( "PASS countdown_timer" );
        $finish;
    end

endmodule